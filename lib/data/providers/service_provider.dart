import 'package:flutter/foundation.dart';

import '../models/service_model.dart';
import '../services/api_service.dart';

class ServiceProvider extends ChangeNotifier {
  final List<String> categories = const ['All', 'Hair', 'Nails', 'Spa', 'Makeup'];

  String _activeCategory = 'All';
  String _query = '';
  double _minPrice = 0;
  double _maxPrice = 5000;
  double _minRating = 0;
  int _maxDuration = 999;
  bool _loading = false;
  List<ServiceModel> _services = const [];
  String? _error;

  String get activeCategory => _activeCategory;
  String get query => _query;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  double get minRating => _minRating;
  int get maxDuration => _maxDuration;
  bool get isLoading => _loading;
  List<ServiceModel> get services => _services;
  String? get error => _error;

  List<ServiceModel> get filtered {
    final q = _query.trim().toLowerCase();
    return _services.where((s) {
      final catOk = _activeCategory == 'All' || s.category.toLowerCase() == _activeCategory.toLowerCase();
      final qOk = q.isEmpty ||
          s.title.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q);
      final priceOk = s.price >= _minPrice && s.price <= _maxPrice;
      final ratingOk = s.rating >= _minRating;
      final durationOk = s.duration <= _maxDuration;
      return catOk && qOk && priceOk && ratingOk && durationOk;
    }).toList();
  }

  List<ServiceModel> get filteredServices => filtered;

  Future<void> fetchServices({String? token, VoidCallback? onUnauthorized}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final api = ApiService.create(
        token: token,
        onUnauthorized: onUnauthorized ?? () {},
      );
      final res = await api.dio.get('/api/services');
      final list = (res.data as List).cast<Map<String, dynamic>>();
      _services = list.map(ServiceModel.fromJson).toList();
      _loading = false;
      notifyListeners();
    } catch (e) {
      _services = const [];
      _loading = false;
      _error = 'Failed to load services. Start the backend and try again.';
      notifyListeners();
    }
  }

  Future<ServiceModel?> fetchServiceById(String id, {String? token, VoidCallback? onUnauthorized}) async {
    try {
      final api = ApiService.create(
        token: token,
        onUnauthorized: onUnauthorized ?? () {},
      );
      final res = await api.dio.get('/api/services/$id');
      return ServiceModel.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return _services.where((s) => s.id == id).firstOrNull;
    }
  }

  void setCategory(String v) {
    _activeCategory = v;
    notifyListeners();
  }

  void setQuery(String v) {
    _query = v;
    notifyListeners();
  }

  void applyFilters({
    required String category,
    required double minPrice,
    required double maxPrice,
    required double minRating,
    required int maxDuration,
  }) {
    _activeCategory = category;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _minRating = minRating;
    _maxDuration = maxDuration;
    notifyListeners();
  }

  void clearFilters() {
    _activeCategory = 'All';
    _minPrice = 0;
    _maxPrice = 5000;
    _minRating = 0;
    _maxDuration = 999;
    notifyListeners();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

