import 'package:flutter/material.dart';
import 'file_type.dart';
import '../constants/colors.dart';

class FileItem {
  final String name;
  final String path;
  final FileType type;
  final String size;
  final int sizeBytes;
  final String modified;
  final DateTime? modifiedAt;
  final int itemCount; // for folders
  final Color accentColor;

  const FileItem({
    required this.name,
    this.path = '',
    required this.type,
    this.size = '',
    this.sizeBytes = 0,
    this.modified = '',
    this.modifiedAt,
    this.itemCount = 0,
    this.accentColor = kAmber,
  });
}
