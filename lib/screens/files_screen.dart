import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../utils/file_service.dart';
import '../utils/recent_service.dart';
import '../models/file_item.dart';
import '../models/file_type.dart';
import '../screens/file_viewer_screen.dart';
import '../widgets/buttons/icon_button.dart';
import '../widgets/tiles/file_row.dart';
import '../widgets/tiles/folder_grid_tile.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});
  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  bool _isGrid = false;
  String _sort = 'Name';
  bool _loading = true;
  List<FileItem> _rootItems = [];

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Column(
      children: [
        // Top bar
        Container(
          color: kBg,
          padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
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
                      'Files',
                      style: TextStyle(
                        color: kBright,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconBtn(icon: Icons.search_rounded, onTap: () {}),
              const SizedBox(width: 8),
              // Grid/list toggle
              IconBtn(
                icon: _isGrid
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded,
                onTap: () => setState(() => _isGrid = !_isGrid),
              ),
            ],
          ),
        ),
        // Sort chips
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
                  label: Text(s),
                  selected: sel,
                  onSelected: (_) => setState(() => _sort = s),
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
        const SizedBox(height: 12),
        // Breadcrumb
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.phone_android_rounded, size: 14, color: kAmber),
              const SizedBox(width: 6),
              Text(
                '/ Internal',
                style: TextStyle(
                  color: kAmber,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // File list / grid (root)
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _isGrid
              ? GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _rootItems.length,
                  itemBuilder: (_, i) => InkWell(
                    onTap: () => _showItemActions(context, _rootItems[i]),
                    child: FolderGridTile(folder: _rootItems[i]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _rootItems.length,
                  itemBuilder: (_, i) => FileRow(
                    file: _rootItems[i],
                    showDivider: i < _rootItems.length - 1,
                    onTap: () => _showItemActions(context, _rootItems[i]),
                  ),
                ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadRootItems();
  }

  void _showItemActions(BuildContext context, FileItem item) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
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
            _actionTile(
              icon: Icons.open_in_new_rounded,
              label: 'Open',
              onTap: () {
                Navigator.pop(ctx);
                _openItem(item);
              },
            ),
            if (item.type != FileType.folder)
              _actionTile(
                icon: Icons.info_outline_rounded,
                label: 'Details',
                onTap: () {
                  Navigator.pop(ctx);
                  _showDetails(item);
                },
              ),
            _actionTile(
              icon: Icons.edit_rounded,
              label: 'Rename',
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(item);
              },
            ),
            _actionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteDialog(item);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: kMuted, size: 20),
      title: Text(label, style: TextStyle(color: kMuted, fontSize: 13)),
      onTap: onTap,
    );
  }

  void _openItem(FileItem item) {
    if (item.type == FileType.folder) {
      // For folders, you could navigate into them or open with file manager
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening folder in file manager...')),
      );
    } else if ([
      FileType.image,
      FileType.video,
      FileType.audio,
    ].contains(item.type)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FileViewerScreen(item: item)),
      );
    } else {
      FileService.openFile(item.path);
    }
  }

  void _showDetails(FileItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        icon: Icon(_getFileIcon(item.type), color: kAmber),
        title: Text(item.name, style: TextStyle(color: kBright, fontSize: 14)),
        content: SizedBox(
          width: double.minPositive,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Type', _fileTypeLabel(item.type)),
                _detailRow('Size', item.size),
                _detailRow('Modified', item.modified),
                _detailRow('Path', item.path),
              ],
            ),
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
          Text(label, style: TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: kBright, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(FileItem item) {
    final controller = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text('Rename', style: TextStyle(color: kBright)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: kBright),
          decoration: InputDecoration(
            hintText: 'New name',
            hintStyle: TextStyle(color: kMuted),
            border: OutlineInputBorder(borderSide: BorderSide(color: kBorder)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: kMuted)),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              final newPath = item.path.replaceRange(
                item.path.lastIndexOf('/'),
                null,
                '/$newName',
              );
              try {
                await FileService.rename(item.path, newPath);
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadRootItems();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File renamed successfully')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text('Rename', style: TextStyle(color: kAmber)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(FileItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text('Delete', style: TextStyle(color: kBright)),
        content: Text(
          'Are you sure you want to delete "${item.name}"?',
          style: TextStyle(color: kMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: kMuted)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FileService.deletePath(item.path);
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadRootItems();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File deleted successfully')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(FileType type) {
    return switch (type) {
      FileType.folder => Icons.folder_rounded,
      FileType.image => Icons.image_rounded,
      FileType.video => Icons.video_library_rounded,
      FileType.audio => Icons.audio_file_rounded,
      FileType.document => Icons.description_rounded,
      FileType.apk => Icons.apps_rounded,
      FileType.archive => Icons.folder_zip_rounded,
      _ => Icons.description_rounded,
    };
  }

  String _fileTypeLabel(FileType type) {
    return switch (type) {
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

  Future<void> _loadRootItems() async {
    setState(() => _loading = true);
    try {
      final root = await FileService.getRootDirectory();
      final list = await FileService.listFiles(root.path);
      if (!mounted) return;
      // Only show directories as root items
      setState(() {
        _rootItems = list.where((f) => f.type == FileType.folder).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
