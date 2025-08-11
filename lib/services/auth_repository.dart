import 'package:dio/dio.dart';
import 'api_client.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  // Register user
  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    String? email,
    String? name,
  }) async {
    try {
      print('Attempting to register user with phone: $phone'); // Debug print
      
      final response = await _apiClient.dio.post('/auth/register', data: {
        'phone': phone,
        'password': password,
        'password_confirmation': password, // Add password confirmation
        if (email != null) 'email': email,
        if (name != null) 'name': name,
      });

      print('Registration successful: ${response.data}'); // Debug print

      if (response.data['data']?['token'] != null) {
        await _apiClient.setAuthToken(response.data['data']['token']);
      }

      return response.data;
    } on DioException catch (e) {
      print('Registration error: ${e.message}'); // Debug print
      print('Error type: ${e.type}'); // Debug print
      print('Error response: ${e.response?.data}'); // Debug print
      throw _handleDioError(e);
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'phone': phone,
        'password': password,
      });

      if (response.data['token'] != null) {
        await _apiClient.setAuthToken(response.data['token']);
      }

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } on DioException catch (e) {
      // Even if logout fails on server, clear local token
      print('Logout error: ${e.message}');
    } finally {
      await _apiClient.clearAuthToken();
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _apiClient.isAuthenticated();
  }

  // Get stored auth token
  Future<String?> getAuthToken() async {
    return await _apiClient.getAuthToken();
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
      return 'انتهت مهلة الاتصال بالخادم';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'انتهت مهلة استقبال البيانات';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'لا يمكن الاتصال بالخادم';
    } else {
      return 'حدث خطأ غير متوقع';
    }
  }
}
