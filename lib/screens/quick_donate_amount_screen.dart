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
import '../constants/app_constants.dart';
import '../models/campaign.dart';
import '../services/campaign_service.dart';
import 'checkout_webview.dart';
import 'donation_success_screen.dart';

class QuickDonateAmountScreen extends StatefulWidget {
  const QuickDonateAmountScreen({super.key});

  @override
  State<QuickDonateAmountScreen> createState() =>
      _QuickDonateAmountScreenState();
}

class _QuickDonateAmountScreenState extends State<QuickDonateAmountScreen> {
  double _selectedAmount = 50.0;
  final TextEditingController _customAmountController = TextEditingController();
  bool _isCustomAmount = false;
  bool _isLoading = false;

  List<double> _presetAmounts = [25.0, 50.0, 100.0, 200.0, 500.0, 1000.0];
  final CampaignService _campaignService = CampaignService();
  Campaign? _selectedCampaign;
  List<Campaign> _activeCampaigns = [];
  bool _isLoadingCampaign = false;
  String? _campaignError;

  @override
  void initState() {
    super.initState();
    _customAmountController.text = _selectedAmount.toString();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadActiveCampaign(),
      _loadQuickDonationAmounts(),
    ]);
  }

  Future<void> _loadActiveCampaign() async {
    setState(() {
      _isLoadingCampaign = true;
      _campaignError = null;
    });

    try {
      final campaigns = await _campaignService.getCharityCampaigns();
      if (!mounted) return;

      final activeCampaigns =
          campaigns.where((campaign) => campaign.isActive).toList();

      if (activeCampaigns.isNotEmpty) {
        activeCampaigns.shuffle();
        setState(() {
          _activeCampaigns = activeCampaigns;
          _selectedCampaign = activeCampaigns.first;
        });
      } else {
        setState(() {
          _activeCampaigns = [];
          _selectedCampaign = null;
          _campaignError = 'no_campaigns_available'.tr();
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _activeCampaigns = [];
        _selectedCampaign = null;
        _campaignError = 'error_loading_programs'.tr();
      });
      print('QuickDonate: Error loading active campaigns: $error');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingCampaign = false;
      });
    }
  }

  Future<void> _loadQuickDonationAmounts() async {
    try {
      final amounts = await _campaignService.getQuickDonationAmounts();
      if (!mounted) return;
      setState(() {
        _presetAmounts = amounts;
      });
      print(
          'QuickDonate: Successfully loaded ${amounts.length} quick amounts from API');
    } catch (error) {
      print('QuickDonate: Error loading quick amounts, using fallback: $error');
    }
  }

  void _showAnotherCampaign() {
    if (_activeCampaigns.isEmpty) {
      _loadActiveCampaign();
      return;
    }

    if (_activeCampaigns.length == 1) {
      setState(() {
        _selectedCampaign = _activeCampaigns.first;
      });
      return;
    }

    final currentId = _selectedCampaign?.id;
    final shuffledCampaigns = List<Campaign>.from(_activeCampaigns)..shuffle();
    final nextCampaign = shuffledCampaigns.firstWhere(
      (campaign) => campaign.id != currentId,
      orElse: () => shuffledCampaigns.first,
    );

    setState(() {
      _selectedCampaign = nextCampaign;
    });
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  void _onAmountSelected(double amount) {
    setState(() {
      _selectedAmount = amount;
      _isCustomAmount = false;
      _customAmountController.text = amount.toString();
    });
  }

  void _onCustomAmountChanged(String value) {
    if (value.isNotEmpty) {
      setState(() {
        _selectedAmount = double.tryParse(value) ?? 0.0;
        _isCustomAmount = true;
      });
    }
  }

  void _onContinue() {
    if (_selectedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_enter_valid_amount'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedCampaign == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('no_campaigns_available'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _processPayment();
  }

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ احصل على التوكن (اختياري)
      final token = await _getAuthToken();

      // الحصول على origin للمنصة الويب
      final origin = kIsWeb ? Uri.base.origin : AppConfig.serverBaseUrl;

      // الحصول على campaign_id من الحملة المختارة
      final campaignIdString = _selectedCampaign?.id ?? '';
      final campaignId = int.tryParse(campaignIdString);
      if (campaignId == null) {
        _showErrorSnackBar('no_campaigns_available'.tr());
        return;
      }

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
        Uri.parse(AppConfig.donationsWithPaymentEndpoint),
        headers: headers,
        body: jsonEncode({
          'campaign_id': campaignId,
          'amount': _selectedAmount,
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

        print(
            '✅ Payment session created: sessionId=$sessionId, checkoutUrl=$checkoutUrl');

        // التحقق من وجود البيانات المطلوبة
        if (sessionId == null || checkoutUrl == null) {
          throw Exception(
              'Missing payment session data: sessionId=$sessionId, checkoutUrl=$checkoutUrl');
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

      // إعداد headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // إضافة Authorization header فقط إذا كان المستخدم مسجل دخول
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse(AppConfig.paymentsConfirmEndpoint),
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
    final locale = context.locale.languageCode;
    final campaignTitle = _selectedCampaign != null
        ? _selectedCampaign!.getLocalizedTitle(locale)
        : 'quick_donation'.tr();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DonationSuccessScreen(
          amount: _selectedAmount,
          campaignTitle: campaignTitle,
          campaignCategory: campaignTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'quick_donation'.tr(),
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
            // Header Section
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: AppColors.surface,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'choose_donation_amount'.tr(),
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'every_riyal_helps'.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.surface.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.extraLargePadding),

            // Campaign Section
            Text(
              'campaign'.tr(),
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildSelectedCampaignSection(),

            const SizedBox(height: AppConstants.extraLargePadding),

            // Preset Amounts Section
            Text(
              'suggested_amounts'.tr(),
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Preset Amounts Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: _presetAmounts.length,
              itemBuilder: (context, index) {
                final amount = _presetAmounts[index];
                final isSelected =
                    _selectedAmount == amount && !_isCustomAmount;

                return GestureDetector(
                  onTap: () => _onAmountSelected(amount),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.3)
                              : AppColors.textPrimary.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          amount.toStringAsFixed(0),
                          style: AppTextStyles.titleLarge.copyWith(
                            color: isSelected
                                ? AppColors.surface
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'riyal'.tr(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected
                                ? AppColors.surface.withOpacity(0.8)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppConstants.extraLargePadding),

            // Custom Amount Section
            Text(
              'or_enter_custom_amount'.tr(),
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isCustomAmount
                      ? AppColors.primary
                      : AppColors.textPrimary.withOpacity(0.1),
                  width: _isCustomAmount ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _customAmountController,
                onChanged: _onCustomAmountChanged,
                keyboardType: TextInputType.number,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'enter_amount'.tr(),
                  hintStyle: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  suffixText: 'riyal'.tr(),
                  suffixStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.all(AppConstants.largePadding),
                ),
              ),
            ),

            const SizedBox(height: AppConstants.extraLargePadding),

            // Selected Amount Display
            if (_selectedAmount > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.largePadding),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'selected_amount'.tr(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_selectedAmount.toStringAsFixed(0)} ${'riyal'.tr()}',
                      style: AppTextStyles.displaySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.extraLargePadding),
            ],
            // Note about automatic allocation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'important_note'.tr(),
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'donation_redirect_note'.tr(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.3,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.extraLargePadding),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_selectedAmount > 0 &&
                        _selectedCampaign != null &&
                        !_isLoading)
                    ? _onContinue
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_selectedAmount > 0 &&
                          _selectedCampaign != null &&
                          !_isLoading)
                      ? AppColors.primary
                      : AppColors.textSecondary.withOpacity(0.3),
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
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
                          const Icon(Icons.payment, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            (_selectedAmount > 0 && _selectedCampaign != null)
                                ? 'proceed_to_payment'.tr()
                                : (_selectedCampaign == null
                                    ? 'select_campaign_to_continue'.tr()
                                    : 'choose_donation_amount'.tr()),
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

  Widget _buildSelectedCampaignSection() {
    if (_isLoadingCampaign) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.largePadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      );
    }

    if (_campaignError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.largePadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.error.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _campaignError!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: _loadActiveCampaign,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.refresh),
                label: Text('change_campaign'.tr()),
              ),
            ),
          ],
        ),
      );
    }

    final campaign = _selectedCampaign;
    if (campaign == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.largePadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.campaign_outlined,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'no_campaigns_available'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final locale = context.locale.languageCode;
    final campaignTitle = campaign.getLocalizedTitle(locale);
    final campaignDescription = campaign.getLocalizedDescription(locale);
    final progress = campaign.progressPercentage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.campaign,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  campaignTitle,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            campaignDescription,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'raised_amount'.tr()}: ${campaign.currentAmount.toStringAsFixed(0)} ${'riyal'.tr()}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${'target_amount'.tr()}: ${campaign.targetAmount.toStringAsFixed(0)} ${'riyal'.tr()}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'donors_count'.tr()}: ${campaign.donorCount}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              TextButton.icon(
                onPressed: _showAnotherCampaign,
                icon: const Icon(Icons.shuffle),
                label: Text('change_campaign'.tr()),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
