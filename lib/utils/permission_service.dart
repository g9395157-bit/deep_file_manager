import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles all storage permissions, including MANAGE_EXTERNAL_STORAGE
/// (Android 11+) which gives full access to all files — the same permission
/// used by EX File Manager and similar apps.
///
/// Permission strategy:
///   Android 11+ (SDK 30+) → MANAGE_EXTERNAL_STORAGE
///   Android 10  (SDK 29)  → READ + WRITE_EXTERNAL_STORAGE
///   Android ≤9  (SDK ≤28) → READ + WRITE_EXTERNAL_STORAGE
///   iOS / Desktop         → always granted (sandboxed)
class PermissionService {
  // Cache: avoids hitting the OS on every file operation
  static bool _cachedGranted = false;

  // ──────────────────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns true when a storage permission dialog should be shown.
  static Future<bool> needStoragePermission() async {
    if (!Platform.isAndroid) return false;
    if (_cachedGranted) return false;
    return !(await isStoragePermissionGranted());
  }

  /// Request storage permission. Returns true if granted.
  ///
  /// Tries MANAGE_EXTERNAL_STORAGE first; falls back to legacy READ + WRITE.
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      _cachedGranted = true;
      return true;
    }
    if (_cachedGranted) return true;

    // ── Try MANAGE_EXTERNAL_STORAGE (full access, Android 11+)
    try {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }
      if (status.isGranted) {
        _cachedGranted = true;
        return true;
      }
    } catch (_) {
      // MANAGE_EXTERNAL_STORAGE not available on this SDK version — continue
    }

    // ── Fallback: legacy READ + WRITE (Android 10 and below)
    final readStatus = await Permission.storage.request();
    _cachedGranted = readStatus.isGranted;
    return _cachedGranted;
  }

  /// Check (without requesting) whether storage permission is currently held.
  static Future<bool> isStoragePermissionGranted() async {
    if (!Platform.isAndroid) return true;

    // Check MANAGE_EXTERNAL_STORAGE first
    try {
      if (await Permission.manageExternalStorage.isGranted) {
        _cachedGranted = true;
        return true;
      }
    } catch (_) {}

    // Fallback
    final granted = await Permission.storage.isGranted;
    if (granted) _cachedGranted = true;
    return granted;
  }

  /// Reset the cache (call after the user changes permissions in system
  /// settings and returns to the app).
  static void resetCache() => _cachedGranted = false;

  /// Open the system settings page for this app so the user can manually
  /// grant MANAGE_EXTERNAL_STORAGE (required on Android 11+).
  static Future<void> openAppSettings() => openAppSettings();

  // ──────────────────────────────────────────────────────────────────────────
  // UI helper — show a dialog explaining why permission is needed, with a
  // button to open Settings (mirrors what EX File Manager does).
  // ──────────────────────────────────────────────────────────────────────────

  static Future<bool> showPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1A18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Storage Access Required',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: const Text(
          'Deep File Manager needs full storage access to browse, '
          'open, and manage your files — just like other file manager apps.\n\n'
          'Tap "Allow" to grant access in the next screen, then '
          'enable "Allow access to manage all files".',
          style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Not now',
              style: TextStyle(color: Color(0xFF9E9E9E)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Allow',
              style: TextStyle(color: Color(0xFFFFC107)),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      // On Android 11+, MANAGE_EXTERNAL_STORAGE must be granted via Settings
      final granted = await requestStoragePermission();
      if (!granted) {
        await openAppSettings();
        // Re-check after user returns from Settings
        resetCache();
        return await isStoragePermissionGranted();
      }
      return granted;
    }
    return false;
  }
}
