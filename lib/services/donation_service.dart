import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/donation.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../models/payment_status_response.dart';
import 'api_client.dart';

class DonationService {
  static final DonationService _instance = DonationService._internal();
  factory DonationService() => _instance;
  DonationService._internal();

  final ApiClient _apiClient = ApiClient();
  static const String _baseUrl = 'http://192.168.1.21:8000/api/v1';

  // ===== ENDPOINT 1: Create donation with direct payment (الأسهل) =====
  /// إنشاء تبرع مع دفع مباشر - الأسهل
  /// POST /api/v1/donations/with-payment
  Future<Map<String, dynamic>> createDonationWithPayment({
    required String itemId,
    required String itemType, // 'program' or 'campaign'
    required double amount,
    String? donorName,
    String? donorEmail,
    String? donorPhone,
    String? message,
    bool isAnonymous = false,
  }) async {
    try {
      print('DonationService: Creating donation with direct payment...');
      
      // Ensure API client is initialized
      await _apiClient.initialize();
      
      final token = await _apiClient.getAuthToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final requestData = {
        if (itemType == 'program') 'program_id': itemId,
        if (itemType == 'campaign') 'campaign_id': itemId,
        'amount': amount,
        'is_anonymous': isAnonymous,
        if (donorName != null) 'donor_name': donorName,
        if (donorEmail != null) 'donor_email': donorEmail,
        if (donorPhone != null) 'donor_phone': donorPhone,
        if (message != null) 'message': message,
      };

      print('DonationService: Request data: $requestData');

      final response = await http.post(
        Uri.parse('$_baseUrl/donations/with-payment'),
        headers: headers,
        body: jsonEncode(requestData),
      );

      print('DonationService: Response status: ${response.statusCode}');
      print('DonationService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // استخراج البيانات بشكل صحيح
        final data = responseData['data'] as Map<String, dynamic>?;
        final ps = data?['payment_session'] as Map<String, dynamic>?;
        final paymentUrl = (ps?['payment_url'] ?? responseData['payment_url']) as String?;
        final sessionId = (ps?['session_id'] ?? responseData['session_id']) as String?;
        
        // إرجاع البيانات مع payment_url و session_id
        final result = data ?? responseData;
        if (paymentUrl != null) result['payment_url'] = paymentUrl;
        if (sessionId != null) result['payment_session_id'] = sessionId;
        
        return result;
      } else if (response.statusCode == 401) {
        throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.');
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'بيانات غير صحيحة';
        throw Exception(errorMessage);
      } else {
        throw Exception('حدث خطأ في إنشاء التبرع. يرجى المحاولة مرة أخرى.');
      }
    } catch (e) {
      print('DonationService: Error creating donation with payment: $e');
      rethrow;
    }
  }

  // ===== ENDPOINT 2: Create separate payment session =====
  /// إنشاء جلسة دفع منفصلة
  /// POST /api/v1/payments/create
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
      print('DonationService: Creating separate payment session...');
      
      // Ensure API client is initialized
      await _apiClient.initialize();
      
      final token = await _apiClient.getAuthToken();
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

      print('DonationService: Payment session response status: ${response.statusCode}');
      print('DonationService: Payment session response body: ${response.body}');

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
      print('DonationService: Error creating payment session: $e');
      return PaymentResponse.error('حدث خطأ في الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.');
    }
  }

  // ===== ENDPOINT 3: Check payment status =====
  /// التحقق من حالة الدفع
  /// GET /api/v1/payments/status/{sessionId}
  Future<PaymentStatusResponse> checkPaymentStatus(String sessionId) async {
    try {
      print('DonationService: Checking payment status for session: $sessionId');
      
      // Ensure API client is initialized
      await _apiClient.initialize();
      
      final token = await _apiClient.getAuthToken();
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

      print('DonationService: Status check response status: ${response.statusCode}');
      print('DonationService: Status check response body: ${response.body}');

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
      print('DonationService: Error checking payment status: $e');
      return PaymentStatusResponse.error('حدث خطأ في الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.');
    }
  }

  // ===== HELPER METHODS =====

  /// Generate a unique client reference ID
  String generateClientReferenceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'donation_${timestamp}_$random';
  }

  /// Generate return URL for payment completion
  String generateReturnUrl() {
    return 'https://example.com/return';
  }

  /// Create donation record after successful payment
  Future<Donation?> createDonationRecord({
    required String itemId,
    required String itemType,
    required double amount,
    required String paymentSessionId,
    String? donorName,
    String? donorEmail,
    String? donorPhone,
    String? message,
    bool isAnonymous = false,
  }) async {
    try {
      print('DonationService: Creating donation record...');
      
      await _apiClient.initialize();
      
      final token = await _apiClient.getAuthToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final donationData = {
        if (itemType == 'program') 'program_id': itemId,
        if (itemType == 'campaign') 'campaign_id': itemId,
        'amount': amount,
        'payment_session_id': paymentSessionId,
        'status': 'pending',
        'is_anonymous': isAnonymous,
        if (donorName != null) 'donor_name': donorName,
        if (donorEmail != null) 'donor_email': donorEmail,
        if (donorPhone != null) 'donor_phone': donorPhone,
        if (message != null) 'message': message,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/donations'),
        headers: headers,
        body: jsonEncode(donationData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final donationJson = responseData['data'] ?? responseData;
        return Donation.fromJson(donationJson);
      } else {
        print('DonationService: Failed to create donation record: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('DonationService: Error creating donation record: $e');
      return null;
    }
  }

  /// Update donation status after payment completion
  Future<bool> updateDonationStatus({
    required String donationId,
    required String status,
    double? paidAmount,
  }) async {
    try {
      print('DonationService: Updating donation status...');
      
      await _apiClient.initialize();
      
      final token = await _apiClient.getAuthToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final updateData = {
        'status': status,
        if (paidAmount != null) 'paid_amount': paidAmount,
      };

      final response = await http.put(
        Uri.parse('$_baseUrl/donations/$donationId'),
        headers: headers,
        body: jsonEncode(updateData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('DonationService: Error updating donation status: $e');
      return false;
    }
  }

  /// Get user's donations
  Future<List<Donation>> getUserDonations() async {
    try {
      print('DonationService: Fetching user donations...');
      
      await _apiClient.initialize();
      
      final token = await _apiClient.getAuthToken();
      if (token == null) {
        throw Exception('يجب تسجيل الدخول لعرض التبرعات');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/donations/my'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> donationsData = responseData['data'] ?? responseData;
        
        return donationsData.map((donation) => Donation.fromJson(donation)).toList();
      } else {
        throw Exception('فشل في جلب التبرعات');
      }
    } catch (e) {
      print('DonationService: Error fetching user donations: $e');
      rethrow;
    }
  }
}
