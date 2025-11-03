# Category Language Implementation - إضافة دعم اللغات للفئات

## Overview - نظرة عامة

تم تطبيق نظام دعم اللغات للفئات (Categories) في التطبيق ليعرض أسماء الفئات باللغة المناسبة حسب إعدادات اللغة في التطبيق.

## Features Implemented - الميزات المطبقة

### 1. API Service Updates - تحديث خدمة API
- تم تحديث `CampaignService.getCategories()` ليدعم أسماء الفئات باللغتين العربية والإنجليزية
- يتم إرجاع `name_ar` و `name_en` من API
- إضافة دعم لحقل `status` للفئات

```dart
// lib/services/campaign_service.dart
return categoriesData.map((category) => {
  'id': category['id'],
  'name': category['name'],
  'name_ar': category['name_ar'] ?? category['name'],
  'name_en': category['name_en'] ?? category['name'],
  'description': category['description'] ?? '',
  'status': category['status'] ?? 'active',
}).toList();
```

### 2. Category Utility Class - فئة مساعدة الفئات
تم إنشاء `CategoryUtils` لإدارة عرض أسماء الفئات حسب اللغة:

```dart
// lib/utils/category_utils.dart
class CategoryUtils {
  static String getCategoryName({
    required String nameAr,
    required String nameEn,
    String? fallbackName,
    String? currentLocale,
  }) {
    final locale = currentLocale ?? 'ar';
    
    if (locale == 'ar') {
      return nameAr.isNotEmpty ? nameAr : (fallbackName ?? nameEn);
    } else {
      return nameEn.isNotEmpty ? nameEn : (fallbackName ?? nameAr);
    }
  }
}
```

### 3. Translation Keys - مفاتيح الترجمة
تم إضافة مفاتيح الترجمة للفئات في ملفات الترجمة:

**Arabic (ar.json):**
```json
{
  "category_education_opportunities": "فرص تعليمية",
  "category_housing_transport": "السكن والنقل",
  "category_device_purchase": "شراء الأجهزة",
  "category_exams": "الامتحانات",
  "category_emergency_support": "الدعم الطارئ",
  "category_general_support": "الدعم العام"
}
```

**English (en.json):**
```json
{
  "category_education_opportunities": "Education Opportunities",
  "category_housing_transport": "Housing & Transport",
  "category_device_purchase": "Device Purchase",
  "category_exams": "Exams",
  "category_emergency_support": "Emergency Support",
  "category_general_support": "General Support"
}
```

### 4. Screen Updates - تحديث الشاشات

#### Quick Donate Screen - شاشة التبرع السريع
- تم تحديث `QuickDonateAmountScreen` لاستخدام `CategoryUtils`
- إضافة دعم لتحديث الفئات عند تغيير اللغة
- تحسين آلية تحميل الفئات من API مع fallback للفئات المحلية

```dart
// lib/screens/quick_donate_amount_screen.dart
List<Map<String, dynamic>> get _fallbackCategories {
  final currentLocale = context.locale.languageCode;
  final fallbackCategories = CategoryUtils.getLocalizedFallbackCategories();
  
  return fallbackCategories.map((category) => {
    'id': category['id'],
    'title': CategoryUtils.getCategoryName(
      nameAr: category['name_ar'],
      nameEn: category['name_en'],
      currentLocale: currentLocale,
    ),
    // ... other properties
  }).toList();
}
```

#### Gift Donation Screen - شاشة التبرع الهدية
- تم تحديث `GiftDonationScreen` لاستخدام نفس نظام الفئات المترجمة
- إزالة الفئات الثابتة واستبدالها بالفئات المترجمة

### 5. Language Switching Support - دعم تبديل اللغة
- إضافة `didChangeDependencies()` لتحديث الفئات عند تغيير اللغة
- دعم التحديث التلقائي لأسماء الفئات عند تغيير إعدادات اللغة

## API Integration - تكامل API

### Backend Requirements - متطلبات الخادم
يجب أن يدعم الخادم endpoint التالي مع البيانات المطلوبة:

```http
GET /api/v1/categories
```

**Response Format:**
```json
{
  "data": [
    {
      "id": 1,
      "name": "فرص تعليمية",
      "name_ar": "فرص تعليمية",
      "name_en": "Education Opportunities",
      "description": "مساعدة الطلاب في التعليم",
      "status": "active"
    },
    {
      "id": 2,
      "name": "السكن والنقل",
      "name_ar": "السكن والنقل",
      "name_en": "Housing & Transport",
      "description": "مساعدة في السكن والنقل",
      "status": "active"
    }
  ]
}
```

## Usage Examples - أمثلة الاستخدام

### Creating a New Category - إنشاء فئة جديدة
```http
POST /api/v1/admin/categories
{
  "name_ar": "فئة جديدة",
  "name_en": "New Category",
  "description": "وصف الفئة",
  "status": "active"
}
```

### Displaying Categories - عرض الفئات
```dart
// Get category name based on current locale
String categoryName = CategoryUtils.getCategoryName(
  nameAr: category['name_ar'],
  nameEn: category['name_en'],
  currentLocale: context.locale.languageCode,
);
```

## Benefits - الفوائد

1. **Multilingual Support** - دعم متعدد اللغات
   - عرض الفئات باللغة المناسبة للمستخدم
   - تبديل تلقائي عند تغيير إعدادات اللغة

2. **API Flexibility** - مرونة API
   - دعم الفئات من API أو الفئات المحلية
   - fallback mechanism للفئات المحلية

3. **Consistent UI** - واجهة مستخدم متسقة
   - نفس نظام الفئات في جميع الشاشات
   - تجربة مستخدم موحدة

4. **Maintainable Code** - كود قابل للصيانة
   - فصل منطق الترجمة في utility class
   - إعادة استخدام الكود في شاشات متعددة

## Testing - الاختبار

لتجربة الوظيفة:
1. افتح التطبيق وانتقل لشاشة التبرع السريع
2. لاحظ عرض الفئات باللغة الحالية
3. غيّر اللغة من الإعدادات
4. لاحظ تحديث أسماء الفئات تلقائياً

## Future Enhancements - التحسينات المستقبلية

1. إضافة دعم المزيد من اللغات
2. تحسين نظام cache للفئات
3. إضافة دعم للفئات الديناميكية من admin panel
4. تحسين performance عند تحميل الفئات
