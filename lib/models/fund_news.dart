/// Model for fund news from API (fund_news table).
/// Fields: title_ar, title_en, content_ar, content_en, image, status, order, is_featured, published_at
class FundNews {
  final int id;
  final String titleAr;
  final String titleEn;
  final String contentAr;
  final String contentEn;
  final String? image;
  final String status;
  final int order;
  final bool isFeatured;
  final DateTime? publishedAt;

  const FundNews({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.contentAr,
    required this.contentEn,
    this.image,
    required this.status,
    required this.order,
    required this.isFeatured,
    this.publishedAt,
  });

  String getLocalizedTitle(String locale) {
    if (locale == 'ar') {
      return titleAr.trim().isNotEmpty ? titleAr : titleEn;
    }
    return titleEn.trim().isNotEmpty ? titleEn : titleAr;
  }

  String getLocalizedContent(String locale) {
    if (locale == 'ar') {
      return contentAr.trim().isNotEmpty ? contentAr : contentEn;
    }
    return contentEn.trim().isNotEmpty ? contentEn : contentAr;
  }

  bool get isActive => status == 'active';

  static FundNews fromJson(Map<String, dynamic> json) {
    return FundNews(
      id: _intFromJson(json['id']),
      titleAr: _str(json['title_ar'] ?? json['titleAr']) ?? '',
      titleEn: _str(json['title_en'] ?? json['titleEn']) ?? '',
      contentAr: _str(json['content_ar'] ?? json['contentAr']) ?? '',
      contentEn: _str(json['content_en'] ?? json['contentEn']) ?? '',
      image: _str(json['image_url'] ?? json['image']),
      status: _str(json['status']) ?? 'inactive',
      order: _intFromJson(json['order']),
      isFeatured: json['is_featured'] == true || json['isFeatured'] == true,
      publishedAt: _dateFromJson(json['published_at'] ?? json['publishedAt']),
    );
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  static int _intFromJson(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime? _dateFromJson(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
