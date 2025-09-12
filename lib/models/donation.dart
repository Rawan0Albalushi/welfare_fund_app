class Donation {
  /// معرّف التبرع في الباكند (donation_id أو id)
  final String id;

  /// session الخاص بالدفع من ثواني
  final String? paymentSessionId;

  /// حالة التبرع: pending / paid / cancelled / failed / expired ...
  final String status;

  /// المبلغ المدفوع (إن وُجد)
  final double? paidAmount;

  /// معرّف الحملة (إن كان التبرع لحملة)
  final String? campaignId;

  /// معرّف البرنامج (إن كان التبرع لبرنامج)
  final String? programId;

  /// اسم المتبرع
  final String? donorName;

  /// مبلغ التبرع (بالريال العماني)
  final double amount;

  /// تاريخ إنشاء التبرع (created_at)
  final DateTime date;

  /// ملاحظة/رسالة (note/message)
  final String? message;

  /// هل المتبرع مجهول
  final bool isAnonymous;

  /// رابط الدفع (اختياري — مفيد للعرض)
  final String? paymentUrl;

  /// اسم البرنامج (إذا كان التبرع لبرنامج)
  final String? programName;

  /// اسم الحملة (إذا كان التبرع لحملة)
  final String? campaignName;

  Donation({
    required this.id,
    this.paymentSessionId,
    this.status = 'pending',
    this.paidAmount,
    this.campaignId,
    this.programId,
    this.donorName,
    required this.amount,
    required this.date,
    this.message,
    this.isAnonymous = false,
    this.paymentUrl,
    this.programName,
    this.campaignName,
  });

  /// تحويل ديناميكي إلى double بأمان
  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
    }

  /// قراءة تاريخ من عدة مفاتيح محتملة
  static DateTime _parseDate(Map<String, dynamic> json) {
    final v = json['created_at'] ?? json['date'] ?? json['createdAt'];
    if (v is String) {
      final d = DateTime.tryParse(v);
      if (d != null) return d;
    }
    // fallback: الآن
    return DateTime.now();
  }

  factory Donation.fromJson(Map<String, dynamic> json) {
    final id = (json['donation_id'] ?? json['id'] ?? '').toString();

    return Donation(
      id: id,
      paymentSessionId: json['payment_session_id'] as String?,
      status: (json['status'] as String?)?.toLowerCase() ?? 'pending',
      paidAmount: _toDouble(json['paid_amount'] ?? json['amount_paid'] ?? json['total_paid']),
      campaignId: (json['campaign_id'] ?? json['campaignId'])?.toString(),
      programId: (json['program_id'] ?? json['programId'])?.toString(),
      donorName: (json['donor_name'] ?? json['donorName']) as String?,
      amount: _toDouble(json['amount']) ?? 0.0,
      date: _parseDate(json),
      message: (json['note'] ?? json['message']) as String?,
      isAnonymous: (json['is_anonymous'] ?? json['isAnonymous']) as bool? ?? false,
      paymentUrl: json['payment_url'] as String?,
      programName: (json['program_name'] ?? json['programName'] ?? json['program']?['name'] ?? json['program']?['title']) as String?,
      campaignName: (json['campaign_name'] ?? json['campaignName'] ?? json['campaign']?['name'] ?? json['campaign']?['title']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'donation_id': id,
      if (paymentSessionId != null) 'payment_session_id': paymentSessionId,
      'status': status,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (campaignId != null) 'campaign_id': campaignId,
      if (programId != null) 'program_id': programId,
      if (donorName != null) 'donor_name': donorName,
      'amount': amount,
      'created_at': date.toIso8601String(),
      if (message != null) 'note': message,
      'is_anonymous': isAnonymous,
      if (paymentUrl != null) 'payment_url': paymentUrl,
      if (programName != null) 'program_name': programName,
      if (campaignName != null) 'campaign_name': campaignName,
    };
  }

  // Helpers لحالات الدفع من ثواني
  bool get isPending   => status == 'pending';
  bool get isPaid      => status == 'paid';
  bool get isCancelled => status == 'cancelled' || status == 'canceled';
  bool get isFailed    => status == 'failed';
  bool get isExpired   => status == 'expired';

  /// توافقًا مع تسميات قديمة (completed == paid)
  bool get isCompleted => isPaid;

  Donation copyWith({
    String? id,
    String? paymentSessionId,
    String? status,
    double? paidAmount,
    String? campaignId,
    String? programId,
    String? donorName,
    double? amount,
    DateTime? date,
    String? message,
    bool? isAnonymous,
    String? paymentUrl,
    String? programName,
    String? campaignName,
  }) {
    return Donation(
      id: id ?? this.id,
      paymentSessionId: paymentSessionId ?? this.paymentSessionId,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      campaignId: campaignId ?? this.campaignId,
      programId: programId ?? this.programId,
      donorName: donorName ?? this.donorName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      message: message ?? this.message,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      programName: programName ?? this.programName,
      campaignName: campaignName ?? this.campaignName,
    );
  }
}
