import 'dart:async';

import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/mock_data.dart'; // still used for category definitions (label/icon/color)
import '../models/file_item.dart';
import '../models/file_type.dart';
import '../models/storage_category.dart';
import '../utils/file_service.dart';
import '../utils/recent_service.dart';
import '../widgets/buttons/icon_button.dart';
import '../widgets/storage_arc/storage_arc_card.dart';
import '../widgets/tiles/category_tile.dart';
import '../widgets/tiles/file_row.dart';
import 'package:path/path.dart' as p;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Real data
  List<FileItem> _recentFiles = [];
  List<StorageCategory> _categories = [];
  bool _loadingRecents = true;
  bool _loadingCategories = true;

  // ── Search
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  List<FileItem> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadRecents();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Data loading
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _loadRecents() async {
    try {
      final paths = await RecentService.getRecents();
      final items = <FileItem>[];
      for (final path in paths.take(20)) {
        // cap at 20 for the home preview
        try {
          final stat = await FileService.statFile(path);
          if (stat == null) continue;
          items.add(
            FileItem(
              name: p.basename(path),
              path: path,
              type: FileService.fileTypeFromPath(path),
              size: FileService.formatBytes(stat.size),
              sizeBytes: stat.size,
              modified: stat.modified.toLocal().toString().split(' ').first,
              modifiedAt: stat.modified.toLocal(),
            ),
          );
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _recentFiles = items;
        _loadingRecents = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingRecents = false);
    }
  }

  Future<void> _loadCategories() async {
    // Build categories from their base definitions (kCategories supplies
    // label / icon / color).  We reload real counts in the background so the
    // tiles appear immediately with placeholders and update when ready.
    if (!mounted) return;
    setState(() {
      // Show the skeleton list right away using the mock definitions
      _categories = kCategories;
      _loadingCategories = false;
    });

    // Now asynchronously refresh with real file counts
    final updated = <StorageCategory>[];
    for (final cat in kCategories) {
      try {
        final path = await _categoryPath(cat.label);
        if (path == null) {
          updated.add(cat);
          continue;
        }
        final items = await FileService.listFiles(path);
        final count = items.length;
        // Size: sum of all files in that folder (non-recursive for speed)
        int totalBytes = 0;
        for (final f in items) {
          totalBytes += f.sizeBytes;
        }
        updated.add(
          StorageCategory(
            label: cat.label,
            icon: cat.icon,
            color: cat.color,
            size: FileService.formatBytes(totalBytes),
            count: count == 1 ? '1 item' : '$count items',
            files: items,
          ),
        );
      } catch (_) {
        updated.add(cat);
      }
    }
    if (!mounted) return;
    setState(() => _categories = updated);
  }

  Future<String?> _categoryPath(String label) async {
    const base = '/storage/emulated/0';
    return switch (label.toLowerCase()) {
      'images' => '$base/DCIM',
      'videos' => '$base/Movies',
      'audio' => '$base/Music',
      'documents' => '$base/Documents',
      'downloads' => '$base/Download',
      'apps' => '$base/Android',
      _ => null,
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Search — debounced, filters already-loaded recents (no filesystem scan)
  // ──────────────────────────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _applySearch(query);
    });
  }

  void _applySearch(String query) {
    if (!mounted) return;
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _searchResults = _recentFiles
          .where((f) => f.name.toLowerCase().contains(q))
          .toList();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchCtrl.clear();
        _searchResults = [];
      }
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    // Search results view
    if (_isSearching) {
      return WillPopScope(
        onWillPop: () async {
          _toggleSearch();
          return false;
        },
        child: Column(
          children: [
            _buildSearchBar(topPad),
            Expanded(
              child: _searchCtrl.text.isEmpty
                  ? Center(
                      child: Text(
                        'Start typing to search recent files',
                        style: TextStyle(color: kMuted, fontSize: 13),
                      ),
                    )
                  : _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        'No results found',
                        style: TextStyle(color: kMuted, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _searchResults.length,
                      itemBuilder: (_, i) => FileRow(
                        file: _searchResults[i],
                        showDivider: i < _searchResults.length - 1,
                      ),
                    ),
            ),
          ],
        ),
      );
    }

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
                        _greeting,
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
                IconBtn(icon: Icons.search_rounded, onTap: _toggleSearch),
                const SizedBox(width: 8),
                IconBtn(icon: Icons.tune_rounded, onTap: () {}),
              ],
            ),
          ),
        ),

        // ── Storage arc card (always shows real data from its own service)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: StorageArcCard(),
          ),
        ),

        // ── Categories header
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

        // ── Categories grid (real counts loaded async)
        _loadingCategories
            ? const SliverToBoxAdapter(
                child: SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => CategoryTile(cat: _categories[i]),
                    childCount: _categories.length,
                  ),
                ),
              ),

        // ── Recent files header
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

        // ── Real recent files
        if (_loadingRecents)
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_recentFiles.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Text(
                'No recent files yet.\nOpen files to see them here.',
                style: TextStyle(color: kMuted, fontSize: 13, height: 1.6),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => FileRow(
                  file: _recentFiles[i],
                  showDivider: i < _recentFiles.length - 1,
                ),
                childCount: _recentFiles.take(10).length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar(double topPad) {
    return Container(
      color: kBg,
      padding: EdgeInsets.fromLTRB(16, topPad + 16, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: TextStyle(color: kBright, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search recent files…',
                hintStyle: TextStyle(color: kMuted),
                prefixIcon: Icon(Icons.search_rounded, color: kMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kAmber),
                ),
                filled: true,
                fillColor: kCard,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _toggleSearch,
            child: Text('Cancel', style: TextStyle(color: kAmber)),
          ),
        ],
      ),
    );
  }
}
