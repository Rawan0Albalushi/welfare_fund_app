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

  /// POST /api/v1/students/registration - تقديم طلب تسجيل جديد
  /// 
  /// يدعم الهيكل الجديد للبيانات:
  /// - personal: البيانات الشخصية
  /// - academic: البيانات الأكاديمية  
  /// - guardian: بيانات ولي الأمر
  /// - documents: المرفقات
  Future<Map<String, dynamic>> submitStudentRegistration({
    required int programId,
    // البيانات الشخصية (personal)
    required String fullName,
    required String civilId,
    required DateTime dateOfBirth,
    required String phone,
    required String address,
    required String maritalStatus, // single, married, divorced, widowed
    String? email,
    // البيانات الأكاديمية (academic)
    required String institution,
    required String studentId,
    String? college,
    String? major,
    String? program,
    int? academicYear,
    double? gpa,
    // بيانات ولي الأمر (guardian)
    required String guardianName,
    required String guardianJob,
    required double guardianMonthlyIncome,
    required int guardianFamilySize,
    required bool isFatherAlive,
    required bool isMotherAlive,
    required String parentsMaritalStatus, // stable, separated
    // المرفقات (documents) - اختيارية
    Map<String, Uint8List>? documentFiles,
  }) async {
    try {
      // تحويل تاريخ الميلاد للصيغة المطلوبة YYYY-MM-DD
      String dateOfBirthFormatted = dateOfBirth.toIso8601String().split('T').first;
      
      Map<String, dynamic> data = {
        'program_id': programId,
        // البيانات الشخصية
        'personal[full_name]': fullName,
        'personal[civil_id]': civilId,
        'personal[date_of_birth]': dateOfBirthFormatted,
        'personal[phone]': phone,
        'personal[address]': address,
        'personal[marital_status]': maritalStatus,
        if (email != null && email.isNotEmpty) 'personal[email]': email,
        // البيانات الأكاديمية
        'academic[institution]': institution,
        'academic[student_id]': studentId,
        if (college != null && college.isNotEmpty) 'academic[college]': college,
        if (major != null && major.isNotEmpty) 'academic[major]': major,
        if (program != null && program.isNotEmpty) 'academic[program]': program,
        if (academicYear != null) 'academic[academic_year]': academicYear,
        if (gpa != null) 'academic[gpa]': gpa,
        // بيانات ولي الأمر
        'guardian[name]': guardianName,
        'guardian[job]': guardianJob,
        'guardian[monthly_income]': guardianMonthlyIncome,
        'guardian[family_size]': guardianFamilySize,
        'guardian[is_father_alive]': isFatherAlive ? '1' : '0',
        'guardian[is_mother_alive]': isMotherAlive ? '1' : '0',
        'guardian[parents_marital_status]': parentsMaritalStatus,
      };

      _log('API Data being sent (form-data format):');
      data.forEach((key, value) {
        _log('$key: $value');
      });

      FormData formData = FormData.fromMap(data);
      
      // إضافة المرفقات إذا وجدت
      if (documentFiles != null) {
        for (var entry in documentFiles.entries) {
          String fieldName = 'documents[${entry.key}]';
          String extension = _getFileExtension(entry.value);
          formData.files.add(MapEntry(
            fieldName,
            MultipartFile.fromBytes(
              entry.value,
              filename: '${entry.key}.$extension',
            ),
          ));
          _log('Adding document: $fieldName');
        }
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

  /// دالة قديمة للتوافق مع الكود السابق
  @Deprecated('Use submitStudentRegistration with new parameters instead')
  Future<Map<String, dynamic>> submitStudentRegistrationLegacy({
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
      int academicYearNumber = _convertAcademicYearToNumber(academicYear);
      
      Map<String, dynamic> data = {
        'program_id': programId ?? 1,
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

      _log('API Data being sent (legacy format):');
      data.forEach((key, value) {
        _log('$key: $value');
      });

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

  /// GET /api/v1/students/registration - Get all student registrations (for admin)
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

  /// GET /api/v1/students/registration/{id} - Get specific student registration
  Future<Map<String, dynamic>> getStudentRegistrationById(String id) async {
    try {
      final response = await _apiClient.dio.get('/students/registration/$id');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /api/v1/students/registration/{id}/documents - رفع المستندات
  Future<Map<String, dynamic>> uploadStudentDocuments({
    required String registrationId,
    Map<String, Uint8List>? documentFiles,
  }) async {
    try {
      FormData formData = FormData();

      if (documentFiles != null) {
        for (var entry in documentFiles.entries) {
          String fieldName = entry.key;
          String extension = _getFileExtension(entry.value);
          formData.files.add(MapEntry(
            fieldName,
            MultipartFile.fromBytes(
              entry.value,
              filename: '$fieldName.$extension',
            ),
          ));
          _log('Uploading document: $fieldName');
        }
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

  /// GET /api/v1/students/registration/my-registration - Get current user's registration
  Future<Map<String, dynamic>?> getCurrentUserRegistration() async {
    print('═══════════════════════════════════════════════════════════');
    print('🌐 [getCurrentUserRegistration] Starting...');
    print('═══════════════════════════════════════════════════════════');
    
    try {
      _log('Calling API: GET /api/v1/students/registration/my-registration');
      print('📡 [getCurrentUserRegistration] Making API call to: /students/registration/my-registration');
      
      final response = await _apiClient.dio.get('/students/registration/my-registration');
      
      print('✅ [getCurrentUserRegistration] API call successful');
      print('📊 [getCurrentUserRegistration] Response status code: ${response.statusCode}');
      print('📊 [getCurrentUserRegistration] Response data type: ${response.data.runtimeType}');
      print('📊 [getCurrentUserRegistration] Raw response data: ${response.data}');
      
      _log('API Response: ${response.data}');
      
      if (response.data is Map) {
        _log('Response data keys: ${(response.data as Map).keys}');
        print('📋 [getCurrentUserRegistration] Response keys: ${(response.data as Map).keys.toList()}');
      }
      
      Map<String, dynamic> registrationData;
      
      if (response.data is Map && response.data['data'] != null) {
        _log('Returning data from response.data[\'data\']');
        print('✅ [getCurrentUserRegistration] Found data in response.data[\'data\']');
        registrationData = Map<String, dynamic>.from(response.data['data']);
        print('📦 [getCurrentUserRegistration] Extracted data: $registrationData');
      } else {
        _log('Returning full response.data');
        print('✅ [getCurrentUserRegistration] Using full response.data');
        registrationData = Map<String, dynamic>.from(response.data);
        print('📦 [getCurrentUserRegistration] Full data: $registrationData');
      }
      
      print('📋 [getCurrentUserRegistration] Processing registration data...');
      print('📋 [getCurrentUserRegistration] Registration data keys: ${registrationData.keys.toList()}');
      
      // Normalize status
      if (registrationData.containsKey('status')) {
        String status = registrationData['status']?.toString().toLowerCase() ?? 'under_review';
        print('📊 [getCurrentUserRegistration] Original status: "${registrationData['status']}"');
        print('📊 [getCurrentUserRegistration] Normalized status: "$status"');
        
        switch (status) {
          case 'under_review':
          case 'قيد المراجعة':
            registrationData['status'] = 'under_review';
            print('   ✅ Status normalized to: under_review');
            break;
          case 'accepted':
          case 'مقبول':
            registrationData['status'] = 'accepted';
            print('   ✅ Status normalized to: accepted');
            break;
          case 'rejected':
          case 'مرفوض':
            registrationData['status'] = 'rejected';
            print('   ✅ Status normalized to: rejected');
            break;
          case 'completed':
          case 'مكتمل':
            registrationData['status'] = 'completed';
            print('   ✅ Status normalized to: completed');
            break;
          default:
            print('   ⚠️ Unknown status: $status, defaulting to: under_review');
            registrationData['status'] = 'under_review';
        }
      } else {
        print('   ⚠️ Status key not found, setting default: under_review');
        registrationData['status'] = 'under_review';
      }
      
      // Handle rejection reason
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
      
      print('✅ [getCurrentUserRegistration] Processing complete');
      print('📋 [getCurrentUserRegistration] Final registration data:');
      registrationData.forEach((key, value) {
        print('   - $key: $value');
      });
      print('📋 [getCurrentUserRegistration] Final status: ${registrationData['status']}');
      print('═══════════════════════════════════════════════════════════');
      
      return registrationData;
    } on DioException catch (e) {
      print('❌ [getCurrentUserRegistration] DioException occurred');
      print('❌ [getCurrentUserRegistration] Error message: ${e.message}');
      print('❌ [getCurrentUserRegistration] Response status: ${e.response?.statusCode}');
      print('❌ [getCurrentUserRegistration] Response data: ${e.response?.data}');
      print('❌ [getCurrentUserRegistration] Request path: ${e.requestOptions.path}');
      
      _log('DioException in getCurrentUserRegistration: ${e.message}');
      _log('Response status: ${e.response?.statusCode}');
      _log('Response data: ${e.response?.data}');
      
      if (e.response?.statusCode == 404) {
        print('⚠️ [getCurrentUserRegistration] 404 - No registration found for current user');
        print('⚠️ [getCurrentUserRegistration] Returning null');
        _log('No registration found for current user (404)');
        print('═══════════════════════════════════════════════════════════');
        return null;
      }
      
      if (e.response?.statusCode == 500) {
        print('⚠️ [getCurrentUserRegistration] 500 - Server error');
        print('⚠️ [getCurrentUserRegistration] This is a backend issue that needs to be fixed');
        print('⚠️ [getCurrentUserRegistration] Returning null to prevent app crash');
        _log('Server error (500) in getCurrentUserRegistration - returning null');
        print('═══════════════════════════════════════════════════════════');
        return null;
      }
      
      print('❌ [getCurrentUserRegistration] Throwing error...');
      print('═══════════════════════════════════════════════════════════');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ [getCurrentUserRegistration] Unexpected error: $e');
      print('═══════════════════════════════════════════════════════════');
      return null;
    }
  }

  /// PUT /api/v1/students/registration/{id} - تحديث طلب مرفوض
  Future<Map<String, dynamic>> updateStudentRegistration({
    required String registrationId,
    required Map<String, dynamic> data,
    Map<String, Uint8List>? documentFiles,
  }) async {
    try {
      FormData formData = FormData.fromMap(data);
      
      if (documentFiles != null) {
        for (var entry in documentFiles.entries) {
          String fieldName = 'documents[${entry.key}]';
          String extension = _getFileExtension(entry.value);
          formData.files.add(MapEntry(
            fieldName,
            MultipartFile.fromBytes(
              entry.value,
              filename: '${entry.key}.$extension',
            ),
          ));
        }
      }

      final response = await _apiClient.dio.put(
        '/students/registration/$registrationId',
        data: formData,
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE /api/v1/students/registration/{id} - Delete student registration
  Future<void> deleteStudentRegistration(String registrationId) async {
    try {
      await _apiClient.dio.delete('/students/registration/$registrationId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Helper method to get localized program name
  static String getLocalizedProgramName(Map<String, dynamic> program, String locale) {
    if (locale == 'ar') {
      return program['title_ar']?.isNotEmpty == true ? program['title_ar'] : (program['name'] ?? '');
    } else {
      return program['title_en']?.isNotEmpty == true ? program['title_en'] : (program['name'] ?? '');
    }
  }

  /// GET /api/v1/programs - Get all support programs
  Future<List<Map<String, dynamic>>> getSupportPrograms() async {
    try {
      _log('Calling API: /programs');
      final response = await _apiClient.dio.get('/programs');
      
      _log('API Response for programs: ${response.data}');
      _log('Response data type: ${response.data.runtimeType}');
      _log('Response status code: ${response.statusCode}');
      
      List<Map<String, dynamic>> programs = [];
      
      if (response.data['data'] != null) {
        final data = response.data['data'];
        _log('Data field found: $data');
        _log('Data type: ${data.runtimeType}');
        
        if (data is List) {
          programs = List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          programs = [Map<String, dynamic>.from(data)];
        }
      } else if (response.data is List) {
        programs = List<Map<String, dynamic>>.from(response.data);
        _log('Direct list response: $programs');
      } else if (response.data is Map) {
        programs = [Map<String, dynamic>.from(response.data)];
        _log('Single object response: $programs');
      }
      
      _log('Raw programs data: $programs');
      _log('Programs count: ${programs.length}');
      
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
      
      final validPrograms = programs.where((program) {
        final hasId = program['id'] != null;
        final hasTitleAr = program['title_ar'] != null;
        final hasTitleEn = program['title_en'] != null;
        final hasTitle = program['title'] != null;
        final hasName = program['name'] != null;
        
        final isValid = hasId && (hasTitleAr || hasTitleEn || hasTitle || hasName);
        
        _log('Program validation: id=$hasId, title_ar=$hasTitleAr, title_en=$hasTitleEn, title=$hasTitle, name=$hasName, valid=$isValid');
        
        return isValid;
      }).map((program) {
        final titleAr = program['title_ar'] ?? program['title'] ?? program['name'] ?? 'برنامج غير محدد';
        final titleEn = program['title_en'] ?? program['title'] ?? program['name'] ?? 'Undefined Program';
        
        return {
          'id': program['id'],
          'name': titleAr,
          'title_ar': titleAr,
          'title_en': titleEn,
          'description': program['description_ar'] ?? program['description'] ?? '',
          'description_ar': program['description_ar'] ?? program['description'] ?? '',
          'description_en': program['description_en'] ?? program['description'] ?? '',
          'status': program['status'] ?? 'active',
          'image': program['image'] ?? '',
          'category': program['category'] ?? {},
          'original_data': program,
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

  // Helper: تحديد نوع الملف من البايتات
  String _getFileExtension(Uint8List bytes) {
    // Check for PDF signature
    if (bytes.length >= 4 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) {
      return 'pdf';
    }
    // Check for PNG signature
    if (bytes.length >= 8 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'png';
    }
    // Check for JPEG signature
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'jpg';
    }
    // Default to jpg
    return 'jpg';
  }

  // Helper: تحويل السنة الأكاديمية لرقم
  int _convertAcademicYearToNumber(String academicYear) {
    switch (academicYear.toLowerCase()) {
      case 'first_year':
      case 'السنة الأولى':
        return 1;
      case 'second_year':
      case 'السنة الثانية':
        return 2;
      case 'third_year':
      case 'السنة الثالثة':
        return 3;
      case 'fourth_year':
      case 'السنة الرابعة':
        return 4;
      case 'fifth_year':
      case 'السنة الخامسة':
        return 5;
      case 'sixth_year':
      case 'السنة السادسة':
        return 6;
      default:
        return int.tryParse(academicYear) ?? 1;
    }
  }

  // Helper: تحويل مستوى الدخل للإنجليزية
  String _convertIncomeLevelToEnglish(String incomeLevel) {
    switch (incomeLevel.toLowerCase()) {
      case 'منخفض':
      case 'low':
        return 'low';
      case 'متوسط':
      case 'medium':
        return 'medium';
      case 'مرتفع':
      case 'high':
        return 'high';
      default:
        return 'medium';
    }
  }

  // Handle Dio errors
  String _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        // Handle Laravel validation errors
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          List<String> errorMessages = [];
          errors.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              errorMessages.add(value.first.toString());
            }
          });
          if (errorMessages.isNotEmpty) {
            return errorMessages.join('\n');
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

/// أنواع المستندات المتاحة للرفع
class DocumentType {
  static const String applicationLetter = 'application_letter';
  static const String idCard = 'id_card';
  static const String enrollmentLetter = 'enrollment_letter';
  static const String tuitionLetter = 'tuition_letter';
  static const String incomeProof = 'income_proof';
  static const String bankStatements = 'bank_statements';
  static const String debtProof = 'debt_proof';
  static const String supportingDocuments = 'supporting_documents';
  static const String housingLetter = 'housing_letter';

  static const List<String> all = [
    applicationLetter,
    idCard,
    enrollmentLetter,
    tuitionLetter,
    incomeProof,
    bankStatements,
    debtProof,
    supportingDocuments,
    housingLetter,
  ];

  static String getArabicLabel(String type) {
    switch (type) {
      case applicationLetter:
        return 'رسالة تقديم الطلب';
      case idCard:
        return 'صورة البطاقة الشخصية';
      case enrollmentLetter:
        return 'رسالة الانتظام';
      case tuitionLetter:
        return 'رسالة الرسوم الدراسية';
      case incomeProof:
        return 'إثبات الدخل';
      case bankStatements:
        return 'كشف حساب البنك';
      case debtProof:
        return 'إثبات المديونية';
      case supportingDocuments:
        return 'المستندات الداعمة';
      case housingLetter:
        return 'رسالة رسوم السكن';
      default:
        return type;
    }
  }

  static String getEnglishLabel(String type) {
    switch (type) {
      case applicationLetter:
        return 'Application Letter';
      case idCard:
        return 'ID Card';
      case enrollmentLetter:
        return 'Enrollment Letter';
      case tuitionLetter:
        return 'Tuition Letter';
      case incomeProof:
        return 'Income Proof';
      case bankStatements:
        return 'Bank Statements';
      case debtProof:
        return 'Debt Proof';
      case supportingDocuments:
        return 'Supporting Documents';
      case housingLetter:
        return 'Housing Letter';
      default:
        return type;
    }
  }

  static String getDescription(String type) {
    switch (type) {
      case applicationLetter:
        return 'رسالة موجهة لإدارة الصندوق';
      case idCard:
        return 'صورة البطاقة الشخصية لصاحب الطلب';
      case enrollmentLetter:
        return 'رسالة انتظام الطالب بالدراسة';
      case tuitionLetter:
        return 'رسالة بالرسوم ومدة الدراسة';
      case incomeProof:
        return 'إثبات الدخل الشهري للعائلة';
      case bankStatements:
        return 'كشف حساب 6 أشهر للعاملين';
      case debtProof:
        return 'إثبات المديونية';
      case supportingDocuments:
        return 'عقد زواج/شهادة وفاة/ملكية/إيجار/حكم سجن';
      case housingLetter:
        return 'رسالة رسوم السكن لفصل واحد';
      default:
        return '';
    }
  }
}
