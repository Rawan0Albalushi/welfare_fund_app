# تكامل التبرع السريع مع الحملات

## التحديث المطلوب
تم تحديث التبرع السريع ليربط التبرعات بحملات محددة تابعة للفئة المختارة، وعرض الفئات التي تحتوي على حملات فقط.

## التغييرات المطبقة

### 1. تحميل الحملات بدلاً من الفئات
```dart
// قبل التحديث - تحميل فئات منفصلة
final categories = await _campaignService.getCategories();

// بعد التحديث - تحميل الحملات وتجميعها حسب الفئة
final campaigns = await _campaignService.getCharityCampaigns();
```

### 2. تجميع الحملات حسب الفئة
```dart
// Group campaigns by category
final Map<String, List<Map<String, dynamic>>> groupedCampaigns = {};

for (var campaign in campaigns) {
  final categoryName = campaign.category;
  if (!groupedCampaigns.containsKey(categoryName)) {
    groupedCampaigns[categoryName] = [];
  }
  groupedCampaigns[categoryName]!.add({
    'id': campaign.id,
    'title': campaign.title,
    'description': campaign.description,
    'category': campaign.category,
  });
}
```

### 3. إنشاء فئات من الحملات المجمعة
```dart
// Create categories from grouped campaigns
final categoriesWithCampaigns = <Map<String, dynamic>>[];
groupedCampaigns.forEach((categoryName, campaignList) {
  categoriesWithCampaigns.add({
    'id': categoryName,
    'title': categoryName,
    'description': '${campaignList.length} حملة متاحة',
    'icon': _getCategoryIcon(categoryName),
    'color': _getCategoryColor(categoryName),
    'campaigns': campaignList,
    'campaign_count': campaignList.length,
  });
});
```

### 4. دوال مساعدة للأيقونات والألوان
```dart
IconData _getCategoryIcon(String categoryName) {
  switch (categoryName.toLowerCase()) {
    case 'تعليم':
    case 'education':
      return Icons.school;
    case 'سكن':
    case 'housing':
      return Icons.home;
    case 'أجهزة':
    case 'devices':
      return Icons.computer;
    case 'امتحانات':
    case 'exams':
      return Icons.assignment;
    case 'صحة':
    case 'health':
      return Icons.health_and_safety;
    case 'طعام':
    case 'food':
      return Icons.restaurant;
    default:
      return Icons.category;
  }
}

Color _getCategoryColor(String categoryName) {
  switch (categoryName.toLowerCase()) {
    case 'تعليم':
    case 'education':
      return AppColors.primary;
    case 'سكن':
    case 'housing':
      return AppColors.secondary;
    case 'أجهزة':
    case 'devices':
      return AppColors.accent;
    case 'امتحانات':
    case 'exams':
      return AppColors.success;
    case 'صحة':
    case 'health':
      return Colors.red;
    case 'طعام':
    case 'food':
      return Colors.orange;
    default:
      return AppColors.primary;
  }
}
```

### 5. تحديث API لاستخدام campaign_id
```dart
// قبل التحديث
body: jsonEncode({
  'program_id': programId,
  // ...
}),

// بعد التحديث
body: jsonEncode({
  'campaign_id': campaignId,
  // ...
}),
```

### 6. دالة الحصول على campaign_id
```dart
int _getCampaignIdFromCategory() {
  // إذا كانت الفئة المختارة موجودة في القائمة، استخدم أول حملة من الفئة
  if (widget.selectedCategory != null) {
    final category = widget.categories.firstWhere(
      (cat) => cat['id'] == widget.selectedCategory,
      orElse: () => {'campaigns': []}, // fallback
    );
    
    final campaigns = category['campaigns'] as List<Map<String, dynamic>>?;
    if (campaigns != null && campaigns.isNotEmpty) {
      return int.tryParse(campaigns.first['id'].toString()) ?? 1;
    }
  }
  return 1; // fallback campaign ID
}
```

## السلوك الجديد

### 1. عرض الفئات
- ✅ تظهر فقط الفئات التي تحتوي على حملات
- ✅ كل فئة تعرض عدد الحملات المتاحة
- ✅ أيقونات وألوان مميزة لكل فئة

### 2. ربط التبرع بالحملة
- ✅ التبرع يذهب لأول حملة في الفئة المختارة
- ✅ استخدام `campaign_id` بدلاً من `program_id`
- ✅ ربط مباشر بالحملة المحددة

### 3. تجميع ذكي
- ✅ تجميع الحملات حسب الفئة تلقائياً
- ✅ عرض عدد الحملات في كل فئة
- ✅ إخفاء الفئات الفارغة

## مثال على البيانات

### الحملات المحملة:
```json
[
  {
    "id": 1,
    "title": "حملة دعم الطلاب المحتاجين",
    "category": "تعليم"
  },
  {
    "id": 2,
    "title": "حملة المنح الدراسية",
    "category": "تعليم"
  },
  {
    "id": 3,
    "title": "حملة توفير أجهزة حاسوب",
    "category": "أجهزة"
  }
]
```

### الفئات المعروضة:
```json
[
  {
    "id": "تعليم",
    "title": "تعليم",
    "description": "2 حملة متاحة",
    "icon": "Icons.school",
    "color": "AppColors.primary",
    "campaigns": [
      {"id": 1, "title": "حملة دعم الطلاب المحتاجين"},
      {"id": 2, "title": "حملة المنح الدراسية"}
    ],
    "campaign_count": 2
  },
  {
    "id": "أجهزة",
    "title": "أجهزة",
    "description": "1 حملة متاحة",
    "icon": "Icons.computer",
    "color": "AppColors.accent",
    "campaigns": [
      {"id": 3, "title": "حملة توفير أجهزة حاسوب"}
    ],
    "campaign_count": 1
  }
]
```

## API Request الجديد
```http
POST /api/v1/donations/with-payment
Content-Type: application/json

{
  "campaign_id": 1,
  "amount": 50.0,
  "donor_name": "متبرع",
  "note": "تبرع سريع للطلاب المحتاجين",
  "is_anonymous": false,
  "type": "quick",
  "return_origin": "http://localhost:8080"
}
```

## المميزات الجديدة

### ✅ ربط مباشر بالحملات
- التبرع يذهب لحملة محددة
- لا تبرعات عامة أو غير محددة
- تتبع أفضل للتبرعات

### ✅ عرض ذكي للفئات
- فئات تحتوي على حملات فقط
- عدد الحملات في كل فئة
- أيقونات وألوان مميزة

### ✅ تجميع تلقائي
- تجميع الحملات حسب الفئة
- إخفاء الفئات الفارغة
- تحديث ديناميكي

## كيفية الاختبار

1. افتح التطبيق
2. اذهب للتبرع السريع
3. ستظهر فئات تحتوي على حملات فقط
4. اختر فئة (مثل "تعليم - 2 حملة متاحة")
5. اختر المبلغ واضغط "متابعة الدفع"
6. سيتم إرسال التبرع لأول حملة في الفئة المختارة

## الملفات المعدلة
- `lib/screens/quick_donate_amount_screen.dart`
- `lib/screens/quick_donate_payment_screen.dart`

## النتيجة
الآن التبرع السريع يربط التبرعات بحملات محددة، ويعرض فقط الفئات التي تحتوي على حملات متاحة.
