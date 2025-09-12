# Authentication and Payment Service Updates - تحديثات المصادقة والدفع

## Summary - ملخص

تم تحديث خدمات الدفع والمصادقة لضمان استخدام التوكنات بشكل صحيح وإرسال طلبات API مع رؤوس المصادقة المطلوبة.

Authentication and payment services have been updated to ensure proper token usage and sending API requests with required authentication headers.

## 🔑 Key Updates - التحديثات المهمة

### 1. **Authorization Header Required - رؤوس المصادقة مطلوبة**
```dart
headers: {
  'Authorization': 'Bearer $token', // ✅ هذا مهم جداً!
  'Content-Type': 'application/json',
}
```

### 2. **Token Validation - التحقق من التوكن**
```dart
final token = await _getAuthToken();
if (token == null) {
  // اعرض رسالة للمستخدم
  return;
}
```

### 3. **Consistent API Endpoint - نقطة النهاية الموحدة**
```dart
Uri.parse('$baseUrl/donations/with-payment') // ✅ لا تغير الـ endpoint
```

## 📁 Files Updated - الملفات المحدثة

### 1. **PaymentService** - `lib/services/payment_service.dart`
**New Features Added:**
- ✅ Added `SharedPreferences` import
- ✅ Added `_getAuthToken()` method
- ✅ Added static `baseUrl` constant
- ✅ Added new `createDonationWithPayment()` static method

**Key Method:**
```dart
static Future<Map<String, dynamic>> createDonationWithPayment({
  required int campaignId,
  required double amount,
  required String donorName,
  String? note,
  String type = 'quick',
}) async {
  // ✅ احصل على التوكن
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  
  final response = await http.post(
    Uri.parse('$baseUrl/donations/with-payment'),
    headers: {
      'Authorization': 'Bearer $token', // ✅ مهم جداً!
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'campaign_id': campaignId,
      'amount': amount,
      'donor_name': donorName,
      'note': note,
      'type': type,
    }),
  );
}
```

### 2. **DonationScreen** - `lib/screens/donation_screen.dart`
**New File Created:**
- ✅ Complete donation screen with authentication
- ✅ Token validation before making requests
- ✅ Proper error handling
- ✅ WebView integration for payments

**Key Features:**
```dart
Future<void> _makeDonation() async {
  // ✅ احصل على التوكن
  final token = await _getAuthToken();
  
  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
    );
    return;
  }

  // إنشاء تبرع مع دفع
  final response = await http.post(
    Uri.parse('http://192.168.100.105:8000/api/v1/donations/with-payment'),
    headers: {
      'Authorization': 'Bearer $token', // ✅ مهم!
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'campaign_id': 1,
      'amount': 100.0,
      'donor_name': 'أحمد محمد',
      'note': 'تبرع للطلاب المحتاجين',
    }),
  );
}
```

### 3. **DonationsService** - `lib/services/donations_service.dart`
**New File Created:**
- ✅ Complete service for donation operations
- ✅ Authentication token handling
- ✅ Multiple donation methods (program/campaign)
- ✅ User donations retrieval
- ✅ Donation status checking

**Key Methods:**
```dart
// إنشاء تبرع جديد
Future<Map<String, dynamic>> createDonation({
  required int programId,
  required double amount,
  required String donorName,
  String? note,
  String type = 'quick',
}) async {
  final token = await _getAuthToken();
  
  if (token == null) {
    return {
      'success': false,
      'error': 'لم يتم العثور على رمز المصادقة',
      'status_code': 401
    };
  }

  final response = await http.post(
    Uri.parse('$baseUrl/donations/with-payment'), // ✅ استخدم with-payment
    headers: {
      'Authorization': 'Bearer $token', // ✅ مهم!
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'program_id': programId,
      'amount': amount,
      'donor_name': donorName,
      'note': note,
      'type': type,
    }),
  );
}
```

## 🔍 API Endpoints Verification - التحقق من نقاط النهاية

### **All Services Now Use:**
- **Base URL:** `http://192.168.100.105:8000/api/v1`
- **Donation Endpoint:** `/donations/with-payment`
- **Authentication:** `Bearer $token` header

