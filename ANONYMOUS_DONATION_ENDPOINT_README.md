# 🎯 Anonymous Donation Endpoint - التبرع المجهول للمستخدمين غير المسجلين

## 📋 نظرة عامة

تم إنشاء endpoint مخصص للتبرعات المجهولة للمستخدمين غير المسجلين:
**`POST /api/v1/donations/anonymous-with-payment`**

هذا الـ endpoint مصمم خصيصاً لتبسيط عملية التبرع للمستخدمين الذين لا يرغبون في تسجيل الدخول أو إنشاء حساب.

## 🚀 الميزات الرئيسية

### ✅ **لا يتطلب مصادقة**
- لا حاجة لـ authentication token
- لا حاجة لتسجيل دخول
- يعمل مباشرة للمستخدمين غير المسجلين

### ✅ **تبرع مجهول دائماً**
- `is_anonymous: true` تلقائياً
- يحترم خصوصية المتبرع
- لا يتم ربط التبرع بحساب مستخدم

### ✅ **دفع فوري**
- ينشئ جلسة دفع Thawani مباشرة
- يعيد رابط الدفع والـ session ID
- يدعم جميع وسائل الدفع المتاحة

## 📝 استخدام الـ API

### Request Format
```http
POST /api/v1/donations/anonymous-with-payment
Content-Type: application/json

{
  "program_id": 1,           // أو campaign_id
  "amount": 10.0,            // المبلغ بالريال العماني
  "donor_name": "متبرع مجهول", // اسم المتبرع (اختياري)
  "donor_email": "email@example.com", // البريد الإلكتروني (اختياري)
  "donor_phone": "+96812345678",      // رقم الهاتف (اختياري)
  "note": "تبرع خيري للطلاب"          // رسالة التبرع (اختياري)
}
```

### Response Format
```json
{
  "ok": true,
  "data": {
    "id": "donation_123",
    "amount": 10.0,
    "is_anonymous": true,
    "status": "pending",
    "payment_session_id": "thawani_session_456"
  },
  "payment_url": "https://checkout.thawani.om/pay/...",
  "payment_session_id": "thawani_session_456"
}
```

## 💻 استخدام في التطبيق

### 1. استيراد الخدمة
```dart
import 'lib/services/donation_service.dart';
```

### 2. إنشاء تبرع مجهول
```dart
final donationService = DonationService();

try {
  final result = await donationService.createAnonymousDonationWithPayment(
    itemId: '1',                    // معرف البرنامج أو الحملة
    itemType: 'program',            // 'program' أو 'campaign'
    amount: 10.0,                   // المبلغ بالريال
    donorName: 'متبرع مجهول',        // اسم المتبرع (اختياري)
    donorEmail: 'donor@example.com', // البريد (اختياري)
    donorPhone: '+96812345678',      // الهاتف (اختياري)
    message: 'تبرع خيري',            // الرسالة (اختياري)
  );
  
  // فتح صفحة الدفع
  final paymentUrl = result['payment_url'];
  // استخدام paymentUrl في WebView أو url_launcher
  
} catch (e) {
  print('خطأ في إنشاء التبرع: $e');
}
```

### 3. معالجة الاستجابة
```dart
if (result['ok'] == true) {
  final paymentUrl = result['payment_url'];
  final sessionId = result['payment_session_id'];
  
  // فتح صفحة الدفع
  await launchUrl(Uri.parse(paymentUrl));
  
  // متابعة حالة الدفع
  // يمكن استخدام sessionId للتحقق من حالة الدفع
}
```

## 🔄 التدفق الكامل

### للمستخدمين غير المسجلين:
1. **اختيار حملة/برنامج** → **اختيار مبلغ التبرع**
2. **ضغط "تبرع الآن"** → **استدعاء `createAnonymousDonationWithPayment()`**
3. **إنشاء تبرع مجهول** → **إنشاء جلسة دفع Thawani**
4. **فتح صفحة الدفع** → **إتمام الدفع**
5. **التحقق من الحالة** → **صفحة النجاح**

## 🆚 مقارنة مع الـ Endpoints الأخرى

| الخاصية | `/donations/with-payment` | `/donations/anonymous-with-payment` |
|---------|---------------------------|-------------------------------------|
| **المصادقة** | اختيارية (مع/بدون token) | غير مطلوبة أبداً |
| **الاستخدام** | للمستخدمين المسجلين وغير المسجلين | للمستخدمين غير المسجلين فقط |
| **is_anonymous** | يمكن تخصيصه | دائماً `true` |
| **البساطة** | معقد قليلاً | بسيط جداً |
| **الوضوح** | عام | مخصص للتبرعات المجهولة |

