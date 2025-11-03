// donation_service.dart
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;

import '../models/payment_request.dart';
import '../models/payment_response.dart' hide PaymentStatusResponse;
import '../models/payment_status_response.dart';
import '../models/donation.dart';
import 'api_client.dart';

class DonationService {
  static final DonationService _instance = DonationService._internal();
  factory DonationService() => _instance;
  DonationService._internal();

  final ApiClient _apiClient = ApiClient();
  
  // Getter to access ApiClient from outside
  ApiClient get apiClient => _apiClient;

  // ===== Base URL (محلي) =====
  // Android Emulator يصل لمضيف جهازك بـ 10.0.2.2
  // iOS Simulator غالباً يقدر على localhost
  // الأجهزة الفعلية استخدمي IP الشبكة (مثال: 192.168.1.100)
  static String _resolveFallbackBase() {
    try {
      if (Platform.isAndroid) return 'http://localhost:8000/api/v1';
      if (Platform.isIOS) return 'http://localhost:8000/api/v1';
    } catch (_) {}
    // Fallback عام (غيّريه لعنوان جهازك على الشبكة)
    return 'http://localhost:8000/api/v1';
  }

  String get _apiBase {
    // لو ApiClient مهيّأ بقاعدة مخصّصة نستخدمها؛ غير كذا نستخدم المحلي أعلاه
    try {
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      final dynamic maybe = (_apiClient as dynamic);
      final dynamic v = maybe.baseUrl;
      if (v is String && v.isNotEmpty) {
        final base = v.replaceAll(RegExp(r'/+$'), '');
        return base.endsWith('/v1') ? base : '$base/v1';
      }
    } catch (_) {}
    return _resolveFallbackBase();
  }

