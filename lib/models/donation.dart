class Donation {
  final String id;
  final String campaignId;
  final String donorName;
  final double amount;
  final DateTime date;
  final String? message;
  final bool isAnonymous;

  Donation({
    required this.id,
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
      'campaignId': campaignId,
      'donorName': donorName,
      'amount': amount,
      'date': date.toIso8601String(),
      'message': message,
      'isAnonymous': isAnonymous,
    };
  }
} 