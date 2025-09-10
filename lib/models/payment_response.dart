// payment_response.dart

class PaymentResponse {
  final bool success;
  final String? sessionId;
  final String? paymentUrl; // redirect_url من الباكند
  final String? message;
  final String? error;
  final Map<String, dynamic>? raw; // الاحتفاظ بالردّ كاملًا لو احتجتِه

  PaymentResponse({
    required this.success,
    this.sessionId,
    this.paymentUrl,
    this.message,
    this.error,
    this.raw,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    // مسارات محتملة للقيم:
    // - top-level: session_id, payment_url
    // - nested: data.payment_session.session_id, data.payment_session.redirect_url
    final data = (json['data'] is Map) ? json['data'] as Map<String, dynamic> : null;
    final paymentSession = (data?['payment_session'] is Map)
        ? data!['payment_session'] as Map<String, dynamic>
        : null;

    String? sessionId = _asString(json['session_id']) ?? _asString(paymentSession?['session_id']);
    String? paymentUrl = _asString(json['payment_url']) ??
        _asString(paymentSession?['redirect_url']) ??
        _asString(paymentSession?['payment_url']) ??
        _asString(data?['redirect_url']);

    final String? message = _asString(json['message']);
    String? error = _asString(json['error']);

    // أحيانًا الأخطاء تكون في حقل "errors"
    if (error == null && json['errors'] != null) {
      error = json['errors'].toString();
    }
    // لو success=false ولم يأتِ error، نستخدم message كـ error
    final bool inferredSuccess = (json['success'] is bool)
        ? (json['success'] as bool)
        : (sessionId != null && paymentUrl != null);

    return PaymentResponse(
      success: inferredSuccess,
      sessionId: sessionId,
      paymentUrl: paymentUrl,
      message: message,
      error: error ?? (inferredSuccess ? null : message),
      raw: json,
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
      if (raw != null) 'raw': raw,
    };
  }

  static String? _asString(dynamic v) => v == null ? null : v.toString();
}

/// (اختياري) لردّ /api/v1/payments/status/{sessionId}
class PaymentStatusResponse {
  final bool success;
  final String? paymentStatus; // paid | unpaid | cancelled | failed | unknown
  final String? sessionId;
  final Map<String, dynamic>? raw;

  const PaymentStatusResponse({
    required this.success,
    this.paymentStatus,
    this.sessionId,
    this.raw,
  });

  bool get isPaid => paymentStatus == 'paid';

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      success: (json['success'] is bool) ? json['success'] as bool : true,
      paymentStatus: (json['payment_status']?.toString()),
      sessionId: (json['session_id']?.toString()),
      raw: json,
    );
  }
}
