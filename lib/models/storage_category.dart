import 'package:flutter/material.dart';
import 'file_item.dart';

class StorageCategory {
  final String label;
  final IconData icon;
  final Color color;
  final String size;
  final String count;
  final List<FileItem> files;

  const StorageCategory({
    required this.label,
    required this.icon,
    required this.color,
    required this.size,
    required this.count,
    this.files = const [],
  });
}
