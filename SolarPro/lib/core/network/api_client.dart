import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_pro/core/constants/app_constants.dart';

class EmailVerificationRequiredException implements Exception {
  final String message;
  final String? email;
  final String? role;

  EmailVerificationRequiredException({
    required this.message,
    this.email,
    this.role,
  });

  @override
  String toString() => message;
}

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

  /// Login with email or phone + password (salted bcrypt verification)
  Future<Map<String, dynamic>?> loginWithPassword(String identifier, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'identifier': identifier,
        'password': password,
      });
      final data = res.data as Map<String, dynamic>?;
      if (data != null && data['access_token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.kAccessToken, data['access_token'] as String);
        if (data['refresh_token'] != null) {
          await prefs.setString(AppConstants.kRefreshToken, data['refresh_token'] as String);
        }
        if (data['user'] != null && data['user'] is Map) {
          final user = data['user'] as Map<String, dynamic>;
          if (user['role'] != null) {
            await prefs.setString(AppConstants.kUserRole, user['role'] as String);
          }
          if (user['id'] != null) {
            await prefs.setString(AppConstants.kUserId, user['id'].toString());
          }
          if (user['name'] != null) {
            await prefs.setString(AppConstants.kUserName, user['name'] as String);
          }
          if (user['phone'] != null) {
            await prefs.setString(AppConstants.kUserPhone, user['phone'] as String);
          }
          if (user['email'] != null) {
            await prefs.setString('user_email', user['email'] as String);
          }
        }
      }
      return data;
    } on DioException catch (de) {
      final errData = de.response?.data is Map ? (de.response?.data as Map)['error'] : null;
      final errCode = errData is Map ? errData['code']?.toString() : null;
      if (errCode == 'EMAIL_NOT_VERIFIED' || de.response?.statusCode == 403) {
        final details = errData is Map && errData['details'] is Map ? errData['details'] as Map : null;
        final email = details?['email']?.toString() ?? (identifier.contains('@') ? identifier : null);
        throw EmailVerificationRequiredException(
          message: errData is Map && errData['message'] != null
              ? errData['message'].toString()
              : 'Email verification is required before logging in.',
          email: email,
          role: details?['role']?.toString() ?? 'client',
        );
      }
      final msg = (errData is Map ? errData['message'] : null) ??
          de.response?.data?['detail'] ??
          de.message ??
          'Invalid credentials';
      dev.log('loginWithPassword DioException: $msg');
      throw Exception(msg);
    } catch (e) {
      dev.log('loginWithPassword error: $e');
      rethrow;
    }
  }

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
        if (data['user'] != null && data['user'] is Map) {
          final user = data['user'] as Map<String, dynamic>;
          if (user['role'] != null) {
            await prefs.setString(AppConstants.kUserRole, user['role'] as String);
          }
          if (user['id'] != null) {
            await prefs.setString(AppConstants.kUserId, user['id'].toString());
          }
          if (user['name'] != null) {
            await prefs.setString(AppConstants.kUserName, user['name'] as String);
          }
          if (user['phone'] != null) {
            await prefs.setString(AppConstants.kUserPhone, user['phone'] as String);
          }
          if (user['email'] != null) {
            await prefs.setString('user_email', user['email'] as String);
          }
        }
      }
      return data;
    } on DioException catch (de) {
      final errData = de.response?.data is Map ? (de.response?.data as Map)['error'] : null;
      final errCode = errData is Map ? errData['code']?.toString() : null;
      if (errCode == 'EMAIL_NOT_VERIFIED' || de.response?.statusCode == 403) {
        final details = errData is Map && errData['details'] is Map ? errData['details'] as Map : null;
        final email = details?['email']?.toString();
        throw EmailVerificationRequiredException(
          message: errData is Map && errData['message'] != null
              ? errData['message'].toString()
              : 'Email verification is required before logging in.',
          email: email,
          role: details?['role']?.toString() ?? 'client',
        );
      }
      final msg = (errData is Map ? errData['message'] : null) ??
          de.response?.data?['detail'] ??
          de.message ??
          'Invalid or expired OTP.';
      throw Exception(msg);
    } catch (e) {
      dev.log('verifyOtp error: $e');
      rethrow;
    }
  }

  /// Request a 6-digit email verification code dispatched to email
  Future<bool> sendEmailVerification(String email) async {
    try {
      final res = await _dio.post('/auth/send-verification-email', data: {
        'email': email.trim().toLowerCase(),
      });
      return res.statusCode == 200;
    } catch (e) {
      dev.log('sendEmailVerification error: $e');
      return false;
    }
  }

  /// Verify 6-digit email code and activate client account
  Future<Map<String, dynamic>?> verifyEmail(String email, String code) async {
    try {
      final res = await _dio.post('/auth/verify-email', data: {
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
      });
      final data = res.data as Map<String, dynamic>?;
      if (data != null && data['access_token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.kAccessToken, data['access_token'] as String);
        if (data['refresh_token'] != null) {
          await prefs.setString(AppConstants.kRefreshToken, data['refresh_token'] as String);
        }
        if (data['user'] != null && data['user'] is Map) {
          final user = data['user'] as Map<String, dynamic>;
          if (user['role'] != null) {
            await prefs.setString(AppConstants.kUserRole, user['role'] as String);
          }
          if (user['id'] != null) {
            await prefs.setString(AppConstants.kUserId, user['id'].toString());
          }
          if (user['name'] != null) {
            await prefs.setString(AppConstants.kUserName, user['name'] as String);
          }
          if (user['phone'] != null) {
            await prefs.setString(AppConstants.kUserPhone, user['phone'] as String);
          }
          if (user['email'] != null) {
            await prefs.setString('user_email', user['email'] as String);
          }
        }
      }
      return data;
    } on DioException catch (de) {
      final errData = de.response?.data is Map ? (de.response?.data as Map)['error'] : null;
      final msg = (errData is Map ? errData['message'] : null) ??
          de.response?.data?['detail'] ??
          'Invalid or expired verification code.';
      throw Exception(msg);
    } catch (e) {
      dev.log('verifyEmail error: $e');
      rethrow;
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
      await prefs.remove(AppConstants.kUserName);
      await prefs.remove(AppConstants.kUserPhone);
      await prefs.remove('user_email');
    } catch (e) {
      dev.log('logout error: $e');
    }
  }

  /// Register a new user account (client, vendor, sales)
  Future<Map<String, dynamic>?> registerUser({
    required String name,
    required String phone,
    required String password,
    String? email,
    String role = 'client',
  }) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'name': name.trim(),
        'phone': phone.trim(),
        'password': password,
        'email': email?.trim().toLowerCase(),
        'role': role.trim().toLowerCase(),
      });
      return res.data as Map<String, dynamic>?;
    } on DioException catch (de) {
      final errData = de.response?.data is Map ? (de.response?.data as Map)['error'] : null;
      final msg = (errData is Map ? errData['message'] : null) ??
          de.response?.data?['detail'] ??
          de.message ??
          'Registration failed.';
      throw Exception(msg);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch all active leads from cloud backend
  Future<List<Map<String, dynamic>>> getLeads() async {
    try {
      final res = await _dio.get('/leads');
      if (res.data is Map && res.data['items'] is List) {
        return List<Map<String, dynamic>>.from(res.data['items']);
      } else if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      dev.log('getLeads error: $e');
      return [];
    }
  }

  /// Create a new real lead on cloud backend
  Future<Map<String, dynamic>?> createLead({
    required String name,
    required String phone,
    String? area,
    double kw = 3.0,
    String status = 'new',
    String source = 'Direct',
  }) async {
    try {
      final res = await _dio.post('/leads', data: {
        'name': name.trim(),
        'phone': phone.trim(),
        'area': area?.trim() ?? '',
        'kw': kw,
        'status': status,
        'source': source,
      });
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      dev.log('createLead error: $e');
      rethrow;
    }
  }

  /// Fetch all real customers from cloud backend
  Future<List<Map<String, dynamic>>> getCustomers() async {
    try {
      final res = await _dio.get('/customers');
      if (res.data is Map && res.data['items'] is List) {
        return List<Map<String, dynamic>>.from(res.data['items']);
      } else if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      dev.log('getCustomers error: $e');
      return [];
    }
  }

  /// Create a new real customer on cloud backend
  Future<Map<String, dynamic>?> createCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    double kw = 5.0,
  }) async {
    try {
      final res = await _dio.post('/customers', data: {
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email?.trim().toLowerCase(),
        'address': address?.trim() ?? '',
        'kw': kw,
      });
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      dev.log('createCustomer error: $e');
      rethrow;
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
