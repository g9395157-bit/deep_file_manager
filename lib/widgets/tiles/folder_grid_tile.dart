import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/file_item.dart';

class FolderGridTile extends StatelessWidget {
  final FileItem folder;
  const FolderGridTile({Key? key, required this.folder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_rounded, color: folder.accentColor, size: 42),
          const SizedBox(height: 8),
          Text(
            folder.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: kBright,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${folder.itemCount} items',
            style: TextStyle(color: kMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
