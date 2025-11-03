# Programs Bilingual Display - عرض البرامج باللغات

## نظرة عامة

تم تطبيق نظام عرض البرامج الطلابية (Student Programs) باللغتين العربية والإنجليزية في التطبيق. البرامج تُعرض الآن باللغة المناسبة حسب إعدادات المستخدم.

## الميزات المطبقة

### 1. تحديث خدمة البرامج
تم تحديث `StudentRegistrationService` ليدعم الحقول ثنائية اللغة:

```dart
// دالة مساعدة للحصول على اسم البرنامج باللغة المناسبة
static String getLocalizedProgramName(Map<String, dynamic> program, String locale) {
  if (locale == 'ar') {
    return program['title_ar']?.isNotEmpty == true ? program['title_ar'] : (program['name'] ?? '');
  } else {
    return program['title_en']?.isNotEmpty == true ? program['title_en'] : (program['name'] ?? '');
  }
}
```

### 2. تحديث معالجة البيانات
تم تحديث `getSupportPrograms()` لتحليل الحقول ثنائية اللغة:

```dart
return {
  'id': program['id'],
  'name': program['title'] ?? program['name'] ?? 'برنامج غير محدد',
  'title_ar': program['title_ar'] ?? program['title'] ?? program['name'] ?? '',
  'title_en': program['title_en'] ?? program['title'] ?? program['name'] ?? '',
  'description': program['description'] ?? '',
  'description_ar': program['description_ar'] ?? program['description'] ?? '',
  'description_en': program['description_en'] ?? program['description'] ?? '',
  'status': program['status'] ?? 'active',
};
```

### 3. تحديث واجهة المستخدم
تم تحديث `StudentRegistrationScreen` لعرض البرامج باللغة المناسبة:

```dart
// في قائمة البرامج المنسدلة
Text(
  StudentRegistrationService.getLocalizedProgramName(program, context.locale.languageCode),
  style: AppTextStyles.bodyMedium,
),

// في عرض البرنامج المحدد
final programName = StudentRegistrationService.getLocalizedProgramName(selectedProgram, context.locale.languageCode);
```

### 4. دعم تبديل اللغة
تم إضافة `didChangeDependencies` لتحديث أسماء البرامج عند تغيير اللغة:

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  _refreshProgramNamesForCurrentLocale();
}

void _refreshProgramNamesForCurrentLocale() {
  if (_programs.isNotEmpty && _selectedProgramId != null) {
    setState(() {
      final selectedProgram = _programs.firstWhere(
        (program) => program['id']?.toString() == _selectedProgramId,
        orElse: () => {},
      );
      if (selectedProgram.isNotEmpty) {
        _programController.text = StudentRegistrationService.getLocalizedProgramName(selectedProgram, context.locale.languageCode);
      }
    });
  }
}
```

## API المطلوب

يجب أن يدعم الخادم الحقول ثنائية اللغة للبرامج:

```json
{
  "data": [
    {
      "id": 1,
      "title_ar": "برنامج المنح الدراسية",
      "title_en": "Scholarship Program",
      "description_ar": "وصف البرنامج بالعربية",
      "description_en": "Program description in English",
      "status": "active"
    }
  ]
}
```

## كيفية العمل

### 1. تحميل البرامج
- يتم تحميل البرامج من API: `GET /api/v1/programs/support`
- يتم حفظ البيانات باللغتين العربية والإنجليزية
- يتم استخدام الحقول القديمة كـ fallback

### 2. عرض البرامج
- عند عرض البرنامج، يتم اختيار اللغة المناسبة حسب إعدادات التطبيق
- إذا لم تكن اللغة المطلوبة متوفرة، يتم استخدام اللغة البديلة

### 3. تبديل اللغة
- عند تغيير اللغة من الإعدادات، يتم تحديث جميع البرامج تلقائياً
- يتم إعادة بناء الواجهة لعرض المحتوى باللغة الجديدة

## الفوائد

1. **تجربة مستخدم محسنة**: عرض البرامج بلغة المستخدم المفضلة
2. **مرونة في العرض**: دعم كامل للعربية والإنجليزية
3. **تبديل سلس**: تغيير اللغة دون إعادة تحميل التطبيق
4. **توافق مع الإصدارات السابقة**: دعم للحقول القديمة

## الاختبار

1. افتح التطبيق وانتقل لصفحة تسجيل الطالب
2. لاحظ عرض البرامج باللغة الحالية في القائمة المنسدلة
3. اختر برنامج ولاحظ عرضه باللغة المناسبة
4. غيّر اللغة من الإعدادات
5. لاحظ تحديث أسماء البرامج تلقائياً

## التحسينات المستقبلية

1. إضافة دعم المزيد من اللغات
2. تحسين نظام التخزين المؤقت للبرامج
3. إضافة دعم للبحث في البرامج باللغتين
4. تحسين الأداء عند تحميل البرامج