  // ===== ENDPOINT 1: Create donation with direct payment =====
  /// POST /api/v1/donations/with-payment
  Future<Map<String, dynamic>> createDonationWithPayment({
    required String itemId,   // '123' → سيحوَّل إلى int
    required String itemType, // 'program' | 'campaign'
    required double amount,   // OMR
    String? donorName,
    String? donorEmail,
    String? donorPhone,
    String? message,          // سنرسلها كـ note أيضًا
    bool isAnonymous = false,
    String? returnOrigin,     // origin للمنصة الويب
  }) async {
    try {
      await _apiClient.initialize();
      final token = await _apiClient.getAuthToken();

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      // إضافة token فقط إذا كان موجوداً (للمستخدمين المسجلين)
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        print('DonationService: Using authenticated request with token');
      } else {
        print('DonationService: Using anonymous donation request');
      }

      final idInt = int.tryParse(itemId);
      if (idInt == null) {
        throw Exception('رقم المعرف غير صالح: $itemId');
      }

      final payload = <String, dynamic>{
        if (itemType == 'program') 'program_id': idInt,
        if (itemType == 'campaign') 'campaign_id': idInt,
        'amount': amount, // هذا الإندبوينت عندك يستقبل المبلغ كريال
        'is_anonymous': isAnonymous,
        if (donorName != null) 'donor_name': donorName,
        if (donorEmail != null) 'donor_email': donorEmail,
        if (donorPhone != null) 'donor_phone': donorPhone,
        if (message != null) 'note': message,
        if (message != null) 'message': message, // توافق خلفي إن وُجد
        if (returnOrigin != null) 'return_origin': returnOrigin,
      };

      final uri = Uri.parse('${_apiBase.replaceAll(RegExp(r"/+$"), "")}/donations/with-payment');
      // Debug:
      print('DonationService: Creating donation with payment...');
      print('DonationService: Request URL: $uri');
      print('DonationService: Request headers: $headers');
      print('DonationService: Request payload: $payload');
      
      final response = await http.post(uri, headers: headers, body: jsonEncode(payload));
      
      print('DonationService: Response status: ${response.statusCode}');
      print('DonationService: Response headers: ${response.headers}');
      print('DonationService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        final Map<String, dynamic>? data =
            (responseData['data'] is Map) ? responseData['data'] as Map<String, dynamic> : null;
        final Map<String, dynamic>? ps =
            (data?['payment_session'] is Map) ? data!['payment_session'] as Map<String, dynamic> : null;

        final String? paymentUrl =
            (ps?['payment_url'] ?? ps?['redirect_url'] ?? responseData['payment_url'] ?? data?['payment_url'])
                ?.toString();

        final String? sessionId =
            (ps?['session_id'] ?? responseData['session_id'] ?? data?['session_id'])?.toString();

        // نعيد جسم موحّد يفيد الـ UI
        final result = <String, dynamic>{
          'ok': true,
          'data': data ?? responseData,
          if (paymentUrl != null) 'payment_url': paymentUrl,
          if (sessionId != null) 'payment_session_id': sessionId,
        };
        return result;
      } else if (response.statusCode == 401) {
        throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.');
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final errorMessage = (errorData['message']?.toString()) ?? 'بيانات غير صحيحة';
        throw Exception(errorMessage);
      } else {
        throw Exception('حدث خطأ في إنشاء التبرع. يرجى المحاولة مرة أخرى.');
      }
    } catch (e, stackTrace) {
      print('DonationService: Error creating donation with payment: $e');
      print('DonationService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ===== ENDPOINT 2: Anonymous donation with payment =====
  /// POST /api/v1/donations/anonymous-with-payment
  /// **مخصص للمستخدمين غير المسجلين**: ينشئ تبرع مجهول مع دفع فوري
  Future<Map<String, dynamic>> createAnonymousDonationWithPayment({
    required String itemId,   // '123' → سيحوَّل إلى int
    required String itemType, // 'program' | 'campaign'
    required double amount,   // OMR
    String? donorName,
    String? donorEmail,
    String? donorPhone,
    String? message,          // سنرسلها كـ note أيضًا
    String? returnOrigin,     // origin للمنصة الويب
  }) async {
    try {
      // للتبرعات المجهولة، لا نحتاج token على الإطلاق
      print('DonationService: Creating anonymous donation with payment...');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final idInt = int.tryParse(itemId);
      if (idInt == null) {
        throw Exception('رقم المعرف غير صالح: $itemId');
      }

      final payload = <String, dynamic>{
        if (itemType == 'program') 'program_id': idInt,
        if (itemType == 'campaign') 'campaign_id': idInt,
        'amount': amount,
        'is_anonymous': true, // دائماً true للتبرعات المجهولة
        'donor_name': donorName ?? 'متبرع',
        if (donorEmail != null) 'donor_email': donorEmail,
        if (donorPhone != null) 'donor_phone': donorPhone,
        if (message != null) 'note': message,
        if (message != null) 'message': message, // توافق خلفي إن وُجد
        if (returnOrigin != null) 'return_origin': returnOrigin,
      };

      final uri = Uri.parse('${_apiBase.replaceAll(RegExp(r"/+$"), "")}/donations/anonymous-with-payment');
      final response = await http.post(uri, headers: headers, body: jsonEncode(payload));

      // Debug:
      print('DonationService: Anonymous donation request URL: $uri');
      print('DonationService: Anonymous donation payload: $payload');
      print('DonationService: Anonymous donation response status: ${response.statusCode}');
      print('DonationService: Anonymous donation response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        final Map<String, dynamic>? data =
            (responseData['data'] is Map) ? responseData['data'] as Map<String, dynamic> : null;
        final Map<String, dynamic>? ps =
            (data?['payment_session'] is Map) ? data!['payment_session'] as Map<String, dynamic> : null;

        final String? paymentUrl =
            (ps?['payment_url'] ?? ps?['redirect_url'] ?? responseData['payment_url'] ?? data?['payment_url'])
                ?.toString();

        final String? sessionId =
            (ps?['session_id'] ?? responseData['session_id'] ?? data?['session_id'])?.toString();

        // نعيد جسم موحّد يفيد الـ UI
        final result = <String, dynamic>{
          'ok': true,
          'data': data ?? responseData,
          if (paymentUrl != null) 'payment_url': paymentUrl,
          if (sessionId != null) 'payment_session_id': sessionId,
        };
        return result;
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final errorMessage = (errorData['message']?.toString()) ?? 'بيانات غير صحيحة';
        throw Exception(errorMessage);
      } else {
        throw Exception('حدث خطأ في إنشاء التبرع المجهول. يرجى المحاولة مرة أخرى.');
      }
    } catch (e) {
      print('DonationService: Error creating anonymous donation: $e');
      rethrow;
    }
  }

  // ===== ENDPOINT 3: Create payment session (منفصل) =====
  /// POST /api/v1/payments/create
  /// **ملاحظة**: لا نستخدم returnUrl هنا — النجاح/الإلغاء يُدار من الباكند.
  Future<PaymentResponse> createPaymentSessionV2({
    required double amountOmr,
    String? clientReferenceId,
    int? programId,
    int? campaignId,
    String? donorName,
    String? note,
    String type = 'quick',     // quick | gift
    String? productName,       // اسم يظهر في ثواني
    String? returnOrigin,      // origin للمنصة الويب
  }) async {
    try {
      await _apiClient.initialize();
      final token = await _apiClient.getAuthToken();

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      // إضافة token فقط إذا كان موجوداً (للمستخدمين المسجلين)
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        print('DonationService: Using authenticated payment request with token');
      } else {
        print('DonationService: Using anonymous payment request');
      }

      final req = PaymentRequest(
        amountOmr: amountOmr,                 // سيتحوّل داخليًا إلى بيسة
        clientReferenceId: clientReferenceId, // اختياري
        programId: programId,
        campaignId: campaignId,
        donorName: donorName,
        note: note,
        type: type,
        productName: productName ?? 'تبرع',
        returnOrigin: returnOrigin,
      );

      final uri = Uri.parse('${_apiBase.replaceAll(RegExp(r"/+$"), "")}/payments/create');
      final response = await http.post(uri, headers: headers, body: jsonEncode(req.toJson()));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return PaymentResponse.fromJson(responseData);
      } else if (response.statusCode == 401) {
        return PaymentResponse.error('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.');
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = (errorData['message']?.toString()) ?? 'بيانات غير صحيحة';
        return PaymentResponse.error(errorMessage);
      } else {
        return PaymentResponse.error('حدث خطأ في إنشاء جلسة الدفع. يرجى المحاولة مرة أخرى.');
      }
    } catch (e) {
      return PaymentResponse.error('حدث خطأ في الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.');
    }
  }