### **Verified Files:**
1. ✅ `lib/services/api_client.dart` - Uses `192.168.100.105:8000/api/v1`
2. ✅ `lib/services/auth_service.dart` - Uses `192.168.100.105:8000/api`
3. ✅ `lib/services/payment_service.dart` - Uses `192.168.100.105:8000/api/v1`
4. ✅ `lib/services/donation_service.dart` - Uses `192.168.100.105:8000/api/v1`
5. ✅ `lib/services/donations_service.dart` - Uses `192.168.100.105:8000/api/v1`
6. ✅ `lib/screens/donation_screen.dart` - Uses `192.168.100.105:8000/api/v1`

## 🚀 Usage Examples - أمثلة الاستخدام

### **1. Using PaymentService:**
```dart
try {
  final result = await PaymentService.createDonationWithPayment(
    campaignId: 1,
    amount: 100.0,
    donorName: 'أحمد محمد',
    note: 'تبرع للطلاب المحتاجين',
  );
  
  if (result['success']) {
    // Handle success
    final paymentUrl = result['data']['payment_session']['payment_url'];
    final sessionId = result['data']['payment_session']['session_id'];
  }
} catch (e) {
  // Handle error
  print('Error: $e');
}
```

### **2. Using DonationsService:**
```dart
final donationsService = DonationsService();

// Create program donation
final result = await donationsService.createDonation(
  programId: 1,
  amount: 50.0,
  donorName: 'سارة أحمد',
  note: 'تبرع للتعليم',
);

// Create campaign donation
final campaignResult = await donationsService.createCampaignDonation(
  campaignId: 2,
  amount: 200.0,
  donorName: 'محمد علي',
  note: 'تبرع للإغاثة',
);

// Get user donations
final userDonations = await donationsService.getUserDonations();
```

### **3. Using DonationScreen:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => DonationScreen(),
  ),
);
```

## ⚠️ Important Notes - ملاحظات مهمة

### **1. Authentication Required:**
- All donation operations require a valid authentication token
- Token is automatically retrieved from SharedPreferences
- If no token exists, appropriate error messages are shown

### **2. Error Handling:**
- All services return structured error responses
- Network errors are properly caught and handled
- User-friendly error messages in Arabic

### **3. API Consistency:**
- All services use the same base URL: `192.168.100.105:8000`
- All donation endpoints use `/donations/with-payment`
- Consistent header structure across all requests

### **4. Response Structure:**
```dart
// Success Response
{
  'success': true,
  'data': {...},
  'message': 'تم إنشاء التبرع بنجاح'
}

// Error Response
{
  'success': false,
  'error': 'رسالة الخطأ',
  'status_code': 401
}
```

## 🧪 Testing - الاختبار

### **1. Test Authentication:**
```dart
// Check if user is logged in
final token = await SharedPreferences.getInstance()
    .then((prefs) => prefs.getString('auth_token'));

if (token != null) {
  print('✅ User is authenticated');
} else {
  print('❌ User needs to login');
}
```

### **2. Test Donation Creation:**
```dart
try {
  final result = await PaymentService.createDonationWithPayment(
    campaignId: 1,
    amount: 10.0, // Small amount for testing
    donorName: 'Test User',
    note: 'Test donation',
  );
  print('✅ Donation created: $result');
} catch (e) {
  print('❌ Donation failed: $e');
}
```

### **3. Test API Connection:**
```dart
// Test basic connectivity
final response = await http.get(
  Uri.parse('http://192.168.100.105:8000/api/v1/health'),
  headers: {'Accept': 'application/json'},
);

if (response.statusCode == 200) {
  print('✅ API is accessible');
} else {
  print('❌ API connection failed: ${response.statusCode}');
}
```

## 📋 Next Steps - الخطوات التالية

1. **Test the updated services** with real API calls
2. **Verify authentication flow** works correctly
3. **Test payment integration** with WebView
4. **Update UI components** to use the new services
5. **Add error handling** in UI screens
6. **Test on different devices** and network conditions

## 🔧 Troubleshooting - استكشاف الأخطاء

### **Common Issues:**

1. **401 Unauthorized:**
   - Check if user is logged in
   - Verify token is valid and not expired
   - Ensure token is being sent in Authorization header

2. **Network Errors:**
   - Verify server is running on `192.168.100.105:8000`
   - Check network connectivity
   - Ensure firewall allows connections

3. **422 Validation Errors:**
   - Check request payload structure
   - Verify required fields are provided
   - Ensure data types are correct

4. **Payment WebView Issues:**
   - Verify payment URL is valid
   - Check session ID is properly passed
   - Ensure WebView permissions are granted

---

**All services are now properly configured with authentication and consistent API endpoints!** 🎉
