import 'package:dio/dio.dart';
import 'api_client.dart';

class StudentRegistrationService {
  final ApiClient _apiClient = ApiClient();

  // Submit student application for welfare fund support
  Future<Map<String, dynamic>> submitStudentApplication({
    required String fullName,
    required String studentId,
    required String phone,
    required String university,
    required String college,
    required String major,
    required String academicYear,
    required double gpa,
    required String gender,
    required String maritalStatus,
    required String incomeLevel,
    required String familySize,
    String? email,
    String? idCardImagePath,
  }) async {
    try {
      // Create FormData for file upload if image is provided
      FormData? formData;
      Map<String, dynamic> data = {
        'full_name': fullName,
        'student_id': studentId,
        'phone': phone,
        'university': university,
        'college': college,
        'major': major,
        'academic_year': academicYear,
        'gpa': gpa.toString(),
        'gender': gender,
        'marital_status': maritalStatus,
        'income_level': incomeLevel,
        'family_size': familySize,
        if (email != null && email.isNotEmpty) 'email': email,
      };

      if (idCardImagePath != null) {
        formData = FormData.fromMap(data);
        formData.files.add(MapEntry(
          'id_card_image',
          await MultipartFile.fromFile(idCardImagePath),
        ));
      }

      final response = await _apiClient.dio.post(
        '/student-applications/submit',
        data: formData ?? data,
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get student application status
  Future<Map<String, dynamic>> getApplicationStatus(String studentId) async {
    try {
      final response = await _apiClient.dio.get('/student-applications/status/$studentId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Update student application
  Future<Map<String, dynamic>> updateApplication({
    required String studentId,
    required Map<String, dynamic> data,
    String? idCardImagePath,
  }) async {
    try {
      FormData? formData;
      
      if (idCardImagePath != null) {
        formData = FormData.fromMap(data);
        formData.files.add(MapEntry(
          'id_card_image',
          await MultipartFile.fromFile(idCardImagePath),
        ));
      }

      final response = await _apiClient.dio.put(
        '/student-applications/update/$studentId',
        data: formData ?? data,
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get user's submitted applications
  Future<List<Map<String, dynamic>>> getUserApplications() async {
    try {
      final response = await _apiClient.dio.get('/student-applications/my-applications');
      return List<Map<String, dynamic>>.from(response.data['applications'] ?? []);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
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
