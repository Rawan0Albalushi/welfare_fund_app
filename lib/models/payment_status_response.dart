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
  final double? amount;
  final String? currency;
  final String? transactionId;
  final DateTime? completedAt;
  final String? message;
  final String? error;

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
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    PaymentStatus status = PaymentStatus.unknown;
    
    if (json['status'] != null) {
      switch (json['status'].toString().toLowerCase()) {
        case 'pending':
          status = PaymentStatus.pending;
          break;
        case 'completed':
        case 'success':
          status = PaymentStatus.completed;
          break;
        case 'failed':
        case 'error':
          status = PaymentStatus.failed;
          break;
        case 'cancelled':
        case 'canceled':
          status = PaymentStatus.cancelled;
          break;
        case 'expired':
          status = PaymentStatus.expired;
          break;
      }
    }

    return PaymentStatusResponse(
      success: json['success'] ?? false,
      status: status,
      sessionId: json['session_id'],
      amount: json['amount']?.toDouble(),
      currency: json['currency'],
      transactionId: json['transaction_id'],
      completedAt: json['completed_at'] != null 
          ? DateTime.tryParse(json['completed_at']) 
          : null,
      message: json['message'],
      error: json['error'],
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
    };
  }

  bool get isCompleted => status == PaymentStatus.completed;
  bool get isPending => status == PaymentStatus.pending;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isCancelled => status == PaymentStatus.cancelled;
  bool get isExpired => status == PaymentStatus.expired;
}
