import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Display styles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // Headline styles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // Title styles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Button styles
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.surface,
    height: 1.4,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.surface,
    height: 1.4,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.surface,
    height: 1.4,
  );

  // Page Title styles - unified across all screens
  // Use appBarTitleLight for transparent/light background AppBars
  static const TextStyle appBarTitleLight = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // Use appBarTitleDark for colored/gradient background AppBars
  static const TextStyle appBarTitleDark = TextStyle(
    fontFamily: 'IBMPlexSansArabic',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.surface,
    height: 1.3,
  );
} 