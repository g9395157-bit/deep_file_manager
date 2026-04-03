import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../constants/colors.dart';
import '../models/file_item.dart';
import '../models/file_type.dart';
import '../screens/file_viewer_screen.dart';
import '../utils/file_service.dart';
import '../utils/recent_service.dart';
import '../widgets/buttons/icon_button.dart';
import '../widgets/dialogs/confirmation_card.dart';
import '../widgets/tiles/file_row.dart';
import '../widgets/tiles/folder_grid_tile.dart';

/// Completely rewritten Files screen.
///
/// Key fixes:
///   • Tapping a folder NAVIGATES INTO IT — no bottom sheet on tap.
///   • Long-pressing any item shows the context menu (rename / delete / details).
///   • The navigation stack is managed internally; the system Back button pops
///     one level up rather than leaving the screen.
///   • Sort is applied to the in-memory list — no re-scan.
///   • Search is debounced (300 ms) and filters the already-loaded directory
///     listing — no filesystem traversal on every keystroke.
class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  // ── Navigation stack (list of absolute paths already visited)
  final List<String> _pathStack = [];

  /// The directory currently displayed. Falls back to internal storage root.
  String get _currentPath =>
      _pathStack.isEmpty ? '/storage/emulated/0' : _pathStack.last;

  bool get _canGoUp => _pathStack.isNotEmpty;

  // ── File data
  List<FileItem> _allItems = []; // raw listing of current directory
  List<FileItem> _displayItems = []; // after sort + search filter
  bool _loading = true;
  String? _error;

  // ── UI toggles
  bool _isGrid = false;
  String _sort = 'Name';
  bool _sortAscending = true;

  // ── Search
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  // ──────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadDirectory(_currentPath);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Directory loading
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _loadDirectory(String path) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _allItems = [];
      _displayItems = [];
    });

    try {
      final items = await FileService.listFiles(path);
      if (!mounted) return;
      setState(() {
        _allItems = items;
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Navigation
  // ──────────────────────────────────────────────────────────────────────────

  void _navigateInto(FileItem item) {
    if (item.type == FileType.folder) {
      // Push this folder onto the stack and load it
      setState(() => _pathStack.add(item.path));
      if (_isSearching) _exitSearch();
      _loadDirectory(item.path);
    } else {
      _openFile(item);
    }
  }

  void _navigateUp() {
    if (!_canGoUp) return;
    setState(() => _pathStack.removeLast());
    if (_isSearching) _exitSearch();
    _loadDirectory(_currentPath);
  }

  /// Navigate to a specific level in the breadcrumb.
  void _navigateTo(int stackIndex) {
    // stackIndex == -1 means "root" (before the first push)
    if (stackIndex == _pathStack.length - 1) return; // already there
    setState(() {
      if (stackIndex < 0) {
        _pathStack.clear();
      } else {
        _pathStack.removeRange(stackIndex + 1, _pathStack.length);
      }
    });
    if (_isSearching) _exitSearch();
    _loadDirectory(_currentPath);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Search — debounced, filters in-memory list only
  // ──────────────────────────────────────────────────────────────────────────

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchCtrl.clear();
        _applyFilter();
      }
    });
  }

  void _exitSearch() {
    _searchCtrl.clear();
    setState(() => _isSearching = false);
    _applyFilter();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _applyFilter(),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Sort + Filter — pure in-memory, O(n) at most
  // ──────────────────────────────────────────────────────────────────────────

  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase();

    List<FileItem> items = List.from(_allItems);

    // 1. Filter by search query
    if (query.isNotEmpty) {
      items = items.where((f) => f.name.toLowerCase().contains(query)).toList();
    }

    // 2. Sort: folders always float to the top
    items.sort((a, b) {
      final aDir = a.type == FileType.folder;
      final bDir = b.type == FileType.folder;
      if (aDir != bDir) return aDir ? -1 : 1;

      int cmp = switch (_sort) {
        'Name' => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        'Size' => a.sizeBytes.compareTo(b.sizeBytes),
        'Date' => (a.modifiedAt ?? DateTime(0)).compareTo(
          b.modifiedAt ?? DateTime(0),
        ),
        'Type' => a.type.name.compareTo(b.type.name),
        _ => 0,
      };
      return _sortAscending ? cmp : -cmp;
    });

    setState(() => _displayItems = items);
  }

  void _setSort(String sort) {
    if (_sort == sort) {
      setState(() => _sortAscending = !_sortAscending);
    } else {
      setState(() {
        _sort = sort;
        _sortAscending = true;
      });
    }
    _applyFilter();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // File actions
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _openFile(FileItem item) async {
    await RecentService.addRecent(item.path);
    if (!mounted) return;
    if ([
      FileType.image,
      FileType.video,
      FileType.audio,
      FileType.document,
    ].contains(item.type)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FileViewerScreen(item: item)),
      );
    } else {
      try {
        await FileService.openFile(item.path);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Unable to open file')));
        }
      }
    }
  }

  /// Long-press → action sheet (Open / Details / Rename / Delete)
  void _showContextMenu(FileItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContextSheet(
        item: item,
        onOpen: () {
          Navigator.pop(context);
          if (item.type == FileType.folder) {
            _navigateInto(item);
          } else {
            _openFile(item);
          }
        },
        onDetails: () {
          Navigator.pop(context);
          _showDetails(item);
        },
        onRename: () {
          Navigator.pop(context);
          _showRenameDialog(item);
        },
        onDelete: () {
          Navigator.pop(context);
          _showDeleteDialog(item);
        },
      ),
    );
  }

  void _showDetails(FileItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        icon: Icon(_fileIcon(item.type), color: kAmber),
        title: Text(item.name, style: TextStyle(color: kBright, fontSize: 14)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Type', _fileTypeLabel(item.type)),
              _detailRow('Size', item.size.isEmpty ? '—' : item.size),
              _detailRow(
                'Modified',
                item.modified.isEmpty ? '—' : item.modified,
              ),
              _detailRow('Path', item.path),
              if (item.type == FileType.folder && item.itemCount > 0)
                _detailRow('Items', '${item.itemCount}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: kAmber)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: kMuted, fontSize: 11, letterSpacing: 0.5),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(color: kBright, fontSize: 13),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(FileItem item) {
    final ctrl = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (ctx) => _RenameDialog(
        item: item,
        controller: ctrl,
        onConfirm: () async {
          final newName = ctrl.text.trim();
          if (newName.isEmpty || newName == item.name) {
            Navigator.pop(ctx);
            return;
          }
          final dir = p.dirname(item.path);
          final newPath = '$dir/$newName';
          try {
            await FileService.rename(item.path, newPath);
            if (mounted) {
              Navigator.pop(ctx);
              _loadDirectory(_currentPath);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Renamed successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        },
      ),
    );
  }

  void _showDeleteDialog(FileItem item) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationCard(
        title: 'Delete',
        message: 'Delete "${item.name}"?\n\nThis cannot be undone.',
        confirmText: 'Delete',
        type: ConfirmationType.destructive,
        icon: Icons.delete_outline_rounded,
        onConfirm: () async {
          try {
            await FileService.deletePath(item.path);
            if (mounted) {
              _loadDirectory(_currentPath);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Deleted successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Breadcrumb
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildBreadcrumb() {
    // Segments: ["Internal", folderA, folderB, ...]
    final segments = <_BreadcrumbSegment>[
      _BreadcrumbSegment(label: 'Internal', stackIndex: -1),
      for (int i = 0; i < _pathStack.length; i++)
        _BreadcrumbSegment(label: p.basename(_pathStack[i]), stackIndex: i),
    ];

    return SizedBox(
      height: 28,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: segments.length,
        itemBuilder: (_, i) {
          final seg = segments[i];
          final isLast = i == segments.length - 1;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (i > 0)
                Icon(Icons.chevron_right_rounded, size: 14, color: kMuted),
              GestureDetector(
                onTap: isLast ? null : () => _navigateTo(seg.stackIndex),
                child: Text(
                  seg.label,
                  style: TextStyle(
                    color: isLast ? kAmber : kMuted,
                    fontSize: 13,
                    fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return PopScope(
      // When the navigation stack has folders, intercept back to pop one level
      canPop: !_canGoUp,
      onPopInvoked: (didPop) {
        if (!didPop && _canGoUp) _navigateUp();
      },
      child: Column(
        children: [
          // ── Top bar
          Container(
            color: kBg,
            padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 12),
            child: Row(
              children: [
                // Back arrow when inside a subfolder
                if (_canGoUp)
                  GestureDetector(
                    onTap: _navigateUp,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: kAmber,
                        size: 20,
                      ),
                    ),
                  ),

                Expanded(
                  child: _isSearching
                      ? TextField(
                          controller: _searchCtrl,
                          autofocus: true,
                          style: TextStyle(color: kBright, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Search in folder…',
                            hintStyle: TextStyle(color: kMuted),
                            border: InputBorder.none,
                          ),
                          onChanged: _onSearchChanged,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Internal Storage',
                              style: TextStyle(
                                color: kMuted,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              _canGoUp ? p.basename(_currentPath) : 'Files',
                              style: TextStyle(
                                color: kBright,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),

                IconBtn(
                  icon: _isSearching
                      ? Icons.close_rounded
                      : Icons.search_rounded,
                  onTap: _toggleSearch,
                ),
                const SizedBox(width: 8),
                IconBtn(
                  icon: _isGrid
                      ? Icons.view_list_rounded
                      : Icons.grid_view_rounded,
                  onTap: () => setState(() => _isGrid = !_isGrid),
                ),
              ],
            ),
          ),

          // ── Sort chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['Name', 'Size', 'Date', 'Type'].map((s) {
                final sel = _sort == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s),
                        if (sel) ...[
                          const SizedBox(width: 2),
                          Icon(
                            _sortAscending
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 12,
                            color: kAmber,
                          ),
                        ],
                      ],
                    ),
                    selected: sel,
                    onSelected: (_) => _setSort(s),
                    backgroundColor: kCard,
                    selectedColor: kAmber.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: sel ? kAmber : kMuted,
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: sel ? kAmber.withOpacity(0.5) : kBorder,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // ── Breadcrumb
          _buildBreadcrumb(),
          const SizedBox(height: 10),

          // ── File count
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Row(
                children: [
                  Text(
                    _searchCtrl.text.isNotEmpty
                        ? '${_displayItems.length} result${_displayItems.length == 1 ? '' : 's'}'
                        : '${_displayItems.length} item${_displayItems.length == 1 ? '' : 's'}',
                    style: TextStyle(color: kMuted, fontSize: 12),
                  ),
                ],
              ),
            ),

          // ── Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, color: kMuted, size: 48),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: TextStyle(color: kMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _loadDirectory(_currentPath),
              child: Text('Retry', style: TextStyle(color: kAmber)),
            ),
          ],
        ),
      );
    }

    if (_displayItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isSearching
                  ? Icons.search_off_rounded
                  : Icons.folder_open_rounded,
              color: kMuted,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _isSearching
                  ? 'No files match "${_searchCtrl.text}"'
                  : 'This folder is empty',
              style: TextStyle(color: kMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _displayItems.length,
        itemBuilder: (_, i) {
          final item = _displayItems[i];
          return GestureDetector(
            onTap: () => _navigateInto(item),
            onLongPress: () => _showContextMenu(item),
            child: FolderGridTile(folder: item),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      physics: const BouncingScrollPhysics(),
      itemCount: _displayItems.length,
      itemBuilder: (_, i) {
        final item = _displayItems[i];
        return GestureDetector(
          onLongPress: () => _showContextMenu(item),
          child: FileRow(
            file: item,
            showDivider: i < _displayItems.length - 1,
            onTap: () => _navigateInto(item),
          ),
        );
      },
    );
  }

  // ── Helpers
  IconData _fileIcon(FileType type) => switch (type) {
    FileType.folder => Icons.folder_rounded,
    FileType.image => Icons.image_rounded,
    FileType.video => Icons.video_library_rounded,
    FileType.audio => Icons.audio_file_rounded,
    FileType.document => Icons.description_rounded,
    FileType.apk => Icons.apps_rounded,
    FileType.archive => Icons.folder_zip_rounded,
    _ => Icons.insert_drive_file_rounded,
  };

  String _fileTypeLabel(FileType type) => switch (type) {
    FileType.folder => 'Folder',
    FileType.image => 'Image',
    FileType.video => 'Video',
    FileType.audio => 'Audio',
    FileType.document => 'Document',
    FileType.apk => 'APK',
    FileType.archive => 'Archive',
    _ => 'Other',
  };
}

// ──────────────────────────────────────────────────────────────────────────────
// Helper types
// ──────────────────────────────────────────────────────────────────────────────

class _BreadcrumbSegment {
  final String label;
  final int stackIndex; // -1 = root
  const _BreadcrumbSegment({required this.label, required this.stackIndex});
}

// ──────────────────────────────────────────────────────────────────────────────
// Context menu bottom sheet
// ──────────────────────────────────────────────────────────────────────────────

class _ContextSheet extends StatelessWidget {
  final FileItem item;
  final VoidCallback onOpen;
  final VoidCallback onDetails;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _ContextSheet({
    required this.item,
    required this.onOpen,
    required this.onDetails,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kMuted.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // File name header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Icon(
                  item.type == FileType.folder
                      ? Icons.folder_rounded
                      : Icons.insert_drive_file_rounded,
                  color: kAmber,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      color: kBright,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _tile(Icons.open_in_new_rounded, 'Open', onOpen),
          _tile(Icons.info_outline_rounded, 'Details', onDetails),
          _tile(Icons.edit_rounded, 'Rename', onRename),
          _tile(
            Icons.delete_outline_rounded,
            'Delete',
            onDelete,
            color: Colors.redAccent,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    final c = color ?? kMuted;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: c, size: 20),
      title: Text(label, style: TextStyle(color: c, fontSize: 14)),
      onTap: onTap,
    );
  }
}

/// Rename dialog with custom styling matching the app design
class _RenameDialog extends StatefulWidget {
  final FileItem item;
  final TextEditingController controller;
  final VoidCallback onConfirm;

  const _RenameDialog({
    required this.item,
    required this.controller,
    required this.onConfirm,
  });

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // Select all text except extension
      final name = widget.controller.text;
      final lastDot = name.lastIndexOf('.');
      if (lastDot > 0) {
        widget.controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: lastDot,
        );
      } else {
        widget.controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.controller.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: kAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: kAmber,
                    size: 28,
                  ),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(
                  'Rename',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kBright,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Input field
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  style: TextStyle(color: kBright, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'New name',
                    hintStyle: TextStyle(color: kMuted),
                    prefixIcon: Icon(Icons.edit_rounded, color: kMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kAmber),
                    ),
                    filled: true,
                    fillColor: kSurface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => widget.onConfirm(),
                ),
              ),

              // Divider
              Divider(
                height: 1,
                color: kBorder,
                indent: 0,
                endIndent: 0,
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: kMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onConfirm();
                          Navigator.of(context).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAmber,
                          foregroundColor: kBg,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Rename',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
