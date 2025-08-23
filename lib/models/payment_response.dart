class PaymentResponse {
  final bool success;
  final String? sessionId;
  final String? paymentUrl;
  final String? message;
  final String? error;

  PaymentResponse({
    required this.success,
    this.sessionId,
    this.paymentUrl,
    this.message,
    this.error,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] ?? false,
      sessionId: json['session_id'],
      paymentUrl: json['payment_url'],
      message: json['message'],
      error: json['error'],
    );
  }

  factory PaymentResponse.error(String errorMessage) {
    return PaymentResponse(
      success: false,
      error: errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (sessionId != null) 'session_id': sessionId,
      if (paymentUrl != null) 'payment_url': paymentUrl,
      if (message != null) 'message': message,
      if (error != null) 'error': error,
    };
  }
}
