class AppConfig {
  static const String serverBaseUrl = String.fromEnvironment(
    'APP_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String apiBaseUrlV1 = '$serverBaseUrl/api/v1';
  static const String authBaseUrl = '$serverBaseUrl/api';

  static const String paymentsSuccessUrl = '$apiBaseUrlV1/payments/success';
  static const String paymentsCancelUrl = '$apiBaseUrlV1/payments/cancel';
  static const String donationsWithPaymentEndpoint = '$apiBaseUrlV1/donations/with-payment';
  static const String paymentsConfirmEndpoint = '$apiBaseUrlV1/payments/confirm';

  static String get origin => serverBaseUrl;
}

