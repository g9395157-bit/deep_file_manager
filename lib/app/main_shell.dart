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

  final List<Widget> _screens = const [
    HomeScreen(),
    FilesScreen(),
    RecentsScreen(),
    StorageScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkAndRequestPermissions(),
    );
  }

  Future<void> _checkAndRequestPermissions() async {
    if (_permissionChecked) return;
    _permissionChecked = true;

    final need = await PermissionService.needStoragePermission();
    if (!mounted) return;
    if (!need) return; // only request when needed

    // Show explainer card/dialog
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Storage permission required'),
        content: const Text(
          'Deep File Manager needs storage permissions to list and manage files on your device.\n\n'
          'We will request permission next. You can choose to deny it, and the app will still function with limited features.',
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
      if (open == true) await PermissionService.openAppSettingsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: _buildNavBar(),
    );
  }

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
                  onTap: () => setState(() => _tab = i),
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
