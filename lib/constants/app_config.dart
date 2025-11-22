class AppConfig {
  // ⚠️ مهم: في بيئة الإنتاج يجب استخدام HTTPS بدلاً من HTTP
  // يمكن تعيين APP_URL من خلال environment variable عند البناء
  // مثال: flutter build apk --dart-define=APP_URL=https://api.example.com
  static const String serverBaseUrl = String.fromEnvironment(
    'APP_URL',
    defaultValue: 'http://localhost:8000',
    /*defaultValue: 'http://192.168.1.15:8000', // ⚠️ للاختبار المحلي فقط*/
  );

  static const String apiBaseUrlV1 = '$serverBaseUrl/api/v1';
  static const String authBaseUrl = '$serverBaseUrl/api';

  static const String paymentsSuccessUrl = '$apiBaseUrlV1/payments/success';
  static const String paymentsCancelUrl = '$apiBaseUrlV1/payments/cancel';
  static const String donationsWithPaymentEndpoint = '$apiBaseUrlV1/donations/with-payment';
  static const String paymentsConfirmEndpoint = '$apiBaseUrlV1/payments/confirm';

  static String get origin => serverBaseUrl;
}

