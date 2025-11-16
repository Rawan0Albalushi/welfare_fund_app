import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Dio? _dio;
  static const String _tokenKey = 'auth_token';

  Future<void> initialize() async {
    // Use configured base URL to avoid dotenv issues
    const baseUrl = AppConfig.apiBaseUrlV1;
    print('API Base URL: $baseUrl'); // Debug print
    
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
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(_tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (!kReleaseMode) {
          // Lightweight logging in debug/profile
          final redactedHeaders = Map<String, dynamic>.from(options.headers);
          if (redactedHeaders.containsKey('Authorization')) {
            redactedHeaders['Authorization'] = 'Bearer ***';
          }
          debugPrint('[API][REQ] ${options.method} ${options.uri}');
          debugPrint('[API][HDR] $redactedHeaders');
          if (options.data != null) {
            debugPrint('[API][BDY] ${options.data}');
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 errors by clearing token and redirecting to login
        if (error.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_tokenKey);
          // You can add navigation logic here if needed
        }
        if (!kReleaseMode) {
          debugPrint('[API][ERR] ${error.requestOptions.method} ${error.requestOptions.uri}');
          debugPrint('[API][STS] ${error.response?.statusCode}');
          debugPrint('[API][BDY] ${error.response?.data}');
        }
        handler.next(error);
      },
      onResponse: (response, handler) {
        if (!kReleaseMode) {
          debugPrint('[API][RES] ${response.requestOptions.method} ${response.requestOptions.uri}');
          debugPrint('[API][STS] ${response.statusCode}');
          debugPrint('[API][BDY] ${response.data}');
        }
        handler.next(response);
      },
    ));
  }

  Dio get dio {
    if (_dio == null) {
      throw Exception('ApiClient not initialized. Please call initialize() first.');
    }
    return _dio!;
  }

  Future<void> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null;
  }
}
