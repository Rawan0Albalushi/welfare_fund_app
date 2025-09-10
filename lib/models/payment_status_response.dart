// payment_status_response.dart

enum PaymentStatus {
  pending,
  completed,
  failed,
  cancelled,
  expired,
  unknown,
}

class PaymentStatusResponse {
  final bool success;
  final PaymentStatus status;
  final String? sessionId;
  final double? amount;        // OMR
  final String? currency;      // غالباً OMR
  final String? transactionId; // قد تكون charge_id/payment_id من raw_response
  final DateTime? completedAt;
  final String? message;
  final String? error;
  final Map<String, dynamic>? raw; // يحتفظ بالرد الخام لو احتجته

  PaymentStatusResponse({
    required this.success,
    required this.status,
    this.sessionId,
    this.amount,
    this.currency,
    this.transactionId,
    this.completedAt,
    this.message,
    this.error,
    this.raw,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    // الباكند عندك يرجّع payment_status، وأحياناً قد يأتي status من مصادر أخرى
    final String? statusStr =
        _str(json['payment_status']) ??
        _str(json['status']) ??
        _str((json['raw_response'] is Map) ? (json['raw_response'] as Map)['payment_status'] : null);

    final PaymentStatus mapped = _mapStatus(statusStr);

    // sessionId من أعلى الرد أو من raw_response إن وُجد
    final Map<String, dynamic>? raw =
        (json['raw_response'] is Map) ? Map<String, dynamic>.from(json['raw_response'] as Map) : null;

    final String? sessionId =
        _str(json['session_id']) ??
        _str(raw?['session_id']);

    // المبلغ (OMR): نحاول أولاً من الحقول المباشرة، ثم من total_amount (بيسة)
    double? amountOmr = _toDouble(json['amount']) ?? _toDouble(json['paid_amount']);
    final num? totalAmountBaisa = _toNum(raw?['total_amount']);
    if (amountOmr == null && totalAmountBaisa != null) {
      amountOmr = totalAmountBaisa / 1000.0; // بيسة -> ريال
    }

    // العملة (إن وُجدت في raw_response)
    final String? currency =
        _str(json['currency']) ??
        _str(raw?['currency']) ??
        'OMR';

    // معرّف العملية المحتمل
    final String? transactionId =
        _str(json['transaction_id']) ??
        _str(raw?['payment_id']) ??
        _str(raw?['charge_id']) ??
        _str(raw?['invoice_id']);

    // تاريخ الإتمام المحتمل
    DateTime? completedAt =
        _toDate(json['completed_at']) ??
        _toDate(raw?['updated_at']) ??
        _toDate(raw?['completed_at']);

    // رسائل
    final String? message = _str(json['message']);
    String? error = _str(json['error']);
    if (error == null && json['errors'] != null) {
      error = json['errors'].toString();
    }

    final bool success = (json['success'] is bool)
        ? (json['success'] as bool)
        : (mapped == PaymentStatus.completed);

    return PaymentStatusResponse(
      success: success,
      status: mapped,
      sessionId: sessionId,
      amount: amountOmr,
      currency: currency,
      transactionId: transactionId,
      completedAt: completedAt,
      message: message,
      error: error,
      raw: raw,
    );
  }

  factory PaymentStatusResponse.error(String errorMessage) {
    return PaymentStatusResponse(
      success: false,
      status: PaymentStatus.failed,
      error: errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'status': status.name,
      if (sessionId != null) 'session_id': sessionId,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (transactionId != null) 'transaction_id': transactionId,
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (message != null) 'message': message,
      if (error != null) 'error': error,
      if (raw != null) 'raw_response': raw,
    };
  }

  bool get isCompleted => status == PaymentStatus.completed;
  bool get isPending   => status == PaymentStatus.pending;
  bool get isFailed    => status == PaymentStatus.failed;
  bool get isCancelled => status == PaymentStatus.cancelled;
  bool get isExpired   => status == PaymentStatus.expired;

  // ==== Helpers ====
  static PaymentStatus _mapStatus(String? s) {
    final v = (s ?? '').toLowerCase().trim();
    switch (v) {
      case 'paid':
      case 'success':
      case 'completed':
        return PaymentStatus.completed;

      case 'unpaid':
      case 'pending':
      case 'awaiting_payment':
        return PaymentStatus.pending;

      case 'cancelled':
      case 'canceled':
        return PaymentStatus.cancelled;

      case 'failed':
      case 'error':
      case 'declined':
        return PaymentStatus.failed;

      case 'expired':
        return PaymentStatus.expired;

      default:
        return PaymentStatus.unknown;
    }
  }

  static String? _str(dynamic v) => v == null ? null : v.toString();
  static num? _toNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
    }
  static double? _toDouble(dynamic v) {
    final n = _toNum(v);
    return n == null ? null : n.toDouble();
  }
  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
