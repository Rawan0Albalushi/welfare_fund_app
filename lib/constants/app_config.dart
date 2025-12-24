class AppConfig {
  // ⚠️⚠️⚠️ تحذير أمني حرج ⚠️⚠️⚠️
  // في بيئة الإنتاج يجب استخدام HTTPS بدلاً من HTTP
  // استخدام HTTP يعرض البيانات الحساسة (tokens, payment info) للاعتراض
  // 
  // يمكن تعيين APP_URL من خلال environment variable عند البناء:
  // مثال: flutter build apk --dart-define=APP_URL=https://api.example.com
  // 
  // ⚠️ القيمة الافتراضية أدناه للاختبار المحلي فقط - لا تستخدمها في الإنتاج!
  // ✅ إصلاح: استخدام قيمة أكثر أماناً كـ fallback
  // 
  // ملاحظة: في الإنتاج يجب دائماً تعيين APP_URL عبر --dart-define
  // القيمة الافتراضية هنا للاختبار المحلي فقط
  static const String serverBaseUrl = String.fromEnvironment(
    'APP_URL',
    // ✅ رابط الإنتاج
    defaultValue: 'https://welfare-student.maksab.om',
    //defaultValue: 'http://localhost:8000',
    //defaultValue: 'http://192.168.100.66:8000',
  );
  
  /// التحقق من أن الاتصال آمن (HTTPS) في بيئة الإنتاج
  /// يُستخدم للتحذير في حالة استخدام HTTP
  static bool get isSecureConnection {
    return serverBaseUrl.startsWith('https://');
  }
  
  /// التحقق من أن الاتصال محلي (للاختبار فقط)
  static bool get isLocalConnection {
    return serverBaseUrl.contains('localhost') || 
           serverBaseUrl.contains('127.0.0.1') ||
           serverBaseUrl.startsWith('http://192.168.') ||
           serverBaseUrl.startsWith('http://10.0.2.2');
  }

  static const String apiBaseUrlV1 = '$serverBaseUrl/api/v1';
  static const String authBaseUrl = '$serverBaseUrl/api';

  static const String paymentsSuccessUrl = '$apiBaseUrlV1/payments/success';
  static const String paymentsCancelUrl = '$apiBaseUrlV1/payments/cancel';
  static const String donationsWithPaymentEndpoint = '$apiBaseUrlV1/donations/with-payment';
  static const String paymentsConfirmEndpoint = '$apiBaseUrlV1/payments/confirm';

  static String get origin => serverBaseUrl;
}

