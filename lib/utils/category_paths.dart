import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CategoryPaths {
  /// Returns a sensible folder path for common categories on the current
  /// platform, or null when unknown.
  static Future<String?> getPathForCategory(String label) async {
    final key = label.toLowerCase();
    if (Platform.isAndroid) {
      switch (key) {
        case 'images':
          return '/storage/emulated/0/DCIM';
        case 'videos':
          return '/storage/emulated/0/Movies';
        case 'audio':
          return '/storage/emulated/0/Music';
        case 'documents':
          return '/storage/emulated/0/Documents';
        case 'downloads':
          return '/storage/emulated/0/Download';
        case 'apps':
          return '/storage/emulated/0/Android';
        default:
          return null;
      }
    }

    if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      // iOS sandboxed — return documents dir for most categories.
      return dir.path;
    }

    // Desktop / others: use current working directory as a starting point.
    return Directory.current.path;
  }
}
