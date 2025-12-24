// payment_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_config.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart' hide PaymentStatusResponse;
import '../models/payment_status_response.dart';
import 'api_client.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final ApiClient _apiClient = ApiClient();

  // قاعدة API المستخدمة في بقية الخدمات أيضًا
  static const String baseUrl = AppConfig.apiBaseUrlV1;

  /// النسخة الجديدة الموصى بها — تُطابق باكند Laravel:
  ///
  /// - amountOmr: المبلغ بالريال (OMR) — سيُحوَّل تلقائيًا إلى بيسة في PaymentRequest
  /// - programId/campaignId: أحدهما مطلوب (حسب الباكند)
  /// - productName: الاسم الظاهر في صفحة ثواني (افتراضي "تبرع")
  /// - type: quick | gift
  Future<PaymentResponse> createPaymentSessionV2({
    required double amountOmr,
    String? clientReferenceId,
    int? programId,
    int? campaignId,
    String? donorName,
    String? note,
    String type = 'quick',
    String? productName,
    String? returnOrigin,
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
          debugPrint('PaymentService: Using authenticated request');
        }
      } else {
        // ⚠️ لا نطبع معلومات الدفع في الإنتاج
        if (kDebugMode) {
          debugPrint('PaymentService: Using anonymous payment request');
        }
      }

      final req = PaymentRequest(
        amountOmr: amountOmr,
        clientReferenceId: clientReferenceId,
        programId: programId,
        campaignId: campaignId,
        donorName: donorName,
        note: note,
        type: type,
        productName: productName ?? 'تبرع',
        returnOrigin: returnOrigin,
      );

      final uri = Uri.parse('${AppConfig.apiBaseUrlV1}/payments/create');
      final response = await http.post(uri, headers: headers, body: jsonEncode(req.toJson()));

      // Debug (اختياري)
      // print('Create session -> ${response.statusCode}\n${response.body}');

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
      // print('PaymentService V2: Error creating payment session: $e');
      return PaymentResponse.error('حدث خطأ في الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.');
    }
  }

  /// ⚠️ النسخة القديمة — تُحافظ على التوافق الخلفي مع الاستدعاءات الحالية عندك.
  /// يتم تجاهل returnUrl (صار يُدار في الباكند).
  Future<PaymentResponse> createPaymentSession({
    required double amount,
    required String clientReferenceId,
    required String returnUrl, // لم يعد مستخدمًا
    String? donorName,
    String? donorEmail, // غير مستخدم في الباكند
    String? donorPhone, // غير مستخدم في الباكند
    String? message,    // سنستخدمه كـ productName
    String? itemId,     // غير مستخدم في الباكند
    String? itemType,   // غير مستخدم في الباكند
    int? programId,
    int? campaignId,
    String? note,
    String type = 'quick',
  }) {
    // نعيد التوجيه للـ V2 مع التكييف المناسب
    return createPaymentSessionV2(
      amountOmr: amount,
      clientReferenceId: clientReferenceId,
      programId: programId,
      campaignId: campaignId,
      donorName: donorName,
      note: note,
      type: type,
      productName: message ?? 'تبرع',
    );
  }

  /// التحقق من حالة الدفع عبر sessionId
  Future<PaymentStatusResponse> checkPaymentStatus(String sessionId) async {
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
          debugPrint('PaymentService: Using authenticated status check');
        }
      } else {
        // ⚠️ لا نطبع معلومات الدفع في الإنتاج
        if (kDebugMode) {
          debugPrint('PaymentService: Using anonymous status check');
        }
      }

      final uri = Uri.parse('${AppConfig.apiBaseUrlV1}/payments/status/$sessionId');
      final response = await http.get(uri, headers: headers);

      // Debug (اختياري)
      // print('Check status -> ${response.statusCode}\n${response.body}');

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
      // print('PaymentService: Error checking payment status: $e');
      return PaymentStatusResponse.error('حدث خطأ في الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.');
    }
  }

  /// معرف مرجعي فريد (اختياري)
  String generateClientReferenceId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = (ts % 10000).toString().padLeft(4, '0');
    return 'donation_${ts}_$rand';
  }

  /// إنشاء جلسة دفع لتبرع موجود
  /// POST /api/v1/payments/create-with-donation
  /// 
  /// **الوصف:** إنشاء جلسة دفع لتبرع موجود بالفعل في النظام.
  Future<PaymentResponse> createPaymentWithDonation({
    required String donationId,
    required double amountOmr,
    String? returnOrigin,
  }) async {
    try {
      await _apiClient.initialize();
      final token = await _apiClient.getAuthToken();

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // تحويل المبلغ من ريال إلى بيسة
      final amountInBaisa = (amountOmr * 1000).toInt();

      final payload = <String, dynamic>{
        'donation_id': donationId,
        'products': [
          {
            'name': 'Donation',
            'quantity': 1,
            'unit_amount': amountInBaisa,
          }
        ],
        if (returnOrigin != null) 'return_origin': returnOrigin,
      };

      final uri = Uri.parse('${AppConfig.apiBaseUrlV1}/payments/create-with-donation');
      final response = await http.post(uri, headers: headers, body: jsonEncode(payload));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return PaymentResponse.fromJson(responseData);
      } else if (response.statusCode == 401) {
        return PaymentResponse.error('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.');
      } else if (response.statusCode == 404) {
        return PaymentResponse.error('التبرع غير موجود');
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = (errorData['message']?.toString()) ?? 'التبرع ليس في حالة انتظار الدفع';
        return PaymentResponse.error(errorMessage);
      } else {
        return PaymentResponse.error('حدث خطأ في إنشاء جلسة الدفع. يرجى المحاولة مرة أخرى.');
      }
    } catch (e) {
      return PaymentResponse.error('حدث خطأ في الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.');
    }
  }

  /// نجاح الدفع للموبايل
  /// GET /api/v1/payments/mobile/success
  /// 
  /// **الوصف:** يتم استدعاء هذا الـ endpoint تلقائياً من Thawani بعد إتمام الدفع.
  Future<Map<String, dynamic>> mobileSuccess({
    required String donationId,
    String? sessionId,
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

      final queryParams = <String, String>{
        'donation_id': donationId,
        if (sessionId != null) 'session_id': sessionId,
      };

      final uri = Uri.parse('${AppConfig.apiBaseUrlV1}/payments/mobile/success')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData;
      } else if (response.statusCode == 404) {
        return {
          'status': 'error',
          'message': 'Donation not found',
        };
      } else {
        return {
          'status': 'error',
          'message': 'حدث خطأ في التحقق من حالة الدفع',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'حدث خطأ في الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
      };
    }
  }

  /// الحصول على معلومات الدفع
  /// GET /api/v1/payments?session_id={sessionId}
  /// 
  /// **الوصف:** الحصول على معلومات التبرع وجلسة الدفع.
  Future<Map<String, dynamic>> getPaymentInfo({
    required String sessionId,
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

      final uri = Uri.parse('${AppConfig.apiBaseUrlV1}/payments')
          .replace(queryParameters: {'session_id': sessionId});
      
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData;
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Donation not found for this session',
        };
      } else {
        return {
          'success': false,
          'message': 'حدث خطأ في استرجاع معلومات الدفع',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ في الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
      };
    }
  }

  /// تأكيد حالة الدفع
  /// POST /api/v1/payments/confirm
  /// 
  /// **الوصف:** التحقق من حالة الدفع من Thawani وتحديث حالة التبرع في قاعدة البيانات.
  Future<Map<String, dynamic>> confirmPayment({
    String? sessionId,
    String? donationId,
  }) async {
    try {
      await _apiClient.initialize();
      final token = await _apiClient.getAuthToken();

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final payload = <String, dynamic>{};
      if (sessionId != null) {
        payload['session_id'] = sessionId;
      }
      if (donationId != null) {
        payload['donation_id'] = donationId;
      }

      final uri = Uri.parse('${AppConfig.apiBaseUrlV1}/payments/confirm');
      final response = await http.post(uri, headers: headers, body: jsonEncode(payload));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData;
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'التبرع غير موجود',
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'message': (errorData['message']?.toString()) ?? 'حدث خطأ في تأكيد الدفع',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ في الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
      };
    }
  }

  /// إنشاء تبرع مع دفع مباشر - النسخة الجديدة المحدثة
  static Future<Map<String, dynamic>> createDonationWithPayment({
    required int campaignId,
    required double amount,
    required String donorName,
    String? note,
    String type = 'quick',
    String? returnOrigin,
  }) async {
    try {
      // ✅ احصل على التوكن
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final response = await http.post(
        Uri.parse(AppConfig.donationsWithPaymentEndpoint),
        headers: {
          'Authorization': 'Bearer $token', // ✅ مهم جداً!
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'campaign_id': campaignId,
          'amount': amount,
          'donor_name': donorName,
          'note': note,
          'type': type,
          if (returnOrigin != null) 'return_origin': returnOrigin,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        // ⚠️ لا نعرض تفاصيل الاستجابة في الإنتاج لأسباب أمنية
        if (kDebugMode) {
          debugPrint('PaymentService: Failed to create donation: ${response.statusCode}');
        }
        throw Exception('فشل في إنشاء التبرع');
      }
    } catch (e) {
      // ⚠️ لا نعرض تفاصيل الخطأ في الإنتاج
      if (kDebugMode) {
        debugPrint('PaymentService: Network error: $e');
      }
      throw Exception('حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى');
    }
  }
}
