class PaymentRequest {
  final double amount;
  final String clientReferenceId;
  final String returnUrl;
  final String? donorName;
  final String? donorEmail;
  final String? donorPhone;
  final String? message;
  final String? itemId;
  final String? itemType;

  PaymentRequest({
    required this.amount,
    required this.clientReferenceId,
    required this.returnUrl,
    this.donorName,
    this.donorEmail,
    this.donorPhone,
    this.message,
    this.itemId,
    this.itemType,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': (amount * 100).round(), // تحويل إلى هللات
      'client_reference_id': clientReferenceId,
      'return_url': returnUrl,
      'currency': 'OMR',
      'products': [
        {
          'name': message ?? 'تبرع خيري', // اسم الحملة أو رسالة التبرع
          'quantity': 1,
          'unit_amount': (amount * 100).round(),
        }
      ],
      // البيانات الإضافية للمتابعة
      'metadata': {
        'donor_name': donorName ?? 'متبرع',
        'donor_email': donorEmail ?? 'donor@example.com',
        'donor_phone': donorPhone ?? '+96812345678',
        'message': message ?? 'تبرع خيري',
        if (itemId != null) 'item_id': itemId,
        if (itemType != null) 'item_type': itemType,
      }
    };
  }

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      amount: json['amount']?.toDouble() ?? 0.0,
      clientReferenceId: json['client_reference_id'] ?? '',
      returnUrl: json['return_url'] ?? '',
      donorName: json['donor_name'],
      donorEmail: json['donor_email'],
      donorPhone: json['donor_phone'],
      message: json['message'],
      itemId: json['item_id'],
      itemType: json['item_type'],
    );
  }
}
