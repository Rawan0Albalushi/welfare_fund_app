import 'package:flutter/material.dart';

class StudentRegistrationCardData {
  final StudentRegistrationCardBackground? background;
  final String? headlineAr;
  final String? headlineEn;
  final String? subtitleAr;
  final String? subtitleEn;
  final String? backgroundImageUrl;

  const StudentRegistrationCardData({
    this.background,
    this.headlineAr,
    this.headlineEn,
    this.subtitleAr,
    this.subtitleEn,
    this.backgroundImageUrl,
  });

  factory StudentRegistrationCardData.fromMap(Map<String, dynamic> map) {
    return StudentRegistrationCardData(
      background: StudentRegistrationCardBackground.fromMap(map['background']),
      headlineAr: _toNullableString(map['headline_ar']),
      headlineEn: _toNullableString(map['headline_en']),
      subtitleAr: _toNullableString(map['subtitle_ar']),
      subtitleEn: _toNullableString(map['subtitle_en']),
      backgroundImageUrl: _toNullableString(map['background_image_url']),
    );
  }

  StudentRegistrationCardData copyWith({
    StudentRegistrationCardBackground? background,
    String? headlineAr,
    String? headlineEn,
    String? subtitleAr,
    String? subtitleEn,
    String? backgroundImageUrl,
  }) {
    return StudentRegistrationCardData(
      background: background ?? this.background,
      headlineAr: headlineAr ?? this.headlineAr,
      headlineEn: headlineEn ?? this.headlineEn,
      subtitleAr: subtitleAr ?? this.subtitleAr,
      subtitleEn: subtitleEn ?? this.subtitleEn,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
    );
  }

  static String? _toNullableString(Object? value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }
}

class StudentRegistrationCardBackground {
  final String? type;
  final Color? colorFrom;
  final Color? colorTo;

  const StudentRegistrationCardBackground({
    this.type,
    this.colorFrom,
    this.colorTo,
  });

  factory StudentRegistrationCardBackground.fromMap(dynamic value) {
    if (value is! Map<String, dynamic>) {
      return const StudentRegistrationCardBackground();
    }
    return StudentRegistrationCardBackground(
      type: _toNullableString(value['type']),
      colorFrom: _parseColor(value['color_from']),
      colorTo: _parseColor(value['color_to']),
    );
  }

  static String? _toNullableString(Object? value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  static Color? _parseColor(Object? value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    final normalized = raw.replaceAll('#', '');
    final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
    if (hex.length != 8) return null;
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }
}