  /// **توافق خلفي** — النسخة القديمة
  Future<PaymentResponse> createPaymentSession({
    required double amount,
    required String clientReferenceId,
    required String returnUrl, // غير مستخدم الآن
    String? donorName,
    String? donorEmail,
    String? donorPhone,
    String? message,
    String? itemId,
    String? itemType,
    int? programId,
    int? campaignId,
    String? note,
    String type = 'quick',
  }) {
    return createPaymentSessionV2(
      amountOmr: amount,
      clientReferenceId: clientReferenceId,
      programId: programId ?? (itemType == 'program' ? int.tryParse(itemId ?? '') : null),
      campaignId: campaignId ?? (itemType == 'campaign' ? int.tryParse(itemId ?? '') : null),
      donorName: donorName,
      note: note ?? message,
      type: type,
      productName: message ?? 'تبرع',
    );
  }

  // ===== ENDPOINT 3: Check payment status =====
  /// GET /api/v1/payments/status/{sessionId}
  Future<PaymentStatusResponse> checkPaymentStatus(String sessionId) async {
    try {
      await _apiClient.initialize();
      final token = await _apiClient.getAuthToken();

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final uri = Uri.parse('${_apiBase.replaceAll(RegExp(r"/+$"), "")}/payments/status/$sessionId');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return PaymentStatusResponse.fromJson(responseData);
      } else if (response.statusCode == 401) {
        return PaymentStatusResponse.error('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.');
      } else if (response.statusCode == 404) {
        return PaymentStatusResponse.error('لم يتم العثور على جلسة الدفع.');
      } else {
        return PaymentStatusResponse.error('حدث خطأ في التحقق من حالة الدفع. يرجى المحاولة مرة أخرى.');
      }
    } catch (e) {
      return PaymentStatusResponse.error('حدث خطأ في الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.');
    }
  }

  // ===== ENDPOINT 4: Get recent donations =====
  /// GET /api/v1/donations/recent?limit=5
  /// Get the last 5 donations from the API
  Future<List<Donation>> getRecentDonations({int limit = 5}) async {
    try {
      await _apiClient.initialize();
      final token = await _apiClient.getAuthToken();

      print('DonationService: Getting recent donations with limit: $limit');
      print('DonationService: Token exists: ${token != null}');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null) headers['Authorization'] = 'Bearer $token';

      // Build query parameters
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      
      final uri = Uri.parse('${_apiBase.replaceAll(RegExp(r"/+$"), "")}/donations/recent')
          .replace(queryParameters: queryParams);
      print('DonationService: Fetching recent donations from: $uri');
      
      final response = await http.get(uri, headers: headers);
      print('DonationService: Response status: ${response.statusCode}');
      print('DonationService: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final donations = _parseDonationsResponse(response.body);
        print('DonationService: Successfully parsed ${donations.length} recent donations');
        return donations;
      } else if (response.statusCode == 401) {
        print('DonationService: Unauthorized - user not authenticated');
        return []; // Return empty list for unauthenticated users
      } else if (response.statusCode == 404) {
        print('DonationService: Recent donations endpoint not found');
        return []; // Return empty list if endpoint doesn't exist
      } else {
        print('DonationService: Error fetching recent donations: HTTP ${response.statusCode}');
        print('DonationService: Error response: ${response.body}');
        return []; // Return empty list on error
      }
    } catch (e) {
      print('DonationService: Error fetching recent donations: $e');
      return []; // Return empty list on error
    }
  }

  // ===== ENDPOINT 5: Get user donations =====
  /// Try multiple possible endpoints to get user donations
  /// 1. GET /api/v1/donations/recent (most likely to work)
  /// 2. GET /api/v1/me/donations (if exists)
  /// 3. GET /api/v1/donations (if exists)
  Future<List<Donation>> getUserDonations({
    int? page,
    int? limit,
    bool getAllDonations = false,
  }) async {
    try {
      await _apiClient.initialize();
      final token = await _apiClient.getAuthToken();

      print('DonationService: Token exists: ${token != null}');
      print('DonationService: API Base: $_apiBase');
      if (token != null) {
        print('DonationService: Token preview: ${token.substring(0, 20)}...');
      }

      if (token == null || token.isEmpty) {
        print('DonationService: No auth token found, returning empty donations list');
        return []; // إرجاع قائمة فارغة بدلاً من خطأ
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // If getAllDonations is true, fetch all donations with pagination
      if (getAllDonations) {
        return await _getAllDonationsWithPagination(headers);
      }

      // Try multiple endpoints in order of likelihood
      final endpoints = [
        '/me/donations',  // Try user-specific donations first
        '/donations/recent', 
        '/donations',
      ];
      
      for (final endpoint in endpoints) {
        try {
          // Build query parameters for pagination
          final queryParams = <String, String>{};
          if (page != null) queryParams['page'] = page.toString();
          if (limit != null) queryParams['limit'] = limit.toString();
          
          final uri = Uri.parse('${_apiBase.replaceAll(RegExp(r"/+$"), "")}$endpoint')
              .replace(queryParameters: queryParams);
          print('DonationService: Trying endpoint: $uri');
          
          final response = await http.get(uri, headers: headers);
          print('DonationService: Response status: ${response.statusCode}');
          print('DonationService: Response body: ${response.body}');
          
          if (response.statusCode == 200) {
            final donations = _parseDonationsResponse(response.body);
            print('DonationService: Successfully parsed ${donations.length} donations from $endpoint');
            return donations;
          } else if (response.statusCode == 404) {
            print('DonationService: Endpoint $endpoint not found, trying next...');
            continue;
          } else {
            // For other errors, throw the error
            print('DonationService: Error with endpoint $endpoint: HTTP ${response.statusCode}');
            print('DonationService: Error response: ${response.body}');
            throw Exception('HTTP ${response.statusCode}: ${response.body}');
          }
        } catch (e) {
          print('DonationService: Error with endpoint $endpoint: $e');
          if (endpoint == endpoints.last) {
            rethrow; // If this is the last endpoint, rethrow the error
          }
          continue; // Try next endpoint
        }
      }
      
      throw Exception('جميع endpoints التبرعات غير متاحة');
    } catch (e) {
      print('DonationService: Error fetching user donations: $e');
      rethrow;
    }
  }

  // Helper method to get all donations with pagination
  Future<List<Donation>> _getAllDonationsWithPagination(Map<String, String> headers) async {
    List<Donation> allDonations = [];
    int currentPage = 1;
    int limit = 50; // Fetch 50 donations per page
    bool hasMoreData = true;
    
    print('DonationService: Starting to fetch all donations with pagination...');
    
    // Try multiple endpoints in order of likelihood
    final endpoints = [
      '/me/donations',  // Try user-specific donations first
      '/donations/recent', 
      '/donations',
    ];
    
    for (final endpoint in endpoints) {
      try {
        print('DonationService: Trying endpoint $endpoint for pagination...');
        
        while (hasMoreData) {
          final queryParams = <String, String>{
            'page': currentPage.toString(),
            'limit': limit.toString(),
          };
          
          final uri = Uri.parse('${_apiBase.replaceAll(RegExp(r"/+$"), "")}$endpoint')
              .replace(queryParameters: queryParams);
          print('DonationService: Fetching page $currentPage from: $uri');
          
          final response = await http.get(uri, headers: headers);
          print('DonationService: Response status: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            final pageDonations = _parseDonationsResponse(response.body);
            
            if (pageDonations.isEmpty) {
              print('DonationService: No more donations on page $currentPage, stopping pagination');
              hasMoreData = false;
            } else {
              allDonations.addAll(pageDonations);
              print('DonationService: Added ${pageDonations.length} donations from page $currentPage. Total: ${allDonations.length}');
              
              // Check if we got less than the limit, which means this is the last page
              if (pageDonations.length < limit) {
                print('DonationService: Got ${pageDonations.length} donations (less than limit $limit), this is the last page');
                hasMoreData = false;
              } else {
                currentPage++;
              }
            }
          } else if (response.statusCode == 404) {
            print('DonationService: Endpoint $endpoint not found, trying next...');
            break; // Try next endpoint
          } else {
            print('DonationService: Error with endpoint $endpoint: HTTP ${response.statusCode}');
            throw Exception('HTTP ${response.statusCode}: ${response.body}');
          }
        }
        
        // If we successfully fetched donations from this endpoint, return them
        if (allDonations.isNotEmpty) {
          print('DonationService: Successfully fetched ${allDonations.length} total donations from $endpoint');
          return allDonations;
        }
        
      } catch (e) {
        print('DonationService: Error with endpoint $endpoint: $e');
        if (endpoint == endpoints.last) {
          rethrow; // If this is the last endpoint, rethrow the error
        }
        // Reset for next endpoint
        allDonations.clear();
        currentPage = 1;
        hasMoreData = true;
        continue; // Try next endpoint
      }
    }
    
    throw Exception('جميع endpoints التبرعات غير متاحة');
  }

  // Helper method to parse donations response
  List<Donation> _parseDonationsResponse(String responseBody) {
    try {
      print('DonationService: Parsing response body: $responseBody');
      final responseData = jsonDecode(responseBody) as Map<String, dynamic>;
      print('DonationService: Parsed response data keys: ${responseData.keys}');
      
      // Handle different response structures
      List<dynamic> donationsData = [];
      if (responseData['data'] is List) {
        donationsData = responseData['data'] as List<dynamic>;
        print('DonationService: Found ${donationsData.length} donations in "data" field');
      } else if (responseData['donations'] is List) {
        donationsData = responseData['donations'] as List<dynamic>;
        print('DonationService: Found ${donationsData.length} donations in "donations" field');
      } else if (responseData is List) {
        donationsData = responseData as List<dynamic>;
        print('DonationService: Found ${donationsData.length} donations in root array');
      } else {
        print('DonationService: No donations array found in response');
        print('DonationService: Available fields: ${responseData.keys}');
      }

      final donations = donationsData
          .map((donationJson) {
            print('DonationService: Parsing donation: $donationJson');
            return Donation.fromJson(donationJson as Map<String, dynamic>);
          })
          .toList();
          
      print('DonationService: Successfully created ${donations.length} Donation objects');
      return donations;
    } catch (e) {
      print('DonationService: Error parsing donations response: $e');
      print('DonationService: Response body was: $responseBody');
      return [];
    }
  }

  // ===== ENDPOINT 5: Get all user donations with pagination =====
  /// Get all user donations by fetching all pages
  Future<List<Donation>> getAllUserDonations() async {
    return await getUserDonations(getAllDonations: true);
  }

  // ===== ENDPOINT 6: Get paid donations only =====
  /// Try to get paid donations by filtering recent donations
  /// Since /me/donations?status=paid may not exist, we'll get all donations and filter
  Future<List<Donation>> getPaidDonations() async {
    try {
      // Get all donations first
      final allDonations = await getUserDonations();
      
      // Filter for paid donations
      final paidDonations = allDonations.where((donation) => 
        donation.isPaid || donation.isCompleted
      ).toList();
      
      print('DonationService: Found ${paidDonations.length} paid donations out of ${allDonations.length} total');
      return paidDonations;
    } catch (e) {
      print('DonationService: Error fetching paid donations: $e');
      rethrow;
    }
  }

  // ===== DEBUG: Test all endpoints =====
  /// Test all possible donation endpoints to see which ones work
  Future<void> testAllEndpoints() async {
    try {
      await _apiClient.initialize();
      final token = await _apiClient.getAuthToken();

      if (token == null) {
        print('DonationService: No token available for testing');
        return;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final endpoints = [
        '/me/donations',
        '/donations/recent',
        '/donations',
        '/user/donations',
        '/my-donations',
      ];

      print('DonationService: Testing all endpoints...');
      
      for (final endpoint in endpoints) {
        try {
          final uri = Uri.parse('${_apiBase.replaceAll(RegExp(r"/+$"), "")}$endpoint');
          print('\n=== Testing: $endpoint ===');
          print('URL: $uri');
          
          final response = await http.get(uri, headers: headers);
          print('Status: ${response.statusCode}');
          print('Response: ${response.body}');
          
          if (response.statusCode == 200) {
            print('✅ SUCCESS: $endpoint works!');
          } else if (response.statusCode == 404) {
            print('❌ NOT FOUND: $endpoint');
          } else {
            print('⚠️ ERROR: $endpoint - ${response.statusCode}');
          }
        } catch (e) {
          print('❌ EXCEPTION: $endpoint - $e');
        }
      }
    } catch (e) {
      print('DonationService: Error testing endpoints: $e');
    }
  }

  // ===== DEBUG: Check donation status =====
  /// Check if a specific donation exists and its status
  Future<Map<String, dynamic>?> checkDonationStatus(String donationId) async {
    try {
      await _apiClient.initialize();
      final token = await _apiClient.getAuthToken();

      if (token == null) {
        print('DonationService: No token available for checking donation status');
        return null;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Try to get the donation by ID
      final uri = Uri.parse('${_apiBase.replaceAll(RegExp(r"/+$"), "")}/donations/$donationId');
      print('DonationService: Checking donation status: $uri');
      
      final response = await http.get(uri, headers: headers);
      print('DonationService: Donation status response: ${response.statusCode}');
      print('DonationService: Donation status body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('DonationService: Failed to get donation status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('DonationService: Error checking donation status: $e');
      return null;
    }
  }

  // ===== Helpers =====
  String generateClientReferenceId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = (ts % 10000).toString().padLeft(4, '0');
    return 'donation_${ts}_$rand';
  }
}
