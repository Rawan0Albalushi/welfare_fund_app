# Thawani: شرط حقل client_reference_id

## المشكلة التي ظهرت في اللوج

```
"field": "client_reference_id",
"message": "Input must only contain English letters, digits, spaces, or Arabic characters."
```

Thawani يرفض أي قيمة لـ `client_reference_id` تحتوي على رموز غير مسموحة (مثل `-` أو `_`).

## الحل في الباكند (Laravel)

عند إنشاء جلسة الدفع مع Thawani، إذا كنت تستخدم `donation_id` كمرجع (مثل `DN_ec9458ae-7849-49e8-bdc3-d0803e411bd3`)، يجب **تنظيف** القيمة قبل إرسالها لـ Thawani:

- المسموح: **حروف إنجليزية، أرقام، مسافات، حروف عربية فقط.**
- غير مسموح: الشرطة `-`، الشرطة السفلية `_`، وأي رموز خاصة.

### مثال (PHP/Laravel)

```php
// قبل الإرسال لـ Thawani
$donationId = $donation->donation_id; // مثلاً: DN_ec9458ae-7849-49e8-bdc3-d0803e411bd3
$clientReferenceId = preg_replace('/[-_]/', '', $donationId);
// النتيجة: DNec9458ae784949e8bdc3d0803e411bd3
```

أو إنشاء مرجع من رقم التبرع فقط:

```php
$clientReferenceId = 'donation' . $donation->id; // donation10
```

ثم استخدم `$clientReferenceId` في طلب إنشاء جلسة الدفع لـ Thawani.

## التطبيق (Flutter)

في التطبيق تم تعديل `generateClientReferenceId()` ليعيد قيمة بدون `_` أو `-` (مثل `donation173908986912300123`) عند استخدام أي مسار يرسل هذا الحقل للباكند.
