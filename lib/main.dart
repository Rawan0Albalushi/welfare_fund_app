import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'providers/setting_page_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }
  print('🔔 Background message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (only for non-web platforms or when options are available)
  if (!kIsWeb) {
    await Firebase.initializeApp();
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } else {
    print('⚠️ Firebase not initialized on web - firebase_options.dart is required');
    print('Run: dart pub global activate flutterfire_cli');
    print('Then: flutterfire configure');
  }
  
  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();
  
  // Register web implementation for webview_flutter when running on web
  if (kIsWeb) {
    // Only register web platform when actually running on web
    // This will be handled by conditional imports if needed
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
  
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      saveLocale: true,
      child: const StudentWelfareFundApp(),
    ),
  );
}

class StudentWelfareFundApp extends StatelessWidget {
  const StudentWelfareFundApp({super.key});

  // تحديد الـ route الأولي بناءً على URL الحالي
  String _getInitialRoute() {
    try {
      // للويب، تحقق من URL الحالي
      String? currentPath;
      if (kIsWeb) {
        try {
          // Use Uri.base which works on web to get pathname
          final uri = Uri.base;
          currentPath = uri.path;
          print('Current URL path: $currentPath');
          print('Current URL full: ${uri.toString()}');
          print('Current query params: ${uri.queryParameters}');
        } catch (e) {
          print('Error reading URL: $e');
          currentPath = '/';
        }
      } else {
        currentPath = '/';
      }
      
      // إذا كان URL يحتوي على payment/success أو payment/cancel
      // ابدأ من payment loading screen لمعالجة المعاملات بشكل صحيح
      if (currentPath.contains('/payment/success') || 
          currentPath.contains('/payment/cancel')) {
        print('Payment redirect detected, starting from payment loading screen');
        return '/payment/loading';
      }
      
      // إذا كان URL يحتوي على /home
      if (currentPath.contains('/home')) {
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
        ChangeNotifierProvider(create: (_) => SettingPageProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        
        // Localization configuration
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        

        // Theme configuration
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'IBMPlexSansArabic',
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

        // RTL/LTR support is handled automatically by EasyLocalization

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
          );
        },
      ),
    );
  }
}
