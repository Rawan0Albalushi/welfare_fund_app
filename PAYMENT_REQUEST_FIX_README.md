# إصلاح طلب الدفع - حل مشكلة التحقق من صحة API

## المشكلة

كانت هناك مشكلة في إنشاء جلسات الدفع حيث كان الخادم يعيد خطأ 422 مع الرسالة:
```
"Either program_id or campaign_id is required"
```

## السبب

كان نموذج `PaymentRequest` يرسل البيانات بالشكل التالي:
```json
{
  "amount": 200,
  "client_reference_id": "donation_1755976148432_8432",
  "return_url": "https://sfund.app/pay/success",
  "currency": "OMR",
  "products": [...],
  "metadata": {
    "item_id": "1",
    "item_type": "campaign"
  }
}
```

لكن الخادم يتوقع إما `program_id` أو `campaign_id` في المستوى الرئيسي للطلب.

## الحل

تم تحديث دالة `toJson()` في نموذج `PaymentRequest` لإضافة الحقول المطلوبة:

```dart
Map<String, dynamic> toJson() {
  return {
    'amount': (amount * 100).round(),
    'client_reference_id': clientReferenceId,
    'return_url': returnUrl,
    'currency': 'OMR',
    // إضافة program_id أو campaign_id حسب النوع
    if (itemType == 'program' && itemId != null) 'program_id': itemId,
    if (itemType == 'campaign' && itemId != null) 'campaign_id': itemId,
    'products': [...],
    'metadata': {...}
  };
}
```

## النتيجة

الآن يتم إرسال البيانات بالشكل الصحيح:
```json
{
  "amount": 200,
  "client_reference_id": "donation_1755976148432_8432",
  "return_url": "https://sfund.app/pay/success",
  "currency": "OMR",
  "campaign_id": "1",
  "products": [...],
  "metadata": {...}
}
```

## الملفات المتأثرة

- `lib/models/payment_request.dart` - تحديث دالة `toJson()`

## الاختبار

1. افتح التطبيق
2. انتقل إلى أي حملة خيرية
3. اختر مبلغ للتبرع
4. تأكد من أن عملية الدفع تعمل بدون أخطاء

## السجلات المتوقعة

```
PaymentService: Create session response status: 200
PaymentService: Create session response body: {"success":true,"data":{...}}
CampaignDonationScreen: PaymentResponse success: true
```

## التأثير على الميزات الأخرى

هذا الإصلاح يؤثر على جميع عمليات الدفع في التطبيق:
- ✅ تبرعات الحملات الخيرية
- ✅ تبرعات البرامج الطلابية
- ✅ التبرع السريع
- ✅ إهداء التبرعات
