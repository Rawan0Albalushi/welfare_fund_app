import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';

import '../models/campaign.dart';
import '../providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import 'payment_webview.dart';
import 'donation_success_screen.dart';
import 'payment_failed_screen.dart';

class CampaignDonationScreen extends StatefulWidget {
  final Campaign campaign;

  const CampaignDonationScreen({
    super.key,
    required this.campaign,
  });

  @override
  State<CampaignDonationScreen> createState() => _CampaignDonationScreenState();
}

class _CampaignPaymentResult {
  final PaymentState? state;
  final double? amount;
  final String? campaignTitle;
  final String? donationId;
  final String? sessionId;

  const _CampaignPaymentResult({
    this.state,
    this.amount,
    this.campaignTitle,
    this.donationId,
    this.sessionId,
  });

  factory _CampaignPaymentResult.fromNavigatorResult(dynamic result) {
    if (result is Map) {
      final map = Map<String, dynamic>.from(result);
      return _CampaignPaymentResult(
        state: _parseState(map['state']),
        amount: _parseAmount(map['amount']),
        campaignTitle: _asString(map['campaignTitle']) ?? _asString(map['campaign_title']),
        donationId: _asString(map['donationId']) ?? _asString(map['donation_id']),
        sessionId: _asString(map['sessionId']) ?? _asString(map['session_id']),
      );
    }

    if (result is PaymentState) {
      return _CampaignPaymentResult(state: result);
    }

    return const _CampaignPaymentResult();
  }

  static PaymentState? _parseState(dynamic value) {
    if (value is PaymentState) return value;
    if (value is String) {
      for (final state in PaymentState.values) {
        if (state.name == value) return state;
      }
    }
    return null;
  }

