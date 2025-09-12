import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../services/donation_service.dart';
import '../providers/auth_provider.dart';
import 'my_donations_screen.dart';
// WebView web platform registration (for Flutter Web)
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;

class DonationSuccessScreen extends StatefulWidget {
  final double? amount;
  final String? campaignTitle;
  final String? campaignCategory;
  final String? donationId;
  final String? sessionId;

  const DonationSuccessScreen({
    super.key,
    this.amount,
    this.campaignTitle,
    this.campaignCategory,
    this.donationId,
    this.sessionId,
  });

  @override
  State<DonationSuccessScreen> createState() => _DonationSuccessScreenState();
}

class _DonationSuccessScreenState extends State<DonationSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _checkmarkController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkmarkAnimation;
  
  final DonationService _donationService = DonationService();
  
  // متغيرات للبيانات المستخرجة من URL
  String? _donationId;
  String? _sessionId;
  double? _amount;
  String? _campaignTitle;

  @override
  void initState() {
    super.initState();
    
    // استخراج query parameters من URL
    _extractQueryParameters();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _checkmarkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkmarkController,
      curve: Curves.easeInOut,
    ));
    
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _animationController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _checkmarkController.forward();
  }

  void _extractQueryParameters() {
    try {
      // استخراج query parameters من URL
      final uri = Uri.base;
      _donationId = uri.queryParameters['donation_id'];
      _sessionId = uri.queryParameters['session_id'];
      
      // استخراج المبلغ إذا كان متوفراً
      final amountStr = uri.queryParameters['amount'];
      if (amountStr != null) {
        _amount = double.tryParse(amountStr);
        print('DonationSuccessScreen: Parsed amount from URL: $_amount');
      }
      
      // استخراج عنوان الحملة إذا كان متوفراً
      _campaignTitle = uri.queryParameters['campaign_title'];
      
      print('DonationSuccessScreen: donation_id = $_donationId');
      print('DonationSuccessScreen: session_id = $_sessionId');
      print('DonationSuccessScreen: amount = $_amount');
      print('DonationSuccessScreen: campaign_title = $_campaignTitle');
      
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
      
      print('DonationSuccessScreen: Fetching donation details for $_donationId');
      
      // استدعاء API للحصول على تفاصيل التبرع
      final response = await _donationService.checkDonationStatus(_donationId!);
      
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data != null) {
          setState(() {
            _amount = (data['amount'] as num?)?.toDouble();
            _campaignTitle = data['campaign_title'] as String?;
          });
          
          print('DonationSuccessScreen: Fetched amount: $_amount');
          print('DonationSuccessScreen: Fetched campaign title: $_campaignTitle');
        }
      } else {
        print('DonationSuccessScreen: Failed to fetch donation details - user may not be authenticated');
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
      print('DonationSuccessScreen: Error fetching donation details: $e');
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
  void dispose() {
    _animationController.dispose();
    _checkmarkController.dispose();
    super.dispose();
  }

  void _goToHome() {
    // للويب، غير URL في المتصفح
    if (kIsWeb) {
      html.window.history.pushState(null, '', '/');
    }
    
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppConstants.homeRoute,
      (route) => false,
    );
  }
  
  void _goToMyDonations() {
    // للويب، نظف URL في المتصفح
    if (kIsWeb) {
      html.window.history.pushState(null, '', '/my-donations');
    }
    
    Navigator.of(context).popUntil((route) => route.isFirst);
    // Navigate to My Donations screen with force refresh
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyDonationsScreen(forceRefresh: true),
      ),
    );
  }
  
  Future<void> _refreshDonationsData() async {
    try {
      // Force refresh donations data by calling the API
      await _donationService.getUserDonations();
      print('DonationSuccessScreen: Donations data refreshed successfully');
    } catch (e) {
      print('DonationSuccessScreen: Error refreshing donations data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            children: [
              const SizedBox(height: AppConstants.extraLargePadding),
              
              // Success Animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.success,
                        AppColors.success.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _checkmarkAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _checkmarkAnimation.value,
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 48,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.extraLargePadding),

              // Success Message
              Text(
                'تم التبرع بنجاح!',
                style: AppTextStyles.displaySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'شكراً لك على مساهمتك في مساعدة الطلاب المحتاجين',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppConstants.extraLargePadding),

              // Donation Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.largePadding),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.textPrimary.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'مبلغ التبرع',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${(_amount ?? widget.amount ?? 0.0).toStringAsFixed(2)} ريال عماني',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Campaign Info (if available)
                    if ((_campaignTitle ?? widget.campaignTitle) != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'البرنامج',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _campaignTitle ?? widget.campaignTitle ?? '',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Donation ID (if available)
                    if (_donationId != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'رقم التبرع',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _donationId!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تاريخ التبرع',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          DateTime.now().toString().substring(0, 10),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Transaction ID
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'رقم المعاملة',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.extraLargePadding),

              // Impact Message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.largePadding),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.volunteer_activism,
                      color: AppColors.success,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'تأثير تبرعك',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تبرعك سيساعد في توفير التعليم والاحتياجات الأساسية للطلاب المحتاجين',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.extraLargePadding),

              // Action Buttons
              Column(
                children: [
                  // View My Donations Button (only for logged in users)
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.isAuthenticated) {
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await _refreshDonationsData();
                              _goToMyDonations();
                            },
                            icon: const Icon(Icons.favorite, size: 20),
                            label: Text(
                              'عرض تبرعاتي',
                              style: AppTextStyles.buttonLarge.copyWith(
                                color: AppColors.surface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: AppColors.surface,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              shadowColor: AppColors.success.withOpacity(0.3),
                            ),
                          ),
                        );
                      } else {
                        // لا تعرض الزر للمستخدمين غير المسجلين
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Back to Home Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _goToHome,
                      icon: const Icon(Icons.home, size: 20),
                      label: Text(
                        'العودة للرئيسية',
                        style: AppTextStyles.buttonLarge.copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.extraLargePadding),

              // Thank You Message
              Container(
                padding: const EdgeInsets.all(AppConstants.largePadding),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.textPrimary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'شكراً لك على ثقتك بنا',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'سنواصل العمل لمساعدة الطلاب المحتاجين',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.extraLargePadding),
            ],
          ),
        ),
      ),
    );
  }
} 