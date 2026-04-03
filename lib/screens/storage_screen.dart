import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/mock_data.dart';
import '../models/file_type.dart';
import '../widgets/storage_arc/segmented_arc_painter.dart';
import '../utils/file_service.dart';
import '../utils/storage_search_service.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({Key? key}) : super(key: key);

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  bool _loading = true;
  List<(String label, double gb, Color color)> _segments = [];

  @override
  void initState() {
    super.initState();
    _computeSegments();
  }

  Future<void> _computeSegments() async {
    setState(() => _loading = true);
    final results = <(String, double, Color)>[];

    // Category to FileType mapping
    final categoryTypes = [
      ('Videos', {FileType.video}, kBlue),
      ('Apps', {FileType.apk}, kOrange),
      ('Images', {FileType.image}, kPink),
      ('Downloads', {FileType.apk, FileType.archive, FileType.document}, kTeal),
      ('Audio', {FileType.audio}, kPurple),
      ('Documents', {FileType.document}, kAmber),
    ];

    try {
      final root = await FileService.getRootDirectory();
      double totalBytes = 0.0;

      for (final (label, types, color) in categoryTypes) {
        try {
          final files = await StorageSearchService.searchFilesByType(
            root.path,
            types,
          );
          final bytes = files.fold<int>(0, (s, f) => s + f.sizeBytes);
          final gb = bytes / (1024 * 1024 * 1024);
          results.add((label, gb, color));
          totalBytes += bytes;
        } catch (_) {
          results.add((label, 0.0, color));
        }
      }

      // If total is zero (e.g., desktop or no permissions), fall back to mock
      if (totalBytes <= 0) {
        _segments = [
          ('Videos', 18.7, kBlue),
          ('Apps', 6.8, kOrange),
          ('Images', 4.2, kPink),
          ('Downloads', 3.4, kTeal),
          ('Audio', 2.1, kPurple),
          ('Documents', 0.9, kAmber),
        ];
      } else {
        _segments = results;
      }
    } catch (_) {
      // Fall back to mock data on error
      _segments = [
        ('Videos', 18.7, kBlue),
        ('Apps', 6.8, kOrange),
        ('Images', 4.2, kPink),
        ('Downloads', 3.4, kTeal),
        ('Audio', 2.1, kPurple),
        ('Documents', 0.9, kAmber),
      ];
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final total = _segments.fold<double>(0.0, (s, e) => s + e.$2);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: kBg,
            padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 16),
            child: Text(
              'Storage Analysis',
              style: TextStyle(
                color: kBright,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        // Big ring
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CustomPaint(
                      painter: SegmentedArcPainter(
                        segments: _segments
                            .map(
                              (s) => (s.$2 / (total > 0 ? total : 1.0), s.$3),
                            )
                            .toList(),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${total.toInt()} GB',
                              style: TextStyle(
                                color: kBright,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'total',
                              style: TextStyle(color: kMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    children: _segments
                        .map(
                          (s) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: s.$3,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${s.$1}  ${s.$2.toStringAsFixed(1)} GB',
                                style: TextStyle(color: kMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Category breakdown bars
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text(
              'Breakdown',
              style: TextStyle(
                color: kBright,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((_, i) {
              final s = _segments[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: s.$3.withAlpha((0.15 * 255).round()),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              kCategories[i].icon,
                              color: s.$3,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s.$1,
                              style: TextStyle(
                                color: kBright,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${s.$2.toStringAsFixed(1)} GB',
                            style: TextStyle(
                              color: s.$3,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total > 0 ? s.$2 / total : 0,
                          minHeight: 5,
                          backgroundColor: kBorder,
                          valueColor: AlwaysStoppedAnimation(s.$3),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          total > 0
                              ? '${((s.$2 / total) * 100).toStringAsFixed(1)}%'
                              : '0%',
                          style: TextStyle(color: kMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }, childCount: _segments.length),
          ),
        ),
      ],
    );
  }
}
