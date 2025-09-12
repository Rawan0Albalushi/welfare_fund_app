import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DonationsService {
  static const String baseUrl = 'http://192.168.1.21:8000/api/v1';
  
  // احصل على التوكن من التخزين المحلي
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // إنشاء تبرع جديد
  Future<Map<String, dynamic>> createDonation({
    required int programId,
    required double amount,
    required String donorName,
    String? note,
    String type = 'quick',
  }) async {
    try {
      final token = await _getAuthToken();
      
      if (token == null) {
        return {
          'success': false,
          'error': 'لم يتم العثور على رمز المصادقة',
          'status_code': 401
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/donations/with-payment'), // ✅ استخدم with-payment
        headers: {
          'Authorization': 'Bearer $token', // ✅ مهم!
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'program_id': programId,
          'amount': amount,
          'donor_name': donorName,
          'note': note,
          'type': type,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message']
        };
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'خطأ في الاتصال: ${e.toString()}',
        'status_code': 0
      };
    }
  }

  // إنشاء تبرع للحملة
  Future<Map<String, dynamic>> createCampaignDonation({
    required int campaignId,
    required double amount,
    required String donorName,
    String? note,
    String type = 'quick',
  }) async {
    try {
      final token = await _getAuthToken();
      
      if (token == null) {
        return {
          'success': false,
          'error': 'لم يتم العثور على رمز المصادقة',
          'status_code': 401
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/donations/with-payment'), // ✅ استخدم with-payment
        headers: {
          'Authorization': 'Bearer $token', // ✅ مهم!
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'campaign_id': campaignId,
          'amount': amount,
          'donor_name': donorName,
          'note': note,
          'type': type,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message']
        };
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'خطأ في الاتصال: ${e.toString()}',
        'status_code': 0
      };
    }
  }

  // الحصول على تبرعات المستخدم
  Future<Map<String, dynamic>> getUserDonations() async {
    try {
      final token = await _getAuthToken();
      
      if (token == null) {
        return {
          'success': false,
          'error': 'لم يتم العثور على رمز المصادقة',
          'status_code': 401
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/me/donations'),
        headers: {
          'Authorization': 'Bearer $token', // ✅ مهم!
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'تم جلب التبرعات بنجاح'
        };
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'خطأ في الاتصال: ${e.toString()}',
        'status_code': 0
      };
    }
  }

  // التحقق من حالة التبرع
  Future<Map<String, dynamic>> checkDonationStatus(String donationId) async {
    try {
      final token = await _getAuthToken();
      
      if (token == null) {
        return {
          'success': false,
          'error': 'لم يتم العثور على رمز المصادقة',
          'status_code': 401
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/donations/$donationId'),
        headers: {
          'Authorization': 'Bearer $token', // ✅ مهم!
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'تم جلب حالة التبرع بنجاح'
        };
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'خطأ في الاتصال: ${e.toString()}',
        'status_code': 0
      };
    }
  }

  // معالجة الأخطاء
  Map<String, dynamic> _handleError(http.Response response) {
    try {
      final errorData = json.decode(response.body);
      return {
        'success': false,
        'error': errorData['message'] ?? 'حدث خطأ غير متوقع',
        'status_code': response.statusCode,
        'details': errorData
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'حدث خطأ في الخادم (${response.statusCode})',
        'status_code': response.statusCode,
        'details': response.body
      };
    }
  }
}
