import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/file_item.dart';
import '../../utils/file_utils.dart';

class FileGridCard extends StatelessWidget {
  final FileItem file;
  const FileGridCard({Key? key, required this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ext = fileExt(file.name);
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: file.accentColor.withAlpha((0.12 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ext.isEmpty
                ? Icon(fileIcon(file.type), color: file.accentColor, size: 24)
                : Center(
                    child: Text(
                      ext,
                      style: TextStyle(
                        color: file.accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
          ),
          const Spacer(),
          Text(
            file.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: kBright,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            file.size,
            style: TextStyle(
              color: file.accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
