# عرض بيانات المستخدم في صفحة الإعدادات

## المشكلة
لا يتم عرض اسم المستخدم ورقم الهاتف في صفحة الإعدادات رغم أن المستخدم مسجل دخول.

## التحليل

### 1. المشكلة المحتملة:
- بنية البيانات القادمة من API قد تكون مختلفة عما نتوقعه
- البيانات قد تكون متداخلة في `data` أو `user` object
- الحقول قد تكون بأسماء مختلفة

### 2. النقاط المحتملة للمشكلة:

#### أ. بنية استجابة `/auth/me`:
```json
// احتمال 1: بيانات مباشرة
{
  "name": "اسم المستخدم",
  "email": "user@example.com",
  "phone": "+966501234567"
}

// احتمال 2: بيانات في data object
{
  "data": {
    "name": "اسم المستخدم",
    "email": "user@example.com",
    "phone": "+966501234567"
  }
}

// احتمال 3: بيانات في user object
{
  "user": {
    "name": "اسم المستخدم",
    "email": "user@example.com",
    "phone": "+966501234567"
  }
}
```

#### ب. أسماء الحقول المحتملة:
- `name` أو `user_name` أو `full_name`
- `email` أو `user_email`
- `phone` أو `phone_number` أو `mobile`

## الحلول المطبقة

### 1. تحسين AuthProvider:
```dart
// Load user profile
Future<void> _loadUserProfile() async {
  try {
    final profile = await _authService.getCurrentUser();
    print('AuthProvider: Raw profile data: $profile');
    print('AuthProvider: Profile keys: ${profile.keys}');
    
    // Handle different response structures
    if (profile['data'] != null) {
      _userProfile = profile['data'];
      print('AuthProvider: Using profile.data: ${_userProfile}');
    } else {
      _userProfile = profile;
      print('AuthProvider: Using profile directly: ${_userProfile}');
    }
    
    _isAuthenticated = true;
    print('AuthProvider: User profile loaded successfully. isAuthenticated: $_isAuthenticated');
    print('AuthProvider: Final userProfile keys: ${_userProfile?.keys}');
  } catch (error) {
    print('Error loading user profile: $error');
    _isAuthenticated = false;
    _userProfile = null;
  }
}
```

### 2. تحسين صفحة الإعدادات:
```dart
Widget _buildAuthenticatedProfileSection(Map<String, dynamic>? userProfile) {
  print('SettingsScreen: Building profile section with userProfile: $userProfile');
  
  // محاولة استخراج البيانات من بنى مختلفة
  final userName = userProfile?['name'] ?? 
                  userProfile?['user']?['name'] ?? 
                  userProfile?['user_name'] ?? 
                  userProfile?['full_name'] ?? 
                  'المستخدم';
                  
  final userEmail = userProfile?['email'] ?? 
                   userProfile?['user']?['email'] ?? 
                   userProfile?['user_email'] ?? 
                   '';
                   
  final userPhone = userProfile?['phone'] ?? 
                   userProfile?['user']?['phone'] ?? 
                   userProfile?['phone_number'] ?? 
                   userProfile?['mobile'] ?? 
                   '';
  
  print('SettingsScreen: Extracted userName: $userName');
  print('SettingsScreen: Extracted userEmail: $userEmail');
  print('SettingsScreen: Extracted userPhone: $userPhone');
  
  // ... باقي الكود
}
```

### 3. تحسين AuthService:
```dart
// Get current user profile
Future<Map<String, dynamic>> getCurrentUser() async {
  try {
    final response = await _dio!.get('/auth/me');
    print('AuthService: getCurrentUser response: ${response.data}');
    print('AuthService: getCurrentUser response keys: ${response.data.keys}');
    return response.data;
  } on DioException catch (e) {
    throw _handleDioError(e);
  }
}
```

## خطوات التشخيص

### 1. مراقبة السجلات:
```bash
flutter run --debug
```

### 2. البحث عن الرسائل التالية:
- `AuthService: getCurrentUser response:`
- `AuthProvider: Raw profile data:`
- `SettingsScreen: Building profile section with userProfile:`
- `SettingsScreen: Extracted userName:`

### 3. تحليل بنية البيانات:
- تحديد البنية الفعلية للبيانات القادمة من API
- تحديد أسماء الحقول الصحيحة
- تحديد مستوى التداخل في البيانات

## الحلول المحتملة

### الحل 1: تعديل أسماء الحقول
إذا كانت أسماء الحقول مختلفة، قم بتحديث الكود ليتطابق مع API.

### الحل 2: إضافة معالجة إضافية
```dart
// دالة مساعدة لاستخراج البيانات
String _extractUserData(Map<String, dynamic>? profile, List<String> possibleKeys) {
  if (profile == null) return '';
  
  for (String key in possibleKeys) {
    if (profile.containsKey(key) && profile[key] != null) {
      return profile[key].toString();
    }
  }
  
  // البحث في user object إذا كان موجوداً
  if (profile.containsKey('user') && profile['user'] is Map) {
    for (String key in possibleKeys) {
      if (profile['user'].containsKey(key) && profile['user'][key] != null) {
        return profile['user'][key].toString();
      }
    }
  }
  
  return '';
}

// استخدام الدالة
final userName = _extractUserData(userProfile, ['name', 'user_name', 'full_name']);
final userEmail = _extractUserData(userProfile, ['email', 'user_email']);
final userPhone = _extractUserData(userProfile, ['phone', 'phone_number', 'mobile']);
```

### الحل 3: تحديث API
إذا كان API يعيد بنية غير متوقعة، يمكن طلب تحديث API ليعيد البيانات بالشكل المطلوب.

## الاختبار

### 1. تسجيل الدخول:
- تأكد من تسجيل الدخول بنجاح
- مراقبة رسائل debug

### 2. فتح صفحة الإعدادات:
- تأكد من ظهور المحتوى المخصص للمستخدمين المسجلين
- مراقبة رسائل debug لبيانات المستخدم

### 3. التحقق من البيانات:
- تأكد من عرض اسم المستخدم
- تأكد من عرض رقم الهاتف
- تأكد من عرض البريد الإلكتروني (إذا كان متوفراً)

## النتيجة المتوقعة

بعد تطبيق الحلول:
- ✅ عرض اسم المستخدم في صفحة الإعدادات
- ✅ عرض رقم الهاتف في صفحة الإعدادات
- ✅ عرض البريد الإلكتروني (إذا كان متوفراً)
- ✅ رسائل debug واضحة لمراقبة البيانات
- ✅ معالجة مرنة لبنى البيانات المختلفة
