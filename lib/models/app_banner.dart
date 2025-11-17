import '../constants/app_config.dart';

/// Represents a marketing banner that can be displayed across the app.
class AppBanner {
  final String id;
  final String? title;
  final String? titleAr;
  final String? titleEn;
  final String? subtitle;
  final String? subtitleAr;
  final String? subtitleEn;
  final String? description;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? imageUrl;
  final String? mobileImageUrl;
  final String? actionUrl;
  final String? actionLabel;
  final bool isFeatured;
  final bool isActive;
  final int priority;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final List<String> placements;
  final bool showOnHome;
  final Map<String, dynamic> metadata;

  const AppBanner({
    required this.id,
    this.title,
    this.titleAr,
    this.titleEn,
    this.subtitle,
    this.subtitleAr,
    this.subtitleEn,
    this.description,
    this.descriptionAr,
    this.descriptionEn,
    this.imageUrl,
    this.mobileImageUrl,
    this.actionUrl,
    this.actionLabel,
    required this.isFeatured,
    required this.isActive,
    required this.priority,
    this.startsAt,
    this.endsAt,
    required this.placements,
    required this.showOnHome,
    required this.metadata,
  });

  bool get isWithinSchedule {
    final now = DateTime.now();
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    if (endsAt != null && now.isAfter(endsAt!)) return false;
    return true;
  }

  bool get shouldDisplay => isActive && isWithinSchedule;

  bool get shouldDisplayOnHome {
    if (!shouldDisplay) return false;
    if (showOnHome) return true;
    if (placements.isEmpty) return true;
    return placements.any((placement) {
      final normalized = placement.toLowerCase();
      return normalized.contains('home') ||
          normalized.contains('main') ||
          normalized.contains('landing');
    });
  }

  AppBanner copyWith({
    String? imageUrl,
    String? mobileImageUrl,
  }) {
    return AppBanner(
      id: id,
      title: title,
      titleAr: titleAr,
      titleEn: titleEn,
      subtitle: subtitle,
      subtitleAr: subtitleAr,
      subtitleEn: subtitleEn,
      description: description,
      descriptionAr: descriptionAr,
      descriptionEn: descriptionEn,
      imageUrl: imageUrl ?? this.imageUrl,
      mobileImageUrl: mobileImageUrl ?? this.mobileImageUrl,
      actionUrl: actionUrl,
      actionLabel: actionLabel,
      isFeatured: isFeatured,
      isActive: isActive,
      priority: priority,
      startsAt: startsAt,
      endsAt: endsAt,
      placements: placements,
      showOnHome: showOnHome,
      metadata: metadata,
    );
  }

  factory AppBanner.fromJson(Map<String, dynamic> json) {
    final metadata = <String, dynamic>{};
    if (json['metadata'] is Map<String, dynamic>) {
      metadata.addAll(json['metadata'] as Map<String, dynamic>);
    } else if (json['meta'] is Map<String, dynamic>) {
      metadata.addAll(json['meta'] as Map<String, dynamic>);
    }

    final placements = _extractPlacements(json['placements'] ?? json['placement'] ?? json['display_on']);
    final startsAt = _parseDate(json['starts_at'] ?? json['start_at'] ?? json['start_date']);
    final endsAt = _parseDate(json['ends_at'] ?? json['end_at'] ?? json['end_date']);

    return AppBanner(
      id: _asString(json['id'] ?? json['uuid'] ?? json['slug']) ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _asString(json['title'] ?? json['name']),
      titleAr: _asString(json['title_ar'] ?? json['name_ar']),
      titleEn: _asString(json['title_en'] ?? json['name_en']),
      subtitle: _asString(json['subtitle'] ?? json['sub_title'] ?? json['short_title']),
      subtitleAr: _asString(json['subtitle_ar'] ?? json['sub_title_ar']),
      subtitleEn: _asString(json['subtitle_en'] ?? json['sub_title_en']),
      description: _asString(json['description'] ?? json['body'] ?? json['content']),
      descriptionAr: _asString(json['description_ar'] ?? json['body_ar']),
      descriptionEn: _asString(json['description_en'] ?? json['body_en']),
      imageUrl: _resolveImageUrl(json['image_url'] ?? json['image'] ?? json['banner'] ?? json['media_url']),
      mobileImageUrl: _resolveImageUrl(json['mobile_image_url'] ?? json['mobile_image'] ?? json['image_mobile']),
      actionUrl: _resolveUrl(json['cta_link'] ?? json['action_url'] ?? json['link'] ?? json['url']),
      actionLabel: _asString(json['cta_text'] ?? json['action_text'] ?? json['button_text'] ?? json['button_label']),
      isFeatured: _asBool(json['is_featured'] ?? json['featured'] ?? (json['type'] == 'featured')),
      isActive: _asBool(json['is_active'] ?? json['active'] ?? (json['status'] == 'active') ?? true),
      priority: _asInt(json['priority'] ?? json['order'] ?? json['sort'] ?? json['position']) ?? 0,
      startsAt: startsAt,
      endsAt: endsAt,
      placements: placements,
      showOnHome: _asBool(json['show_on_home'] ?? json['display_on_home'] ?? json['home']),
      metadata: metadata,
    );
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final stringValue = value.toString().trim();
    return stringValue.isEmpty ? null : stringValue;
  }

  static bool _asBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().toLowerCase().trim();
    return ['true', '1', 'yes', 'active', 'enabled'].contains(normalized);
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static List<String> _extractPlacements(dynamic raw) {
    final result = <String>[];
    if (raw == null) return result;

    if (raw is String) {
      if (raw.contains(',')) {
        result.addAll(raw.split(',').map((e) => e.trim()).where((element) => element.isNotEmpty));
      } else {
        final value = raw.trim();
        if (value.isNotEmpty) result.add(value);
      }
    } else if (raw is List) {
      for (final entry in raw) {
        final value = entry?.toString().trim();
        if (value != null && value.isNotEmpty) {
          result.add(value);
        }
      }
    }

    return result;
  }

  static String? _resolveUrl(dynamic value) {
    final url = _asString(value);
    if (url == null) return null;
    if (url.startsWith('http')) return url;
    if (url.startsWith('//')) {
      return 'https:$url';
    }
    final base = AppConfig.serverBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final adjustedPath = url.startsWith('/') ? url : '/$url';
    return '$base$adjustedPath';
  }

  static String? _resolveImageUrl(dynamic value) {
    final resolved = _resolveUrl(value);
    return resolved;
  }
}


