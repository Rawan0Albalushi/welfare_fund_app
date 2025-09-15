# إصلاح مشكلة استخراج بيانات جلسة الدفع

## المشكلة
كان هناك خطأ في استخراج `sessionId` و `checkoutUrl` من استجابة API، مما يؤدي إلى خطأ:
```
❌ Error: TypeError: null: type 'Null' is not a subtype of type 'String'
```

## السبب
كان الكود يحاول استخراج البيانات من المسارات الخطأ في استجابة API.

### استجابة API الفعلية:
```json
{
  "message": "Donation and payment session created successfully",
  "data": {
    "donation": {
      "program_id": null,
      "campaign_id": 1,
      "amount": 6.00,
      "donor_name": "متبرع",
      "note": "تبرع سريع للطلاب المحتاجين",
      "type": "quick",
      "status": "pending",
      "user_id": null,
      "expires_at": "2025-09-21T11:19:53.000000Z",
      "donation_id": "DN_b0bb3d5e-d8b8-4c28-adb4-eb0039ff193f",
      "updated_at": "2025-09-14T11:19:53.000000Z",
      "created_at": "2025-09-14T11:19:52.000000Z",
      "id": 206,
      "payment_session_id": "checkout_dp7mWcR6ETDHpwuB3DyKwjNMI3JuPdi3wyCyhhQ6JXOxcumppQ",
      "payment_url": "https://uatcheckout.thawani.om/pay/checkout_dp7mWcR6ETDHpwuB3DyKwjNMI3JuPdi3wyCyhhQ6JXOxcumppQ?key=HGvTMLDssJghr9tlN9gr4DVYt0qyBy"
    },
    "payment_session": {
      "session_id": "checkout_dp7mWcR6ETDHpwuB3DyKwjNMI3JuPdi3wyCyhhQ6JXOxcumppQ",
      "payment_url": "https://uatcheckout.thawani.om/pay/checkout_dp7mWcR6ETDHpwuB3DyKwjNMI3JuPdi3wyCyhhQ6JXOxcumppQ?key=HGvTMLDssJghr9tlN9gr4DVYt0qyBy"
    }
  }
}
```

## الحل المطبق

### 1. إصلاح استخراج sessionId
```dart
// قبل الإصلاح - مسارات خاطئة
final sessionId = data['session_id'] ?? data['data']?['session_id'];

// بعد الإصلاح - مسارات صحيحة
final sessionId = data['data']?['payment_session']?['session_id'] ?? 
                 data['session_id'] ?? 
                 data['data']?['session_id'];
```

### 2. إصلاح استخراج checkoutUrl
```dart
// قبل الإصلاح - مسارات خاطئة
final checkoutUrl = data['checkout_url'] ?? data['data']?['checkout_url'] ?? data['payment_url'];

// بعد الإصلاح - مسارات صحيحة
final checkoutUrl = data['data']?['payment_session']?['payment_url'] ?? 
                   data['data']?['payment_url'] ?? 
                   data['checkout_url'] ?? 
                   data['payment_url'];
```

### 3. إضافة تحقق من البيانات
```dart
// التحقق من وجود البيانات المطلوبة
if (sessionId == null || checkoutUrl == null) {
  throw Exception('Missing payment session data: sessionId=$sessionId, checkoutUrl=$checkoutUrl');
}
```

## المسارات الصحيحة للبيانات

### sessionId:
1. `data.payment_session.session_id` (الأولوية الأولى)
2. `session_id` (fallback)
3. `data.session_id` (fallback)

### checkoutUrl:
1. `data.payment_session.payment_url` (الأولوية الأولى)
2. `data.payment_url` (fallback)
3. `checkout_url` (fallback)
4. `payment_url` (fallback)

## النتيجة المتوقعة

### قبل الإصلاح:
```
✅ Quick donation response: {message: Donation and payment session created successfully, data: {...}}
✅ Payment session created: sessionId=null, checkoutUrl=null
❌ Error: TypeError: null: type 'Null' is not a subtype of type 'String'
```

### بعد الإصلاح:
```
✅ Quick donation response: {message: Donation and payment session created successfully, data: {...}}
✅ Payment session created: sessionId=checkout_dp7mWcR6ETDHpwuB3DyKwjNMI3JuPdi3wyCyhhQ6JXOxcumppQ, checkoutUrl=https://uatcheckout.thawani.om/pay/checkout_dp7mWcR6ETDHpwuB3DyKwjNMI3JuPdi3wyCyhhQ6JXOxcumppQ?key=HGvTMLDssJghr9tlN9gr4DVYt0qyBy
✅ Payment page opened
```

## المميزات الجديدة

### ✅ استخراج صحيح للبيانات
- مسارات صحيحة لـ sessionId و checkoutUrl
- دعم متعدد المسارات (fallback)
- تحقق من وجود البيانات

### ✅ معالجة أخطاء محسنة
- رسائل خطأ واضحة
- تحقق من البيانات قبل الاستخدام
- منع الأخطاء الناتجة عن null values

### ✅ توافق مع API
- دعم هيكل استجابة API الحالي
- مرونة في التعامل مع التغييرات المستقبلية
- دعم متعدد الإصدارات

## كيفية الاختبار

1. افتح التطبيق
2. اذهب للتبرع السريع
3. اختر فئة ومبلغ
4. اضغط "إتمام التبرع"
5. يجب أن تظهر رسائل debug صحيحة:
   - `✅ Payment session created: sessionId=xxx, checkoutUrl=xxx`
   - `✅ Payment page opened`
6. يجب أن تفتح صفحة الدفع في Thawani Pay

## الملفات المعدلة
- `lib/screens/quick_donate_payment_screen.dart`

## النتيجة
الآن التبرع السريع يستخرج بيانات جلسة الدفع بشكل صحيح ويفتح صفحة الدفع بدون أخطاء.
