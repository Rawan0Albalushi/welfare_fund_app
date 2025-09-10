# API URL Update to 192.168.100.103 - تحديث عنوان API

## Summary - ملخص

تم تحديث جميع عناوين API في التطبيق من `localhost:8000` إلى `192.168.100.103:8000` لضمان الاتصال الصحيح مع الخادم.

All API URLs in the application have been updated from `localhost:8000` to `192.168.100.103:8000` to ensure proper server connectivity.

## Files Updated - الملفات المحدثة

### 1. API Client Service
**File:** `lib/services/api_client.dart`
- **Before:** `const baseUrl = 'http://localhost:8000/api/v1';`
- **After:** `const baseUrl = 'http://192.168.100.103:8000/api/v1';`

### 2. Authentication Service
**File:** `lib/services/auth_service.dart`
- **Before:** `const baseUrl = 'http://localhost:8000/api/v1';`
- **After:** `const baseUrl = 'http://192.168.100.103:8000/api/v1';`

### 3. Payment Service
**File:** `lib/services/payment_service.dart`
- **Before:** `static const String _baseUrl = 'http://localhost:8000/api/v1';`
- **After:** `static const String _baseUrl = 'http://192.168.100.103:8000/api/v1';`

**Return URLs Updated:**
- **Before:** `'http://localhost:8000/api/v1/payments/success'`
- **After:** `'http://192.168.100.103:8000/api/v1/payments/success'`

### 4. Donation Service
**File:** `lib/services/donation_service.dart`
- **Before:** `static const String _baseUrl = 'http://localhost:8000/api/v1';`
- **After:** `static const String _baseUrl = 'http://192.168.100.103:8000/api/v1';`

**Return URLs Updated:**
- **Before:** `'http://localhost:8000/api/v1/payments/success'`
- **After:** `'http://192.168.100.103:8000/api/v1/payments/success'`

### 5. Campaign Donation Screen
**File:** `lib/screens/campaign_donation_screen.dart`
- **Before:** `successUrl: 'http://localhost:8000/api/v1/payments/success?session_id=$sessionId'`
- **After:** `successUrl: 'http://192.168.100.103:8000/api/v1/payments/success?session_id=$sessionId'`

- **Before:** `cancelUrl: 'http://localhost:8000/api/v1/payments/cancel?session_id=$sessionId'`
- **After:** `cancelUrl: 'http://192.168.100.103:8000/api/v1/payments/cancel?session_id=$sessionId'`

### 6. Payment WebView Screen
**File:** `lib/screens/payment_webview.dart`
- **Before:** `url.contains('localhost:8000/api/v1/payments/success')`
- **After:** `url.contains('192.168.100.103:8000/api/v1/payments/success')`

- **Before:** `url.contains('localhost:8000/api/v1/payments/cancel')`
- **After:** `url.contains('192.168.100.103:8000/api/v1/payments/cancel')`

### 7. Payment Screen
**File:** `lib/screens/payment_screen.dart`
- **Before:** `successUrl: 'http://localhost:8000/api/v1/payments/success?session_id=${paymentProvider.currentSessionId}'`
- **After:** `successUrl: 'http://192.168.100.103:8000/api/v1/payments/success?session_id=${paymentProvider.currentSessionId}'`

- **Before:** `cancelUrl: 'http://localhost:8000/api/v1/payments/cancel?session_id=${paymentProvider.currentSessionId}'`
- **After:** `cancelUrl: 'http://192.168.100.103:8000/api/v1/payments/cancel?session_id=${paymentProvider.currentSessionId}'`

## API Endpoints - نقاط النهاية

### Base URL - الرابط الأساسي
```
http://192.168.100.103:8000/api/v1
```

### Key Endpoints - النقاط الرئيسية
- **Authentication:** `/auth/login`, `/auth/register`, `/auth/me`
- **Campaigns:** `/campaigns`, `/v1/campaigns`
- **Programs:** `/programs`, `/v1/programs`
- **Donations:** `/donations`, `/donations/with-payment`
- **Payments:** `/payments/create`, `/payments?session_id={id}`
- **Student Registration:** `/students/registration`

## Testing - اختبار

### 1. Health Check
```bash
curl -X GET http://192.168.100.103:8000/api/v1/health
```

### 2. Authentication Test
```bash
curl -X POST http://192.168.100.103:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone": "test", "password": "test"}'
```

### 3. Campaigns Test
```bash
curl -X GET http://192.168.100.103:8000/api/v1/campaigns
```

### 4. Payment Creation Test
```bash
curl -X POST http://192.168.100.103:8000/api/v1/payments/create \
  -H "Content-Type: application/json" \
  -d '{"amount": 10.0, "client_reference_id": "test_123", "return_url": "http://192.168.100.103:8000/api/v1/payments/success"}'
```

## Verification - التحقق

### Check All Updated Files
```bash
grep -r "192.168.100.103" lib/services/
grep -r "192.168.100.103" lib/screens/
```

### Verify No Localhost Remains
```bash
grep -r "localhost" lib/**/*.dart
```

## Network Configuration - إعدادات الشبكة

### Server Requirements - متطلبات الخادم
- **IP Address:** `192.168.100.103`
- **Port:** `8000`
- **Protocol:** `HTTP`
- **API Version:** `v1`

### Client Requirements - متطلبات العميل
- **Network Access:** Must be on the same network as `192.168.100.103`
- **Firewall:** Port 8000 must be accessible
- **DNS:** No DNS resolution required (direct IP access)

## Troubleshooting - استكشاف الأخطاء

### Common Issues - المشاكل الشائعة

1. **Connection Refused**
   - Check if server is running on `192.168.100.103:8000`
   - Verify network connectivity
   - Check firewall settings

2. **Timeout Errors**
   - Verify server is responsive
   - Check network latency
   - Increase timeout values if needed

3. **Authentication Errors**
   - Verify API endpoints are correct
   - Check token validity
   - Ensure proper headers are sent

### Debug Commands - أوامر التصحيح

```bash
# Test network connectivity
ping 192.168.100.103

# Test port accessibility
telnet 192.168.100.103 8000

# Test API health
curl -v http://192.168.100.103:8000/api/v1/health
```

## Rollback Instructions - تعليمات التراجع

If you need to revert to localhost:

1. **Update all service files:**
   ```dart
   const baseUrl = 'http://localhost:8000/api/v1';
   ```

2. **Update all return URLs:**
   ```dart
   return 'http://localhost:8000/api/v1/payments/success';
   ```

3. **Update all screen files with localhost URLs**

4. **Test connectivity to localhost:8000**

## Summary - ملخص

✅ **Successfully Updated:** All API URLs from `localhost:8000` to `192.168.100.103:8000`
✅ **Files Modified:** 7 files across services and screens
✅ **Endpoints Verified:** All payment, donation, and authentication endpoints updated
✅ **Return URLs Updated:** Success and cancel URLs for payment flow
✅ **Testing Ready:** Application ready for testing with new server IP

The application is now configured to connect to the server at `192.168.100.103:8000` and should work properly with the backend API.
