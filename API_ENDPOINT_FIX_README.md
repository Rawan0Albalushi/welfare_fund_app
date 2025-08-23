# 🔧 إصلاح API Endpoints

## المشكلة
كانت بعض الملفات تستخدم الـ endpoint الخاطئ:
- ❌ `http://192.168.1.21:8000/api`
- ✅ `http://192.168.1.21:8000/api/v1`

## الملفات التي تم إصلاحها

### 1. `lib/services/api_client.dart`
```dart
// قبل الإصلاح
const baseUrl = 'http://192.168.1.21:8000/api';

// بعد الإصلاح
const baseUrl = 'http://192.168.1.21:8000/api/v1';
```

### 2. `lib/services/auth_service.dart`
```dart
// قبل الإصلاح
const baseUrl = 'http://192.168.1.21:8000/api';

// بعد الإصلاح
const baseUrl = 'http://192.168.1.21:8000/api/v1';
```

## الملفات التي كانت صحيحة بالفعل

### 1. `lib/services/donation_service.dart`
```dart
static const String _baseUrl = 'http://192.168.1.21:8000/api/v1';
```

### 2. `lib/services/payment_service.dart`
```dart
static const String _baseUrl = 'http://192.168.1.21:8000/api/v1';
```

## النتيجة

الآن جميع الـ endpoints تستخدم المسار الصحيح:
- ✅ `POST /api/v1/donations/with-payment`
- ✅ `POST /api/v1/payments/create`
- ✅ `GET /api/v1/payments/status/{sessionId}`
- ✅ `POST /api/v1/auth/login`
- ✅ `POST /api/v1/auth/register`

## اختبار التطبيق

بعد هذا الإصلاح، يجب أن يعمل التطبيق بشكل صحيح:
1. ✅ إنشاء التبرع
2. ✅ فتح صفحة الدفع
3. ✅ إتمام عملية الدفع

## ملاحظة

هذا الإصلاح يضمن أن جميع الطلبات تذهب إلى الـ API الصحيح مع الإصدار المطلوب `/v1`.
