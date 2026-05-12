import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_strings.dart';

typedef OnUnauthorized = void Function();

class ApiService {
  final Dio _dio;

  ApiService._(this._dio);

  static ApiService create({
    required String? token,
    required OnUnauthorized onUnauthorized,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppStrings.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          var authToken = token;
          if (authToken == null || authToken.isEmpty) {
            final prefs = await SharedPreferences.getInstance();
            authToken = prefs.getString('auth_token');
          }
          if (authToken != null && authToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $authToken';
          }
          handler.next(options);
        },
        onError: (e, handler) {
          final code = e.response?.statusCode;
          if (code == 401) {
            onUnauthorized();
          }
          final message = (e.response?.data is Map<String, dynamic>)
              ? (e.response?.data['message']?.toString() ?? 'Request failed')
              : (e.message ?? 'Request failed');
          handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: AppException(message),
            ),
          );
        },
      ),
    );

    return ApiService._(dio);
  }

  Dio get dio => _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final res = await _dio.get(path, queryParameters: query);
    return res.data;
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    final res = await _dio.post(path, data: data);
    return res.data;
  }

  Future<dynamic> patch(String path, {dynamic data}) async {
    final res = await _dio.patch(path, data: data);
    return res.data;
  }

  Future<dynamic> delete(String path, {dynamic data}) async {
    final res = await _dio.delete(path, data: data);
    return res.data;
  }
}

class AppException implements Exception {
  final String message;
  AppException(this.message);
  @override
  String toString() => message;
}
