# API URL Update to 192.168.100.105 - تحديث عنوان API

## Summary - ملخص

تم تحديث جميع عناوين API في التطبيق من `192.168.1.101:8000` إلى `192.168.100.105:8000` لضمان الاتصال الصحيح مع الخادم.

All API URLs in the application have been updated from `192.168.1.101:8000` to `192.168.100.105:8000` to ensure proper server connectivity.

## Files Updated - الملفات المحدثة

### 1. API Client Service
**File:** `lib/services/api_client.dart`
- **Before:** `const baseUrl = 'http://192.168.1.101:8000/api/v1';`
- **After:** `const baseUrl = 'http://192.168.100.105:8000/api/v1';`

### 2. Authentication Service
**File:** `lib/services/auth_service.dart`
- **Before:** `const baseUrl = 'http://192.168.1.101:8000/api';`
- **After:** `const baseUrl = 'http://192.168.100.105:8000/api';`

### 3. Payment Service
**File:** `lib/services/payment_service.dart`
- **Before:** `static const String _baseUrl = 'http://192.168.1.101:8000/api/v1';`
- **After:** `static const String _baseUrl = 'http://192.168.100.105:8000/api/v1';`

### 4. Donation Service
**File:** `lib/services/donation_service.dart`
- **Before:** `'http://192.168.1.101:8000/api/v1'`
- **After:** `'http://192.168.100.105:8000/api/v1'`

**Updated in multiple locations:**
- Platform-specific URLs for Android and iOS
- Fallback base URL

## How the Update Works - كيفية عمل التحديث

### 1. Service Initialization
```dart
// في main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API Client
  await ApiClient().initialize();
  
  // Initialize Auth Service
  await AuthService().initialize();
  
  runApp(const StudentWelfareFundApp());
}
```

### 2. New URL Configuration
```dart
// في api_client.dart
const baseUrl = 'http://192.168.100.105:8000/api/v1';

// في auth_service.dart
const baseUrl = 'http://192.168.100.105:8000/api';

// في payment_service.dart
static const String _baseUrl = 'http://192.168.100.105:8000/api/v1';

// في donation_service.dart
if (Platform.isAndroid) return 'http://192.168.100.105:8000/api/v1';
if (Platform.isIOS) return 'http://192.168.100.105:8000/api/v1';
```

## Verification - التأكد من التحديث

### 1. Run the Application
```bash
flutter run
```

### 2. Monitor Console Output
ستظهر رسائل في Console تؤكد العناوين الجديدة:
```
API Base URL: http://192.168.100.105:8000/api/v1
AuthService: Using base URL: http://192.168.100.105:8000/api
```

## Testing - اختبار الاتصال

### 1. Test Student Registration
- انتقل إلى شاشة تسجيل الطالب
- املأ النموذج
- اضغط على "إرسال الطلب"
- تأكد من عدم ظهور أخطاء اتصال

### 2. Test Authentication
- جرب تسجيل الدخول
- تأكد من نجاح العملية
- تحقق من حفظ البيانات

### 3. Test Donations
- جرب إنشاء تبرع
- تأكد من نجاح عملية الدفع
- تحقق من حفظ التبرع

### 4. Test Payment Flow
- جرب عملية الدفع الكاملة
- تأكد من نجاح المعاملة
- تحقق من تحديث الحالة

## Network Configuration - إعدادات الشبكة

### Server Details
- **Server IP:** `192.168.100.105`
- **Port:** `8000`
- **API Base URL:** `http://192.168.100.105:8000/api/v1`
- **Auth URL:** `http://192.168.100.105:8000/api`

### Network Requirements
- تأكد من أن الجهاز متصل بنفس الشبكة
- تأكد من أن الخادم يعمل على العنوان الجديد
- تأكد من عدم وجود جدار حماية يمنع الاتصال

## Troubleshooting - استكشاف الأخطاء

### Common Issues
1. **Connection Timeout:** تأكد من أن الخادم يعمل
2. **404 Errors:** تأكد من صحة مسارات API
3. **Authentication Errors:** تأكد من صحة التوكن

### Debug Steps
1. تحقق من Console للرسائل التشخيصية
2. تأكد من اتصال الشبكة
3. جرب الوصول للخادم من المتصفح
4. تحقق من إعدادات الخادم

## Previous Updates - التحديثات السابقة

This update replaces the previous configuration that used `192.168.1.101:8000`. All services have been consistently updated to use the new IP address `192.168.100.105:8000`.

تم استبدال الإعداد السابق الذي كان يستخدم `192.168.1.101:8000`. تم تحديث جميع الخدمات بشكل متسق لاستخدام عنوان IP الجديد `192.168.100.105:8000`.