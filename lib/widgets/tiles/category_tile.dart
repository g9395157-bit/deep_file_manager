import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/file_type.dart';
import '../../models/storage_category.dart';
import '../../screens/file_list_screen.dart';
import '../../utils/category_paths.dart';
import '../../utils/storage_search_service.dart';
import '../../utils/file_service.dart';

class CategoryTile extends StatelessWidget {
  final StorageCategory cat;
  const CategoryTile({Key? key, required this.cat}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _searchAndShowCategory(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: cat.color.withAlpha((0.15 * 255).round()),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(cat.icon, color: cat.color, size: 20),
            ),
            const Spacer(),
            Text(
              cat.label,
              style: TextStyle(
                color: kBright,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              cat.size,
              style: TextStyle(
                color: cat.color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchAndShowCategory(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Searching for ${cat.label}...',
              style: TextStyle(color: kMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );

    try {
      final root = await FileService.getRootDirectory();
      final types = _getFileTypesForCategory();
      final results = await StorageSearchService.searchFilesByType(
        root.path,
        types,
        maxDepth: 15,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FileListScreen(title: cat.label, files: results),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching: $e')));
    }
  }

  Set<FileType> _getFileTypesForCategory() {
    return switch (cat.label) {
      'Images' => {FileType.image},
      'Videos' => {FileType.video},
      'Audio' => {FileType.audio},
      'Documents' => {FileType.document},
      'Downloads' => {FileType.apk, FileType.archive, FileType.document},
      'Apps' => {FileType.apk},
      _ => {FileType.other},
    };
  }
}
