import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import 'home_screen.dart';
import 'donation_success_screen.dart';
import 'payment_failed_screen.dart';
import '../services/payment_service.dart';
import '../services/browser_url_service_stub.dart'
  if (dart.library.html) '../services/browser_url_service_web.dart';
import '../utils/redirect_utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _navigated = false;
  final BrowserUrlService _browserUrl = BrowserUrlServiceImpl();

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: AppConstants.splashFadeDuration,
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: AppConstants.splashSlideDuration,
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: AppConstants.splashScaleDuration,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _initializeFirebaseMessaging();
    _startAnimations();
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // request permission for notifications
      await messaging.requestPermission();

      // get device token
      final token = await messaging.getToken();
      print('📱 FCM TOKEN: $token');

      // listen for notifications while app is open
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📩 Foreground notification: ${message.notification?.title}');
      });

      // Send FCM token to API if user is authenticated
      if (token != null) {
        await _sendFcmTokenToApi(token);
      }
    } catch (e) {
      print('Error initializing Firebase Messaging: $e');
    }
  }

  Future<void> _sendFcmTokenToApi(String fcmToken) async {
    try {
      // Check if user is authenticated
      final apiClient = ApiClient();
      final isAuthenticated = await apiClient.isAuthenticated();
      
      if (!isAuthenticated) {
        print('⚠️ User not authenticated, skipping FCM token registration');
        return;
      }

      // Get device ID
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;
      String platform;
      
      if (kIsWeb) {
        // Web platform
        final webInfo = await deviceInfo.webBrowserInfo;
        deviceId = webInfo.vendor ?? 'unknown';
        platform = 'web';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        platform = 'android';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        platform = 'ios';
      } else {
        deviceId = 'unknown';
        platform = 'unknown';
      }

      // Send to API
      await apiClient.sendFcmToken(
        deviceId: deviceId,
        fcmToken: fcmToken,
        platform: platform,
      );
      
      print('✅ FCM token sent to API successfully');
    } catch (e) {
      print('❌ Error sending FCM token to API: $e');
      // Don't throw - FCM token registration failure shouldn't break the app
    }
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _slideController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _scaleController.forward();

    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();

    if (!mounted) return;
    _checkForPaymentRedirect();
  }
  
  void _checkForPaymentRedirect() {
    if (kIsWeb) {
      try {
        final uri = Uri.base;
        final redirect = parsePaymentRedirect(uri);

        if (redirect.type == PaymentRedirectType.success) {
          _navigated = true;
          _browserUrl.cleanQuery();
          _navigateToPaymentSuccess(redirect.queryParams);
          return;
        }

        if (redirect.type == PaymentRedirectType.cancel) {
          _navigated = true;
          _browserUrl.cleanQuery();
          _navigateToPaymentCancel(redirect.queryParams);
          return;
        }
      } catch (error, stackTrace) {
        debugPrint('SplashScreen: Error checking payment redirect: $error');
        debugPrint('$stackTrace');
      }
    }
    
    // Navigate to home after animations complete
    Future.delayed(AppConstants.splashToHomeDelay, () {
      if (mounted && !_navigated) {
        _navigateToHome();
      }
    });
  }
  
  Future<void> _navigateToPaymentSuccess(Map<String, String> queryParams) async {
    if (!mounted) return;

    final donationId = queryParams['donation_id'];
    final sessionId = queryParams['session_id'];
    final amount = double.tryParse(queryParams['amount'] ?? '');
    final campaignTitle = queryParams['campaign_title'];
    
    // Basic validation
    if (sessionId == null || sessionId.isEmpty || amount == null || !amount.isFinite || amount <= 0) {
      return _navigateToPaymentCancel({
        ...queryParams,
        'error_message': 'payment.invalidData'.tr(),
      });
    }
    
    // Optional server verification if sessionId is present (guaranteed non-null above)
    final verifiedSessionId = sessionId;
    if (verifiedSessionId.isNotEmpty) {
      try {
        final status = await PaymentService().checkPaymentStatus(verifiedSessionId);
        if (!mounted) return;
        if (!(status.isCompleted)) {
          // If not completed, fallback to failure route with friendly message
          return _navigateToPaymentCancel({
            ...queryParams,
            'error_message': status.message ?? status.error ?? 'payment.notCompleted'.tr(),
          });
        }
      } catch (e) {
        // On verification error, proceed but prefer failure screen
        if (!mounted) return;
        return _navigateToPaymentCancel({
          ...queryParams,
          'error_message': 'payment.verifyError'.tr(),
        });
      }
    }
    
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
  
  Future<void> _navigateToPaymentCancel(Map<String, String> queryParams) async {
    if (!mounted) return;

    final donationId = queryParams['donation_id'];
    final sessionId = queryParams['session_id'];
    final amount = double.tryParse(queryParams['amount'] ?? '');
    final campaignTitle = queryParams['campaign_title'];
    final errorMessage = queryParams['error_message'];
    
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

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: AppConstants.pageTransitionDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.modernGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background decorative elements
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface.withOpacity(0.05),
                  ),
                ),
              ),
              
              // Main content
              Padding(
                padding: const EdgeInsets.all(AppConstants.extraLargePadding),
                child: Column(
                  children: [
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Modern logo with enhanced styling
                                  Semantics(
                                    label: 'splash.logoLabel'.tr(),
                                    image: true,
                                    child: Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(70),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withOpacity(0.3),
                                            blurRadius: 30,
                                            offset: const Offset(0, 15),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.favorite,
                                        size: 70,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  Text(
                                    'splash.title'.tr(), // 'تبرع معنا'
                                    style: const TextStyle(
                                      fontFamily: 'Calibri',
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.surface,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'splash.subtitle'.tr(), // 'تصنع الفرق، تبرعاً تلو الآخر'
                                    style: TextStyle(
                                      fontFamily: 'Calibri',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.surface.withOpacity(0.8),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Welcome message and button
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppConstants.largePadding),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(AppConstants.largeRadius),
                                border: Border.all(
                                  color: AppColors.surface.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'splash.welcome'.tr(), // 'مرحباً بك في منصة التبرعات'
                                    style: const TextStyle(
                                      fontFamily: 'Calibri',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.surface,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'splash.description'.tr(), // 'نساعد المحتاجين من خلال تبرعات المجتمع'
                                    style: TextStyle(
                                      fontFamily: 'Calibri',
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: AppColors.surface.withOpacity(0.9),
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppConstants.extraLargePadding),
                            
                            // Modern button with glass effect
                            Container(
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _navigated ? null : () {
                                    _navigated = true;
                                    _navigateToHome();
                                  },
                                  borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                                  child: Semantics(
                                    button: true,
                                    enabled: !_navigated,
                                    label: 'splash.startNow'.tr(),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'splash.startNow'.tr(), // 'ابدأ الآن'
                                            style: const TextStyle(
                                              fontFamily: 'Calibri',
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 