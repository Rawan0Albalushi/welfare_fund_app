import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';

import '../models/campaign.dart';
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

class _CampaignDonationScreenState extends State<CampaignDonationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  double _selectedAmount = 0;
  final List<double> _quickAmounts = [50, 100, 200, 500, 1000];
  final TextEditingController _customAmountController = TextEditingController();

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
    if (!_validateAmount()) return;

    final provider = context.read<PaymentProvider>();

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

    // إنشاء التبرع مع الدفع مباشرة
    await provider.initiateDonationWithPayment(
      amount: _selectedAmount,
      donorName: 'generous_donor'.tr(),
      message: 'donation_for_campaign'.tr().replaceAll('{title}', widget.campaign.title),
      programId: programId,
      campaignId: campaignId,
      note: 'donation_message'.tr(),
    );

    if (provider.state == PaymentState.sessionCreated && provider.paymentUrl != null) {
      // افتح الـ WebView داخل التطبيق
      provider.startPayment();

      final result = await Navigator.push<PaymentState>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebView(
            paymentUrl: provider.paymentUrl!,
            sessionId: provider.currentSessionId!,
          ),
        ),
      );

      // التعامل مع نتيجة الـ WebView
      if (result == PaymentState.paymentSuccess || provider.isPaymentSuccessful) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DonationSuccessScreen(
              amount: _selectedAmount,
              campaignTitle: widget.campaign.title,
              campaignCategory: widget.campaign.category,
            ),
          ),
        );
      } else if (result == PaymentState.paymentFailed ||
          result == PaymentState.paymentCancelled ||
          result == PaymentState.paymentExpired ||
          provider.isPaymentFailed) {
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
      } else {
        // حالة غير متوقعة — تحقّق من الحالة من الباكند
        await provider.checkPaymentStatus();
        if (provider.isPaymentSuccessful) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DonationSuccessScreen(
                amount: _selectedAmount,
                campaignTitle: widget.campaign.title,
                campaignCategory: widget.campaign.category,
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
                expandedHeight: 300,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(_getCampaignImage(widget.campaign.category)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppColors.primary.withOpacity(0.8)],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
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
                                  widget.campaign.category,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // العنوان
                              Text(
                                widget.campaign.title,
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
                                          '${'target_amount'.tr()}: ${widget.campaign.targetAmount.toStringAsFixed(0)} ${'riyal'.tr()}',
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
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${(widget.campaign.progressPercentage * 100).toStringAsFixed(1)}%',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.surface,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                          widget.campaign.description,
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

                      // اختيار المبلغ
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
                      const SizedBox(height: 40),

                      // زر التبرع
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

  String _getCampaignImage(String category) {
    switch (category) {
      case 'فرص التعليم':
        return 'https://images.pexels.com/photos/8613318/pexels-photo-8613318.jpeg?auto=compress&cs=tinysrgb&w=800';
    case 'السكن والنقل':
        return 'https://images.pexels.com/photos/271816/pexels-photo-271816.jpeg?auto=compress&cs=tinysrgb&w=800';
      case 'الإعانة الشهرية':
        return 'https://images.pexels.com/photos/4386375/pexels-photo-4386375.jpeg?auto=compress&cs=tinysrgb&w=800';
      case 'شراء أجهزة':
        return 'https://images.pexels.com/photos/1181671/pexels-photo-1181671.jpeg?auto=compress&cs=tinysrgb&w=800';
      case 'رسوم الاختبارات':
        return 'https://images.pexels.com/photos/4145195/pexels-photo-4145195.jpeg?auto=compress&cs=tinysrgb&w=800';
      default:
        return 'https://images.pexels.com/photos/5905708/pexels-photo-5905708.jpeg?auto=compress&cs=tinysrgb&w=800';
    }
  }
}
