# 🔧 دليل تصحيح إعدادات Thawani

## المشكلة الحالية
```
Thawani API request failed: Server error: `POST https://uatcheckout.thawani.om/checkout/session` resulted in a `500 Internal Server Error`
```

## 🔍 خطوات التصحيح

### 1. التحقق من إعدادات Thawani في Laravel

#### ملف الإعدادات (.env)
```env
# Thawani Configuration
THAWANI_PUBLIC_KEY=your_public_key_here
THAWANI_SECRET_KEY=your_secret_key_here
THAWANI_BASE_URL=https://uatcheckout.thawani.om
THAWANI_API_VERSION=v1
```

#### التحقق من المفاتيح
```bash
# في Laravel
php artisan tinker
echo env('THAWANI_PUBLIC_KEY');
echo env('THAWANI_SECRET_KEY');
```

### 2. اختبار الاتصال بـ Thawani

#### اختبار مباشر
```bash
curl -X POST https://uatcheckout.thawani.om/checkout/session \
  -H "Content-Type: application/json" \
  -H "thawani-api-key: YOUR_SECRET_KEY" \
  -d '{
    "client_reference_id": "test_123",
    "mode": "payment",
    "products": [
      {
        "name": "تبرع تجريبي",
        "quantity": 1,
        "unit_amount": 1000
      }
    ],
    "currency": "OMR",
    "success_url": "https://example.com/success",
    "cancel_url": "https://example.com/cancel"
  }'
```

### 3. التحقق من سجلات Laravel

#### مراقبة السجلات
```bash
# في مجلد Laravel
tail -f storage/logs/laravel.log

# أو في التطبيق
Log::error('Thawani Error', ['response' => $response]);
```

### 4. إصلاحات محتملة

#### أ) تحديث إعدادات Thawani
```php
// في config/services.php
'thawani' => [
    'public_key' => env('THAWANI_PUBLIC_KEY'),
    'secret_key' => env('THAWANI_SECRET_KEY'),
    'base_url' => env('THAWANI_BASE_URL', 'https://uatcheckout.thawani.om'),
    'api_version' => env('THAWANI_API_VERSION', 'v1'),
],
```

#### ب) إضافة معالجة الأخطاء
```php
try {
    $response = Http::withHeaders([
        'thawani-api-key' => config('services.thawani.secret_key'),
        'Content-Type' => 'application/json',
    ])->post(config('services.thawani.base_url') . '/checkout/session', $data);
    
    if ($response->successful()) {
        return $response->json();
    } else {
        Log::error('Thawani API Error', [
            'status' => $response->status(),
            'body' => $response->body(),
            'headers' => $response->headers(),
        ]);
        throw new Exception('Thawani API Error: ' . $response->body());
    }
} catch (Exception $e) {
    Log::error('Thawani Request Failed', ['error' => $e->getMessage()]);
    throw $e;
}
```

### 5. اختبار البيئة

#### UAT vs Production
```php
// تأكد من استخدام البيئة الصحيحة
$baseUrl = app()->environment('production') 
    ? 'https://checkout.thawani.om' 
    : 'https://uatcheckout.thawani.om';
```

### 6. التحقق من البيانات المرسلة

#### تنسيق البيانات المطلوب
```json
{
  "client_reference_id": "unique_reference_id",
  "mode": "payment",
  "products": [
    {
      "name": "تبرع خيري",
      "quantity": 1,
      "unit_amount": 1000
    }
  ],
  "currency": "OMR",
  "success_url": "https://your-app.com/success",
  "cancel_url": "https://your-app.com/cancel",
  "metadata": {
    "donor_name": "أحمد محمد",
    "campaign_id": "123"
  }
}
```

## 🚨 رسائل الخطأ الشائعة

### خطأ 500 - Internal Server Error
- **السبب**: مشكلة في إعدادات Thawani أو بيانات غير صحيحة
- **الحل**: التحقق من المفاتيح وتنسيق البيانات

### خطأ 401 - Unauthorized
- **السبب**: مفتاح API غير صحيح
- **الحل**: تحديث THAWANI_SECRET_KEY

### خطأ 422 - Validation Error
- **السبب**: بيانات غير صحيحة في الطلب
- **الحل**: التحقق من تنسيق البيانات

## 📞 الدعم

إذا استمرت المشكلة:
1. راجع سجلات Laravel
2. تحقق من إعدادات Thawani
3. اتصل بدعم Thawani
4. اختبر في بيئة مختلفة
