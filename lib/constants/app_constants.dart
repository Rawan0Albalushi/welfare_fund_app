class AppConstants {
  // App info
  static const String appName = 'صندوق رعاية الطلاب';
  static const String appVersion = '1.0.0';
  
  // API
//static const String baseUrl = "https://welfare-student.maksab.om/api/v1";
  static const String baseUrl = "http://192.168.100.66:8000/api/v1";
  
  // Routes
  static const String splashRoute = '/splash';
  static const String homeRoute = '/home';
  static const String paymentSuccessRoute = '/payment/success';
  static const String paymentCancelRoute = '/payment/cancel';
  static const String fundNewsRoute = '/fund-news';
  
  // Padding values
  static const double smallPadding = 8.0;
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;
  
  // Radius values
  static const double smallRadius = 8.0;
  static const double defaultRadius = 12.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 24.0;
  
  // Icon sizes
  static const double smallIconSize = 16.0;
  static const double defaultIconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double extraLargeIconSize = 48.0;
  
  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  
  // Splash-specific timings
  static const Duration splashFadeDuration = Duration(milliseconds: 2000);
  static const Duration splashSlideDuration = Duration(milliseconds: 1500);
  static const Duration splashScaleDuration = Duration(milliseconds: 1000);
  static const Duration splashToHomeDelay = Duration(milliseconds: 2000);
  
  // Screen dimensions
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

} 