import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../constants/app_colors.dart';
import '../constants/app_config.dart';
import '../constants/app_text_styles.dart';
import '../providers/auth_provider.dart';

class PhoneOtpVerifyScreen extends StatefulWidget {
  final String verifyId;
  final String phone;
  final String? maskedPhone;
  /// في بيئة التطوير: إذا الباكند أرسل الرمز في الاستجابة (otp / dev_otp / debug_otp) نعرضه هنا للاختبار
  final String? devOtp;

  const PhoneOtpVerifyScreen({
    super.key,
    required this.verifyId,
    required this.phone,
    this.maskedPhone,
    this.devOtp,
  });

  @override
  State<PhoneOtpVerifyScreen> createState() => _PhoneOtpVerifyScreenState();
}

class _PhoneOtpVerifyScreenState extends State<PhoneOtpVerifyScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isResending = false;
  String _currentVerifyId = '';
  String? _fetchedDevOtp;

  @override
  void initState() {
    super.initState();
    _currentVerifyId = widget.verifyId;
    if (AppConfig.isLocalConnection && (widget.devOtp == null || widget.devOtp!.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDevOtp());
    }
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// Masks phone so only last 4 digits show, e.g. ****9633
  static String _maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '****';
    if (digits.length <= 4) return '****' + digits;
    return '****' + digits.substring(digits.length - 4);
  }

  /// Always show phone as ****XXXX (last 4 digits only)
  String get _displayPhone => _maskPhone(widget.phone);

  Future<void> _fetchDevOtp() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final otp = await authProvider.getDevOtp(_currentVerifyId);
      if (mounted && otp != null && otp.isNotEmpty) {
        setState(() => _fetchedDevOtp = otp);
      }
    } catch (_) {}
  }

  String? get _effectiveDevOtp => _fetchedDevOtp ?? widget.devOtp;

  Widget _buildDevOtpHint() {
    final hasDevOtp = _effectiveDevOtp != null && _effectiveDevOtp!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report_outlined, size: 20, color: AppColors.info),
              const SizedBox(width: 8),
              Text(
                'otp_dev_mode'.tr(),
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasDevOtp) ...[
            Text(
              'otp_dev_code_label'.tr(),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _effectiveDevOtp!,
                    style: AppTextStyles.titleMedium.copyWith(
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    _otpController.text = _effectiveDevOtp!;
                    setState(() {});
                  },
                  icon: const Icon(Icons.touch_app, size: 18),
                  label: Text('otp_use_this_code'.tr()),
                ),
              ],
            ),
          ] else
            Text(
              'otp_dev_check_logs'.tr(),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Future<void> _handleVerify() async {
    if (_formKey.currentState?.validate() != true) return;
    final code = _otpController.text.trim();
    if (code.length != 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'otp_must_be_6_digits'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.verifyPhoneOtp(_currentVerifyId, code);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'phone_verified_successfully'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'invalid_verification_code'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      final displayMessage = message.contains(' ')
          ? message
          : message.tr();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            displayMessage,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.surface),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _handleResend() async {
    setState(() => _isResending = true);
    HapticFeedback.lightImpact();

    try {
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.resendOtp(widget.phone);
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _currentVerifyId = result['verifyId'] as String;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'otp_resent'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.surface),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResending = false);
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      final displayMessage = message.contains(' ') ? message : message.tr();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            displayMessage,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.surface),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  centerTitle: true,
                  iconTheme: const IconThemeData(color: AppColors.surface),
                  leading: IconButton(
                    icon: Icon(
                      isRtl ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                      color: AppColors.surface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    'verify_phone'.tr(),
                    style: AppTextStyles.appBarTitleDark,
                  ),
                  flexibleSpace: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.modernGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.surfaceVariant,
                            width: 1,
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.modernGradient,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'otp_enter_code'.tr(),
                                      style: AppTextStyles.headlineSmall
                                          .copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'otp_sent_to'.tr().replaceAll(
                                  '{0}',
                                  '\u2068$_displayPhone\u2069', // LTR isolate so number shows as ****9633 in RTL
                                ),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (AppConfig.isLocalConnection) ...[
                                const SizedBox(height: 16),
                                _buildDevOtpHint(),
                                const SizedBox(height: 16),
                              ],
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 6,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: AppTextStyles.headlineMedium.copyWith(
                                  letterSpacing: 8,
                                ),
                                decoration: InputDecoration(
                                  hintText: '••••••',
                                  hintStyle: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.textTertiary,
                                    letterSpacing: 8,
                                  ),
                                  counterText: '',
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.sms_outlined,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.surfaceVariant,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.surfaceVariant,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.error,
                                      width: 1.5,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.background,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.length != 6) {
                                    return 'otp_must_be_6_digits'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: AppColors.modernGradient,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: _isLoading ? null : _handleVerify,
                                      child: Center(
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  color: AppColors.surface,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.verified_user_outlined,
                                                    color: AppColors.surface,
                                                    size: 24,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    'verify'.tr(),
                                                    style: AppTextStyles
                                                        .buttonLarge
                                                        .copyWith(
                                                      color: AppColors.surface,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: TextButton(
                                  onPressed: _isResending ? null : _handleResend,
                                  child: _isResending
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : Text(
                                          'resend_code'.tr(),
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
