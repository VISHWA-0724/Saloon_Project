import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

class StorageService {
  static const _kToken = 'auth_token';
  static const _kUser = 'auth_user';
  static const _kIsDarkMode = 'isDarkMode';
  static const _kHasSeenOnboarding = 'hasSeenOnboarding';
  static const _kWishlist = 'wishlist_ids';

  final SharedPreferences _prefs;
  StorageService._(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService._(prefs);
  }

  String? get token => _prefs.getString(_kToken);

  Future<void> setToken(String? v) async {
    if (v == null) {
      await _prefs.remove(_kToken);
    } else {
      await _prefs.setString(_kToken, v);
    }
  }

  UserModel? get user {
    final raw = _prefs.getString(_kUser);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> setUser(UserModel? u) async {
    if (u == null) {
      await _prefs.remove(_kUser);
    } else {
      await _prefs.setString(_kUser, jsonEncode(u.toJson()));
    }
  }

  bool get isDarkMode => _prefs.getBool(_kIsDarkMode) ?? false;
  Future<void> setIsDarkMode(bool v) => _prefs.setBool(_kIsDarkMode, v);

  bool get hasSeenOnboarding => _prefs.getBool(_kHasSeenOnboarding) ?? false;
  Future<void> setHasSeenOnboarding(bool v) => _prefs.setBool(_kHasSeenOnboarding, v);

  List<String> get wishlistIds => _prefs.getStringList(_kWishlist) ?? const [];
  Future<void> setWishlistIds(List<String> ids) => _prefs.setStringList(_kWishlist, ids);
}

