# 🔧 متطلبات الباكند - دعم التبرعات المجهولة

## 📋 نظرة عامة

لضمان عمل التبرعات المجهولة للمستخدمين غير المسجلين، يجب على الباكند دعم الـ endpoint التالي:
**`POST /api/v1/donations/anonymous-with-payment`**

## 🎯 المتطلبات الأساسية

### 1. **Route الجديد**
```php
// routes/api.php
Route::post('/v1/donations/anonymous-with-payment', [DonationController::class, 'createAnonymousDonationWithPayment']);
```

### 2. **Controller Method**
```php
// app/Http/Controllers/DonationController.php
public function createAnonymousDonationWithPayment(Request $request)
{
    // التحقق من صحة البيانات
    $request->validate([
        'amount' => 'required|numeric|min:0.01',
        'program_id' => 'nullable|exists:programs,id',
        'campaign_id' => 'nullable|exists:campaigns,id',
        'donor_name' => 'nullable|string|max:255',
        'donor_email' => 'nullable|email|max:255',
        'donor_phone' => 'nullable|string|max:20',
        'note' => 'nullable|string|max:1000',
    ]);

    // التأكد من وجود إما program_id أو campaign_id
    if (!$request->program_id && !$request->campaign_id) {
        return response()->json([
            'success' => false,
            'message' => 'يجب تحديد برنامج أو حملة'
        ], 422);
    }

    // إنشاء التبرع المجهول
    $donation = Donation::create([
        'user_id' => null, // دائماً null للتبرعات المجهولة
        'program_id' => $request->program_id,
        'campaign_id' => $request->campaign_id,
        'amount' => $request->amount,
        'donor_name' => $request->donor_name ?? 'متبرع',
        'donor_email' => $request->donor_email,
        'donor_phone' => $request->donor_phone,
        'note' => $request->note,
        'is_anonymous' => true, // دائماً true للتبرعات المجهولة
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

### 3. **Middleware Configuration**
```php
// routes/api.php
// إزالة auth middleware من routes التبرعات المجهولة
Route::middleware([])->group(function () {
    Route::post('/v1/donations/anonymous-with-payment', [DonationController::class, 'createAnonymousDonationWithPayment']);
    Route::post('/v1/donations/with-payment', [DonationController::class, 'createDonationWithPayment']);
    Route::post('/v1/payments/create', [PaymentController::class, 'createPaymentSession']);
    Route::get('/v1/payments/status/{sessionId}', [PaymentController::class, 'checkPaymentStatus']);
});
```

## 🔄 تحديث الـ Model

### Donation Model
```php
// app/Models/Donation.php
protected $fillable = [
    'user_id',        // يمكن أن يكون null للتبرعات المجهولة
    'program_id',
    'campaign_id',
    'amount',
    'donor_name',
    'donor_email',
    'donor_phone',
    'note',
    'is_anonymous',
    'status',
    'payment_session_id',
    'paid_amount',
];

// إضافة العلاقات
public function user()
{
    return $this->belongsTo(User::class);
}

public function program()
{
    return $this->belongsTo(Program::class);
}

public function campaign()
{
    return $this->belongsTo(Campaign::class);
}
```

## 🗄️ تحديث قاعدة البيانات

### Migration للتبرعات المجهولة
```php
// database/migrations/add_anonymous_donation_fields.php
Schema::table('donations', function (Blueprint $table) {
    $table->unsignedBigInteger('user_id')->nullable()->change(); // السماح بـ null
    $table->string('donor_name')->nullable(); // اسم المتبرع
    $table->string('donor_email')->nullable(); // بريد المتبرع
    $table->string('donor_phone')->nullable(); // هاتف المتبرع
    $table->text('note')->nullable(); // رسالة التبرع
    $table->boolean('is_anonymous')->default(false); // هل التبرع مجهول
    $table->string('status')->default('pending'); // حالة التبرع
    $table->string('payment_session_id')->nullable(); // معرف جلسة الدفع
    $table->decimal('paid_amount', 10, 2)->nullable(); // المبلغ المدفوع فعلياً
});
```

## 🔐 الأمان والتحقق

### 1. **Rate Limiting**
```php
// app/Http/Kernel.php
protected $middlewareGroups = [
    'api' => [
        'throttle:60,1', // 60 طلب في الدقيقة
    ],
];
```

### 2. **CSRF Protection**
```php
// app/Http/Middleware/VerifyCsrfToken.php
protected $except = [
    'api/v1/donations/anonymous-with-payment',
    'api/v1/donations/with-payment',
    'api/v1/payments/*',
];
```

### 3. **Input Sanitization**
```php
// في Controller
$donorName = strip_tags($request->donor_name);
$donorEmail = filter_var($request->donor_email, FILTER_SANITIZE_EMAIL);
$donorPhone = preg_replace('/[^0-9+\-\s]/', '', $request->donor_phone);
```

## 📊 Logging والمراقبة

### 1. **Log Anonymous Donations**
```php
// في Controller
Log::info('Anonymous donation created', [
    'donation_id' => $donation->id,
    'amount' => $donation->amount,
    'program_id' => $donation->program_id,
    'campaign_id' => $donation->campaign_id,
    'ip_address' => $request->ip(),
    'user_agent' => $request->userAgent(),
]);
```

### 2. **Analytics**
```php
// تتبع إحصائيات التبرعات المجهولة
public function getAnonymousDonationStats()
{
    return [
        'total_anonymous_donations' => Donation::where('is_anonymous', true)->count(),
        'total_anonymous_amount' => Donation::where('is_anonymous', true)->sum('amount'),
        'recent_anonymous_donations' => Donation::where('is_anonymous', true)
            ->where('created_at', '>=', now()->subDays(30))
            ->count(),
    ];
}
```

## 🧪 الاختبار

### 1. **Unit Tests**
```php
// tests/Feature/AnonymousDonationTest.php
public function test_can_create_anonymous_donation()
{
    $response = $this->postJson('/api/v1/donations/anonymous-with-payment', [
        'program_id' => 1,
        'amount' => 10.0,
        'donor_name' => 'متبرع مجهول',
        'donor_email' => 'anonymous@example.com',
    ]);

    $response->assertStatus(201)
        ->assertJson([
            'success' => true,
            'data' => [
                'donation' => [
                    'is_anonymous' => true,
                    'user_id' => null,
                ]
            ]
        ]);
}

