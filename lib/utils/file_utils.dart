import 'package:flutter/material.dart';
import '../models/file_type.dart';

/// Get icon for file type
IconData fileIcon(FileType t) {
  switch (t) {
    case FileType.folder:
      return Icons.folder_rounded;
    case FileType.image:
      return Icons.image_rounded;
    case FileType.video:
      return Icons.play_circle_rounded;
    case FileType.audio:
      return Icons.music_note_rounded;
    case FileType.document:
      return Icons.description_rounded;
    case FileType.apk:
      return Icons.android_rounded;
    case FileType.archive:
      return Icons.folder_zip_rounded;
    case FileType.other:
      return Icons.insert_drive_file_rounded;
  }
}

/// Get file extension from filename
String fileExt(String name) {
  final parts = name.split('.');
  return parts.length > 1 ? parts.last.toUpperCase() : '';
}
