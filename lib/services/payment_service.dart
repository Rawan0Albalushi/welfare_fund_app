// payment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  // تأكد أن هذا يطابق العنوان في ApiClient.initialize
  static const String _baseUrl = 'http://192.168.1.101:8000/api/v1';
  static const String baseUrl = 'http://192.168.1.101:8000/api/v1';

  String get _apiBase => _baseUrl;

  // احصل على التوكن من التخزين المحلي
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

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
        print('PaymentService: Using authenticated request with token');
      } else {
        print('PaymentService: Using anonymous payment request');
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

      final uri = Uri.parse('${_apiBase.replaceAll(RegExp(r"/+\$"), "")}/payments/create');
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
        print('PaymentService: Using authenticated status check with token');
      } else {
        print('PaymentService: Using anonymous status check');
      }

      final uri = Uri.parse('${_apiBase.replaceAll(RegExp(r"/+\$"), "")}/payments/status/$sessionId');
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
        Uri.parse('$baseUrl/donations/with-payment'),
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
        throw Exception('Failed to create donation: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
