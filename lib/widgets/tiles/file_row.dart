import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/file_item.dart';
import '../../utils/file_utils.dart';

class FileRow extends StatelessWidget {
  final FileItem file;
  final bool showDivider;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;
  const FileRow({
    Key? key,
    required this.file,
    this.showDivider = true,
    this.onTap,
    this.onMoreTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ext = fileExt(file.name);
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: file.accentColor.withAlpha((0.12 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: file.type.name == 'folder'
                      ? Icon(
                          Icons.folder_rounded,
                          color: file.accentColor,
                          size: 24,
                        )
                      : ext.isEmpty
                      ? Icon(
                          fileIcon(file.type),
                          color: file.accentColor,
                          size: 22,
                        )
                      : Center(
                          child: Text(
                            ext,
                            style: TextStyle(
                              color: file.accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: kBright,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (file.size.isNotEmpty) ...[
                            Text(
                              file.size,
                              style: TextStyle(color: kMuted, fontSize: 12),
                            ),
                            Text(
                              '  ·  ',
                              style: TextStyle(color: kBorder, fontSize: 12),
                            ),
                          ],
                          Text(
                            file.modified,
                            style: TextStyle(color: kMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onMoreTap,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: kMuted,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 1, color: kBorder, indent: 58),
      ],
    );
  }
}