public function test_anonymous_donation_without_authentication()
{
    // التأكد من عدم الحاجة للمصادقة
    $response = $this->postJson('/api/v1/donations/anonymous-with-payment', [
        'campaign_id' => 1,
        'amount' => 5.0,
    ]);

    $response->assertStatus(201);
}
```

### 2. **Integration Tests**
```php
public function test_anonymous_donation_creates_payment_session()
{
    $response = $this->postJson('/api/v1/donations/anonymous-with-payment', [
        'program_id' => 1,
        'amount' => 10.0,
    ]);

    $response->assertStatus(201)
        ->assertJsonStructure([
            'success',
            'data' => [
                'donation',
                'payment_session'
            ],
            'payment_url',
            'session_id'
        ]);
}
```

## 📱 Response Format

### Success Response
```json
{
    "success": true,
    "data": {
        "donation": {
            "id": 123,
            "user_id": null,
            "program_id": 1,
            "campaign_id": null,
            "amount": 10.0,
            "donor_name": "متبرع",
            "donor_email": "anonymous@example.com",
            "donor_phone": "+96812345678",
            "note": "تبرع خيري",
            "is_anonymous": true,
            "status": "pending",
            "created_at": "2024-01-01T12:00:00Z"
        },
        "payment_session": {
            "session_id": "thawani_session_456",
            "payment_url": "https://checkout.thawani.om/pay/...",
            "amount": 1000, // بالبيسة
            "currency": "OMR"
        }
    },
    "payment_url": "https://checkout.thawani.om/pay/...",
    "session_id": "thawani_session_456"
}
```

### Error Response
```json
{
    "success": false,
    "message": "بيانات غير صحيحة",
    "errors": {
        "amount": ["المبلغ مطلوب"],
        "program_id": ["يجب تحديد برنامج أو حملة"]
    }
}
```

## 🚀 النشر والتحديث

### 1. **Database Migration**
```bash
php artisan make:migration add_anonymous_donation_fields
php artisan migrate
```

### 2. **Clear Cache**
```bash
php artisan config:clear
php artisan route:clear
php artisan cache:clear
```

### 3. **Test Endpoint**
```bash
curl -X POST http://localhost:8000/api/v1/donations/anonymous-with-payment \
  -H "Content-Type: application/json" \
  -d '{
    "program_id": 1,
    "amount": 10.0,
    "donor_name": "متبرع مجهول"
  }'
```

## ✅ قائمة التحقق

- [ ] إضافة Route الجديد
- [ ] إنشاء Controller Method
- [ ] تحديث Donation Model
- [ ] إضافة Database Migration
- [ ] تحديث Middleware Configuration
- [ ] إضافة Unit Tests
- [ ] إضافة Integration Tests
- [ ] تحديث Documentation
- [ ] اختبار الـ Endpoint
- [ ] نشر التحديثات

## 🎯 الخلاصة

بعد تطبيق هذه المتطلبات، سيدعم الباكند التبرعات المجهولة للمستخدمين غير المسجلين:

- ✅ **Endpoint مخصص**: `/api/v1/donations/anonymous-with-payment`
- ✅ **لا يتطلب مصادقة**: يعمل بدون authentication token
- ✅ **تبرع مجهول دائماً**: `is_anonymous: true`
- ✅ **دفع فوري**: ينشئ جلسة دفع Thawani
- ✅ **أمان كامل**: rate limiting و input sanitization
- ✅ **مراقبة وإحصائيات**: logging و analytics
- ✅ **اختبار شامل**: unit و integration tests
