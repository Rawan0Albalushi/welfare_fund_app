# تحديث نظام المصادقة في التبرع السريع

## التحديث المطلوب
تم تحديث نظام التبرع السريع ليدعم المستخدمين المسجلين وغير المسجلين، مثل نظام الدفع العادي.

## التغييرات المطبقة

### 1. دعم المستخدمين غير المسجلين
```dart
// قبل التحديث - يتطلب تسجيل دخول إجباري
if (token == null) {
  _showErrorSnackBar('login_required'.tr());
  return;
}

// بعد التحديث - دعم اختياري للمصادقة
final headers = <String, String>{
  'Content-Type': 'application/json',
};

// إضافة Authorization header فقط إذا كان المستخدم مسجل دخول
if (token != null && token.isNotEmpty) {
  headers['Authorization'] = 'Bearer $token';
  print('QuickDonate: Using authenticated request with token');
} else {
  print('QuickDonate: Using anonymous donation request');
}
```

### 2. تحديث دالة إنشاء التبرع
```dart
Future<void> _processPayment() async {
  setState(() {
    _isLoading = true;
  });

  try {
    // ✅ احصل على التوكن (اختياري)
    final token = await _getAuthToken();
    
    // إعداد headers
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    // إضافة Authorization header فقط إذا كان المستخدم مسجل دخول
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    // استدعاء API مع headers مناسبة
    final response = await http.post(
      Uri.parse('http://192.168.100.105:8000/api/v1/donations/with-payment'),
      headers: headers,
      body: jsonEncode({
        'program_id': programId,
        'amount': widget.amount,
        'donor_name': 'متبرع',
        'note': 'تبرع سريع للطلاب المحتاجين',
        'is_anonymous': false,
        'type': 'quick',
        'return_origin': origin,
      }),
    );
    // ... باقي الكود
  }
}
```

### 3. تحديث دالة تأكيد الدفع
```dart
Future<void> _confirmPayment(String sessionId) async {
  try {
    final token = await _getAuthToken();
    
    // إعداد headers
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    // إضافة Authorization header فقط إذا كان المستخدم مسجل دخول
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    final response = await http.post(
      Uri.parse('http://192.168.100.105:8000/api/v1/payments/confirm'),
      headers: headers,
      body: jsonEncode({
        'session_id': sessionId,
      }),
    );
    // ... باقي الكود
  }
}
```

## السلوك الجديد

### للمستخدمين المسجلين:
- ✅ يتم إرسال `Authorization: Bearer {token}` في headers
- ✅ يتم ربط التبرع بحساب المستخدم
- ✅ يظهر التبرع في قائمة "تبرعاتي"
- ✅ يحصل على إشعارات التبرع

### للمستخدمين غير المسجلين:
- ✅ يتم إرسال طلب بدون Authorization header
- ✅ يتم إنشاء تبرع مجهول
- ✅ لا يظهر في قائمة "تبرعاتي" (لأنه غير مسجل دخول)
- ✅ يمكنه التبرع بحرية تامة

## رسائل Debug
```dart
// للمستخدمين المسجلين:
print('QuickDonate: Using authenticated request with token');

// للمستخدمين غير المسجلين:
print('QuickDonate: Using anonymous donation request');
```

## API Requests

### للمستخدمين المسجلين:
```http
POST /api/v1/donations/with-payment
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
Content-Type: application/json

{
  "program_id": 1,
  "amount": 50.0,
  "donor_name": "متبرع",
  "note": "تبرع سريع للطلاب المحتاجين",
  "is_anonymous": false,
  "type": "quick",
  "return_origin": "http://localhost:8080"
}
```

### للمستخدمين غير المسجلين:
```http
POST /api/v1/donations/with-payment
Content-Type: application/json

{
  "program_id": 1,
  "amount": 50.0,
  "donor_name": "متبرع",
  "note": "تبرع سريع للطلاب المحتاجين",
  "is_anonymous": false,
  "type": "quick",
  "return_origin": "http://localhost:8080"
}
```

## المميزات الجديدة

### ✅ مرونة في المصادقة
- دعم المستخدمين المسجلين وغير المسجلين
- لا حاجة لتسجيل دخول إجباري
- تجربة مستخدم محسنة

### ✅ توافق مع النظام العادي
- نفس منطق الدفع العادي
- نفس معالجة الأخطاء
- نفس تدفق العملية

### ✅ أمان محافظ عليه
- التحقق من التوكن عند وجوده
- معالجة آمنة للبيانات
- حماية من الأخطاء

## كيفية الاختبار

### للمستخدمين المسجلين:
1. سجل دخولك
2. اذهب للتبرع السريع
3. اختر المبلغ والفئة
4. اضغط "إتمام التبرع"
5. ستظهر رسالة: "Using authenticated request with token"

### للمستخدمين غير المسجلين:
1. تأكد من عدم تسجيل الدخول
2. اذهب للتبرع السريع
3. اختر المبلغ والفئة
4. اضغط "إتمام التبرع"
5. ستظهر رسالة: "Using anonymous donation request"

## الملفات المعدلة
- `lib/screens/quick_donate_payment_screen.dart`

## النتيجة
الآن التبرع السريع يعمل بنفس منطق الدفع العادي، ويدعم جميع أنواع المستخدمين بدون قيود.
