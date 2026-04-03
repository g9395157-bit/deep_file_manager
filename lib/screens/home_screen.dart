import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/mock_data.dart';
import '../widgets/buttons/icon_button.dart';
import '../widgets/storage_arc/storage_arc_card.dart';
import '../widgets/tiles/category_tile.dart';
import '../widgets/tiles/file_row.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Top bar
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning',
                        style: TextStyle(
                          color: kMuted,
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Deep File Manager',
                        style: TextStyle(
                          color: kBright,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                // Search btn
                IconBtn(icon: Icons.search_rounded, onTap: () {}),
                const SizedBox(width: 8),
                IconBtn(icon: Icons.tune_rounded, onTap: () {}),
              ],
            ),
          ),
        ),
        // ── Storage arc card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: StorageArcCard(),
          ),
        ),
        // ── Categories
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories',
                  style: TextStyle(
                    color: kBright,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'See all',
                  style: TextStyle(
                    color: kAmber,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => CategoryTile(cat: kCategories[i]),
              childCount: kCategories.length,
            ),
          ),
        ),
        // ── Recent files
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Files',
                  style: TextStyle(
                    color: kBright,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'See all',
                  style: TextStyle(
                    color: kAmber,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => FileRow(
                file: kRecentFiles[i],
                showDivider: i < kRecentFiles.length - 1,
              ),
              childCount: kRecentFiles.length,
            ),
          ),
        ),
      ],
    );
  }
}
