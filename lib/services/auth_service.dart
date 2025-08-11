import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late Dio _dio;
  static const String _baseUrl = 'http://192.168.100.130:8000/api/v1';
  static const String _tokenKey = 'auth_token';

  Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptor for automatic token handling
    _dio.interceptors.add(InterceptorsWrapper(
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
  }

  // Register user
  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String name,
    String? email,
  }) async {
    try {
             final response = await _dio.post('/auth/register', data: {
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

  // Login user
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
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
      final response = await _dio.get('/auth/me');
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
      final response = await _dio.patch('/me/edit/profile', data: {
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
      await _dio.post('/auth/logout');
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
