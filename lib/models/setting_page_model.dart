class SettingPageModel {
  final String key;
  final String titleAr;
  final String titleEn;
  final String contentAr;
  final String contentEn;

  SettingPageModel({
    required this.key,
    required this.titleAr,
    required this.titleEn,
    required this.contentAr,
    required this.contentEn,
  });

  // Helper methods to get localized content
  String getLocalizedTitle(String locale) {
    if (locale == 'ar') {
      return titleAr.isNotEmpty ? titleAr : titleEn;
    } else {
      return titleEn.isNotEmpty ? titleEn : titleAr;
    }
  }

  String getLocalizedContent(String locale) {
    if (locale == 'ar') {
      return contentAr.isNotEmpty ? contentAr : contentEn;
    } else {
      return contentEn.isNotEmpty ? contentEn : contentAr;
    }
  }

  factory SettingPageModel.fromJson(Map<String, dynamic> json) {
    return SettingPageModel(
      key: json['key']?.toString() ?? '',
      titleAr: json['title_ar']?.toString() ?? json['titleAr']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? json['titleEn']?.toString() ?? '',
      contentAr: json['content_ar']?.toString() ?? json['contentAr']?.toString() ?? '',
      contentEn: json['content_en']?.toString() ?? json['contentEn']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title_ar': titleAr,
      'title_en': titleEn,
      'content_ar': contentAr,
      'content_en': contentEn,
    };
  }

  SettingPageModel copyWith({
    String? key,
    String? titleAr,
    String? titleEn,
    String? contentAr,
    String? contentEn,
  }) {
    return SettingPageModel(
      key: key ?? this.key,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      contentAr: contentAr ?? this.contentAr,
      contentEn: contentEn ?? this.contentEn,
    );
  }
}

