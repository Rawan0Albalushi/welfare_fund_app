# تحديث الصفحة الرئيسية بعد تسجيل الخروج

## المشكلة
الصفحة الرئيسية لا تتحدث تلقائياً بعد تسجيل الخروج، مما يعني أن المحتوى المخصص للمستخدمين المسجلين يبقى ظاهراً حتى إعادة تشغيل التطبيق.

## الحل المطبق

### 1. تحديث الصفحة الرئيسية لاستخدام AuthProvider

#### أ. إضافة Imports المطلوبة:
```dart
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
```

#### ب. تحديث دالة build لاستخدام Consumer:
```dart
@override
Widget build(BuildContext context) {
  return Consumer<AuthProvider>(
    builder: (context, authProvider, child) {
      final isAuthenticated = authProvider.isAuthenticated;
      final userProfile = authProvider.userProfile;
      
      print('HomeScreen: Building with isAuthenticated: $isAuthenticated');
      print('HomeScreen: User profile: ${userProfile?.keys}');
      
      return Scaffold(
        // ... باقي الكود
      );
    },
  );
}
```

#### ج. تحديث الدوال لاستخدام AuthProvider:
```dart
// تحديث دالة _onMyDonations
void _onMyDonations() async {
  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;
    
    if (!mounted) return;
    
    if (isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MyDonationsScreen(),
        ),
      );
    } else {
      _showLoginBottomSheet();
    }
  } catch (error) {
    if (mounted) {
      _showLoginBottomSheet();
    }
  }
}

// تحديث دالة _checkApplicationStatus
Future<void> _checkApplicationStatus() async {
  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;
    if (!isAuthenticated) return;
    
    // ... باقي الكود
  } catch (error) {
    // ... معالجة الأخطاء
  }
}

// تحديث دالة _onRegister
void _onRegister() async {
  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;
    print('Auth check result for student registration: $isAuthenticated');
    
    if (!isAuthenticated) {
      _showLoginBottomSheet();
      return;
    }
    
    // ... باقي الكود
  } catch (error) {
    _showLoginBottomSheet();
  }
}
```

### 2. إضافة مراقب لتغييرات حالة المصادقة

#### أ. إضافة Listener في initState:
```dart
@override
void initState() {
  super.initState();
  _loadSampleCampaigns();
  _checkApplicationStatus();
  
  // Listen to auth changes
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.addListener(_onAuthStateChanged);
  });
}
```

#### ب. إضافة دالة مراقبة التغييرات:
```dart
void _onAuthStateChanged() {
  // Update application status when auth state changes
  _checkApplicationStatus();
}
```

#### ج. تنظيف Listener في dispose:
```dart
@override
void dispose() {
  // Remove auth listener
  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.removeListener(_onAuthStateChanged);
  } catch (e) {
    // Ignore if provider is not available
  }
  
  _searchController.dispose();
  super.dispose();
}
```

## المزايا

### 1. التحديث التلقائي:
- ✅ تحديث فوري للصفحة الرئيسية عند تسجيل الدخول
- ✅ تحديث فوري للصفحة الرئيسية عند تسجيل الخروج
- ✅ تحديث حالة طلب التسجيل الطلابي تلقائياً

### 2. تحسين الأداء:
- ✅ استخدام Consumer بدلاً من استدعاء API في كل مرة
- ✅ تجنب إعادة بناء الصفحة غير الضرورية
- ✅ إدارة أفضل للموارد

### 3. تجربة مستخدم محسنة:
- ✅ استجابة فورية للتغييرات
- ✅ عدم الحاجة لإعادة تشغيل التطبيق
- ✅ عرض المحتوى المناسب لحالة المستخدم

## كيفية عمل التحديث

### 1. عند تسجيل الدخول:
1. `AuthProvider.login()` يتم استدعاؤها
2. حالة المصادقة تتحدث في `AuthProvider`
3. `notifyListeners()` يتم استدعاؤها
4. `Consumer<AuthProvider>` في الصفحة الرئيسية يكتشف التغيير
5. الصفحة الرئيسية تُعاد بناؤها مع المحتوى الجديد
6. `_onAuthStateChanged()` يتم استدعاؤها
7. `_checkApplicationStatus()` يتم استدعاؤها لتحديث حالة الطلب

### 2. عند تسجيل الخروج:
1. `AuthProvider.logout()` يتم استدعاؤها
2. حالة المصادقة تتحدث في `AuthProvider`
3. `notifyListeners()` يتم استدعاؤها
4. `Consumer<AuthProvider>` في الصفحة الرئيسية يكتشف التغيير
5. الصفحة الرئيسية تُعاد بناؤها مع المحتوى الجديد
6. `_onAuthStateChanged()` يتم استدعاؤها
7. `_checkApplicationStatus()` يتم استدعاؤها لمسح حالة الطلب

## الاختبار

### 1. تسجيل الدخول:
- ✅ فتح الصفحة الرئيسية
- ✅ تسجيل الدخول
- ✅ التحقق من تحديث المحتوى فوراً
- ✅ التحقق من ظهور بيانات المستخدم

### 2. تسجيل الخروج:
- ✅ فتح الصفحة الرئيسية
- ✅ تسجيل الخروج من الإعدادات
- ✅ التحقق من تحديث المحتوى فوراً
- ✅ التحقق من إخفاء المحتوى المخصص للمستخدمين المسجلين

### 3. مراقبة السجلات:
```bash
flutter run --debug
```

البحث عن الرسائل التالية:
- `HomeScreen: Building with isAuthenticated:`
- `AuthProvider: Login successful`
- `AuthProvider: Logout successful`

## النتيجة النهائية

بعد تطبيق التحديثات:
- ✅ تحديث فوري للصفحة الرئيسية عند تسجيل الدخول/الخروج
- ✅ عرض المحتوى المناسب لحالة المستخدم
- ✅ تحديث حالة طلب التسجيل الطلابي تلقائياً
- ✅ تحسين الأداء وتجربة المستخدم
- ✅ عدم الحاجة لإعادة تشغيل التطبيق
