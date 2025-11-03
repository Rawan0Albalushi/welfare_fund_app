# Campaign Bilingual Display - عرض الحملات باللغات

## نظرة عامة

تم تطبيق نظام عرض الحملات باللغتين العربية والإنجليزية في التطبيق. التطبيق يعرض الحملات باللغة المناسبة حسب إعدادات المستخدم.

## الميزات المطبقة

### 1. نموذج الحملة المحدث
تم تحديث نموذج `Campaign` ليدعم الحقول ثنائية اللغة:

```dart
class Campaign {
  final String titleAr;           // العنوان بالعربية
  final String titleEn;           // العنوان بالإنجليزية
  final String descriptionAr;     // الوصف بالعربية
  final String descriptionEn;     // الوصف بالإنجليزية
  final String? impactDescriptionAr;  // وصف التأثير بالعربية
  final String? impactDescriptionEn;  // وصف التأثير بالإنجليزية
  // ... باقي الحقول
}
```

### 2. دوال الترجمة
تم إضافة دوال للحصول على المحتوى باللغة المناسبة:

```dart
// الحصول على العنوان باللغة المناسبة
String getLocalizedTitle(String locale) {
  if (locale == 'ar') {
    return titleAr.isNotEmpty ? titleAr : title;
  } else {
    return titleEn.isNotEmpty ? titleEn : title;
  }
}

// الحصول على الوصف باللغة المناسبة
String getLocalizedDescription(String locale) {
  if (locale == 'ar') {
    return descriptionAr.isNotEmpty ? descriptionAr : description;
  } else {
    return descriptionEn.isNotEmpty ? descriptionEn : description;
  }
}
```

### 3. عرض الحملات في الواجهة
تم تحديث `CampaignCard` لعرض المحتوى باللغة المناسبة:

```dart
Text(
  campaign.getLocalizedTitle(context.locale.languageCode),
  style: AppTextStyles.titleMedium,
),
```

### 4. دعم الفئات المترجمة
تم تحديث عرض أسماء الفئات لتكون مترجمة:

```dart
String _getLocalizedCategoryName(String category) {
  // خريطة أسماء الفئات إلى مفاتيح الترجمة
  final categoryMap = {
    'فرص تعليمية': 'category_education_opportunities',
    'السكن والنقل': 'category_housing_transport',
    'شراء الأجهزة': 'category_device_purchase',
    'الامتحانات': 'category_exams',
    // ... المزيد
  };
  
  final translationKey = categoryMap[category];
  if (translationKey != null) {
    return translationKey.tr();
  }
  
  return category;
}
```

## كيفية العمل

### 1. تحميل الحملات
- يتم تحميل الحملات من API مع الحقول ثنائية اللغة
- يتم حفظ البيانات باللغتين العربية والإنجليزية

### 2. عرض الحملات
- عند عرض الحملة، يتم اختيار اللغة المناسبة حسب إعدادات التطبيق
- إذا لم تكن اللغة المطلوبة متوفرة، يتم استخدام اللغة البديلة

### 3. تبديل اللغة
- عند تغيير اللغة من الإعدادات، يتم تحديث جميع الحملات تلقائياً
- يتم إعادة بناء الواجهة لعرض المحتوى باللغة الجديدة

## API المطلوب

يجب أن يدعم الخادم الحقول ثنائية اللغة:

```json
{
  "id": 1,
  "title_ar": "حملة تعليمية",
  "title_en": "Education Campaign",
  "description_ar": "وصف الحملة بالعربية",
  "description_en": "Campaign description in English",
  "impact_description_ar": "التأثير بالعربية",
  "impact_description_en": "Impact in English",
  "category": {
    "name_ar": "فرص تعليمية",
    "name_en": "Education Opportunities"
  }
}
```

## الفوائد

1. **تجربة مستخدم محسنة**: عرض المحتوى بلغة المستخدم المفضلة
2. **مرونة في العرض**: دعم كامل للعربية والإنجليزية
3. **تبديل سلس**: تغيير اللغة دون إعادة تحميل التطبيق
4. **توافق مع الإصدارات السابقة**: دعم للحقول القديمة

## الاختبار

1. افتح التطبيق وانتقل لشاشة الحملات
2. لاحظ عرض الحملات باللغة الحالية
3. غيّر اللغة من الإعدادات
4. لاحظ تحديث المحتوى تلقائياً
5. تأكد من عمل جميع شاشات عرض الحملات

## التحسينات المستقبلية

1. إضافة دعم المزيد من اللغات
2. تحسين نظام التخزين المؤقت
3. تحسين الأداء عند تحميل الحملات
4. إضافة دعم للبحث باللغتين
