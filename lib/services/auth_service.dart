import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Dio? _dio;
  static const String _tokenKey = 'auth_token';

  Future<void> initialize() async {
    // Use configured base URL to avoid dotenv issues
    const baseUrl = AppConfig.authBaseUrl;
    print('AuthService: Using base URL: $baseUrl');
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptor for automatic token handling
    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token to all requests
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 errors by clearing token
        if (error.response?.statusCode == 401) {
          await _clearToken();
        }
        handler.next(error);
      },
    ));
    
    print('AuthService: Dio initialized successfully');
  }

  // Register user (legacy - without phone verification)
  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String name,
    String? email,
  }) async {
    if (_dio == null) {
      throw Exception('AuthService not initialized. Please call initialize() first.');
    }
    
    try {
      final response = await _dio!.post('/auth/register', data: {
         'phone': phone,
         'password': password,
         'password_confirmation': passwordConfirmation,
         'name': name,
         if (email != null && email.isNotEmpty) 'email': email,
       });

      // Store token if received
      if (response.data['data']?['token'] != null) {
        await _saveToken(response.data['data']['token']);
      } else if (response.data['token'] != null) {
        await _saveToken(response.data['token']);
      }

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// تسجيل جديد بالهاتف مع إرسال OTP (بدون حفظ توكن حتى التحقق)
  /// Returns: { "verifyId": "...", "phone": "968****4567" }
  Future<Map<String, dynamic>> registerWithPhone({
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String name,
    String? email,
  }) async {
    if (_dio == null) {
      throw Exception('AuthService not initialized. Please call initialize() first.');
    }
    try {
      final response = await _dio!.post('/auth/register/phone', data: {
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
      });
      final data = response.data;
      // للتطوير: طباعة الاستجابة في الـ log (إذا الباكند يرسل otp في الاستجابة ستظهر هنا)
      assert(() {
        print('AuthService [register/phone] response: $data');
        final devOtp = data['data']?['otp'] ?? data['data']?['dev_otp'] ?? data['data']?['debug_otp'] ?? data['data']?['code'];
        if (devOtp != null) {
          print('AuthService [DEV] OTP من الباكند: $devOtp');
        }
        return true;
      }());
      return data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// إدخال رمز التحقق وإكمال التسجيل - يحفظ التوكن عند النجاح
  Future<Map<String, dynamic>> verifyPhoneOtp({
    required String verifyId,
    required String verifyCode,
  }) async {
    if (_dio == null) {
      throw Exception('AuthService not initialized. Please call initialize() first.');
    }
    try {
      final response = await _dio!.post('/auth/verify/phone/otp', data: {
        'verifyId': verifyId,
        'verifyCode': verifyCode,
      });
      final data = response.data;
      if (data['data']?['token'] != null) {
        await _saveToken(data['data']['token']);
      } else if (data['token'] != null) {
        await _saveToken(data['token']);
      }
      return data;
    } on DioException catch (e) {
      if (e.response != null) {
        final status = e.response!.statusCode;
        final data = e.response!.data;
        if (data is Map<String, dynamic> && data['message'] != null) {
          throw Exception(data['message'].toString());
        }
        if (status == 404) {
          throw Exception('session_expired_register_again');
        }
        if (status == 203) {
          throw Exception('code_expired_request_new');
        }
        if (status == 201 || status == 422) {
          throw Exception('invalid_verification_code');
        }
      }
      throw _handleDioError(e);
    }
  }

  /// في بيئة التطوير فقط: جلب الرمز عبر GET /auth/dev/otp?verifyId=...
  /// Returns: data.otp أو null إذا الـ endpoint غير متوفر
  Future<String?> getDevOtp(String verifyId) async {
    if (_dio == null) return null;
    try {
      final response = await _dio!.get(
        '/auth/dev/otp',
        queryParameters: {'verifyId': verifyId},
      );
      final data = response.data;
      final otp = data['data']?['otp'] ?? data['otp'];
      return otp?.toString();
    } on DioException catch (_) {
      return null;
    }
  }

  /// إعادة إرسال رمز OTP
  /// Returns: { "data": { "verifyId": "uuid-new", "phone": "968****4567" } }
  Future<Map<String, dynamic>> resendOtp({required String phone}) async {
    if (_dio == null) {
      throw Exception('AuthService not initialized. Please call initialize() first.');
    }
    try {
      final response = await _dio!.post('/auth/resend-otp', data: {
        'phone': phone,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    if (_dio == null) {
      throw Exception('AuthService not initialized. Please call initialize() first.');
    }
    
    try {
      final response = await _dio!.post('/auth/login', data: {
        'phone': phone,
        'password': password,
      });

      // Store token if received
      if (response.data['data']?['token'] != null) {
        await _saveToken(response.data['data']['token']);
      } else if (response.data['token'] != null) {
        await _saveToken(response.data['token']);
      }

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio!.get('/v1/me/edit/profile');
      print('AuthService: getCurrentUser response: ${response.data}');
      print('AuthService: getCurrentUser response keys: ${response.data.keys}');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    String? email,
  }) async {
    try {
      final response = await _dio!.patch('/v1/me/edit/profile', data: {
        'name': name,
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
      });

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await _dio!.post('/auth/logout');
    } on DioException catch (e) {
      // Even if logout fails on server, clear local token
      print('Logout error: ${e.message}');
    } finally {
      await _clearToken();
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _getToken();
    return token != null;
  }

  // Get stored auth token
  Future<String?> getToken() async {
    return await _getToken();
  }

  // Save token to SharedPreferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Get token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Clear token from SharedPreferences
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Handle Dio errors and extract meaningful error messages
  String _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        // Handle Laravel validation errors
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }
        }
        // Handle general error message
        if (data['message'] != null) {
          return data['message'].toString();
        }
      }
      return 'حدث خطأ في الخادم (${e.response!.statusCode})';
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'انتهت مهلة الاتصال بالخادم (30 ثانية)';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'انتهت مهلة استقبال البيانات (30 ثانية)';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'لا يمكن الاتصال بالخادم';
    } else {
      return 'حدث خطأ غير متوقع';
    }
  }
}
