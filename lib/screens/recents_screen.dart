import 'dart:async';
import 'dart:io';

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

/// Fixed Recents screen:
///   • Loads real recent files from RecentService (SharedPreferences).
///   • Groups items by date (Today / Yesterday / Earlier).
///   • Search is debounced (300 ms) and filters the in-memory list — no
///     filesystem traversal on every keystroke.
class RecentsScreen extends StatefulWidget {
  const RecentsScreen({super.key});

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen> {
  // ── Data
  List<FileItem> _allItems = [];
  bool _loading = true;

  // ── Search
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  List<FileItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Data loading
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _loadRecents() async {
    try {
      final paths = await RecentService.getRecents();
      final items = <FileItem>[];
      for (final path in paths) {
        try {
          final f = File(path);
          if (!await f.exists()) continue;
          final stat = await f.stat();
          items.add(
            FileItem(
              name: p.basename(path),
              path: path,
              type: _typeFromPath(path),
              size: FileService.formatBytes(stat.size),
              sizeBytes: stat.size,
              modified: stat.modified.toLocal().toString().split(' ').first,
              modifiedAt: stat.modified.toLocal(),
            ),
          );
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _allItems = items;
        _filteredItems = List.from(items);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Search — debounced, in-memory only (no filesystem scan)
  // ──────────────────────────────────────────────────────────────────────────

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchCtrl.clear();
        _filteredItems = List.from(_allItems);
      }
    });
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilter(query);
    });
  }

  void _applyFilter(String query) {
    if (!mounted) return;
    if (query.isEmpty) {
      setState(() => _filteredItems = List.from(_allItems));
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filteredItems = _allItems
          .where((f) => f.name.toLowerCase().contains(q))
          .toList();
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // File opening
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _openItem(FileItem item) async {
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
      return;
    }
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

  // ──────────────────────────────────────────────────────────────────────────
  // Date grouping helpers
  // ──────────────────────────────────────────────────────────────────────────

  String _groupLabel(DateTime? dt) {
    if (dt == null) return 'Earlier';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(itemDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'This week';
    return 'Earlier';
  }

  /// Groups the list into ordered sections.
  List<_Section> _buildSections(List<FileItem> items) {
    final Map<String, List<FileItem>> map = {};
    const order = ['Today', 'Yesterday', 'This week', 'Earlier'];

    for (final item in items) {
      final label = _groupLabel(item.modifiedAt);
      map.putIfAbsent(label, () => []).add(item);
    }

    return order
        .where((g) => map.containsKey(g))
        .map((g) => _Section(label: g, items: map[g]!))
        .toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        // ── Top bar
        Container(
          color: kBg,
          padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: _isSearching
                    ? TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        style: TextStyle(color: kBright, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Search recent files…',
                          hintStyle: TextStyle(color: kMuted),
                          border: InputBorder.none,
                        ),
                        onChanged: _onSearchChanged,
                      )
                    : Text(
                        'Recent Files',
                        style: TextStyle(
                          color: kBright,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              IconBtn(
                icon: _isSearching ? Icons.close_rounded : Icons.search_rounded,
                onTap: _toggleSearch,
              ),
              if (!_isSearching) ...[
                const SizedBox(width: 8),
                IconBtn(icon: Icons.delete_sweep_rounded, onTap: _confirmClear),
              ],
            ],
          ),
        ),

        // ── Content
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filteredItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSearching
                            ? Icons.search_off_rounded
                            : Icons.history_rounded,
                        color: kMuted,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isSearching
                            ? 'No results for "${_searchCtrl.text}"'
                            : 'No recent files yet',
                        style: TextStyle(color: kMuted, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : _buildGroupedList(),
        ),
      ],
    );
  }

  Widget _buildGroupedList() {
    final sections = _buildSections(_filteredItems);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: sections.fold<int>(
        0,
        (sum, s) => sum + 1 + s.items.length, // 1 for the header
      ),
      itemBuilder: (_, globalIndex) {
        // Map globalIndex to (section, row)
        int cursor = 0;
        for (final section in sections) {
          if (globalIndex == cursor) {
            // Section header
            return Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
              child: Text(
                section.label,
                style: TextStyle(
                  color: kMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            );
          }
          cursor++;
          final rowIndex = globalIndex - cursor;
          if (rowIndex < section.items.length) {
            final file = section.items[rowIndex];
            return FileRow(
              file: file,
              showDivider: rowIndex < section.items.length - 1,
              onTap: () => _openItem(file),
            );
          }
          cursor += section.items.length;
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationCard(
        title: 'Clear History',
        message: 'Remove all recent files from history?\n\nThis cannot be undone.',
        confirmText: 'Clear',
        type: ConfirmationType.destructive,
        icon: Icons.history_toggle_off_rounded,
        onConfirm: () async {
          await RecentService.clearRecents();
          if (mounted) {
            setState(() {
              _allItems = [];
              _filteredItems = [];
            });
          }
        },
      ),
    );
  }

  // ── Helpers
  static FileType _typeFromPath(String path) {
    final ext = p.extension(path).toLowerCase().replaceAll('.', '');
    if (ext.isEmpty) return FileType.other;
    const imgs = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'];
    const vids = ['mp4', 'mkv', 'mov', 'avi', 'webm'];
    const auds = ['mp3', 'wav', 'm4a', 'aac'];
    const docs = [
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      'txt',
      'md',
      'rtf',
    ];
    const arch = ['zip', 'rar', '7z', 'tar', 'gz'];
    if (imgs.contains(ext)) return FileType.image;
    if (vids.contains(ext)) return FileType.video;
    if (auds.contains(ext)) return FileType.audio;
    if (docs.contains(ext)) return FileType.document;
    if (ext == 'apk') return FileType.apk;
    if (arch.contains(ext)) return FileType.archive;
    return FileType.other;
  }
}

class _Section {
  final String label;
  final List<FileItem> items;
  const _Section({required this.label, required this.items});
}
