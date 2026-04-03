import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Returns true if storage-related permission is already granted.
  static Future<bool> isStoragePermissionGranted() async {
    if (Platform.isAndroid) {
      // On Android 11+ apps may use MANAGE_EXTERNAL_STORAGE; otherwise storage.
      if (await Permission.manageExternalStorage.status.isGranted) return true;
      if (await Permission.storage.status.isGranted) return true;
      return false;
    } else if (Platform.isIOS) {
      // On iOS we treat photo library access as storage access.
      return await Permission.photos.status.isGranted ||
          await Permission.photosAddOnly.status.isGranted;
    }
    return true;
  }

  /// Returns true when permission is not yet granted and therefore needed.
  static Future<bool> needStoragePermission() async {
    return !(await isStoragePermissionGranted());
  }

  /// Requests the appropriate storage permission for the platform.
  /// Returns true if permission was granted.
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Try manageExternalStorage first (Android 11+). If it isn't available or
      // denied, fall back to the regular storage permission.
      try {
        final manageStatus = await Permission.manageExternalStorage.request();
        if (manageStatus.isGranted) return true;
      } catch (_) {}

      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }
    return true;
  }

  /// Opens app settings so the user can enable permissions manually.
  static Future<bool> openAppSettingsPage() async {
    return await openAppSettings();
  }
}
