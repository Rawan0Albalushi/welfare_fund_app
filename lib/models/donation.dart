class Donation {
  final String id;
  final String? paymentSessionId;
  final String status;
  final double? paidAmount;
  final String campaignId;
  final String donorName;
  final double amount;
  final DateTime date;
  final String? message;
  final bool isAnonymous;

  Donation({
    required this.id,
    this.paymentSessionId,
    this.status = 'pending',
    this.paidAmount,
    required this.campaignId,
    required this.donorName,
    required this.amount,
    required this.date,
    this.message,
    this.isAnonymous = false,
  });

  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['id'] as String,
      paymentSessionId: json['payment_session_id'] as String?,
      status: json['status'] as String? ?? 'pending',
      paidAmount: json['paid_amount']?.toDouble(),
      campaignId: json['campaignId'] as String,
      donorName: json['donorName'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      message: json['message'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (paymentSessionId != null) 'payment_session_id': paymentSessionId,
      'status': status,
      if (paidAmount != null) 'paid_amount': paidAmount,
      'campaignId': campaignId,
      'donorName': donorName,
      'amount': amount,
      'date': date.toIso8601String(),
      'message': message,
      'isAnonymous': isAnonymous,
    };
  }

  // Helper methods for status checking
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => status == 'expired';

  // Create a copy with updated fields
  Donation copyWith({
    String? id,
    String? paymentSessionId,
    String? status,
    double? paidAmount,
    String? campaignId,
    String? donorName,
    double? amount,
    DateTime? date,
    String? message,
    bool? isAnonymous,
  }) {
    return Donation(
      id: id ?? this.id,
      paymentSessionId: paymentSessionId ?? this.paymentSessionId,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      campaignId: campaignId ?? this.campaignId,
      donorName: donorName ?? this.donorName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      message: message ?? this.message,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }
} 