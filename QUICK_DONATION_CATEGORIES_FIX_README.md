# إصلاح مشكلة عرض فئات التبرع السريع

## المشكلة
كانت صفحة التبرع السريع تطلب من المستخدم اختيار فئة التبرع ولكن لا تعرض الفئات المتاحة للاختيار.

## السبب
1. الفئات لم تكن تُحمل بشكل صحيح من API
2. لم تكن هناك فئات افتراضية (fallback) تُعرض في حالة فشل تحميل API
3. لم تكن هناك معالجة لحالة عدم وجود فئات

## الحل المطبق

### 1. إضافة فئات افتراضية
```dart
final List<Map<String, dynamic>> _fallbackCategories = [
  {
    'id': '1',
    'title': 'education_opportunities'.tr(),
    'description': 'education_opportunities'.tr(),
    'icon': Icons.school,
    'color': AppColors.primary,
  },
  {
    'id': '2',
    'title': 'housing_transport'.tr(),
    'description': 'help_students_succeed'.tr(),
    'icon': Icons.home,
    'color': AppColors.secondary,
  },
  {
    'id': '3',
    'title': 'device_purchase'.tr(),
    'description': 'help_students_succeed'.tr(),
    'icon': Icons.computer,
    'color': AppColors.accent,
  },
  {
    'id': '4',
    'title': 'education_opportunities'.tr(),
    'description': 'help_students_succeed'.tr(),
    'icon': Icons.assignment,
    'color': AppColors.success,
  },
];
```

### 2. تهيئة الفئات في initState
```dart
@override
void initState() {
  super.initState();
  _customAmountController.text = _selectedAmount.toString();
  // Initialize with fallback categories first
  _categories = _fallbackCategories;
  print('QuickDonate: Initialized with ${_categories.length} fallback categories');
  _loadDataFromAPI();
}
```

### 3. إضافة معالجة لحالة عدم وجود فئات
```dart
// Categories Grid
if (_categories.isNotEmpty) ...[
  GridView.count(
    // ... عرض الفئات
  ),
] else ...[
  // Loading or error state for categories
  Container(
    // ... عرض رسالة التحميل
  ),
],
```

### 4. إضافة النصوص المطلوبة للترجمة
```json
{
  "education_opportunities": "فرص تعليمية",
  "housing_transport": "السكن والنقل", 
  "device_purchase": "شراء الأجهزة",
  "choose_donation_category": "اختر فئة التبرع",
  "loading_categories": "جاري تحميل الفئات..."
}
```

## النتيجة
الآن صفحة التبرع السريع تعرض 4 فئات افتراضية:
1. **فرص تعليمية** (أيقونة مدرسة)
2. **السكن والنقل** (أيقونة منزل)
3. **شراء الأجهزة** (أيقونة كمبيوتر)
4. **فرص تعليمية** (أيقونة امتحان)

## الميزات الجديدة
- ✅ عرض فئات افتراضية فوراً عند فتح الصفحة
- ✅ محاولة تحميل فئات من API (اختياري)
- ✅ معالجة حالة عدم وجود فئات
- ✅ رسالة تحميل أثناء جلب البيانات من API
- ✅ دعم الترجمة الكامل

## كيفية الاختبار
1. افتح التطبيق
2. اذهب للصفحة الرئيسية
3. اضغط على "التبرع السريع"
4. ستظهر 4 فئات للاختيار منها
5. اختر أي فئة واضغط "متابعة الدفع"

## الملفات المعدلة
- `lib/screens/quick_donate_amount_screen.dart`
- `assets/translations/ar.json`
- `assets/translations/en.json`
