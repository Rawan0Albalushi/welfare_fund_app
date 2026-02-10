/// Model for fund partner from API (fund_partners table).
///
/// الباكند يعيد:
/// - [logo]: المسار النسبي (مثل fund-partners/abc123.jpg) أو null.
/// - [logo_url]: الرابط الكامل للشعار (APP_URL + /storage/ + logo) أو null.
/// يُفضّل استخدام logo_url للعرض دون تركيب مسار يدوياً.
class FundPartner {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? logo;
  final String? link;
  final String status;
  final int order;
  final bool isFeatured;

  const FundPartner({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    this.logo,
    this.link,
    required this.status,
    required this.order,
    required this.isFeatured,
  });

  String getLocalizedName(String locale) {
    if (locale == 'ar') {
      return nameAr.trim().isNotEmpty ? nameAr : nameEn;
    }
    return nameEn.trim().isNotEmpty ? nameEn : nameAr;
  }

  String? getLocalizedDescription(String locale) {
    if (locale == 'ar') {
      final d = descriptionAr?.trim();
      return (d != null && d.isNotEmpty) ? d : descriptionEn?.trim();
    }
    final d = descriptionEn?.trim();
    return (d != null && d.isNotEmpty) ? d : descriptionAr?.trim();
  }

  bool get isActive => status == 'active';

  static FundPartner fromJson(Map<String, dynamic> json) {
    return FundPartner(
      id: _intFromJson(json['id']),
      nameAr: _str(json['name_ar'] ?? json['nameAr']) ?? '',
      nameEn: _str(json['name_en'] ?? json['nameEn']) ?? '',
      descriptionAr: _str(json['description_ar'] ?? json['descriptionAr']),
      descriptionEn: _str(json['description_en'] ?? json['descriptionEn']),
      logo: _strNonEmpty(json['logo_url'] ?? json['logo'] ?? json['image_url'] ?? json['image']),
      link: _str(json['link']),
      status: _str(json['status']) ?? 'inactive',
      order: _intFromJson(json['order']),
      isFeatured: json['is_featured'] == true || json['isFeatured'] == true,
    );
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  /// مثل _str لكن يعيد null إذا كانت القيمة فارغة (للمسارات والروابط)
  static String? _strNonEmpty(dynamic v) {
    final s = _str(v);
    return (s != null && s.trim().isNotEmpty) ? s.trim() : null;
  }

  static int _intFromJson(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
