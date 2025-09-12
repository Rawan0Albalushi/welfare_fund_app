import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'checkout_webview.dart';

class DonationScreen extends StatefulWidget {
  final int? campaignId;
  final String? campaignTitle;
  final double? initialAmount;
  final String? donorName;

  const DonationScreen({
    super.key,
    this.campaignId,
    this.campaignTitle,
    this.initialAmount,
    this.donorName,
  });

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  bool _isLoading = false;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _donorNameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with provided values
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount.toString();
    }
    if (widget.donorName != null) {
      _donorNameController.text = widget.donorName!;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _donorNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _makeDonation() async {
    // Validate inputs
    if (_amountController.text.isEmpty) {
      _showErrorSnackBar('يرجى إدخال المبلغ');
      return;
    }

    if (_donorNameController.text.isEmpty) {
      _showErrorSnackBar('يرجى إدخال اسم المتبرع');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showErrorSnackBar('يرجى إدخال مبلغ صحيح');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ احصل على التوكن
      final token = await _getAuthToken();
      
      if (token == null) {
        _showErrorSnackBar('يجب تسجيل الدخول أولاً');
        return;
      }

      // الحصول على origin للمنصة الويب
      final origin = Uri.base.origin; // مثال: http://localhost:49887
      
      // 1) استدعاء POST /api/v1/donations/with-payment مع return_origin
      final response = await http.post(
        Uri.parse('http://192.168.1.21:8000/api/v1/donations/with-payment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'campaign_id': widget.campaignId ?? 1,
          'amount': amount,
          'donor_name': _donorNameController.text.trim(),
          'note': _noteController.text.trim().isEmpty 
              ? 'تبرع للطلاب المحتاجين' 
              : _noteController.text.trim(),
          'return_origin': origin, // إضافة return_origin
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Donation response: $data');
        
        // استخراج البيانات من الاستجابة
        final sessionId = data['session_id'] ?? data['data']?['session_id'];
        final checkoutUrl = data['checkout_url'] ?? data['data']?['checkout_url'] ?? data['payment_url'];
        
        print('✅ Payment session created: sessionId=$sessionId, checkoutUrl=$checkoutUrl');
        
        // 2) فتح checkout مباشرة في نفس التبويب للمنصة الويب
        if (kIsWeb) {
          await launchUrlString(
            checkoutUrl,
            webOnlyWindowName: '_self', // نفس التبويب
          );
          
          // إظهار رسالة للمستخدم
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم فتح صفحة الدفع في نفس التبويب. يرجى إتمام الدفع...'),
              backgroundColor: AppColors.info,
              duration: Duration(seconds: 3),
            ),
          );
          
          // الانتظار قليلاً ثم التحقق من حالة الدفع
          await Future.delayed(const Duration(seconds: 5));
          await _confirmPayment(sessionId);
        } else {
          // للمنصات المحمولة، استخدم CheckoutWebView
          _openCheckoutWebView(checkoutUrl, sessionId);
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'فشل في إنشاء جلسة الدفع';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error: $e');
      _showErrorSnackBar('خطأ في إنشاء التبرع: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // احصل على التوكن من التخزين المحلي
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // فتح CheckoutWebView للدفع
  void _openCheckoutWebView(String checkoutUrl, String sessionId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutWebView(
          checkoutUrl: checkoutUrl,
          successUrl: 'http://192.168.1.21:8000/api/v1/payments/success',
          cancelUrl: 'http://192.168.1.21:8000/api/v1/payments/cancel',
        ),
      ),
    );

    // معالجة النتائج
    if (result != null) {
      if (result['status'] == 'success') {
        // 3) إذا رجع result.status == 'success' ناد POST /api/v1/payments/confirm
        await _confirmPayment(sessionId);
      } else if (result['status'] == 'cancel') {
        // 4) إذا رجع 'cancel' اعرض رسالة إلغاء فقط
        _showCancelMessage();
      }
    }
  }

  // تأكيد الدفع
  Future<void> _confirmPayment(String sessionId) async {
    try {
      final token = await _getAuthToken();
      
      final response = await http.post(
        Uri.parse('http://192.168.1.21:8000/api/v1/payments/confirm'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'session_id': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        // اعرض شاشة "نجاح التبرّع"
        _showDonationSuccess();
      } else {
        throw Exception('فشل في تأكيد الدفع');
      }
    } catch (e) {
      print('❌ Error confirming payment: $e');
      _showErrorSnackBar('خطأ في تأكيد الدفع: $e');
    }
  }

  // عرض رسالة الإلغاء
  void _showCancelMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إلغاء عملية الدفع'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // عرض شاشة نجاح التبرع
  void _showDonationSuccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('نجح التبرع'),
          ],
        ),
        content: const Text('تم التبرع بنجاح! شكراً لك على دعمك للطلاب المحتاجين.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // إغلاق الحوار
              Navigator.of(context).pop(); // العودة للشاشة السابقة
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'التبرع',
          style: AppTextStyles.headlineMedium.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campaign Info Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.campaignTitle ?? 'تبرع للطلاب المحتاجين',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ساعد الطلاب المحتاجين في الحصول على التعليم المناسب',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Donation Form
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تفاصيل التبرع',
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'المبلغ (ريال عماني)',
                        hintText: 'أدخل المبلغ',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Donor Name Field
                    TextFormField(
                      controller: _donorNameController,
                      decoration: InputDecoration(
                        labelText: 'اسم المتبرع',
                        hintText: 'أدخل اسم المتبرع',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Note Field
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'ملاحظة (اختياري)',
                        hintText: 'أدخل ملاحظة أو رسالة',
                        prefixIcon: const Icon(Icons.note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Donate Button
            ElevatedButton(
              onPressed: _isLoading ? null : _makeDonation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'جاري المعالجة...',
                          style: AppTextStyles.buttonLarge,
                        ),
                      ],
                    )
                  : Text(
                      'تبرع الآن',
                      style: AppTextStyles.buttonLarge,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
