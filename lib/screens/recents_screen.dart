import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../constants/colors.dart';
import '../widgets/buttons/icon_button.dart';
import '../widgets/labels/section_label.dart';
import '../widgets/tiles/file_row.dart';
import '../utils/recent_service.dart';
import '../utils/file_service.dart';
import '../models/file_item.dart';
import '../models/file_type.dart';
import 'file_viewer_screen.dart';

class RecentsScreen extends StatefulWidget {
  const RecentsScreen({Key? key}) : super(key: key);

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen> {
  List<FileItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final paths = await RecentService.getRecents();
    final list = <FileItem>[];
    for (final pth in paths) {
      try {
        final f = File(pth);
        if (!await f.exists()) continue;
        final stat = await f.stat();
        final name = p.basename(pth);
        final type = _fileTypeFromPath(pth);
        list.add(
          FileItem(
            name: name,
            path: pth,
            type: type,
            size: stat.size > 0 ? _formatBytes(stat.size) : '',
            modified: stat.modified.toLocal().toString().split(' ').first,
          ),
        );
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int i = 0;
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    final fixed = size < 10 ? size.toStringAsFixed(1) : size.toStringAsFixed(0);
    return '$fixed ${suffixes[i]}';
  }

  static FileType _fileTypeFromPath(String path) {
    final ext = p.extension(path).toLowerCase().replaceAll('.', '');
    if (ext.isEmpty) return FileType.other;
    final imgs = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'];
    final vids = ['mp4', 'mkv', 'mov', 'avi', 'webm'];
    final auds = ['mp3', 'wav', 'm4a', 'aac'];
    final docs = [
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
    final arch = ['zip', 'rar', '7z', 'tar', 'gz'];
    if (imgs.contains(ext)) return FileType.image;
    if (vids.contains(ext)) return FileType.video;
    if (auds.contains(ext)) return FileType.audio;
    if (docs.contains(ext)) return FileType.document;
    if (ext == 'apk') return FileType.apk;
    if (arch.contains(ext)) return FileType.archive;
    return FileType.other;
  }

  Future<void> _openItem(FileItem item) async {
    if (item.path.isEmpty) return;
    if (item.type == FileType.image || item.type == FileType.document) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FileViewerScreen(item: item)),
      );
      return;
    }
    await RecentService.addRecent(item.path);
    try {
      await FileService.openFile(item.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open file')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Column(
      children: [
        Container(
          color: kBg,
          padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Recent Files',
                  style: TextStyle(
                    color: kBright,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconBtn(icon: Icons.search_rounded, onTap: () {}),
            ],
          ),
        ),
        // Day groups
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    SectionLabel(label: 'Recent'),
                    ..._items.map(
                      (f) => FileRow(
                        file: f,
                        showDivider: f != _items.last,
                        onTap: () => _openItem(f),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
        ),
      ],
    );
  }
}
