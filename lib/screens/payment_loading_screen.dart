import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html show window;
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import 'donation_success_screen.dart';
import 'payment_failed_screen.dart';

class PaymentLoadingScreen extends StatefulWidget {
  const PaymentLoadingScreen({super.key});

  @override
  State<PaymentLoadingScreen> createState() => _PaymentLoadingScreenState();
}

class _PaymentLoadingScreenState extends State<PaymentLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _startAnimations();
    _checkPaymentStatus();
  }

  void _startAnimations() {
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  void _checkPaymentStatus() async {
    // تهيئة AuthProvider أولاً للحفاظ على حالة المصادقة
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();
      print('PaymentLoadingScreen: AuthProvider initialized successfully');
    } catch (e) {
      print('PaymentLoadingScreen: Error initializing AuthProvider: $e');
    }
    
    if (kIsWeb) {
      try {
        final currentPath = html.window.location.pathname;
        final queryParams = Uri.base.queryParameters;
        
        print('PaymentLoadingScreen: Checking payment status');
        print('PaymentLoadingScreen: Current path: $currentPath');
        print('PaymentLoadingScreen: Query params: $queryParams');
        
        // محاكاة loading لمدة 2-3 ثواني
        await Future.delayed(const Duration(seconds: 2));
        
        if (!mounted) return;
        
        if (currentPath?.contains('/payment/success') == true) {
          print('PaymentLoadingScreen: Redirecting to payment success screen');
          _navigateToPaymentSuccess(queryParams);
        } else if (currentPath?.contains('/payment/cancel') == true) {
          print('PaymentLoadingScreen: Redirecting to payment cancel screen');
          _navigateToPaymentCancel(queryParams);
        } else {
          // إذا لم يكن payment redirect، اذهب للصفحة الرئيسية
          _navigateToHome();
        }
      } catch (e) {
        print('PaymentLoadingScreen: Error checking payment status: $e');
        if (mounted) {
          _navigateToHome();
        }
      }
    } else {
      // للمنصات غير الويب، اذهب للصفحة الرئيسية
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _navigateToHome();
      }
    }
  }

  void _navigateToPaymentSuccess(Map<String, String> queryParams) {
    final donationId = queryParams['donation_id'];
    final sessionId = queryParams['session_id'];
    final amount = double.tryParse(queryParams['amount'] ?? '0');
    final campaignTitle = queryParams['campaign_title'];
    
    print('PaymentLoadingScreen: Payment success params - donationId: $donationId, amount: $amount');
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => DonationSuccessScreen(
          donationId: donationId,
          sessionId: sessionId,
          amount: amount,
          campaignTitle: campaignTitle,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: AppConstants.pageTransitionDuration,
      ),
    );
  }

  void _navigateToPaymentCancel(Map<String, String> queryParams) {
    final donationId = queryParams['donation_id'];
    final sessionId = queryParams['session_id'];
    final amount = double.tryParse(queryParams['amount'] ?? '0');
    final campaignTitle = queryParams['campaign_title'];
    final errorMessage = queryParams['error_message'];
    
    print('PaymentLoadingScreen: Payment cancel params - donationId: $donationId, amount: $amount');
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PaymentFailedScreen(
          donationId: donationId,
          sessionId: sessionId,
          amount: amount,
          campaignTitle: campaignTitle,
          errorMessage: errorMessage,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: AppConstants.pageTransitionDuration,
      ),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.modernGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Loading Animation
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(60),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _rotationAnimation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotationAnimation.value * 2 * 3.14159,
                                child: const Icon(
                                  Icons.payment,
                                  size: 50,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Loading Text
                const Text(
                  'جاري معالجة الدفع...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.surface,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'يرجى الانتظار قليلاً',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.surface.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Progress Indicator
                Container(
                  width: 200,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 200 * _pulseAnimation.value * 0.3,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
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
