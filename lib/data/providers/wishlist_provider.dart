import 'package:flutter/foundation.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';

class WishlistProvider extends ChangeNotifier {
  final StorageService _storage;
  final Set<String> _ids = {};

  WishlistProvider(this._storage) {
    _ids.addAll(_storage.wishlistIds);
  }

  Set<String> get ids => _ids;

  bool isSaved(String serviceId) => _ids.contains(serviceId);

  Future<void> _persist({
    String? token,
    VoidCallback? onUnauthorized,
  }) async {
    await _storage.setWishlistIds(_ids.toList());
    if (token == null || token.isEmpty) return;
    final api = ApiService.create(token: token, onUnauthorized: onUnauthorized ?? () {});
    await api.dio.patch('/api/users/wishlist', data: {'wishlist': _ids.toList()});
  }

  Future<void> toggle(
    String serviceId, {
    String? token,
    VoidCallback? onUnauthorized,
  }) async {
    final existed = _ids.contains(serviceId);
    if (existed) {
      _ids.remove(serviceId);
    } else {
      _ids.add(serviceId);
    }
    notifyListeners();
    try {
      await _persist(token: token, onUnauthorized: onUnauthorized);
    } catch (_) {
      if (existed) {
        _ids.add(serviceId);
      } else {
        _ids.remove(serviceId);
      }
      await _storage.setWishlistIds(_ids.toList());
      notifyListeners();
    }
  }

  Future<void> remove(
    String serviceId, {
    String? token,
    VoidCallback? onUnauthorized,
  }) async {
    if (!_ids.contains(serviceId)) return;
    _ids.remove(serviceId);
    notifyListeners();
    try {
      await _persist(token: token, onUnauthorized: onUnauthorized);
    } catch (_) {
      _ids.add(serviceId);
      await _storage.setWishlistIds(_ids.toList());
      notifyListeners();
    }
  }

  Future<void> add(
    String serviceId, {
    String? token,
    VoidCallback? onUnauthorized,
  }) async {
    if (_ids.contains(serviceId)) return;
    _ids.add(serviceId);
    notifyListeners();
    try {
      await _persist(token: token, onUnauthorized: onUnauthorized);
    } catch (_) {
      _ids.remove(serviceId);
      await _storage.setWishlistIds(_ids.toList());
      notifyListeners();
    }
  }
}

