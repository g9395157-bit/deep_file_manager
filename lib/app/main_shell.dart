import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../utils/permission_service.dart';
import '../screens/home_screen.dart';
import '../screens/files_screen.dart';
import '../screens/recents_screen.dart';
import '../screens/storage_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  bool _permissionChecked = false;
  late final PageController _pageController;

  // Each screen is wrapped in _KeepAliveTab so state (scroll position, folder
  // navigation stack, etc.) is preserved when the user switches tabs.
  late final List<Widget> _screens = const [
    _KeepAliveTab(child: HomeScreen()),
    _KeepAliveTab(child: FilesScreen()),
    _KeepAliveTab(child: RecentsScreen()),
    _KeepAliveTab(child: StorageScreen()),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkAndRequestPermissions(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Tab switching
  // ──────────────────────────────────────────────────────────────────────────

  /// Called by the nav bar — animates the PageView to the target page.
  void _onTabTapped(int index) {
    if (_tab == index) return; // already there
    setState(() => _tab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  /// Called by PageView when the user finishes a swipe gesture.
  void _onPageChanged(int index) {
    if (_tab != index) setState(() => _tab = index);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Permissions
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _checkAndRequestPermissions() async {
    if (_permissionChecked) return;
    _permissionChecked = true;

    final need = await PermissionService.needStoragePermission();
    if (!mounted || !need) return;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Storage permission required'),
        content: const Text(
          'Deep File Manager needs storage permissions to list and manage '
          'files on your device.\n\nWe will request permission next.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final granted = await PermissionService.requestStoragePermission();
    if (!mounted) return;
    if (!granted) {
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permission denied'),
          content: const Text(
            'Permissions were not granted. You can enable them in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
      if (open == true) await PermissionService.openAppSettings();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      // PageView handles horizontal swipe natively and correctly resolves
      // gesture conflicts with nested horizontal scrollables (sort chips, etc.)
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        // ClampingScrollPhysics gives a snappy feel without rubber-banding,
        // and importantly does NOT interfere with vertical scrolling inside
        // each page.
        physics: const _TabSwipePhysics(),
        children: _screens,
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Bottom nav bar
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildNavBar() {
    const items = [
      (Icons.home_rounded, Icons.home_outlined, 'Home'),
      (Icons.folder_rounded, Icons.folder_outlined, 'Files'),
      (Icons.access_time_rounded, Icons.access_time_outlined, 'Recent'),
      (Icons.storage_rounded, Icons.storage_outlined, 'Storage'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        border: Border(top: BorderSide(color: kBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = _tab == i;
              final item = items[i];
              return Expanded(
                child: InkWell(
                  onTap: () => _onTabTapped(i),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? const LinearGradient(
                                    colors: [kAmber, kOrange],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            selected ? item.$1 : item.$2,
                            color: selected ? kBg : kMuted,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$3,
                          style: TextStyle(
                            color: selected ? kAmber : kMuted,
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _KeepAliveTab
//
// Wraps any screen so its widget tree is kept in memory when the user
// navigates to another tab — scroll positions, folder stacks, and loaded data
// are all preserved.
// ─────────────────────────────────────────────────────────────────────────────

class _KeepAliveTab extends StatefulWidget {
  final Widget child;
  const _KeepAliveTab({required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by the mixin
    return widget.child;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TabSwipePhysics
//
// Custom scroll physics for the tab PageView:
//   • Clamps at the first and last tab (no rubber-band overscroll).
//   • Uses a slightly higher minimum fling velocity so that accidental
//     micro-swipes while tapping don't trigger a tab change.
// ─────────────────────────────────────────────────────────────────────────────

class _TabSwipePhysics extends PageScrollPhysics {
  const _TabSwipePhysics() : super(parent: const ClampingScrollPhysics());

  @override
  _TabSwipePhysics applyTo(ScrollPhysics? ancestor) => _TabSwipePhysics();

  // Require at least 400 px/s to trigger a page snap on swipe, which
  // prevents accidental tab changes during normal content interaction.
  @override
  double get minFlingVelocity => 400.0;
}
