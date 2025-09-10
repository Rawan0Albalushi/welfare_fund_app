// payment_request.dart

class PaymentRequest {
  /// المبلغ بالريال العماني (OMR)
  final double amountOmr;

  /// معرف مرجعي (اختياري) — الباكند سيستخدم donation_id غالبًا كمرجع داخلي
  final String? clientReferenceId;

  /// ربط التبرع ببرنامج أو حملة (أحدهما مطلوب على الأقل في الباكند)
  final int? programId;
  final int? campaignId;

  /// معلومات إضافية يقبلها الباكند
  final String? donorName; // donor_name
  final String? note;      // note
  final String type;       // quick | gift

  /// اسم المنتج/التبرع الظاهر في ثواني
  final String? productName;

  const PaymentRequest({
    required this.amountOmr,
    this.clientReferenceId,
    this.programId,
    this.campaignId,
    this.donorName,
    this.note,
    this.type = 'quick',
    this.productName,
  });

  /// تحضير الجسم المرسل لباكند Laravel (/api/v1/payments/create)
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'products': [
        {
          'name': productName ?? 'تبرع',
          'quantity': 1,
          'unit_amount': _toBaisa(amountOmr), // بيسة
        }
      ],
      // هذه الحقول كلها يقبلها الباكند الحالي
      if (clientReferenceId != null) 'client_reference_id': clientReferenceId,
      if (programId != null) 'program_id': programId,
      if (campaignId != null) 'campaign_id': campaignId,
      if (donorName != null) 'donor_name': donorName,
      if (note != null) 'note': note,
      'type': type, // quick | gift
      // لا نرسل success_url / cancel_url من الفرونت — تُدار من .env في الباكند
      // لا نرسل currency أو return_url — غير مستخدمة في باكندنا
    };

    return map;
  }

  /// محوّل مساعد: OMR -> بيسة
  static int _toBaisa(double omr) => (omr * 1000).round();

  /// (اختياري) إنشاء كائن من JSON لو احتجتِ ترجيع/عرض الطلب لاحقًا
  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    // نحاول استخراج الاسم والمبلغ من products إن وُجدت، وإلا قيم افتراضية
    final products = (json['products'] is List) ? (json['products'] as List) : const [];
    final first = products.isNotEmpty ? products.first as Map<String, dynamic> : const {};

    final unitAmount = (first['unit_amount'] is num) ? (first['unit_amount'] as num).toInt() : 0;
    final amountOmr = unitAmount > 0 ? unitAmount / 1000.0 : (json['amount'] is num ? (json['amount'] as num) / 1000.0 : 0.0);

    return PaymentRequest(
      amountOmr: amountOmr,
      clientReferenceId: json['client_reference_id'] as String?,
      programId: (json['program_id'] is num) ? (json['program_id'] as num).toInt() : null,
      campaignId: (json['campaign_id'] is num) ? (json['campaign_id'] as num).toInt() : null,
      donorName: json['donor_name'] as String?,
      note: json['note'] as String?,
      type: (json['type'] as String?) ?? 'quick',
      productName: (first['name'] as String?) ?? 'تبرع',
    );
  }
}
