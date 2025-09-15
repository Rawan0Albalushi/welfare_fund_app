import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:easy_localization/easy_localization.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import 'checkout_webview.dart';
import 'donation_success_screen.dart';

class QuickDonatePaymentScreen extends StatefulWidget {
  final double amount;
  final String? selectedCategory;
  final List<Map<String, dynamic>> categories;

  const QuickDonatePaymentScreen({
    super.key,
    required this.amount,
    required this.selectedCategory,
    required this.categories,
  });

  @override
  State<QuickDonatePaymentScreen> createState() => _QuickDonatePaymentScreenState();
}

class _QuickDonatePaymentScreenState extends State<QuickDonatePaymentScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _processPayment() async {

    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ احصل على التوكن (اختياري)
      final token = await _getAuthToken();
      
      // الحصول على origin للمنصة الويب
      final origin = Uri.base.origin;
      
      // الحصول على campaign_id من الفئة المختارة
      final campaignId = _getCampaignIdFromCategory();
      
      // إعداد headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      // إضافة Authorization header فقط إذا كان المستخدم مسجل دخول
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        print('QuickDonate: Using authenticated request with token');
      } else {
        print('QuickDonate: Using anonymous donation request');
      }
      
      // 1) استدعاء POST /api/v1/donations/with-payment مع return_origin
      final response = await http.post(
        Uri.parse('http://192.168.1.101:8000/api/v1/donations/with-payment'),
        headers: headers,
        body: jsonEncode({
          'campaign_id': campaignId,
          'amount': widget.amount,
          'donor_name': 'متبرع',
          'note': 'تبرع سريع للطلاب المحتاجين',
          'is_anonymous': false,
          'type': 'quick',
          'return_origin': origin,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Quick donation response: $data');
        
        // استخراج البيانات من الاستجابة
        final sessionId = data['data']?['payment_session']?['session_id'] ?? 
                         data['session_id'] ?? 
                         data['data']?['session_id'];
        final checkoutUrl = data['data']?['payment_session']?['payment_url'] ?? 
                           data['data']?['payment_url'] ?? 
                           data['checkout_url'] ?? 
                           data['payment_url'];
        
        print('✅ Payment session created: sessionId=$sessionId, checkoutUrl=$checkoutUrl');
        
        // التحقق من وجود البيانات المطلوبة
        if (sessionId == null || checkoutUrl == null) {
          throw Exception('Missing payment session data: sessionId=$sessionId, checkoutUrl=$checkoutUrl');
        }
        
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

  int _getCampaignIdFromCategory() {
    // إذا كانت الفئة المختارة موجودة في القائمة، استخدم أول حملة من الفئة
    if (widget.selectedCategory != null) {
      final category = widget.categories.firstWhere(
        (cat) => cat['id'] == widget.selectedCategory,
        orElse: () => {'campaigns': []}, // fallback
      );
      
      final campaigns = category['campaigns'] as List<Map<String, dynamic>>?;
      if (campaigns != null && campaigns.isNotEmpty) {
        return int.tryParse(campaigns.first['id'].toString()) ?? 1;
      }
    }
    return 1; // fallback campaign ID
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
          successUrl: 'http://192.168.1.101:8000/api/v1/payments/success',
          cancelUrl: 'http://192.168.1.101:8000/api/v1/payments/cancel',
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
      
      // إعداد headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      // إضافة Authorization header فقط إذا كان المستخدم مسجل دخول
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.post(
        Uri.parse('http://192.168.1.101:8000/api/v1/payments/confirm'),
        headers: headers,
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // عرض شاشة نجاح التبرع
  void _showDonationSuccess() {
    final categoryTitle = widget.selectedCategory != null
        ? widget.categories.firstWhere((cat) => cat['id'] == widget.selectedCategory)['title']
        : 'تبرع سريع';

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DonationSuccessScreen(
          amount: widget.amount,
          campaignTitle: categoryTitle,
          campaignCategory: categoryTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryTitle = widget.selectedCategory != null
        ? widget.categories.firstWhere((cat) => cat['id'] == widget.selectedCategory)['title']
        : 'تبرع سريع';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'payment_details'.tr(),
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.largePadding),
              decoration: BoxDecoration(
                gradient: AppColors.modernGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.payment,
                    color: AppColors.surface,
                    size: 32,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'donation_summary'.tr(),
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'amount'.tr(),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.surface.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        '${widget.amount.toStringAsFixed(0)} ريال عماني',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'category'.tr(),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.surface.withOpacity(0.9),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          categoryTitle,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.extraLargePadding),

            // Payment Method Section
            Text(
              'payment_method'.tr(),
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Payment Method Cards
            Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.payment,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thawani Pay',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'secure_payment_desc'.tr(),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.extraLargePadding),

            // Terms and Conditions
            Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textPrimary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'payment_terms'.tr(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.extraLargePadding),

            // Complete Donation Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading 
                      ? AppColors.textSecondary.withOpacity(0.3)
                      : AppColors.primary,
                  foregroundColor: AppColors.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: AppColors.primary.withOpacity(0.3),
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
                            'processing_payment'.tr(),
                            style: AppTextStyles.buttonLarge.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'complete_donation'.tr(),
                            style: AppTextStyles.buttonLarge.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
