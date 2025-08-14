# تحديث تسجيل الخروج والتنقل

## المشكلة
بعد تسجيل الخروج، التطبيق لا يعود للصفحة الرئيسية ولا يحدث حالة الطلب تلقائياً.

## الحل المطبق

### 1. تحديث دالة تسجيل الخروج في SettingsScreen

#### أ. إضافة التنقل للصفحة الرئيسية:
```dart
// Navigate back to home screen and clear navigation stack
if (mounted) {
  Navigator.of(context).pushNamedAndRemoveUntil(
    AppConstants.homeRoute,
    (route) => false,
  );
}
```

#### ب. إضافة import المطلوب:
```dart
import '../constants/app_constants.dart';
```

### 2. تحسين تحديث حالة الطلب في HomeScreen

#### أ. إضافة debug prints للتتبع:
```dart
void _onAuthStateChanged() {
  print('HomeScreen: Auth state changed, updating application status...');
  _checkApplicationStatus();
}
```

#### ب. تحسين معالجة حالة عدم تسجيل الدخول:
```dart
if (!isAuthenticated) {
  print('HomeScreen: User not authenticated, clearing application data');
  setState(() {
    _applicationData = null;
    _isCheckingApplication = false;
  });
  return;
}
```

### 3. تحسين AuthProvider

#### أ. إضافة debug prints في دالة logout:
```dart
print('AuthProvider: Starting logout process...');
print('AuthProvider: Logout successful. isAuthenticated: $_isAuthenticated');
print('AuthProvider: Logout process completed, notifying listeners');
```

## كيفية عمل التحديث

### 1. عند تسجيل الخروج:
1. المستخدم يضغط على "تسجيل الخروج" في الإعدادات
2. `_performLogout()` يتم استدعاؤها
3. `AuthProvider.logout()` يتم استدعاؤها
4. حالة المصادقة تتحدث (`_isAuthenticated = false`)
5. `notifyListeners()` يتم استدعاؤها
6. `Consumer<AuthProvider>` في الصفحة الرئيسية يكتشف التغيير
7. `_onAuthStateChanged()` يتم استدعاؤها
8. `_checkApplicationStatus()` يتم استدعاؤها وتُمسح بيانات الطلب
9. `Navigator.pushNamedAndRemoveUntil()` يعود للصفحة الرئيسية
10. الصفحة الرئيسية تُعاد بناؤها مع المحتوى الجديد

### 2. التحديث التلقائي:
- ✅ مسح بيانات الطلب عند تسجيل الخروج
- ✅ العودة للصفحة الرئيسية
- ✅ مسح stack التنقل
- ✅ تحديث UI فوراً

## الاختبار

### 1. تسجيل الخروج:
- ✅ فتح الإعدادات
- ✅ تسجيل الخروج
- ✅ التحقق من العودة للصفحة الرئيسية
- ✅ التحقق من مسح بيانات الطلب
- ✅ التحقق من عدم ظهور المحتوى المخصص للمستخدمين المسجلين

### 2. مراقبة السجلات:
```bash
flutter run --debug
```

البحث عن الرسائل التالية:
- `AuthProvider: Starting logout process...`
- `AuthProvider: Logout successful. isAuthenticated: false`
- `HomeScreen: Auth state changed, updating application status...`
- `HomeScreen: User not authenticated, clearing application data`

## النتيجة النهائية

بعد تطبيق التحديثات:
- ✅ العودة التلقائية للصفحة الرئيسية بعد تسجيل الخروج
- ✅ مسح بيانات الطلب تلقائياً
- ✅ تحديث UI فوراً
- ✅ مسح stack التنقل
- ✅ تجربة مستخدم محسنة
