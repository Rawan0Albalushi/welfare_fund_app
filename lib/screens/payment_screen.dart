import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

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
    // التحقق من المبلغ
    if (_selectedAmount <= 0) {
      _toast('please_choose_donation_amount_validation'.tr());
      return false;
    }
    
    // حد أدنى للمبلغ (1 ريال)
    const double minAmount = 1.0;
    if (_selectedAmount < minAmount) {
      _toast('${'minimum_amount_is'.tr()} $minAmount ${'riyal'.tr()}');
      return false;
    }
    
    // حد أقصى للمبلغ (100,000 ريال) لحماية من القيم غير المعقولة
    const double maxAmount = 100000.0;
    if (_selectedAmount > maxAmount) {
      _toast('${'maximum_amount_is'.tr()} ${maxAmount.toStringAsFixed(0)} ${'riyal'.tr()}');
      return false;
    }
    
    // التحقق من الاسم
    final donorName = _donorNameController.text.trim();
    if (donorName.isEmpty) {
      _toast('please_enter_donor_name_validation'.tr());
      return false;
    }
    
    // التحقق من طول الاسم (2-100 حرف)
    if (donorName.length < 2) {
      _toast('donor_name_must_be_at_least_2_characters'.tr());
      return false;
    }
    if (donorName.length > 100) {
      _toast('donor_name_too_long'.tr());
      return false;
    }
    
    // التحقق من البريد الإلكتروني
    final email = _donorEmailController.text.trim();
    if (email.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        _toast('please_enter_valid_email_validation_payment'.tr());
        return false;
      }
      // التحقق من طول البريد الإلكتروني
      if (email.length > 255) {
        _toast('email_too_long'.tr());
        return false;
      }
    }
    
    // التحقق من رقم الهاتف (إذا تم إدخاله)
    final phone = _donorPhoneController.text.trim();
    if (phone.isNotEmpty) {
      // إزالة المسافات والرموز للتحقق
      final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      // التحقق من أن الرقم يحتوي على أرقام فقط وطوله معقول (8-15 رقم)
      if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
        _toast('please_enter_valid_phone'.tr());
        return false;
      }
      if (cleanPhone.length < 8 || cleanPhone.length > 15) {
        _toast('phone_must_be_between_8_and_15_digits'.tr());
        return false;
      }
    }
    
    // التحقق من طول الرسالة (إذا تم إدخالها)
    final message = _messageController.text.trim();
    if (message.isNotEmpty && message.length > 500) {
      _toast('message_too_long'.tr());
      return false;
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
    
    if (!mounted) return;

    try {
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

      if (!mounted) return;

      if (provider.state == PaymentState.sessionCreated && provider.paymentUrl != null) {
        // انتقل للـ WebView
        provider.startPayment();

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentWebView(
              paymentUrl: provider.paymentUrl!,
              sessionId: provider.currentSessionId!, // للاحتفاظ به محليًا
            ),
          ),
        );

        print('PaymentScreen: Received result from PaymentWebView: $result');
        final parsedResult = _PaymentFlowResult.fromNavigatorResult(result);
        print('PaymentScreen: Parsed result - state: ${parsedResult.state}, donationId: ${parsedResult.donationId}, sessionId: ${parsedResult.sessionId}, amount: ${parsedResult.amount}, campaignTitle: ${parsedResult.campaignTitle}');
        final PaymentState? resultState = parsedResult.state;

        // التعامل مع النتيجة
        if (resultState == PaymentState.paymentSuccess) {
          if (!mounted) return;
          
          // التحقق الإضافي من الحالة قبل عرض صفحة النجاح
          final sessionId = parsedResult.sessionId ?? provider.currentSessionId;
          if (sessionId != null) {
            try {
              await provider.checkPaymentStatus();
              
              // إذا كانت الحالة pending، لا نعرض صفحة النجاح
              if (provider.isPending) {
                print('PaymentScreen: Payment is still pending, not showing success screen');
                // نعرض رسالة الانتظار بدلاً من ذلك
                _toast('checking_payment_status_please_wait'.tr(), color: AppColors.info);
                return;
              }
              
              // إذا لم تكن الحالة success، لا نعرض صفحة النجاح
              if (!provider.isPaymentSuccessful) {
                print('PaymentScreen: Payment is not successful, not showing success screen');
                return;
              }
            } catch (e) {
              print('PaymentScreen: Error verifying payment status: $e');
              // في حالة الخطأ، نعرض صفحة النجاح بناءً على النتيجة الأصلية
            }
          }
          
          final finalAmount = parsedResult.amount ?? _selectedAmount;
          final finalCampaignTitle = parsedResult.campaignTitle ?? widget.campaignTitle ?? 'charity_donation'.tr();
          final finalDonationId = parsedResult.donationId;
          final finalSessionId = parsedResult.sessionId ?? provider.currentSessionId;
          
          print('PaymentScreen: Navigating to DonationSuccessScreen with:');
          print('  - amount: $finalAmount');
          print('  - campaignTitle: $finalCampaignTitle');
          print('  - donationId: $finalDonationId');
          print('  - sessionId: $finalSessionId');
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DonationSuccessScreen(
                amount: finalAmount,
                campaignTitle: finalCampaignTitle,
                campaignCategory: widget.campaignCategory ?? 'general_donation'.tr(),
                donationId: finalDonationId,
                sessionId: finalSessionId,
              ),
            ),
          );
        } else if (resultState == PaymentState.paymentFailed ||
            resultState == PaymentState.paymentCancelled ||
            resultState == PaymentState.paymentExpired) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentFailedScreen(
                errorMessage: provider.displayErrorMessage,
                campaignTitle: widget.campaignTitle ?? 'charity_donation'.tr(),
                amount: _selectedAmount,
              ),
            ),
          );
        } else if (result != null) {
          // لو رجع شيء غير متوقع، جرّب استعلام الحالة من الباكند
          await provider.checkPaymentStatus();
          if (provider.isPaymentSuccessful) {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DonationSuccessScreen(
                  amount: _selectedAmount,
                  campaignTitle: widget.campaignTitle ?? 'charity_donation'.tr(),
                  campaignCategory: widget.campaignCategory ?? 'general_donation'.tr(),
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
                  campaignTitle: widget.campaignTitle ?? 'charity_donation'.tr(),
                  amount: _selectedAmount,
                ),
              ),
            );
          }
        } else {
          // المستخدم أغلق الشاشة بدون نتيجة واضحة
          provider.cancelPayment();
        }
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentFailedScreen(
              errorMessage: provider.displayErrorMessage,
              campaignTitle: widget.campaignTitle ?? 'charity_donation'.tr(),
              amount: _selectedAmount,
            ),
          ),
        );
      }
    } catch (e) {
      // معالجة الأخطاء بشكل آمن دون تسريب معلومات حساسة
      if (!mounted) return;
      _toast('error_occurred_processing_payment'.tr());
      
      // إعادة تعيين حالة الدفع
      final provider = context.read<PaymentProvider>();
      provider.resetPaymentState();
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
                          'complete_donation'.tr(),
                          style: AppTextStyles.headlineLarge.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'choose_donation_amount_and_enter_your_data'.tr(),
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
                        title: 'choose_donation_amount_title'.tr(),
                        icon: Icons.favorite_outline,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'quick_amounts'.tr(),
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
                              'or_enter_custom_amount_payment'.tr(),
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
                                  hintText: 'enter_amount_in_riyal'.tr(),
                                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  suffixText: 'riyal'.tr(),
                                  suffixStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    final parsed = double.tryParse(value);
                                    // التأكد من أن المبلغ إيجابي
                                    if (parsed != null && parsed >= 0) {
                                      _selectedAmount = parsed;
                                    } else if (value.isEmpty) {
                                      _selectedAmount = 0;
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      _buildSection(
                        title: 'donor_information_title'.tr(),
                        icon: Icons.person_outline,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'donor_name_required'.tr(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _textField(controller: _donorNameController, hint: 'enter_your_full_name'.tr()),
                            const SizedBox(height: 16),

                            Text(
                              'email_optional'.tr(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _textField(
                              controller: _donorEmailController,
                              hint: 'enter_your_email'.tr(),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'phone_optional'.tr(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _textField(
                              controller: _donorPhoneController,
                              hint: 'enter_your_phone'.tr(),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'message_optional'.tr(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _textField(
                              controller: _messageController,
                              hint: 'add_message_with_donation'.tr(),
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
                                          'creating_payment_session'.tr(),
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
                                          'complete_payment'.tr(),
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
                                'all_payments_secure_encrypted'.tr(),
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

class _PaymentFlowResult {
  final PaymentState? state;
  final double? amount;
  final String? campaignTitle;
  final String? donationId;
  final String? sessionId;

  const _PaymentFlowResult({
    this.state,
    this.amount,
    this.campaignTitle,
    this.donationId,
    this.sessionId,
  });

  factory _PaymentFlowResult.fromNavigatorResult(dynamic result) {
    print('_PaymentFlowResult: Parsing result, type: ${result.runtimeType}');
    
    if (result is Map) {
      final map = Map<String, dynamic>.from(result as Map);
      print('_PaymentFlowResult: Map keys: ${map.keys.toList()}');
      print('_PaymentFlowResult: Map values - state: ${map['state']}, donationId: ${map['donationId']}, donation_id: ${map['donation_id']}, sessionId: ${map['sessionId']}, session_id: ${map['session_id']}, amount: ${map['amount']}');
      
      final parsed = _PaymentFlowResult(
        state: _parseState(map['state']),
        amount: _parseAmount(map['amount']),
        campaignTitle: _extractString(map['campaignTitle']) ?? _extractString(map['campaign_title']),
        donationId: _extractString(map['donationId']) ?? _extractString(map['donation_id']),
        sessionId: _extractString(map['sessionId']) ?? _extractString(map['session_id']),
      );
      
      print('_PaymentFlowResult: Parsed result - state: ${parsed.state}, donationId: ${parsed.donationId}, sessionId: ${parsed.sessionId}, amount: ${parsed.amount}');
      return parsed;
    }

    if (result is PaymentState) {
      print('_PaymentFlowResult: Result is PaymentState: $result');
      return _PaymentFlowResult(state: result);
    }

    print('_PaymentFlowResult: Result is null or unknown type, returning empty result');
    return const _PaymentFlowResult();
  }

  static PaymentState? _parseState(dynamic value) {
    if (value is PaymentState) {
      return value;
    }
    if (value is String) {
      for (final state in PaymentState.values) {
        if (state.name == value) {
          return state;
        }
      }
    }
    return null;
  }

  static double? _parseAmount(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final normalized = value.replaceAll(RegExp(r'[^0-9\.\-]'), '');
      return double.tryParse(normalized);
    }
    return null;
  }

  static String? _extractString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }
}
