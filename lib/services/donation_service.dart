// donation_service.dart
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;

import '../models/payment_request.dart';
import '../models/payment_response.dart' hide PaymentStatusResponse;
import '../models/payment_status_response.dart';
import 'api_client.dart';

class DonationService {
  static final DonationService _instance = DonationService._internal();
  factory DonationService() => _instance;
  DonationService._internal();

  final ApiClient _apiClient = ApiClient();

  // ===== Base URL (محلي) =====
  // Android Emulator يصل لمضيف جهازك بـ 10.0.2.2
  // iOS Simulator غالباً يقدر على localhost
  // الأجهزة الفعلية استخدمي IP الشبكة (مثال: 192.168.100.105)
  static String _resolveFallbackBase() {
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
      if (Platform.isIOS) return 'http://localhost:8000/api/v1';
    } catch (_) {}
    // Fallback عام (غيّريه لعنوان جهازك على الشبكة)
    return 'http://192.168.100.105:8000/api/v1';
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
  }) async {
    try {
      await _apiClient.initialize();
      final token = await _apiClient.getAuthToken();

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null) headers['Authorization'] = 'Bearer $token';

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
      };

      final uri = Uri.parse('${_apiBase.replaceAll(RegExp(r"/+$"), "")}/donations/with-payment');
      final response = await http.post(uri, headers: headers, body: jsonEncode(payload));

      // Debug:
      // print('with-payment -> ${response.statusCode}\n${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

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
    } catch (e) {
      // print('DonationService: Error creating donation with payment: $e');
      rethrow;
    }
  }

  // ===== ENDPOINT 2: Create payment session (منفصل) =====
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
  }) async {
    try {
      await _apiClient.initialize();
      final token = await _apiClient.getAuthToken();

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final req = PaymentRequest(
        amountOmr: amountOmr,                 // سيتحوّل داخليًا إلى بيسة
        clientReferenceId: clientReferenceId, // اختياري
        programId: programId,
        campaignId: campaignId,
        donorName: donorName,
        note: note,
        type: type,
        productName: productName ?? 'تبرع',
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

  // ===== Helpers =====
  String generateClientReferenceId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = (ts % 10000).toString().padLeft(4, '0');
    return 'donation_${ts}_$rand';
  }
}