## 🧪 الاختبار

### ملف الاختبار
تم إنشاء ملف `test_anonymous_donation.dart` لاختبار الوظائف:

```bash
# تشغيل الاختبار
dart test_anonymous_donation.dart
```

### سيناريوهات الاختبار
1. **تبرع لبرنامج** - مع جميع البيانات
2. **تبرع لحملة** - مع بيانات جزئية
3. **تبرع بسيط** - مع البيانات الأساسية فقط

## 📋 متطلبات الباكند

### Route الجديد المطلوب:
```php
// routes/api.php
Route::post('/v1/donations/anonymous-with-payment', [DonationController::class, 'createAnonymousDonationWithPayment']);
```

### Controller Method:
```php
public function createAnonymousDonationWithPayment(Request $request)
{
    $donation = Donation::create([
        'user_id' => null, // دائماً null للتبرعات المجهولة
        'campaign_id' => $request->campaign_id,
        'program_id' => $request->program_id,
        'amount' => $request->amount,
        'donor_name' => $request->donor_name ?? 'متبرع',
        'donor_email' => $request->donor_email,
        'donor_phone' => $request->donor_phone,
        'note' => $request->note,
        'is_anonymous' => true, // دائماً true
        'status' => 'pending',
    ]);
    
    // إنشاء جلسة الدفع
    $paymentSession = $this->createThawaniSession($donation);
    
    return response()->json([
        'success' => true,
        'data' => [
            'donation' => $donation,
            'payment_session' => $paymentSession,
        ],
        'payment_url' => $paymentSession['payment_url'],
        'session_id' => $paymentSession['session_id'],
    ]);
}
```

## 🎉 المزايا

### للمستخدمين غير المسجلين:
- ✅ **سهولة الاستخدام**: لا حاجة لتسجيل دخول
- ✅ **خصوصية كاملة**: تبرع مجهول دائماً
- ✅ **سرعة في التنفيذ**: خطوات أقل للتبرع
- ✅ **أمان**: لا يتم تخزين بيانات شخصية

### للمطورين:
- ✅ **وضوح في الكود**: endpoint مخصص للتبرعات المجهولة
- ✅ **سهولة الصيانة**: منطق منفصل عن التبرعات العادية
- ✅ **مرونة**: يمكن تخصيصه حسب الحاجة
- ✅ **اختبار سهل**: منطق بسيط وواضح

## 📱 مثال كامل في التطبيق

```dart
// في صفحة التبرع
class DonationScreen extends StatefulWidget {
  final String itemId;
  final String itemType;
  
  @override
  _DonationScreenState createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final _donationService = DonationService();
  
  Future<void> _makeAnonymousDonation(double amount) async {
    try {
      setState(() => _isLoading = true);
      
      final result = await _donationService.createAnonymousDonationWithPayment(
        itemId: widget.itemId,
        itemType: widget.itemType,
        amount: amount,
        donorName: _donorNameController.text.isNotEmpty 
            ? _donorNameController.text 
            : null,
        donorEmail: _donorEmailController.text.isNotEmpty 
            ? _donorEmailController.text 
            : null,
        donorPhone: _donorPhoneController.text.isNotEmpty 
            ? _donorPhoneController.text 
            : null,
        message: _messageController.text.isNotEmpty 
            ? _messageController.text 
            : null,
      );
      
      if (result['ok'] == true) {
        // فتح صفحة الدفع
        final paymentUrl = result['payment_url'];
        await launchUrl(Uri.parse(paymentUrl));
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في إنشاء التبرع: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تبرع الآن')),
      body: Column(
        children: [
          // واجهة اختيار المبلغ
          // ...
          
          ElevatedButton(
            onPressed: _isLoading ? null : () => _makeAnonymousDonation(selectedAmount),
            child: _isLoading 
                ? CircularProgressIndicator() 
                : Text('تبرع الآن'),
          ),
        ],
      ),
    );
  }
}
```

## 🎯 الخلاصة

تم إنشاء endpoint مخصص `/api/v1/donations/anonymous-with-payment` لتبسيط عملية التبرع للمستخدمين غير المسجلين:

- **🎯 هدف واضح**: مخصص للتبرعات المجهولة فقط
- **🚀 سهولة الاستخدام**: لا يتطلب مصادقة أو تسجيل دخول
- **🔒 خصوصية كاملة**: تبرع مجهول دائماً
- **💳 دفع فوري**: ينشئ جلسة دفع Thawani مباشرة
- **🧪 قابل للاختبار**: منطق بسيط وواضح

هذا الـ endpoint يجعل تجربة التبرع أكثر سلاسة للمستخدمين الذين يفضلون عدم إنشاء حساب.
