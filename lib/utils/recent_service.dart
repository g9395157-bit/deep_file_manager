import 'package:shared_preferences/shared_preferences.dart';

class RecentService {
  static const _kRecentsKey = 'recent_files';
  static const _kMaxRecents = 50;

  static Future<List<String>> getRecents() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getStringList(_kRecentsKey) ?? <String>[];
  }

  static Future<void> addRecent(String path) async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_kRecentsKey) ?? <String>[];
    // Move to front and dedupe
    list.remove(path);
    list.insert(0, path);
    if (list.length > _kMaxRecents) list.removeRange(_kMaxRecents, list.length);
    await sp.setStringList(_kRecentsKey, list);
  }

  static Future<void> clearRecents() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kRecentsKey);
  }
}
