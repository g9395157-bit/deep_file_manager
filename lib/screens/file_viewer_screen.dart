import 'dart:io';

import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/file_item.dart';
import '../models/file_type.dart';
import '../utils/file_service.dart';
import '../utils/recent_service.dart';

class FileViewerScreen extends StatefulWidget {
  final FileItem item;
  const FileViewerScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  String? _text;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _maybeLoad();
  }

  Future<void> _maybeLoad() async {
    if (widget.item.path.isEmpty) return;
    await RecentService.addRecent(widget.item.path);
    if (widget.item.type == FileType.document) {
      setState(() => _loading = true);
      final t = await FileService.readTextFile(widget.item.path);
      if (!mounted) return;
      setState(() {
        _text = t ?? 'Unable to read file';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kSurface,
        foregroundColor: kBright,
        title: Text(widget.item.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: widget.item.path.isNotEmpty
                ? () => FileService.openFile(widget.item.path)
                : null,
          ),
        ],
      ),
      backgroundColor: kBg,
      body: Center(
        child: Padding(padding: const EdgeInsets.all(12), child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.item.path.isEmpty) {
      return const Text('No path for this item');
    }
    if (_loading) return const CircularProgressIndicator();

    if (widget.item.type == FileType.image) {
      final f = File(widget.item.path);
      if (f.existsSync()) {
        return InteractiveViewer(child: Image.file(f));
      }
      return const Text('Image not found');
    }

    if (widget.item.type == FileType.document) {
      if (_text == null) return const Text('Unable to read file');
      return SingleChildScrollView(
        child: SelectableText(_text!, style: const TextStyle(fontSize: 14)),
      );
    }

    // For other types, attempt to open with platform handler
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.insert_drive_file_rounded, size: 72),
        const SizedBox(height: 12),
        Text(widget.item.name, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => FileService.openFile(widget.item.path),
          child: const Text('Open'),
        ),
      ],
    );
  }
}
