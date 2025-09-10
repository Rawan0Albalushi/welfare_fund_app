import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';

import '../providers/payment_provider.dart';
import 'payment_webview.dart';
import 'donation_success_screen.dart';
import 'payment_failed_screen.dart';

class PaymentScreen extends StatefulWidget {
  final double initialAmount;
  final String? campaignTitle;
  final String? campaignCategory;
  final String? itemId;     // معرف البرنامج/الحملة كسلسلة
  final String? itemType;   // 'program' | 'campaign'

  const PaymentScreen({
    super.key,
    required this.initialAmount,
    this.campaignTitle,
    this.campaignCategory,
    this.itemId,
    this.itemType,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  double _selectedAmount = 0;
  final List<double> _quickAmounts = [50, 100, 200, 500, 1000];

  final TextEditingController _customAmountController = TextEditingController();
  final TextEditingController _donorNameController = TextEditingController();
  final TextEditingController _donorEmailController = TextEditingController();
  final TextEditingController _donorPhoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedAmount = widget.initialAmount;
    if (_selectedAmount > 0) {
      _customAmountController.text = _selectedAmount.toString();
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _customAmountController.dispose();
    _donorNameController.dispose();
    _donorEmailController.dispose();
    _donorPhoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _selectAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _customAmountController.clear();
    });
  }

  bool _validateForm() {
    if (_selectedAmount <= 0) {
      _toast('يرجى اختيار مبلغ للتبرع');
      return false;
    }
    if (_donorNameController.text.trim().isEmpty) {
      _toast('يرجى إدخال اسم المتبرع');
      return false;
    }
    final email = _donorEmailController.text.trim();
    if (email.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        _toast('يرجى إدخال بريد إلكتروني صحيح');
        return false;
      }
    }
    return true;
  }

  void _toast(String msg, {Color color = AppColors.error}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _proceedToPayment() async {
    if (!_validateForm()) return;

    final provider = context.read<PaymentProvider>();

    // ابدأ دورة الدفع بقيمة المبلغ
    provider.initializePayment(_selectedAmount);

    // حوّلي itemId إلى int حسب النوع
    int? programId;
    int? campaignId;
    final rawId = widget.itemId ?? '';
    final parsedId = int.tryParse(rawId);
    if (parsedId != null) {
      if (widget.itemType == 'program') programId = parsedId;
      if (widget.itemType == 'campaign') campaignId = parsedId;
    }

    // إنشاء التبرع مع الدفع مباشرة
    await provider.initiateDonationWithPayment(
      amount: _selectedAmount,
      donorName: _donorNameController.text.trim(),
      donorEmail: _donorEmailController.text.trim().isNotEmpty ? _donorEmailController.text.trim() : null,
      donorPhone: _donorPhoneController.text.trim().isNotEmpty ? _donorPhoneController.text.trim() : null,
      message: _messageController.text.trim().isNotEmpty ? _messageController.text.trim() : null,
      itemId: widget.itemId,
      itemType: widget.itemType,
      programId: programId,
      campaignId: campaignId,
      note: _messageController.text.trim().isNotEmpty ? _messageController.text.trim() : null,
    );

    if (provider.state == PaymentState.sessionCreated && provider.paymentUrl != null) {
      // انتقل للـ WebView
      provider.startPayment();

      final result = await Navigator.push<PaymentState>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebView(
            paymentUrl: provider.paymentUrl!,
            sessionId: provider.currentSessionId!, // للاحتفاظ به محليًا
          ),
        ),
      );

      // التعامل مع النتيجة
      if (result == PaymentState.paymentSuccess) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DonationSuccessScreen(
              amount: _selectedAmount,
              campaignTitle: widget.campaignTitle ?? 'تبرع خيري',
              campaignCategory: widget.campaignCategory ?? 'تبرع عام',
            ),
          ),
        );
      } else if (result == PaymentState.paymentFailed ||
          result == PaymentState.paymentCancelled ||
          result == PaymentState.paymentExpired) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentFailedScreen(
              errorMessage: provider.displayErrorMessage,
              campaignTitle: widget.campaignTitle ?? 'تبرع خيري',
              amount: _selectedAmount,
            ),
          ),
        );
      } else {
        // لو رجع شيء غير متوقع، جرّب استعلام الحالة من الباكند
        await provider.checkPaymentStatus();
        if (provider.isPaymentSuccessful) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DonationSuccessScreen(
                amount: _selectedAmount,
                campaignTitle: widget.campaignTitle ?? 'تبرع خيري',
                campaignCategory: widget.campaignCategory ?? 'تبرع عام',
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
                campaignTitle: widget.campaignTitle ?? 'تبرع خيري',
                amount: _selectedAmount,
              ),
            ),
          );
        }
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentFailedScreen(
            errorMessage: provider.displayErrorMessage,
            campaignTitle: widget.campaignTitle ?? 'تبرع خيري',
            amount: _selectedAmount,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment, size: 48, color: AppColors.surface),
                          const SizedBox(height: 16),
                          Text(
                            'إتمام التبرع',
                            style: AppTextStyles.headlineLarge.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اختر مبلغ التبرع وأدخل بياناتك',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.surface.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
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

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.largePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        title: 'اختر مبلغ التبرع',
                        icon: Icons.favorite_outline,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مبالغ سريعة',
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
                                          '${amount.toStringAsFixed(0)} ريال',
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
                              'أو أدخل مبلغاً مخصصاً',
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
                                  hintText: 'أدخل المبلغ بالريال',
                                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  suffixText: 'ريال',
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

                      const SizedBox(height: 32),

                      _buildSection(
                        title: 'معلومات المتبرع',
                        icon: Icons.person_outline,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'اسم المتبرع *',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _textField(controller: _donorNameController, hint: 'أدخل اسمك الكامل'),
                            const SizedBox(height: 16),

                            Text(
                              'البريد الإلكتروني (اختياري)',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _textField(
                              controller: _donorEmailController,
                              hint: 'أدخل بريدك الإلكتروني',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'رقم الهاتف (اختياري)',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _textField(
                              controller: _donorPhoneController,
                              hint: 'أدخل رقم هاتفك',
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'رسالة (اختياري)',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _textField(
                              controller: _messageController,
                              hint: 'أضف رسالة مع تبرعك',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      Consumer<PaymentProvider>(
                        builder: (_, provider, __) {
                          final isLoading = provider.isLoading;
                          return SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _proceedToPayment,
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
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface)),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'جاري إنشاء جلسة الدفع...',
                                          style: AppTextStyles.buttonLarge.copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.payment, size: 24),
                                        const SizedBox(width: 12),
                                        Text(
                                          'إتمام الدفع',
                                          style: AppTextStyles.buttonLarge.copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

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
                                'جميع المدفوعات آمنة ومشفرة. بياناتك محمية بنسبة 100%',
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

  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
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

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textTertiary, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
