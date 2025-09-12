import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// WebView web platform registration (for Flutter Web)
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window; // safe import for web check
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'constants/app_colors.dart';
import 'constants/app_text_styles.dart';
import 'constants/app_constants.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/donation_success_screen.dart';
import 'screens/payment_failed_screen.dart';
import 'screens/payment_loading_screen.dart';
import 'services/auth_service.dart';
import 'services/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/payment_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Register web implementation for webview_flutter when running on web
  try {
    // A simple runtime check: if 'window' exists, we're on web
    // ignore: unnecessary_null_comparison
    if (html.window != null) {
      WebViewPlatform.instance = WebWebViewPlatform();
    }
  } catch (_) {
    // Not running on web; ignore
  }
  
  try {
    // Initialize API Client
    await ApiClient().initialize();
    print('API Client initialized successfully');
    
    // Initialize Auth Service
    await AuthService().initialize();
    print('Auth Service initialized successfully');
  } catch (e) {
    print('Error during initialization: $e');
  }
  
  runApp(const StudentWelfareFundApp());
}

class StudentWelfareFundApp extends StatelessWidget {
  const StudentWelfareFundApp({super.key});

  // تحديد الـ route الأولي بناءً على URL الحالي
  String _getInitialRoute() {
    try {
      // للويب، تحقق من URL الحالي
      final currentPath = html.window.location.pathname;
      print('Current URL path: $currentPath');
      
      // إذا كان URL يحتوي على payment/success أو payment/cancel
      // ابدأ من payment loading screen لمعالجة المعاملات بشكل صحيح
      if (currentPath?.contains('/payment/success') == true || 
          currentPath?.contains('/payment/cancel') == true) {
        print('Payment redirect detected, starting from payment loading screen');
        return '/payment/loading';
      }
      
      // إذا كان URL يحتوي على /home
      if (currentPath?.contains('/home') == true) {
        print('Redirecting to home screen');
        return AppConstants.homeRoute;
      }
    } catch (e) {
      print('Error checking URL: $e');
    }
    
    // افتراضي: ابدأ من splash screen
    return AppConstants.splashRoute;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,

        // Theme configuration
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),

          // App bar theme
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),

          // Card theme
          cardTheme: CardTheme(
            color: AppColors.surface,
            elevation: 4,
            shadowColor: AppColors.textPrimary.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
            ),
          ),

          // Elevated button theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              elevation: 2,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.largePadding,
                vertical: AppConstants.defaultPadding,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              ),
            ),
          ),

          // Text button theme
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.smallPadding,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              ),
            ),
          ),

          // Input decoration theme
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: AppConstants.smallPadding,
            ),
          ),

          // Text theme
          textTheme: const TextTheme(
            displayLarge: AppTextStyles.displayLarge,
            displayMedium: AppTextStyles.displayMedium,
            displaySmall: AppTextStyles.displaySmall,
            headlineLarge: AppTextStyles.headlineLarge,
            headlineMedium: AppTextStyles.headlineMedium,
            headlineSmall: AppTextStyles.headlineSmall,
            titleLarge: AppTextStyles.titleLarge,
            titleMedium: AppTextStyles.titleMedium,
            titleSmall: AppTextStyles.titleSmall,
            bodyLarge: AppTextStyles.bodyLarge,
            bodyMedium: AppTextStyles.bodyMedium,
            bodySmall: AppTextStyles.bodySmall,
            labelLarge: AppTextStyles.labelLarge,
            labelMedium: AppTextStyles.labelMedium,
            labelSmall: AppTextStyles.labelSmall,
          ),

          // Icon theme
          iconTheme: const IconThemeData(
            color: AppColors.textPrimary,
            size: AppConstants.defaultIconSize,
          ),

          // Scaffold theme
          scaffoldBackgroundColor: AppColors.background,
        ),

        // RTL support for Arabic
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl, // Arabic RTL support
            child: child!,
          );
        },

        // Initial route - check URL first
        initialRoute: _getInitialRoute(),

        // Route configuration
        routes: {
          AppConstants.splashRoute: (context) => const SplashScreen(),
          AppConstants.homeRoute: (context) => const HomeScreen(),
          AppConstants.paymentSuccessRoute: (context) => const DonationSuccessScreen(),
          AppConstants.paymentCancelRoute: (context) => const PaymentFailedScreen(),
          '/payment/loading': (context) => const PaymentLoadingScreen(),
        },
      ),
    );
  }
}
