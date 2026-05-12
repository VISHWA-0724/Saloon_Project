import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final StorageService _storage;

  UserModel? _user;
  String? _token;
  bool _loading = false;
  String? _error;

  AuthProvider(this._storage) {
    _token = _storage.token;
    _user = _storage.user;
  }

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isAdmin => _user?.role == 'admin';

  Future<void> loadUser() async {
    _token = _storage.token;
    if (_token == null || _token!.isEmpty) {
      _user = null;
      notifyListeners();
      return;
    }
    try {
      final api = _api(logout);
      final res = await api.dio.get('/api/users/profile');
      _user = UserModel.fromJson(res.data as Map<String, dynamic>);
      await _storage.setUser(_user);
    } catch (_) {
      // token invalid or offline; keep cached user if any
      _user = _storage.user;
    }
    notifyListeners();
  }

  ApiService _api(OnUnauthorized onUnauthorized) =>
      ApiService.create(token: _token, onUnauthorized: onUnauthorized);

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final api = _api(logout);
      final res = await api.dio.post('/api/auth/login', data: {
        'email': email.trim(),
        'password': password,
      });
      final data = res.data as Map<String, dynamic>;
      _token = data['token']?.toString();
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _storage.setToken(_token);
      await _storage.setUser(_user);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _messageFromError(
        e,
        'Login failed. Please check your credentials.',
      );
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final api = _api(logout);
      final res = await api.dio.post('/api/auth/register', data: {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
      });
      final data = res.data as Map<String, dynamic>;
      _token = data['token']?.toString();
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _storage.setToken(_token);
      await _storage.setUser(_user);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _messageFromError(e, 'Registration failed. Try again.');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storage.setToken(null);
    await _storage.setUser(null);
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final api = _api(logout);
      final res = await api.dio.patch('/api/users/profile', data: {
        'name': name.trim(),
        'phone': phone.trim(),
      });
      _user = UserModel.fromJson(res.data as Map<String, dynamic>);
      await _storage.setUser(_user);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _messageFromError(e, 'Could not update profile.');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadProfileImage(XFile image) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final api = _api(logout);
      final fileName = image.name.isEmpty ? 'profile.jpg' : image.name;
      final form = FormData.fromMap({
        'image': kIsWeb
            ? MultipartFile.fromBytes(
                await image.readAsBytes(),
                filename: fileName,
              )
            : await MultipartFile.fromFile(
                image.path,
                filename: fileName,
              ),
      });
      final res = await api.dio.post('/api/users/profile-image', data: form);
      final data = res.data as Map<String, dynamic>;
      final uploadedUser = data['user'];
      if (uploadedUser is Map<String, dynamic>) {
        _user = UserModel.fromJson(uploadedUser);
        await _storage.setUser(_user);
      } else {
        final url = (data['url'] ?? data['profileImage'] ?? '').toString();
        if (_user != null && url.isNotEmpty) {
          _user = UserModel(
            id: _user!.id,
            name: _user!.name,
            email: _user!.email,
            phone: _user!.phone,
            profileImage: url,
            role: _user!.role,
            points: _user!.points,
            bookingsCount: _user!.bookingsCount,
            reviewsCount: _user!.reviewsCount,
            wishlist: _user!.wishlist,
          );
          await _storage.setUser(_user);
        }
      }
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _messageFromError(e, 'Could not upload image.');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  String _messageFromError(Object error, String fallback) {
    if (error is DioException) {
      final wrapped = error.error;
      if (wrapped is AppException && wrapped.message.trim().isNotEmpty) {
        return wrapped.message;
      }

      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message']?.toString().trim();
        if (message != null && message.isNotEmpty) return message;
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Cannot reach the backend. Check your internet connection or API URL.';
      }

      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) return message;
    }

    if (error is AppException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return fallback;
  }
}
