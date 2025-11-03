import 'package:easy_localization/easy_localization.dart';

class CategoryUtils {
  /// Get the appropriate category name based on current locale
  /// Falls back to name_ar if current locale is Arabic, otherwise name_en
  static String getCategoryName({
    required String nameAr,
    required String nameEn,
    String? fallbackName,
    String? currentLocale,
  }) {
    // Use provided locale or default to Arabic
    final locale = currentLocale ?? 'ar';
    
    if (locale == 'ar') {
      return nameAr.isNotEmpty ? nameAr : (fallbackName ?? nameEn);
    } else {
      return nameEn.isNotEmpty ? nameEn : (fallbackName ?? nameAr);
    }
  }

  /// Get category name from category map
  static String getCategoryNameFromMap(Map<String, dynamic> category) {
    return getCategoryName(
      nameAr: category['name_ar'] ?? category['name'] ?? '',
      nameEn: category['name_en'] ?? category['name'] ?? '',
      fallbackName: category['name'],
    );
  }

  /// Get localized fallback categories
  static List<Map<String, dynamic>> getLocalizedFallbackCategories() {
    return [
      {
        'id': '1',
        'title': 'category_education_opportunities'.tr(),
        'name_ar': 'فرص تعليمية',
        'name_en': 'Education Opportunities',
        'description': 'help_students_succeed'.tr(),
        'icon': 'school',
        'color': 'primary',
      },
      {
        'id': '2',
        'title': 'category_housing_transport'.tr(),
        'name_ar': 'السكن والنقل',
        'name_en': 'Housing & Transport',
        'description': 'help_students_succeed'.tr(),
        'icon': 'home',
        'color': 'secondary',
      },
      {
        'id': '3',
        'title': 'category_device_purchase'.tr(),
        'name_ar': 'شراء الأجهزة',
        'name_en': 'Device Purchase',
        'description': 'help_students_succeed'.tr(),
        'icon': 'computer',
        'color': 'accent',
      },
      {
        'id': '4',
        'title': 'category_exams'.tr(),
        'name_ar': 'الامتحانات',
        'name_en': 'Exams',
        'description': 'help_students_succeed'.tr(),
        'icon': 'assignment',
        'color': 'success',
      },
    ];
  }
}
