// donation_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/app_config.dart';
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
  static String _resolveFallbackBase() => AppConfig.apiBaseUrlV1;

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

  /// طباعة مفاتيح الخريطة (ومستوى واحد داخلي) للتشخيص
  static void _debugPrintNestedKeys(String prefix, Map<String, dynamic>? map) {
    if (!kDebugMode || map == null) return;
    debugPrint('$prefix keys: ${map.keys.toList()}');
    for (final entry in map.entries) {
      if (entry.value is Map) {
        debugPrint('$prefix.${entry.key} keys: ${(entry.value as Map).keys.toList()}');
      }
    }
  }

  /// استخراج رابط دفع من أي مكان في الخريطة (لتوافق أشكال الباكند المختلفة)
  static String? _extractPaymentUrlFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    for (final entry in map.entries) {
      final v = entry.value;
      final key = entry.key.toLowerCase();
      if (v is String && v.startsWith('http') && v.length > 10) {
        if (key.contains('url') || key.contains('link') || v.contains('pay') || v.contains('checkout') || v.contains('thawani')) {
          return v;
        }
      }
      if (v is Map) {
        final found = _extractPaymentUrlFromMap(Map<String, dynamic>.from(v));
        if (found != null) return found;
      }
    }
    return null;
  }

  /// استخراج session_id من أي مكان في الخريطة
  static String? _extractSessionIdFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final sid = map['session_id'] ?? map['sessionId'];
    if (sid is String && sid.isNotEmpty) return sid;
    for (final entry in map.entries) {
      if (entry.value is Map) {
        final found = _extractSessionIdFromMap(Map<String, dynamic>.from(entry.value));
        if (found != null) return found;
      }
    }
    return null;
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
        // ⚠️ لا نطبع معلومات المصادقة في الإنتاج
        if (kDebugMode) {
          debugPrint('DonationService: Using authenticated request');
        }
      } else {
        // ⚠️ لا نطبع معلومات الدفع في الإنتاج
        if (kDebugMode) {
          debugPrint('DonationService: Using anonymous donation request');
        }
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
      // ⚠️ لا نطبع معلومات حساسة في الإنتاج (URLs, headers, payloads)
      if (kDebugMode) {
        debugPrint('DonationService: Creating donation with payment');
      }
      
      final response = await http.post(uri, headers: headers, body: jsonEncode(payload));
      
      // ⚠️ لا نطبع تفاصيل الاستجابة في الإنتاج
      if (kDebugMode) {
        debugPrint('DonationService: Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (kDebugMode) {
          debugPrint('DonationService: Response keys: ${responseData.keys.toList()}');
          _debugPrintNestedKeys('DonationService: response', responseData);
        }

        final Map<String, dynamic>? data =
            (responseData['data'] is Map) ? responseData['data'] as Map<String, dynamic> : null;
        final Map<String, dynamic>? ps =
            (data?['payment_session'] is Map) ? data!['payment_session'] as Map<String, dynamic> : null;

        // دعم أشكال متعددة من الباكند: payment_url, checkout_url, redirect_url, url
        String? paymentUrl = (ps?['payment_url'] ?? ps?['redirect_url'] ?? ps?['checkout_url'] ?? ps?['url'] ??
            responseData['payment_url'] ?? responseData['checkout_url'] ?? responseData['redirect_url'] ?? responseData['url'] ??
            data?['payment_url'] ?? data?['checkout_url'] ?? data?['redirect_url'] ?? data?['url'])
            ?.toString();
        if (paymentUrl == null || paymentUrl.isEmpty) {
          paymentUrl = _extractPaymentUrlFromMap(responseData);
        }

        String? sessionId = (ps?['session_id'] ?? responseData['session_id'] ?? data?['session_id'])?.toString();
        if (sessionId == null || sessionId.isEmpty) {
          sessionId = _extractSessionIdFromMap(responseData);
        }

        // استخراج donation_id من الاستجابة
        final Map<String, dynamic>? donation =
            (data?['donation'] is Map) ? data!['donation'] as Map<String, dynamic> : null;
        final String? donationId =
            (donation?['donation_id'] ?? donation?['id'] ?? data?['donation_id'] ?? responseData['donation_id'])?.toString();

        if (kDebugMode && (paymentUrl == null || sessionId == null)) {
          debugPrint('DonationService: Missing from response - paymentUrl: ${paymentUrl != null}, sessionId: ${sessionId != null}, donationId: ${donationId != null}');
          debugPrint('DonationService: data keys: ${data?.keys.toList()}, ps keys: ${ps?.keys.toList()}');
          debugPrint('DonationService: Raw response body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
        }

        // حالة: التبرع أنشئ لكن فشل إنشاء جلسة الدفع (مثلاً خطأ من Thawani)
        final paymentError = data?['payment_error'];
        if ((paymentUrl == null || sessionId == null) && (paymentError != null || (responseData['message']?.toString() ?? '').toLowerCase().contains('payment'))) {
          final backendMessage = responseData['message']?.toString() ?? '';
          if (kDebugMode) {
            debugPrint('═══════════════════════════════════════════════════════════');
            debugPrint('🔴 [فشل الدفع] التبرع أنشئ لكن جلسة الدفع فشلت');
            debugPrint('🔴 message من الباكند: $backendMessage');
            debugPrint('🔴 donation_id: $donationId');
            debugPrint('🔴 payment_error من الباكند: $paymentError');
            if (paymentError is Map) {
              debugPrint('🔴 payment_error (تفاصيل): $paymentError');
            } else if (paymentError is String) {
              debugPrint('🔴 payment_error (نص): $paymentError');
            }
            debugPrint('🔴 استجابة الباكند كاملة (body): ${response.body}');
            debugPrint('═══════════════════════════════════════════════════════════');
          }
          final result = <String, dynamic>{
            'ok': false,
            'data': data ?? responseData,
            'error_message': backendMessage.isNotEmpty ? backendMessage : 'تم إنشاء التبرع لكن تعذر فتح صفحة الدفع. يرجى المحاولة لاحقاً أو التواصل مع الدعم.',
            if (paymentError != null) 'payment_error': paymentError,
            if (donationId != null) 'donation_id': donationId,
          };
          return result;
        }

        // نعيد جسم موحّد يفيد الـ UI
        final result = <String, dynamic>{
          'ok': true,
          'data': data ?? responseData,
          if (paymentUrl != null) 'payment_url': paymentUrl,
          if (sessionId != null) 'payment_session_id': sessionId,
          if (donationId != null) 'donation_id': donationId,
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
      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════════════════════════');
        debugPrint('🔴 [فشل الدفع] خطأ أثناء إنشاء التبرع مع الدفع');
        debugPrint('🔴 الاستثناء: $e');
        debugPrint('🔴 Stack trace: $stackTrace');
        debugPrint('═══════════════════════════════════════════════════════════');
      }
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
      // ⚠️ لا نطبع معلومات حساسة في الإنتاج
      if (kDebugMode) {
        debugPrint('DonationService: Creating anonymous donation with payment');
      }

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

      // ⚠️ لا نطبع معلومات حساسة في الإنتاج (URLs, payloads, response bodies)
      if (kDebugMode) {
        debugPrint('DonationService: Anonymous donation response status: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        final Map<String, dynamic>? data =
            (responseData['data'] is Map) ? responseData['data'] as Map<String, dynamic> : null;
        final Map<String, dynamic>? ps =
            (data?['payment_session'] is Map) ? data!['payment_session'] as Map<String, dynamic> : null;

        final String? paymentUrl = (ps?['payment_url'] ?? ps?['redirect_url'] ?? ps?['checkout_url'] ??
            responseData['payment_url'] ?? responseData['checkout_url'] ?? data?['payment_url'] ?? data?['checkout_url'])
            ?.toString();
        final String? sessionId = (ps?['session_id'] ?? responseData['session_id'] ?? data?['session_id'])?.toString();

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
      if (kDebugMode) {
        debugPrint('DonationService: Error creating anonymous donation');
      }
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
        // ⚠️ لا نطبع معلومات المصادقة في الإنتاج
        if (kDebugMode) {
          debugPrint('DonationService: Using authenticated payment request');
        }
      } else {
        // ⚠️ لا نطبع معلومات الدفع في الإنتاج
        if (kDebugMode) {
          debugPrint('DonationService: Using anonymous payment request');
        }
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

  /// استرجاع تفاصيل نجاح الدفع من واجهة الموبايل الجديدة
  Future<Map<String, dynamic>> fetchMobilePaymentSuccessData({
    required String successUrl,
  }) async {
    try {
      await _apiClient.initialize();
      final token = await _apiClient.getAuthToken();

      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final uri = Uri.tryParse(successUrl);
      if (uri == null) {
        throw Exception('رابط نجاح الدفع غير صالح');
      }

      // ⚠️ لا نطبع URLs أو response bodies في الإنتاج
      if (kDebugMode) {
        debugPrint('DonationService: Fetching mobile success data');
      }
      final response = await http.get(uri, headers: headers);
      if (kDebugMode) {
        debugPrint('DonationService: Mobile success status: ${response.statusCode}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return _normalizeSuccessResponse(decoded);
        }
        throw Exception('استجابة غير متوقعة من خادم الدفع');
      } else if (response.statusCode == 401) {
        throw Exception('يرجى تسجيل الدخول لمتابعة عملية الدفع.');
      } else if (response.statusCode == 404) {
        throw Exception('تعذر العثور على بيانات الدفع.');
      } else {
        throw Exception('فشل في استرجاع بيانات النجاح (${response.statusCode}).');
      }
    } catch (e, stackTrace) {
      // ⚠️ لا نطبع تفاصيل الخطأ في الإنتاج
      if (kDebugMode) {
        debugPrint('DonationService: Error fetching mobile success data');
        debugPrint('DonationService: Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  Map<String, dynamic> _normalizeSuccessResponse(Map<String, dynamic> response) {
    final normalized = Map<String, dynamic>.from(response);

    // Normalize top-level amount
    if (normalized.containsKey('amount')) {
      normalized['amount'] = _parseAmount(normalized['amount']);
    }

    // Normalize data object
    final data = normalized['data'];
    if (data is Map<String, dynamic>) {
      final nested = Map<String, dynamic>.from(data);
      
      // Normalize amount in data
      if (nested.containsKey('amount')) {
        nested['amount'] = _parseAmount(nested['amount']);
      }
      
      // Normalize donation object if exists
      final donation = nested['donation'];
      if (donation is Map<String, dynamic>) {
        final donationMap = Map<String, dynamic>.from(donation);
        if (donationMap.containsKey('amount')) {
          donationMap['amount'] = _parseAmount(donationMap['amount']);
        }
        if (donationMap.containsKey('paid_amount')) {
          donationMap['paid_amount'] = _parseAmount(donationMap['paid_amount']);
        }
        nested['donation'] = donationMap;
      }
      
      normalized['data'] = nested;
    }

    return normalized;
  }

  double? _parseAmount(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  // ===== ENDPOINT 4: Get recent donations =====
  /// GET /api/v1/donations/recent?limit=5
  /// Get the last 5 donations from the API
  Future<List<Donation>> getRecentDonations({int limit = 5}) async {
    try {
      await _apiClient.initialize();
      final token = await _apiClient.getAuthToken();

      // ⚠️ لا نطبع معلومات المصادقة في الإنتاج
      if (kDebugMode) {
        debugPrint('DonationService: Getting recent donations with limit: $limit');
      }

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
      // ⚠️ لا نطبع URLs أو response bodies في الإنتاج
      if (kDebugMode) {
        debugPrint('DonationService: Fetching recent donations');
      }
      
      final response = await http.get(uri, headers: headers);
      if (kDebugMode) {
        debugPrint('DonationService: Response status: ${response.statusCode}');
      }
      
      if (response.statusCode == 200) {
        final donations = _parseDonationsResponse(response.body);
        if (kDebugMode) {
          debugPrint('DonationService: Successfully parsed ${donations.length} recent donations');
        }
        return donations;
      } else if (response.statusCode == 401) {
        if (kDebugMode) {
          debugPrint('DonationService: Unauthorized - user not authenticated');
        }
        return []; // Return empty list for unauthenticated users
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          debugPrint('DonationService: Recent donations endpoint not found');
        }
        return []; // Return empty list if endpoint doesn't exist
      } else {
        if (kDebugMode) {
          debugPrint('DonationService: Error fetching recent donations: HTTP ${response.statusCode}');
        }
        return []; // Return empty list on error
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DonationService: Error fetching recent donations');
      }
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

      // ⚠️ لا نطبع معلومات المصادقة أو URLs في الإنتاج
      if (kDebugMode) {
        debugPrint('DonationService: Checking authentication');
      }

      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          debugPrint('DonationService: No auth token found, returning empty donations list');
        }
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
          // ⚠️ لا نطبع URLs أو response bodies في الإنتاج
          if (kDebugMode) {
            debugPrint('DonationService: Trying endpoint: $endpoint');
          }
          
          final response = await http.get(uri, headers: headers);
          if (kDebugMode) {
            debugPrint('DonationService: Response status: ${response.statusCode}');
          }
          
          if (response.statusCode == 200) {
            final donations = _parseDonationsResponse(response.body);
            if (kDebugMode) {
              debugPrint('DonationService: Successfully parsed ${donations.length} donations from $endpoint');
            }
            return donations;
          } else if (response.statusCode == 404) {
            if (kDebugMode) {
              debugPrint('DonationService: Endpoint $endpoint not found, trying next...');
            }
            continue;
          } else {
            // For other errors, throw the error
            if (kDebugMode) {
              debugPrint('DonationService: Error with endpoint $endpoint: HTTP ${response.statusCode}');
            }
            throw Exception('HTTP ${response.statusCode}');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('DonationService: Error with endpoint $endpoint');
          }
          if (endpoint == endpoints.last) {
            rethrow; // If this is the last endpoint, rethrow the error
          }
          continue; // Try next endpoint
        }
      }
      
      throw Exception('جميع endpoints التبرعات غير متاحة');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DonationService: Error fetching user donations');
      }
      rethrow;
    }
  }

  // Helper method to get all donations with pagination
  Future<List<Donation>> _getAllDonationsWithPagination(Map<String, String> headers) async {
    const int limit = 50; // Fetch 50 donations per page
    
    print('DonationService: Starting to fetch all donations with pagination...');
    
    // Try multiple endpoints in order of likelihood
    final endpoints = [
      '/me/donations',  // Try user-specific donations first
      '/donations/recent', 
      '/donations',
    ];
    
    for (final endpoint in endpoints) {
      int currentPage = 1;
      bool hasMoreData = true;
      final List<Donation> collectedDonations = [];
      bool receivedSuccessfulResponse = false;

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
            receivedSuccessfulResponse = true;
            final pageDonations = _parseDonationsResponse(response.body);
            
            if (pageDonations.isEmpty) {
              print('DonationService: No donations returned on page $currentPage, stopping pagination for $endpoint');
              hasMoreData = false;
            } else {
              collectedDonations.addAll(pageDonations);
              print('DonationService: Added ${pageDonations.length} donations from page $currentPage. Total so far: ${collectedDonations.length}');
              
              // Check if we got less than the limit, which means this is the last page
              if (pageDonations.length < limit) {
                print('DonationService: Got ${pageDonations.length} donations (less than limit $limit), this is the last page');
                hasMoreData = false;
              } else {
                currentPage++;
              }
            }
          } else if (response.statusCode == 404) {
            print('DonationService: Endpoint $endpoint not found (404), moving to next endpoint');
            hasMoreData = false;
          } else {
            print('DonationService: Error with endpoint $endpoint: HTTP ${response.statusCode}');
            throw Exception('HTTP ${response.statusCode}: ${response.body}');
          }
        }
        
        if (receivedSuccessfulResponse) {
          print('DonationService: Successfully fetched ${collectedDonations.length} total donations from $endpoint');
          return collectedDonations;
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
  /// معرف مرجعي — فقط حروف إنجليزية وأرقام (متطلب Thawani لـ client_reference_id).
  String generateClientReferenceId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = (ts % 100000).toString().padLeft(5, '0');
    return 'donation${ts}$rand';
  }
}
