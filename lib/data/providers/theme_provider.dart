import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storage;
  bool _isDarkMode;

  ThemeProvider(this._storage) : _isDarkMode = _storage.isDarkMode;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _storage.setIsDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> setDark(bool v) async {
    _isDarkMode = v;
    await _storage.setIsDarkMode(_isDarkMode);
    notifyListeners();
  }
}

