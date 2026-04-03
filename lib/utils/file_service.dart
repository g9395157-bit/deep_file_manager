import 'dart:io';
import 'dart:async';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/file_item.dart';
import '../models/file_type.dart';
import 'permission_service.dart';

class FileService {
  // ──────────────────────────────────────────────────────────────────────────
  // Root directory
  // ──────────────────────────────────────────────────────────────────────────

  static Future<Directory> getRootDirectory() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0');
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return Directory.current;
    }
    return Directory.systemTemp;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Stat — returns null when the file does not exist or is inaccessible.
  // Used by home_screen to hydrate recent file metadata.
  // ──────────────────────────────────────────────────────────────────────────

  static Future<FileStat?> statFile(String path) async {
    try {
      final entity = File(path);
      if (!await entity.exists()) return null;
      return await entity.stat();
    } catch (_) {
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Formatting
  // ──────────────────────────────────────────────────────────────────────────

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    int i = 0;
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    final fixed = size < 10 ? size.toStringAsFixed(1) : size.toStringAsFixed(0);
    return '$fixed ${suffixes[i]}';
  }

  // ──────────────────────────────────────────────────────────────────────────
  // File type detection
  // ──────────────────────────────────────────────────────────────────────────

  static FileType fileTypeFromPath(String path, {bool isDir = false}) {
    if (isDir) return FileType.folder;
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

  // ──────────────────────────────────────────────────────────────────────────
  // List files in a directory (one level only — callers navigate the tree)
  // ──────────────────────────────────────────────────────────────────────────

  /// Lists files and folders at [path].
  ///
  /// Sorting preference is folders-first / alpha; callers that want a
  /// different sort order can re-sort the returned list in-memory.
  static Future<List<FileItem>> listFiles(String path) async {
    // Permission check (uses cache — almost free after first call)
    if (await PermissionService.needStoragePermission()) {
      final granted = await PermissionService.requestStoragePermission();
      if (!granted) throw Exception('Storage permission denied');
    }

    final dir = Directory(path);
    if (!await dir.exists()) return [];

    final entities = await dir.list().toList();

    // Folders first, then alphabetical
    entities.sort((a, b) {
      final aDir = a is Directory;
      final bDir = b is Directory;
      if (aDir != bDir) return aDir ? -1 : 1;
      return a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });

    final results = <FileItem>[];
    for (final e in entities) {
      // Skip hidden files/folders (names starting with '.')
      final name = p.basename(e.path);
      if (name.startsWith('.')) continue;

      try {
        final stat = await e.stat();
        final isDir = e is Directory;
        final type = fileTypeFromPath(e.path, isDir: isDir);
        final sizeText = isDir ? '' : formatBytes(stat.size);
        final modified = stat.modified.toLocal().toString().split(' ').first;

        int itemCount = 0;
        if (isDir) {
          // Count direct children without recursing (fast)
          try {
            itemCount = await (e as Directory)
                .list()
                .where((child) => !p.basename(child.path).startsWith('.'))
                .length;
          } catch (_) {}
        }

        results.add(
          FileItem(
            name: name,
            path: e.path,
            type: type,
            size: sizeText,
            sizeBytes: stat.size,
            modified: modified,
            modifiedAt: stat.modified.toLocal(),
            itemCount: itemCount,
          ),
        );
      } catch (_) {
        // Skip files/folders we cannot stat (permissions, etc.)
      }
    }

    return results;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // File operations
  // ──────────────────────────────────────────────────────────────────────────

  static Future<void> deletePath(String path) async {
    if (await PermissionService.needStoragePermission()) {
      final granted = await PermissionService.requestStoragePermission();
      if (!granted) throw Exception('Storage permission denied');
    }
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.notFound) return;
    if (type == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: true);
    } else {
      await File(path).delete();
    }
  }

  static Future<void> rename(String from, String to) async {
    final f = File(from);
    if (await f.exists()) {
      await f.rename(to);
      return;
    }
    final d = Directory(from);
    if (await d.exists()) await d.rename(to);
  }

  static Future<void> openFile(String path) async {
    await OpenFilex.open(path);
  }

  static Future<String?> readTextFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  static Future<int> getDirectorySize(Directory dir) async {
    int total = 0;
    try {
      await for (final e in dir.list(recursive: true, followLinks: false)) {
        if (e is File) {
          try {
            total += (await e.stat()).size;
          } catch (_) {}
        }
      }
    } catch (_) {}
    return total;
  }
}
