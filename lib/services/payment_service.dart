import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../models/payment_status_response.dart';
import 'api_client.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final ApiClient _apiClient = ApiClient();
  static const String _baseUrl = 'http://192.168.1.21:8000/api/v1';

  /// Create a payment session with Thawani
  Future<PaymentResponse> createPaymentSession({
    required double amount,
    required String clientReferenceId,
    required String returnUrl,
    String? donorName,
    String? donorEmail,
    String? donorPhone,
    String? message,
    String? itemId,
    String? itemType,
  }) async {
    try {
      // Ensure API client is initialized
      await _apiClient.initialize();
      
      final token = await _apiClient.getAuthToken();
      // Make authentication optional for anonymous donations
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final request = PaymentRequest(
        amount: amount,
        clientReferenceId: clientReferenceId,
        returnUrl: returnUrl,
        donorName: donorName,
        donorEmail: donorEmail,
        donorPhone: donorPhone,
        message: message,
        itemId: itemId,
        itemType: itemType,
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/payments/create'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('PaymentService: Create session response status: ${response.statusCode}');
      print('PaymentService: Create session response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return PaymentResponse.fromJson(responseData);
      } else if (response.statusCode == 401) {
        return PaymentResponse.error('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.');
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'بيانات غير صحيحة';
        return PaymentResponse.error(errorMessage);
      } else {
        return PaymentResponse.error('حدث خطأ في إنشاء جلسة الدفع. يرجى المحاولة مرة أخرى.');
      }
    } catch (e) {
      print('PaymentService: Error creating payment session: $e');
      return PaymentResponse.error('حدث خطأ في الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.');
    }
  }

  /// Check payment status using session ID
  Future<PaymentStatusResponse> checkPaymentStatus(String sessionId) async {
    try {
      // Ensure API client is initialized
      await _apiClient.initialize();
      
      final token = await _apiClient.getAuthToken();
      // Make authentication optional for status check
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/payments/status/$sessionId'),
        headers: headers,
      );

      print('PaymentService: Check status response status: ${response.statusCode}');
      print('PaymentService: Check status response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return PaymentStatusResponse.fromJson(responseData);
      } else if (response.statusCode == 401) {
        return PaymentStatusResponse.error('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.');
      } else if (response.statusCode == 404) {
        return PaymentStatusResponse.error('لم يتم العثور على جلسة الدفع.');
      } else {
        return PaymentStatusResponse.error('حدث خطأ في التحقق من حالة الدفع. يرجى المحاولة مرة أخرى.');
      }
    } catch (e) {
      print('PaymentService: Error checking payment status: $e');
      return PaymentStatusResponse.error('حدث خطأ في الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.');
    }
  }

  /// Generate a unique client reference ID
  String generateClientReferenceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'donation_${timestamp}_$random';
  }

  /// Generate return URL for payment completion
  String generateReturnUrl() {
    // Use a simple URL that Thawani will accept
    return 'https://example.com/return';
  }
}
