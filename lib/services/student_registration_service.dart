import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'api_client.dart';

class StudentRegistrationService {
  final ApiClient _apiClient = ApiClient();

  void _log(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'StudentRegistrationService',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // POST /api/v1/students/registration - Submit student registration
  Future<Map<String, dynamic>> submitStudentRegistration({
    required String fullName,
    required String studentId,
    required String phone,
    required String university,
    required String college,
    required String major,
    required String program,
    required String academicYear,
    required double gpa,
    required String gender,
    required String maritalStatus,
    required String incomeLevel,
    required String familySize,
    String? email,
    String? idCardImagePath,
    Uint8List? idCardImageBytes,
    String? address,
    String? emergencyContact,
    String? emergencyPhone,
    String? financialNeed,
    String? previousSupport,
    int? programId,
  }) async {
    try {
      // Convert academic year string to number
      int academicYearNumber = _convertAcademicYearToNumber(academicYear);
      
      Map<String, dynamic> data = {
        'program_id': programId ?? 1, // Use selected program ID or default to 1
        'personal[full_name]': fullName,
        'personal[student_id]': studentId,
        'personal[email]': email ?? '',
        'personal[phone]': phone,
        'personal[gender]': gender == 'ذكر' ? 'male' : 'female',
        'academic[university]': university,
        'academic[college]': college,
        'academic[major]': major,
        'academic[program]': program,
        'academic[academic_year]': academicYearNumber,
        'academic[gpa]': gpa,
        'financial[income_level]': _convertIncomeLevelToEnglish(incomeLevel),
        'financial[family_size]': familySize,
      };

      // Print the data being sent to API
      _log('API Data being sent (form-data format):');
      data.forEach((key, value) {
        _log('$key: $value');
      });

      // Always use FormData for multipart/form-data
      FormData formData = FormData.fromMap(data);
      
      if (idCardImageBytes != null) {
        formData.files.add(MapEntry(
          'id_card_image',
          MultipartFile.fromBytes(
            idCardImageBytes,
            filename: 'id_card.jpg',
          ),
        ));
      }

      final response = await _apiClient.dio.post(
        '/students/registration',
        data: formData,
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // GET /api/v1/students/registration - Get all student registrations (for admin)
  Future<List<Map<String, dynamic>>> getAllStudentRegistrations({
    int? page,
    int? limit,
    String? status,
    String? search,
  }) async {
    try {
      Map<String, dynamic> queryParams = {};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;

      final response = await _apiClient.dio.get(
        '/students/registration',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // GET /api/v1/students/registration/{id} - Get specific student registration
  Future<Map<String, dynamic>> getStudentRegistrationById(String id) async {
    try {
      final response = await _apiClient.dio.get('/students/registration/$id');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // POST /api/v1/students/registration/{id}/documents - Upload documents for student registration
  Future<Map<String, dynamic>> uploadStudentDocuments({
    required String registrationId,
    String? idCardImagePath,
    Uint8List? idCardImageBytes,
    String? transcriptPath,
    Uint8List? transcriptBytes,
    String? incomeCertificatePath,
    Uint8List? incomeCertificateBytes,
    String? familyCardPath,
    Uint8List? familyCardBytes,
    String? otherDocumentsPath,
    Uint8List? otherDocumentsBytes,
  }) async {
    try {
      Map<String, dynamic> data = {};
      FormData formData = FormData.fromMap(data);

      // Add files if provided
      if (idCardImageBytes != null) {
        formData.files.add(MapEntry(
          'id_card_image',
          MultipartFile.fromBytes(
            idCardImageBytes,
            filename: 'id_card.jpg',
          ),
        ));
      }

      if (transcriptBytes != null) {
        formData.files.add(MapEntry(
          'transcript',
          MultipartFile.fromBytes(
            transcriptBytes,
            filename: 'transcript.pdf',
          ),
        ));
      }

      if (incomeCertificateBytes != null) {
        formData.files.add(MapEntry(
          'income_certificate',
          MultipartFile.fromBytes(
            incomeCertificateBytes,
            filename: 'income_certificate.pdf',
          ),
        ));
      }

      if (familyCardBytes != null) {
        formData.files.add(MapEntry(
          'family_card',
          MultipartFile.fromBytes(
            familyCardBytes,
            filename: 'family_card.pdf',
          ),
        ));
      }

      if (otherDocumentsBytes != null) {
        formData.files.add(MapEntry(
          'other_documents',
          MultipartFile.fromBytes(
            otherDocumentsBytes,
            filename: 'other_documents.pdf',
          ),
        ));
      }

      final response = await _apiClient.dio.post(
        '/students/registration/$registrationId/documents',
        data: formData,
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get current user's student registration
  Future<Map<String, dynamic>?> getCurrentUserRegistration() async {
    try {
      _log('Calling API: /students/registration/my-registration');
      final response = await _apiClient.dio.get('/students/registration/my-registration');
      _log('API Response: ${response.data}');
      
      // Extract data from response
      _log('Response data type: ${response.data.runtimeType}');
      _log('Response data keys: ${response.data.keys}');
      
      Map<String, dynamic> registrationData;
      
      if (response.data['data'] != null) {
        _log('Returning data from response.data[\'data\']');
        registrationData = Map<String, dynamic>.from(response.data['data']);
      } else {
        _log('Returning full response.data');
        registrationData = Map<String, dynamic>.from(response.data);
      }
      
      // Ensure status is properly formatted
      if (registrationData.containsKey('status')) {
        String status = registrationData['status']?.toString().toLowerCase() ?? 'pending';
        // Normalize status values
        switch (status) {
          case 'pending':
          case 'في الانتظار':
            registrationData['status'] = 'pending';
            break;
          case 'under_review':
          case 'قيد المراجعة':
          case 'قيد الدراسة':
            registrationData['status'] = 'under_review';
            break;
          case 'approved':
          case 'accepted':
          case 'مقبول':
          case 'تم القبول':
            registrationData['status'] = 'approved';
            break;
          case 'rejected':
          case 'مرفوض':
          case 'تم الرفض':
            registrationData['status'] = 'rejected';
            break;
          default:
            registrationData['status'] = 'pending';
        }
      } else {
        registrationData['status'] = 'pending';
      }
      
      // Ensure rejection_reason is properly handled
      if (registrationData.containsKey('rejection_reason')) {
        String? rejectionReason = registrationData['rejection_reason']?.toString();
        if (rejectionReason != null && rejectionReason.isNotEmpty) {
          registrationData['rejection_reason'] = rejectionReason;
        } else {
          registrationData['rejection_reason'] = null;
        }
      } else {
        registrationData['rejection_reason'] = null;
      }
      
      _log('Processed registration data: $registrationData');
      _log("Final status: ${registrationData['status']}");
      _log("Final rejection reason: ${registrationData['rejection_reason']}");
      
      return registrationData;
    } on DioException catch (e) {
      _log('DioException in getCurrentUserRegistration: ${e.message}');
      _log('Response status: ${e.response?.statusCode}');
      _log('Response data: ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        _log('No registration found (404)');
        return null; // No registration found
      }
      throw _handleDioError(e);
    }
  }

  // Update student registration
  Future<Map<String, dynamic>> updateStudentRegistration({
    required String registrationId,
    required Map<String, dynamic> data,
    String? idCardImagePath,
    Uint8List? idCardImageBytes,
  }) async {
    try {
      FormData? formData;
      
      if (idCardImageBytes != null) {
        formData = FormData.fromMap(data);
        formData.files.add(MapEntry(
          'id_card_image',
          MultipartFile.fromBytes(
            idCardImageBytes,
            filename: 'id_card.jpg',
          ),
        ));
      }

      final response = await _apiClient.dio.put(
        '/students/registration/$registrationId',
        data: formData ?? data,
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Delete student registration
  Future<void> deleteStudentRegistration(String registrationId) async {
    try {
      await _apiClient.dio.delete('/students/registration/$registrationId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Helper method to get localized program name
  static String getLocalizedProgramName(Map<String, dynamic> program, String locale) {
    if (locale == 'ar') {
      return program['title_ar']?.isNotEmpty == true ? program['title_ar'] : (program['name'] ?? '');
    } else {
      return program['title_en']?.isNotEmpty == true ? program['title_en'] : (program['name'] ?? '');
    }
  }

  // GET /api/v1/programs - Get all support programs
  Future<List<Map<String, dynamic>>> getSupportPrograms() async {
    try {
      _log('Calling API: /programs');
      final response = await _apiClient.dio.get('/programs');
      
      _log('API Response for programs: ${response.data}');
      _log('Response data type: ${response.data.runtimeType}');
      _log('Response status code: ${response.statusCode}');
      
      List<Map<String, dynamic>> programs = [];
      
      if (response.data['data'] != null) {
        // Handle Laravel Resource format
        final data = response.data['data'];
        _log('Data field found: $data');
        _log('Data type: ${data.runtimeType}');
        
        if (data is List) {
          programs = List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          // Single program case
          programs = [Map<String, dynamic>.from(data)];
        }
      } else if (response.data is List) {
        // Handle direct list response
        programs = List<Map<String, dynamic>>.from(response.data);
        _log('Direct list response: $programs');
      } else if (response.data is Map) {
        // Handle single object response
        programs = [Map<String, dynamic>.from(response.data)];
        _log('Single object response: $programs');
      }
      
      _log('Raw programs data: $programs');
      _log('Programs count: ${programs.length}');
      
      // Print each program details for debugging
      for (int i = 0; i < programs.length; i++) {
        final program = programs[i];
        _log('Program $i:');
        _log('  - Raw data: $program');
        _log('  - Keys: ${program.keys.toList()}');
        _log('  - ID: ${program['id']} (type: ${program['id']?.runtimeType})');
        _log('  - Title: ${program['title']} (type: ${program['title']?.runtimeType})');
        _log('  - Name: ${program['name']} (type: ${program['name']?.runtimeType})');
        _log('  - Description: ${program['description']} (type: ${program['description']?.runtimeType})');
      }
      
      // Validate and normalize programs
      final validPrograms = programs.where((program) {
        // Check for different possible field names
        final hasId = program['id'] != null;
        final hasTitleAr = program['title_ar'] != null;
        final hasTitleEn = program['title_en'] != null;
        final hasTitle = program['title'] != null;
        final hasName = program['name'] != null;
        
        final isValid = hasId && (hasTitleAr || hasTitleEn || hasTitle || hasName);
        
        _log('Program validation: id=$hasId, title_ar=$hasTitleAr, title_en=$hasTitleEn, title=$hasTitle, name=$hasName, valid=$isValid');
        
        return isValid;
      }).map((program) {
        // Normalize the data structure with bilingual support
        final titleAr = program['title_ar'] ?? program['title'] ?? program['name'] ?? 'برنامج غير محدد';
        final titleEn = program['title_en'] ?? program['title'] ?? program['name'] ?? 'Undefined Program';
        
        return {
          'id': program['id'],
          'name': titleAr, // Use Arabic title as default name
          'title_ar': titleAr,
          'title_en': titleEn,
          'description': program['description_ar'] ?? program['description'] ?? '',
          'description_ar': program['description_ar'] ?? program['description'] ?? '',
          'description_en': program['description_en'] ?? program['description'] ?? '',
          'status': program['status'] ?? 'active',
          'image': program['image'] ?? '',
          'category': program['category'] ?? {},
          'original_data': program, // Keep original data for debugging
        };
      }).toList();
      
      _log('Valid programs count: ${validPrograms.length}');
      if (validPrograms.isNotEmpty) {
        _log(
          'Valid programs: ${validPrograms.map((p) => '${p['id']}: ${p['name']}').join(', ')}',
        );
      } else {
        _log('No valid programs found. All programs: ${programs.map((p) => p.toString()).join(', ')}');
      }
      
      return validPrograms;
    } on DioException catch (e) {
      _log('Error fetching support programs: ${e.message}');
      _log('Response status: ${e.response?.statusCode}');
      _log('Response data: ${e.response?.data}');
      _log('Request URL: ${e.requestOptions.uri}');
      _log('Request method: ${e.requestOptions.method}');
      
      if (e.response?.statusCode == 404) {
        _log('No programs found (404) - Support category not found');
        throw Exception('Support category not found. Please contact the administrator to add support programs.');
      }
      
      throw _handleDioError(e);
    } catch (error, stackTrace) {
      _log(
        'Unexpected error fetching support programs: $error',
        error,
        stackTrace,
      );
      throw Exception('Failed to load support programs. Please try again later.');
    }
  }

  // Helper methods for data conversion
  int _convertAcademicYearToNumber(String academicYear) {
    switch (academicYear) {
      case 'السنة الأولى':
        return 1;
      case 'السنة الثانية':
        return 2;
      case 'السنة الثالثة':
        return 3;
      case 'السنة الرابعة':
        return 4;
      case 'السنة الخامسة':
        return 5;
      case 'السنة السادسة':
        return 6;
      default:
        return 1;
    }
  }

  String _convertIncomeLevelToEnglish(String incomeLevel) {
    switch (incomeLevel) {
      case 'منخفض':
        return 'low';
      case 'متوسط':
        return 'medium';
      case 'مرتفع':
        return 'high';
      default:
        return 'medium';
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
