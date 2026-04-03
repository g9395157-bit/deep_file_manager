import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../constants/colors.dart';
import '../models/file_item.dart';
import '../widgets/buttons/icon_button.dart';
import '../widgets/dialogs/confirmation_card.dart';
import '../widgets/tiles/file_grid_card.dart';
import '../widgets/tiles/file_row.dart';
import '../utils/file_service.dart';
import '../screens/file_viewer_screen.dart';
import '../models/file_type.dart';
import '../utils/recent_service.dart';

class FileListScreen extends StatefulWidget {
  final String title;
  final List<FileItem>? files;
  final String? rootPath;

  const FileListScreen({
    super.key,
    required this.title,
    this.files,
    this.rootPath,
  });

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  bool _isGrid = false;
  bool _loading = false;
  List<FileItem> _items = [];
  String _sort = 'Name';

  @override
  void initState() {
    super.initState();
    _initFiles();
  }

  Future<void> _initFiles() async {
    if (widget.rootPath != null && widget.rootPath!.isNotEmpty) {
      setState(() => _loading = true);
      try {
        final list = await FileService.listFiles(widget.rootPath!);
        if (!mounted) return;
        setState(() {
          _items = list;
          _sortItems();
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _items = [];
        });
        // Show a simple error snackbar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        });
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else if (widget.files != null) {
      _items = widget.files!;
      _sortItems();
    }
  }

  void _sortItems() {
    switch (_sort) {
      case 'Name':
        _items.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case 'Size':
        _items.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
        break;
      case 'Date':
        _items.sort(
          (a, b) => (b.modifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(
                a.modifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
              ),
        );
        break;
      case 'Type':
        _items.sort((a, b) => a.type.index.compareTo(b.type.index));
        break;
    }
  }

  Future<void> _openItem(FileItem item) async {
    if (item.type == FileType.folder) {
      if (item.path.isEmpty) {
        // No path for this mock item
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder path not available')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FileListScreen(title: item.name, rootPath: item.path),
        ),
      );
      return;
    }

    if (item.type == FileType.image || item.type == FileType.document) {
      if (item.path.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File path not available')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FileViewerScreen(item: item)),
      );
      return;
    }

    if (item.path.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File path not available')));
      return;
    }
    try {
      await RecentService.addRecent(item.path);
      await FileService.openFile(item.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open file')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // App bar
          Container(
            color: kSurface,
            padding: EdgeInsets.fromLTRB(8, topPad + 10, 16, 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  color: kBright,
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: kBright,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconBtn(
                  icon: Icons.search_rounded,
                  onTap: () {
                    showSearch(
                      context: context,
                      delegate: _FileSearchDelegate(
                        items: _items,
                        onOpen: _openItem,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(Icons.sort_rounded, color: kBright),
                  onSelected: (v) => setState(() {
                    _sort = v;
                    _sortItems();
                  }),
                  itemBuilder: (_) => ['Name', 'Size', 'Date', 'Type']
                      .map((s) => PopupMenuItem(value: s, child: Text(s)))
                      .toList(),
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
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_open_rounded,
                          color: kMuted,
                          size: 64,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Empty folder',
                          style: TextStyle(color: kMuted, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : _isGrid
                ? GridView.builder(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.1,
                        ),
                    itemCount: _items.length,
                    itemBuilder: (_, i) => InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openItem(_items[i]),
                      onLongPress: () => _showItemActions(_items[i], i),
                      child: FileGridCard(file: _items[i]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _items.length,
                    itemBuilder: (_, i) => FileRow(
                      file: _items[i],
                      showDivider: i < _items.length - 1,
                      onTap: () => _openItem(_items[i]),
                      onMoreTap: () => _showItemActions(_items[i], i),
                    ),
                  ),
          ),
        ],
      ),
      // FAB — new folder
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: kAmber,
        foregroundColor: kBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.create_new_folder_rounded),
      ),
    );
  }

  Future<void> _showItemActions(FileItem item, int index) async {
    if (item.path.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No path for this item')));
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Open'),
              onTap: () {
                Navigator.pop(ctx);
                _openItem(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Rename'),
              onTap: () async {
                Navigator.pop(ctx);
                final newName = await _showRenameDialog(item.name);
                if (newName == null || newName.trim().isEmpty) return;
                final dir = p.dirname(item.path);
                final newPath = p.join(dir, newName);
                try {
                  await FileService.rename(item.path, newPath);
                  // refresh the list
                  if (widget.rootPath != null) {
                    final list = await FileService.listFiles(widget.rootPath!);
                    if (!mounted) return;
                    setState(() => _items = list);
                  } else {
                    setState(() {
                      _items[index] = FileItem(
                        name: newName,
                        path: newPath,
                        type: item.type,
                        size: item.size,
                        sizeBytes: item.sizeBytes,
                        modified: item.modified,
                        modifiedAt: item.modifiedAt,
                        itemCount: item.itemCount,
                        accentColor: item.accentColor,
                      );
                    });
                  }
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rename failed')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dCtx) => ConfirmationCard(
                    title: 'Delete',
                    message: 'Delete "${item.name}"?\n\nThis cannot be undone.',
                    confirmText: 'Delete',
                    type: ConfirmationType.destructive,
                    icon: Icons.delete_outline_rounded,
                  ),
                );
                if (ok != true) return;
                try {
                  await FileService.deletePath(item.path);
                  if (!mounted) return;
                  setState(() => _items.removeAt(index));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Delete failed')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Details'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: Text(item.name),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Path: ${item.path}'),
                        const SizedBox(height: 8),
                        Text('Size: ${item.size}'),
                        const SizedBox(height: 8),
                        Text('Modified: ${item.modifiedAt ?? item.modified}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showRenameDialog(String current) async {
    final ctrl = TextEditingController(text: current);
    final res = await showDialog<String?>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'New name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, ctrl.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    return res;
  }
}

class _FileSearchDelegate extends SearchDelegate<FileItem?> {
  final List<FileItem> items;
  final Future<void> Function(FileItem) onOpen;

  _FileSearchDelegate({required this.items, required this.onOpen})
    : super(searchFieldLabel: 'Search files');

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) {
    final res = items
        .where((f) => f.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: res.length,
      itemBuilder: (_, i) => ListTile(
        title: Text(res[i].name),
        subtitle: Text(res[i].path),
        onTap: () async {
          await onOpen(res[i]);
          close(context, res[i]);
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}
