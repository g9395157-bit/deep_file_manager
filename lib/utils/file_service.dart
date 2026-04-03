import 'dart:io';
import 'dart:async';
// Removed unused foundation import
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/file_item.dart';
import '../models/file_type.dart';
import 'permission_service.dart';

class FileService {
  /// Returns a sensible root directory for the current platform.
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

  static FileType fileTypeFromPath(String path, {bool isDir = false}) {
    if (isDir) return FileType.folder;
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

  /// List files and folders at [path] and return them as `FileItem`s.
  /// Throws when storage permission is required but denied.
  static Future<List<FileItem>> listFiles(String path) async {
    final needPerm = await PermissionService.needStoragePermission();
    if (needPerm) {
      final granted = await PermissionService.requestStoragePermission();
      if (!granted) throw Exception('Storage permission denied');
    }

    final dir = Directory(path);
    if (!await dir.exists()) return [];

    final entities = await dir.list().toList();

    entities.sort((a, b) {
      final aIsDir = a is Directory;
      final bIsDir = b is Directory;
      if (aIsDir && !bIsDir) return -1;
      if (!aIsDir && bIsDir) return 1;
      return a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });

    final results = <FileItem>[];
    for (final e in entities) {
      try {
        final stat = await e.stat();
        final name = p.basename(e.path);
        final isDir = e is Directory;
        final type = fileTypeFromPath(e.path, isDir: isDir);
        final sizeText = isDir ? '' : formatBytes(stat.size);
        final modified = stat.modified.toLocal().toString().split(' ').first;
        int itemCount = 0;
        if (isDir) {
          try {
            itemCount = await (e as Directory).list().length;
          } catch (_) {
            itemCount = 0;
          }
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
        // ignore
      }
    }

    return results;
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

  static Future<String?> readTextFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    try {
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  static Future<void> deletePath(String path) async {
    final needPerm = await PermissionService.needStoragePermission();
    if (needPerm) {
      final granted = await PermissionService.requestStoragePermission();
      if (!granted) throw Exception('Storage permission denied');
    }
    final ent = FileSystemEntity.typeSync(path);
    if (ent == FileSystemEntityType.notFound) return;
    if (ent == FileSystemEntityType.directory) {
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
    if (await d.exists()) {
      await d.rename(to);
    }
  }

  static Future<void> openFile(String path) async {
    await OpenFilex.open(path);
  }
}