  static double? _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.replaceAll(RegExp(r'[^0-9\.\-]'), '');
      return double.tryParse(normalized);
    }
    return null;
  }

  static String? _asString(dynamic value) {
    return value?.toString();
  }
}
class _CampaignDonationScreenState extends State<CampaignDonationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  double _selectedAmount = 0;
  final List<double> _quickAmounts = [50, 100, 200, 500, 1000];
  final TextEditingController _customAmountController = TextEditingController();
  final TextEditingController _donorPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _customAmountController.dispose();
    _donorPhoneController.dispose();
    super.dispose();
  }

  void _selectAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _customAmountController.clear();
    });
  }

  bool _validateAmount() {
    if (_selectedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_choose_donation_amount'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _proceedToDonation() async {
    // Check if campaign is completed
    if (widget.campaign.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('campaign_completed_no_donations'.tr()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (!_validateAmount()) return;

    final provider = context.read<PaymentProvider>();
    final auth = context.read<AuthProvider>();
    final isLoggedIn = auth.isAuthenticated && auth.userProfile != null;
    String? donorPhone = isLoggedIn
        ? (auth.userProfile!['phone']?.toString() ?? auth.userProfile!['user']?['phone']?.toString())
        : _donorPhoneController.text.trim();

    if (!isLoggedIn) {
      if (donorPhone == null || donorPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('please_enter_donor_phone'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      final cleanPhone = donorPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('please_enter_valid_phone'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (cleanPhone.length < 8 || cleanPhone.length > 15) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('phone_must_be_between_8_and_15_digits'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // ابدأ دورة الدفع
    provider.initializePayment(_selectedAmount);

    // استنتاج نوع الهدف (برنامج/حملة) وتحويل المعرف إلى int
    final rawId = widget.campaign.id.toString();
    final parsedId = int.tryParse(rawId);
    int? programId;
    int? campaignId;

    final isProgram = (widget.campaign.type == 'student_program' || widget.campaign.type == 'program');
    if (parsedId != null) {
      if (isProgram) {
        programId = parsedId;
      } else {
        campaignId = parsedId;
      }
    }

    // إنشاء التبرع مع الدفع مباشرة (مع donor_phone للمسجلين)
    await provider.initiateDonationWithPayment(
      amount: _selectedAmount,
      donorName: 'generous_donor'.tr(),
      donorPhone: donorPhone,
      message: 'donation_for_campaign'.tr().replaceAll('{title}', widget.campaign.getLocalizedTitle(context.locale.languageCode)),
      programId: programId,
      campaignId: campaignId,
      note: 'donation_message'.tr(),
    );

    if (provider.state == PaymentState.sessionCreated && provider.paymentUrl != null) {
      // افتح الـ WebView داخل التطبيق
      provider.startPayment();

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebView(
            paymentUrl: provider.paymentUrl!,
            sessionId: provider.currentSessionId!,
          ),
        ),
      );

      final paymentResult = _CampaignPaymentResult.fromNavigatorResult(result);
      final PaymentState? resultState = paymentResult.state;

      // التعامل مع نتيجة الـ WebView
      if (resultState == PaymentState.paymentSuccess || provider.isPaymentSuccessful) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DonationSuccessScreen(
              amount: _selectedAmount,
              campaignTitle: paymentResult.campaignTitle ?? widget.campaign.getLocalizedTitle(context.locale.languageCode),
              campaignCategory: widget.campaign.getLocalizedCategory(context.locale.languageCode),
              donationId: paymentResult.donationId,
              sessionId: paymentResult.sessionId ?? provider.currentSessionId,
            ),
          ),
        );
      } else if (resultState == PaymentState.paymentFailed ||
          resultState == PaymentState.paymentCancelled ||
          resultState == PaymentState.paymentExpired ||
          provider.isPaymentFailed) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentFailedScreen(
              errorMessage: provider.displayErrorMessage,
              campaignTitle: widget.campaign.getLocalizedTitle(context.locale.languageCode),
              amount: _selectedAmount,
            ),
          ),
        );
      } else if (result != null) {
        await provider.checkPaymentStatus();
        if (provider.isPaymentSuccessful) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
            builder: (_) => DonationSuccessScreen(
              amount: _selectedAmount,
              campaignTitle: widget.campaign.getLocalizedTitle(context.locale.languageCode),
              campaignCategory: widget.campaign.getLocalizedCategory(context.locale.languageCode),
            ),
            ),
          );
        } else if (provider.isPaymentFailed) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentFailedScreen(
                errorMessage: provider.displayErrorMessage,
                campaignTitle: widget.campaign.title,
                amount: _selectedAmount,
              ),
            ),
          );
        }
      } else {
        provider.cancelPayment();
      }
    } else {
      // فشل إنشاء الجلسة
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentFailedScreen(
            errorMessage: provider.displayErrorMessage,
            campaignTitle: widget.campaign.title,
            amount: _selectedAmount,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<PaymentProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              // App bar مع صورة الحملة
              SliverAppBar(
                expandedHeight: 350,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      _buildCampaignImage(),
                      Container(
                        width: double.infinity,
                        height: 350,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppColors.primary.withOpacity(0.8)],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(AppConstants.largePadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // شارة التصنيف
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.smallPadding,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.campaign.getLocalizedCategory(context.locale.languageCode),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // العنوان
                              Text(
                                widget.campaign.getLocalizedTitle(context.locale.languageCode),
                                style: AppTextStyles.headlineLarge.copyWith(
                                  color: AppColors.surface,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              // الأرقام
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${widget.campaign.currentAmount.toStringAsFixed(0)} ${'riyal'.tr()}',
                                          style: AppTextStyles.titleLarge.copyWith(
                                            color: AppColors.surface,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          widget.campaign.isCompleted
                                              ? 'campaign_goal_achieved'.tr()
                                              : '${'target_amount'.tr()}: ${widget.campaign.targetAmount.toStringAsFixed(0)} ${'riyal'.tr()}',
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: AppColors.surface.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: widget.campaign.isCompleted
                                          ? AppColors.success
                                          : AppColors.accent,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: widget.campaign.isCompleted
                                          ? [
                                              BoxShadow(
                                                color: AppColors.success.withOpacity(0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (widget.campaign.isCompleted)
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        if (widget.campaign.isCompleted)
                                          const SizedBox(width: 4),
                                        Text(
                                          widget.campaign.isCompleted
                                              ? '${(widget.campaign.progressPercentage * 100).toStringAsFixed(0)}% ${'completed'.tr()}'
                                              : '${(widget.campaign.progressPercentage * 100).toStringAsFixed(1)}%',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.surface,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios, color: AppColors.surface, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // المحتوى
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.largePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // تفاصيل البرنامج
                      _buildSection(
                        title: 'program'.tr(),
                        icon: Icons.info_outline,
                        child: Text(
                          widget.campaign.getLocalizedDescription(context.locale.languageCode),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // إحصائيات
                      _buildSection(
                        title: 'program_statistics'.tr(),
                        icon: Icons.analytics_outlined,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.people_outline,
                                title: 'donors_count'.tr(),
                                value: '${widget.campaign.donorCount}',
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.calendar_today_outlined,
                                title: 'days_remaining'.tr(),
                                value: '${widget.campaign.remainingDays}',
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // اختيار المبلغ (فقط إذا لم تكن الحملة مكتملة)
                      if (!widget.campaign.isCompleted)
                        _buildSection(
                          title: 'select_amount'.tr(),
                          icon: Icons.favorite_outline,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'suggested_amounts'.tr(),
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _quickAmounts.map((amount) {
                                    final isSelected = _selectedAmount == amount;
                                    return Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      child: GestureDetector(
                                        onTap: () => _selectAmount(amount),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.primary : AppColors.surface,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: isSelected ? AppColors.primary : AppColors.textTertiary,
                                              width: 1.5,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: AppColors.primary.withOpacity(0.2),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Text(
                                            '${amount.toStringAsFixed(0)} ${'riyal'.tr()}',
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              color: isSelected ? AppColors.surface : AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'or_enter_custom_amount'.tr(),
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.textTertiary, width: 1.5),
                                ),
                                child: TextField(
                                  controller: _customAmountController,
                                  keyboardType: TextInputType.number,
                                  style: AppTextStyles.bodyLarge,
                                  decoration: InputDecoration(
                                    hintText: 'enter_amount'.tr(),
                                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    suffixText: 'riyal'.tr(),
                                    suffixStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedAmount = double.tryParse(value) ?? 0;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // رقم الهاتف للمتبرعين غير المسجلين فقط
                      Consumer<AuthProvider>(
                        builder: (_, auth, __) {
                          if (auth.isAuthenticated && auth.userProfile != null) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'donor_phone_label'.tr(),
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.textTertiary, width: 1.5),
                                ),
                                child: TextField(
                                  controller: _donorPhoneController,
                                  keyboardType: TextInputType.phone,
                                  style: AppTextStyles.bodyLarge,
                                  decoration: InputDecoration(
                                    hintText: 'enter_your_phone'.tr(),
                                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        },
                      ),

                      // زر التبرع أو حالة الإكمال
                      if (widget.campaign.isCompleted)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.success.withOpacity(0.1),
                                AppColors.success.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.success.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'campaign_completed'.tr(),
                                style: AppTextStyles.headlineSmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'campaign_completed_message'.tr(),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.celebration,
                                      color: AppColors.success,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(widget.campaign.progressPercentage * 100).toStringAsFixed(0)}% ${'goal_achieved'.tr()}',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _proceedToDonation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.surface,
                              elevation: 8,
                              shadowColor: AppColors.primary.withOpacity(0.3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: isLoading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'processing_payment'.tr(),
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.favorite, size: 24),
                                      const SizedBox(width: 12),
                                      Text(
                                        'donate_now'.tr(),
                                        style: AppTextStyles.buttonLarge.copyWith(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // ملاحظة الأمان
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.info.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.security, color: AppColors.info, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'donation_security_notice'.tr(),
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(title, style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textTertiary, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build campaign image widget - use imageUrl directly from backend
  Widget _buildCampaignImage() {
    final imageUrl = widget.campaign.imageUrl.trim();
    
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: 350,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          print('CampaignDonationScreen: Loading image from: $imageUrl');
          return Container(
            width: double.infinity,
            height: 350,
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('CampaignDonationScreen: ERROR loading image from: $imageUrl -> $error');
          return Container(
            width: double.infinity,
            height: 350,
            color: Colors.grey[300],
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 48,
            ),
          );
        },
      );
    }
    
    // Fallback if no image URL
    return Container(
      width: double.infinity,
      height: 350,
      color: Colors.grey[300],
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.grey,
        size: 48,
      ),
    );
  }

}
