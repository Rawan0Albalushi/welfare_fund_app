import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../services/donation_service.dart';
// WebView web platform registration (for Flutter Web)
// ignore: avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

/// شاشة فشل الدفع.
/// - عند الضغط على "المحاولة مرة أخرى" ترجع 'retry' للصفحة السابقة عبر Navigator.pop.
/// - يمكن تمرير رسالة خطأ لعرض التفاصيل للمستخدم.
class PaymentFailedScreen extends StatefulWidget {
  static const String retryResult = 'retry';

  final String? errorMessage;
  final String? campaignTitle;
  final double? amount;
  final String? donationId;
  final String? sessionId;

  const PaymentFailedScreen({
    super.key,
    this.errorMessage,
    this.campaignTitle,
    this.amount,
    this.donationId,
    this.sessionId,
  });

  @override
  State<PaymentFailedScreen> createState() => _PaymentFailedScreenState();
}

class _PaymentFailedScreenState extends State<PaymentFailedScreen> {
  // متغيرات للبيانات المستخرجة من URL
  String? _donationId;
  String? _sessionId;
  String? _errorMessage;
  String? _campaignTitle;
  double? _amount;

  @override
  void initState() {
    super.initState();
    
    // استخراج query parameters من URL
    _extractQueryParameters();
  }

  void _extractQueryParameters() {
    try {
      // استخراج query parameters من URL
      final uri = Uri.base;
      _donationId = uri.queryParameters['donation_id'];
      _sessionId = uri.queryParameters['session_id'];
      _errorMessage = uri.queryParameters['error_message'];
      
      // استخراج المبلغ إذا كان متوفراً
      final amountStr = uri.queryParameters['amount'];
      if (amountStr != null) {
        _amount = double.tryParse(amountStr);
        print('PaymentFailedScreen: Parsed amount from URL: $_amount');
      }
      
      // استخراج عنوان الحملة إذا كان متوفراً
      _campaignTitle = uri.queryParameters['campaign_title'];
      
      if (_donationId == null && widget.donationId != null) _donationId = widget.donationId;
      if (_sessionId == null && widget.sessionId != null) _sessionId = widget.sessionId;
      if (_errorMessage == null && widget.errorMessage != null) _errorMessage = widget.errorMessage;
      if (_amount == null && widget.amount != null) _amount = widget.amount;
      if (_campaignTitle == null && widget.campaignTitle != null) _campaignTitle = widget.campaignTitle;

      if (kDebugMode) {
        print('PaymentFailedScreen: donation_id = $_donationId');
        print('PaymentFailedScreen: session_id = $_sessionId');
        print('PaymentFailedScreen: error_message = $_errorMessage');
        print('PaymentFailedScreen: amount = $_amount');
        print('PaymentFailedScreen: campaign_title = $_campaignTitle');
      }

      // إذا كان لدينا donation_id، احصل على تفاصيل التبرع من API
      if (_donationId != null) {
        _fetchDonationDetails();
      }
    } catch (e) {
      print('Error extracting query parameters: $e');
    }
  }

  Future<void> _fetchDonationDetails() async {
    try {
      if (_donationId == null) return;
      
      print('PaymentFailedScreen: Fetching donation details for $_donationId');
      
      // استدعاء API للحصول على تفاصيل التبرع
      final donationService = DonationService();
      final response = await donationService.checkDonationStatus(_donationId!);
      
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data != null) {
          setState(() {
            _amount = (data['amount'] as num?)?.toDouble();
            _campaignTitle = data['campaign_title'] as String?;
          });
          
          print('PaymentFailedScreen: Fetched amount: $_amount');
          print('PaymentFailedScreen: Fetched campaign title: $_campaignTitle');
        }
      } else {
        print('PaymentFailedScreen: Failed to fetch donation details - user may not be authenticated');
        // إذا فشل الحصول على البيانات من API، استخدم البيانات من URL
        if (_amount == null && widget.amount != null) {
          setState(() {
            _amount = widget.amount;
          });
        }
        if (_campaignTitle == null && widget.campaignTitle != null) {
          setState(() {
            _campaignTitle = widget.campaignTitle;
          });
        }
      }
    } catch (e) {
      print('PaymentFailedScreen: Error fetching donation details: $e');
      // إذا فشل الحصول على البيانات من API، استخدم البيانات من URL
      if (_amount == null && widget.amount != null) {
        setState(() {
          _amount = widget.amount;
        });
      }
      if (_campaignTitle == null && widget.campaignTitle != null) {
        setState(() {
          _campaignTitle = widget.campaignTitle;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.highlight_off,
                  size: 60,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'payment_failed'.tr(),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Donation summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textSecondary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'donation_details'.tr(),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _campaignTitle ?? widget.campaignTitle ?? 'general'.tr(),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(_amount ?? widget.amount ?? 0.0).toStringAsFixed(2)} ريال عماني',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    // Donation ID (if available)
                    if (_donationId != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'donation_id'.tr() + ': $_donationId',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Info
              Text(
                'payment_failed_info'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Actions
              Column(
                children: [
                  // Try Again
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, PaymentFailedScreen.retryResult),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'try_again'.tr(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Back to Home
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // للويب، غير URL في المتصفح
                        if (kIsWeb) {
                          if (kIsWeb) {
                            // Web-specific navigation would go here
                          }
                        }
                        
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppConstants.homeRoute,
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'home'.tr(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
