import 'package:flutter/material.dart';
import 'package:dress_right/models/prefs.dart';
import 'package:dress_right/storage/hive_boxes.dart';

class ThemeProvider with ChangeNotifier {
  ThemeProvider() {
    _load();
  }

  String _themeKey = AppThemeMode.dark;

  ThemeMode get themeMode {
    switch (_themeKey) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.dark:
      default:
        return ThemeMode.dark;
    }
  }

  String get themeKey => _themeKey;

  Future<void> setTheme(String value) async {
    if (value == _themeKey) {
      return;
    }
    _themeKey = value;
    final snapshot = HiveBoxes.prefsSnapshot;
    await HiveBoxes.savePrefs(snapshot.copyWith(theme: value));
    notifyListeners();
  }

  void _load() {
    final snapshot = HiveBoxes.prefsSnapshot;
    _themeKey = snapshot.theme;
    Future.microtask(notifyListeners);
  }
}
