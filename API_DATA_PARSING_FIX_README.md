# إصلاح مشكلة تحليل البيانات من API

## المشكلة
كان هناك خطأ في تحويل البيانات من API:
```
CampaignService: Error fetching programs: NoSuchMethodError: 'toDouble' Dynamic call of null.
Receiver: "50000.00"
Arguments: []
```

## السبب
البيانات تأتي من API كـ strings وليس numbers:
- `goal_amount: "50000.00"` (string)
- `raised_amount: "35100.00"` (string)

لكن الكود كان يحاول استدعاء `.toDouble()` مباشرة.

## الحل المطبق

### 1. إضافة دالة مساعدة لتحليل البيانات
```dart
// Helper method to parse double values from API
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}
```

### 2. تحديث تحليل البيانات
```dart
// Before (causing error)
targetAmount: (program['goal_amount'] ?? 0).toDouble(),
currentAmount: (program['raised_amount'] ?? 0).toDouble(),

// After (fixed)
targetAmount: _parseDouble(program['goal_amount'] ?? 0),
currentAmount: _parseDouble(program['raised_amount'] ?? 0),
```

### 3. إضافة Debug Logging
```dart
// Debug: Print first program data types
if (programsData.isNotEmpty) {
  final firstProgram = programsData.first;
  print('CampaignService: First program goal_amount type: ${firstProgram['goal_amount'].runtimeType}');
  print('CampaignService: First program raised_amount type: ${firstProgram['raised_amount'].runtimeType}');
  print('CampaignService: First program goal_amount value: ${firstProgram['goal_amount']}');
  print('CampaignService: First program raised_amount value: ${firstProgram['raised_amount']}');
}
```

### 4. تحسين معالجة الأخطاء
```dart
} catch (error) {
  print('HomeScreen: Error loading campaigns from API: $error');
  setState(() {
    _isLoadingCampaigns = false;
  });
  
  // Use fallback data
  print('HomeScreen: Using fallback sample data');
  _loadSampleCampaigns();
  
  // Show user-friendly message
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('حدث خطأ في تحميل البرامج، سيتم استخدام البيانات المحلية'),
        backgroundColor: AppColors.warning,
      ),
    );
  }
}
```

## المزايا

### 1. معالجة شاملة للبيانات:
- ✅ يدعم String, int, double, null
- ✅ تحويل آمن للبيانات
- ✅ قيم افتراضية عند الفشل

### 2. Debug Logging:
- ✅ تتبع نوع البيانات
- ✅ تتبع قيم البيانات
- ✅ تسهيل اكتشاف المشاكل

### 3. تجربة مستخدم محسنة:
- ✅ رسائل خطأ واضحة
- ✅ استخدام البيانات الاحتياطية
- ✅ عدم توقف التطبيق

## الاختبار

### 1. اختبار البيانات المختلفة:
```dart
// Test different data types
print(_parseDouble("50000.00")); // 50000.0
print(_parseDouble(50000)); // 50000.0
print(_parseDouble(50000.0)); // 50000.0
print(_parseDouble(null)); // 0.0
print(_parseDouble("invalid")); // 0.0
```

### 2. مراقبة السجلات:
```bash
flutter run --debug
```

البحث عن الرسائل التالية:
- `CampaignService: First program goal_amount type:`
- `CampaignService: First program goal_amount value:`
- `HomeScreen: Using fallback sample data`

## النتيجة النهائية

بعد تطبيق الإصلاح:
- ✅ تحليل صحيح للبيانات من API
- ✅ معالجة شاملة لأنواع البيانات المختلفة
- ✅ تجربة مستخدم سلسة حتى مع الأخطاء
- ✅ Debug logging شامل للتتبع
- ✅ Fallback للبيانات المحلية عند الحاجة
