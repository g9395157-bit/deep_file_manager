import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/file_item.dart';
import '../models/file_type.dart';
import 'file_service.dart';

class StorageSearchService {
  /// Recursively search a directory for files of specific types
  static Future<List<FileItem>> searchFilesByType(
    String rootPath,
    Set<FileType> types, {
    int maxDepth = 10,
  }) async {
    final results = <FileItem>[];
    await _searchRecursive(rootPath, types, results, 0, maxDepth);
    return results;
  }

  static Future<void> _searchRecursive(
    String path,
    Set<FileType> types,
    List<FileItem> results,
    int currentDepth,
    int maxDepth,
  ) async {
    if (currentDepth >= maxDepth) return;

    try {
      final dir = Directory(path);
      if (!await dir.exists()) return;

      final entities = await dir.list().toList();

      for (final e in entities) {
        try {
          if (e is Directory) {
            // Recursively search subdirectories
            await _searchRecursive(
              e.path,
              types,
              results,
              currentDepth + 1,
              maxDepth,
            );
          } else if (e is File) {
            final stat = await e.stat();
            final name = p.basename(e.path);
            final type = FileService.fileTypeFromPath(e.path);

            if (types.contains(type)) {
              results.add(
                FileItem(
                  name: name,
                  path: e.path,
                  type: type,
                  size: FileService.formatBytes(stat.size),
                  sizeBytes: stat.size,
                  modified: stat.modified.toLocal().toString().split(' ').first,
                  modifiedAt: stat.modified.toLocal(),
                ),
              );
            }
          }
        } catch (_) {
          // Skip inaccessible files
        }
      }
    } catch (_) {
      // Skip inaccessible directories
    }
  }

  /// Get all files from a directory recursively (for category browsing)
  static Future<List<FileItem>> getAllFiles(
    String rootPath, {
    int maxDepth = 10,
  }) async {
    return searchFilesByType(
      rootPath,
      FileType.values.toSet(),
      maxDepth: maxDepth,
    );
  }

  /// Search by query string in filename
  static Future<List<FileItem>> searchByName(
    String rootPath,
    String query, {
    int maxDepth = 10,
  }) async {
    final allFiles = await getAllFiles(rootPath, maxDepth: maxDepth);
    return allFiles
        .where((f) => f.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
