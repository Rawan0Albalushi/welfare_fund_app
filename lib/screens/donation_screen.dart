import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:easy_localization/easy_localization.dart';

import '../constants/app_colors.dart';
import '../constants/app_config.dart';
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
      _showErrorSnackBar('required_field'.tr());
      return;
    }

    if (_donorNameController.text.isEmpty) {
      _showErrorSnackBar('required_field'.tr());
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showErrorSnackBar('required_field'.tr());
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ احصل على التوكن
      final token = await _getAuthToken();
      
      if (token == null) {
        _showErrorSnackBar('login_required'.tr());
        return;
      }

      // الحصول على origin للمنصة الويب
      final origin = kIsWeb ? Uri.base.origin : AppConfig.serverBaseUrl;
      
      // 1) استدعاء POST /api/v1/donations/with-payment مع return_origin
      final response = await http.post(
        Uri.parse(AppConfig.donationsWithPaymentEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'campaign_id': widget.campaignId ?? 1,
          'amount': amount,
          'donor_name': _donorNameController.text.trim(),
          'note': _noteController.text.trim().isEmpty 
              ? 'quick_donation_for_needy_students'.tr() 
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
            SnackBar(
              content: Text('payment_page_opened'.tr()),
              backgroundColor: AppColors.info,
              duration: const Duration(seconds: 3),
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
        final errorMessage = errorData['message'] ?? 'payment_failed_creating_session'.tr();
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error: $e');
      _showErrorSnackBar('error_creating_donation'.tr());
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
          successUrl: AppConfig.paymentsSuccessUrl,
          cancelUrl: AppConfig.paymentsCancelUrl,
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
        Uri.parse(AppConfig.paymentsConfirmEndpoint),
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
        throw Exception('payment_failed'.tr());
      }
    } catch (e) {
      print('❌ Error confirming payment: $e');
      _showErrorSnackBar('error_occurred'.tr());
    }
  }

  // عرض رسالة الإلغاء
  void _showCancelMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('payment_cancelled'.tr()),
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
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text('donation_successful'.tr()),
          ],
        ),
        content: Text('thank_you'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // إغلاق الحوار
              Navigator.of(context).pop(); // العودة للشاشة السابقة
            },
            child: Text('ok'.tr()),
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
          'donate_now'.tr(),
          style: AppTextStyles.appBarTitleDark,
        ),
        actions: const [],
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
                      widget.campaignTitle ?? 'support_students'.tr(),
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'help_students_succeed'.tr(),
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
                      'donation_details'.tr(),
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'amount'.tr(),
                        hintText: 'amount'.tr(),
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
                        labelText: 'full_name'.tr(),
                        hintText: 'full_name'.tr(),
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
                        labelText: 'donation_message'.tr(),
                        hintText: 'donation_message'.tr(),
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
                          'loading'.tr(),
                          style: AppTextStyles.buttonLarge,
                        ),
                      ],
                    )
                  : Text(
                      'donate_now'.tr(),
                      style: AppTextStyles.buttonLarge,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
