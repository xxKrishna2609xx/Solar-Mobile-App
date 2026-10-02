import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_pro/core/constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(AppConstants.kAccessToken);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          dev.log('API Request: [${options.method}] ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          dev.log('API Response: [${response.statusCode}] ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          dev.log('API Error: [${error.response?.statusCode}] ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // ── Authentication ─────────────────────────────────────────────────────────

  /// Request 6-digit OTP for login
  Future<Map<String, dynamic>?> requestOtp(String phone) async {
    try {
      final res = await _dio.post('/auth/request-otp', data: {'phone': phone});
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      dev.log('requestOtp error: $e');
      return null;
    }
  }

  /// Verify OTP and store tokens
  Future<Map<String, dynamic>?> verifyOtp(String phone, String otp) async {
    try {
      final res = await _dio.post('/auth/verify-otp', data: {
        'phone': phone,
        'otp': otp,
      });
      final data = res.data as Map<String, dynamic>?;
      if (data != null && data['access_token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.kAccessToken, data['access_token'] as String);
        if (data['refresh_token'] != null) {
          await prefs.setString(AppConstants.kRefreshToken, data['refresh_token'] as String);
        }
      }
      return data;
    } catch (e) {
      dev.log('verifyOtp error: $e');
      return null;
    }
  }

  /// Get current user profile
  Future<Map<String, dynamic>?> getMe() async {
    try {
      final res = await _dio.get('/auth/me');
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      dev.log('getMe error: $e');
      return null;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(AppConstants.kRefreshToken);
      if (refreshToken != null) {
        await _dio.post('/auth/logout', data: {'refresh_token': refreshToken});
      }
      await prefs.remove(AppConstants.kAccessToken);
      await prefs.remove(AppConstants.kRefreshToken);
      await prefs.remove(AppConstants.kUserRole);
      await prefs.remove(AppConstants.kUserId);
    } catch (e) {
      dev.log('logout error: $e');
    }
  }

  // ── Generic GET/POST/PATCH/DELETE Helpers ─────────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.post<T>(path, data: data, queryParameters: queryParameters);
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.patch<T>(path, data: data, queryParameters: queryParameters);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.delete<T>(path, data: data, queryParameters: queryParameters);
  }
}
