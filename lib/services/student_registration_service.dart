import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'api_client.dart';

class StudentRegistrationService {
  final ApiClient _apiClient = ApiClient();

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
      
      // Convert family size string to number
      int familySizeNumber = _convertFamilySizeToNumber(familySize);
      
      // Convert income level to number
      double familyIncome = _convertIncomeLevelToNumber(incomeLevel);
      
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
      print('API Data being sent (form-data format):');
      data.forEach((key, value) {
        print('$key: $value');
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
      print('Calling API: /students/registration/my-registration');
      final response = await _apiClient.dio.get('/students/registration/my-registration');
      print('API Response: ${response.data}');
      
      // Extract data from response
      print('Response data type: ${response.data.runtimeType}');
      print('Response data keys: ${response.data.keys}');
      
      Map<String, dynamic> registrationData;
      
      if (response.data['data'] != null) {
        print('Returning data from response.data[\'data\']');
        registrationData = Map<String, dynamic>.from(response.data['data']);
      } else {
        print('Returning full response.data');
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
      
      print('Processed registration data: $registrationData');
      print('Final status: ${registrationData['status']}');
      print('Final rejection reason: ${registrationData['rejection_reason']}');
      
      return registrationData;
    } on DioException catch (e) {
      print('DioException in getCurrentUserRegistration: ${e.message}');
      print('Response status: ${e.response?.statusCode}');
      print('Response data: ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        print('No registration found (404)');
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

  // GET /api/v1/programs/support - Get all support programs
  Future<List<Map<String, dynamic>>> getSupportPrograms() async {
    try {
      print('Calling API: /programs/support');
      final response = await _apiClient.dio.get('/programs/support');
      
      print('API Response for programs: ${response.data}');
      print('Response data type: ${response.data.runtimeType}');
      print('Response status code: ${response.statusCode}');
      
      List<Map<String, dynamic>> programs = [];
      
      if (response.data['data'] != null) {
        // Handle Laravel Resource format
        final data = response.data['data'];
        print('Data field found: $data');
        print('Data type: ${data.runtimeType}');
        
        if (data is List) {
          programs = List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          // Single program case
          programs = [Map<String, dynamic>.from(data)];
        }
      } else if (response.data is List) {
        // Handle direct list response
        programs = List<Map<String, dynamic>>.from(response.data);
        print('Direct list response: $programs');
      } else if (response.data is Map) {
        // Handle single object response
        programs = [Map<String, dynamic>.from(response.data)];
        print('Single object response: $programs');
      }
      
      print('Raw programs data: $programs');
      print('Programs count: ${programs.length}');
      
      // Print each program details for debugging
      for (int i = 0; i < programs.length; i++) {
        final program = programs[i];
        print('Program $i:');
        print('  - Raw data: $program');
        print('  - Keys: ${program.keys.toList()}');
        print('  - ID: ${program['id']} (type: ${program['id']?.runtimeType})');
        print('  - Title: ${program['title']} (type: ${program['title']?.runtimeType})');
        print('  - Name: ${program['name']} (type: ${program['name']?.runtimeType})');
        print('  - Description: ${program['description']} (type: ${program['description']?.runtimeType})');
      }
      
      // Validate and normalize programs
      final validPrograms = programs.where((program) {
        // Check for different possible field names
        final hasId = program['id'] != null;
        final hasTitle = program['title'] != null;
        final hasName = program['name'] != null;
        
        final isValid = hasId && (hasTitle || hasName);
        
        print('Program validation: id=$hasId, title=$hasTitle, name=$hasName, valid=$isValid');
        
        return isValid;
      }).map((program) {
        // Normalize the data structure
        return {
          'id': program['id'],
          'name': program['title'] ?? program['name'] ?? 'برنامج غير محدد',
          'description': program['description'] ?? '',
          'original_data': program, // Keep original data for debugging
        };
      }).toList();
      
      print('Valid programs count: ${validPrograms.length}');
      if (validPrograms.isNotEmpty) {
        print('Valid programs: ${validPrograms.map((p) => '${p['id']}: ${p['name']}').join(', ')}');
      } else {
        print('No valid programs found. All programs: ${programs.map((p) => p.toString()).join(', ')}');
      }
      
      return validPrograms;
    } on DioException catch (e) {
      print('Error fetching support programs: ${e.message}');
      print('Response status: ${e.response?.statusCode}');
      print('Response data: ${e.response?.data}');
      print('Request URL: ${e.requestOptions.uri}');
      print('Request method: ${e.requestOptions.method}');
      
      if (e.response?.statusCode == 404) {
        print('No programs found (404) - Support category not found');
        throw Exception('Support category not found. Please contact the administrator to add support programs.');
      }
      
      throw _handleDioError(e);
    } catch (error) {
      print('Unexpected error fetching support programs: $error');
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

  int _convertFamilySizeToNumber(String familySize) {
    switch (familySize) {
      case '1-3':
        return 3;
      case '4-6':
        return 6;
      case '7-9':
        return 8;
      case '10+':
        return 10;
      default:
        return 3;
    }
  }

  double _convertIncomeLevelToNumber(String incomeLevel) {
    switch (incomeLevel) {
      case 'منخفض':
        return 2000.0;
      case 'متوسط':
        return 5000.0;
      case 'مرتفع':
        return 10000.0;
      default:
        return 5000.0;
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
