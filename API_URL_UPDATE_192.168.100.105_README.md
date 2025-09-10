# API URL Update to 192.168.100.105 - تحديث عنوان API

## Summary - ملخص

تم تحديث جميع عناوين API في التطبيق من `192.168.100.103:8000` إلى `192.168.100.105:8000` لضمان الاتصال الصحيح مع الخادم.

All API URLs in the application have been updated from `192.168.100.103:8000` to `192.168.100.105:8000` to ensure proper server connectivity.

## Files Updated - الملفات المحدثة

### 1. API Client Service
**File:** `lib/services/api_client.dart`
- **Before:** `const baseUrl = 'http://192.168.100.103:8000/api/v1';`
- **After:** `const baseUrl = 'http://192.168.100.105:8000/api/v1';`

### 2. Authentication Service
**File:** `lib/services/auth_service.dart`
- **Before:** `const baseUrl = 'http://192.168.100.103:8000/api/v1';`
- **After:** `const baseUrl = 'http://192.168.100.105:8000/api/v1';`

### 3. Payment Service
**File:** `lib/services/payment_service.dart`
- **Before:** `static const String _baseUrl = 'http://192.168.100.103:8000/api/v1';`
- **After:** `static const String _baseUrl = 'http://192.168.100.105:8000/api/v1';`

**Return URLs Updated:**
- **Before:** `'http://192.168.100.103:8000/api/v1/payments/success'`
- **After:** `'http://192.168.100.105:8000/api/v1/payments/success'`

### 4. Donation Service
**File:** `lib/services/donation_service.dart`
- **Before:** `static const String _baseUrl = 'http://192.168.100.103:8000/api/v1';`
- **After:** `static const String _baseUrl = 'http://192.168.100.105:8000/api/v1';`

**Return URLs Updated:**
- **Before:** `'http://192.168.100.103:8000/api/v1/payments/success'`
- **After:** `'http://192.168.100.105:8000/api/v1/payments/success'`

### 5. Campaign Donation Screen
**File:** `lib/screens/campaign_donation_screen.dart`
- **Before:** `successUrl: 'http://192.168.100.103:8000/api/v1/payments/success?session_id=$sessionId'`
- **After:** `successUrl: 'http://192.168.100.105:8000/api/v1/payments/success?session_id=$sessionId'`

- **Before:** `cancelUrl: 'http://192.168.100.103:8000/api/v1/payments/cancel?session_id=$sessionId'`
- **After:** `cancelUrl: 'http://192.168.100.105:8000/api/v1/payments/cancel?session_id=$sessionId'`

### 6. Payment WebView Screen
**File:** `lib/screens/payment_webview.dart`
- **Before:** `url.contains('192.168.100.103:8000/api/v1/payments/success')`
- **After:** `url.contains('192.168.100.105:8000/api/v1/payments/success')`

- **Before:** `url.contains('192.168.100.103:8000/api/v1/payments/cancel')`
- **After:** `url.contains('192.168.100.105:8000/api/v1/payments/cancel')`

### 7. Payment Screen
**File:** `lib/screens/payment_screen.dart`
- **Before:** `successUrl: 'http://192.168.100.103:8000/api/v1/payments/success?session_id=${paymentProvider.currentSessionId}'`
- **After:** `successUrl: 'http://192.168.100.105:8000/api/v1/payments/success?session_id=${paymentProvider.currentSessionId}'`

- **Before:** `cancelUrl: 'http://192.168.100.103:8000/api/v1/payments/cancel?session_id=${paymentProvider.currentSessionId}'`
- **After:** `cancelUrl: 'http://192.168.100.105:8000/api/v1/payments/cancel?session_id=${paymentProvider.currentSessionId}'`

## API Endpoints - نقاط النهاية

### Base URL - الرابط الأساسي
```
http://192.168.100.105:8000/api/v1
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
curl -X GET http://192.168.100.105:8000/api/v1/health
```

### 2. Authentication Test
```bash
curl -X POST http://192.168.100.105:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone": "test", "password": "test"}'
```

### 3. Campaigns Test
```bash
curl -X GET http://192.168.100.105:8000/api/v1/campaigns
```

### 4. Programs Test
```bash
curl -X GET http://192.168.100.105:8000/api/v1/programs
```

## Verification Steps - خطوات التحقق

### 1. Check Console Output
When the app starts, you should see:
```
API Base URL: http://192.168.100.105:8000/api/v1
AuthService: Using base URL: http://192.168.100.105:8000/api/v1
```

### 2. Test Authentication
- Try logging in with valid credentials
- Check that login requests go to the new server

### 3. Test Donations
- Create a test donation
- Verify payment URLs use the new IP address
- Check that success/cancel URLs redirect properly

### 4. Test Payment Flow
- Initiate a payment session
- Verify payment URLs contain `192.168.100.105`
- Test payment completion and status checking

## Network Configuration - إعدادات الشبكة

### Server Requirements
- Server must be running on `192.168.100.105:8000`
- API endpoints must be accessible from the client device
- CORS must be configured to allow requests from the app

### Firewall Settings
Ensure the following ports are open:
- Port 8000 (API server)
- Port 80/443 (if using HTTP/HTTPS redirects)

## Troubleshooting - استكشاف الأخطاء

### Common Issues

1. **Connection Refused**
   - Verify server is running on `192.168.100.105:8000`
   - Check network connectivity between client and server
   - Ensure firewall allows connections on port 8000

2. **CORS Errors**
   - Verify CORS configuration on the server
   - Check that the app's origin is allowed

3. **Payment URL Issues**
   - Verify all payment URLs use the new IP address
   - Check that success/cancel URLs are accessible
   - Ensure Thawani payment gateway is configured correctly

### Debug Commands

```bash
# Test server connectivity
ping 192.168.100.105

# Test API endpoint
curl -v http://192.168.100.105:8000/api/v1/health

# Check if port is open
telnet 192.168.100.105 8000
```

## Rollback Instructions - تعليمات الاسترجاع

If you need to rollback to the previous IP address:

1. Replace all instances of `192.168.100.105` with `192.168.100.103`
2. Restart the application
3. Clear app cache if needed

## Notes - ملاحظات

- This update affects all API communications in the app
- Payment processing will use the new server IP
- All success/cancel redirects will point to the new server
- Make sure the backend server is properly configured and running on the new IP

## Date - التاريخ
**Updated:** $(date)
**Previous IP:** 192.168.100.103
**New IP:** 192.168.100.105
