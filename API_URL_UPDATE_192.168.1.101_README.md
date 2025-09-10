# API URL Update to 192.168.1.101 - تحديث عنوان API

## Summary - ملخص

تم تحديث جميع عناوين API في التطبيق من `192.168.100.105:8000` إلى `192.168.1.101:8000` لضمان الاتصال الصحيح مع الخادم.

All API URLs in the application have been updated from `192.168.100.105:8000` to `192.168.1.101:8000` to ensure proper server connectivity.

## Files Updated - الملفات المحدثة

### 1. API Client Service
**File:** `lib/services/api_client.dart`
- **Before:** `const baseUrl = 'http://192.168.100.105:8000/api/v1';`
- **After:** `const baseUrl = 'http://192.168.1.101:8000/api/v1';`

### 2. Authentication Service
**File:** `lib/services/auth_service.dart`
- **Before:** `const baseUrl = 'http://192.168.100.105:8000/api/v1';`
- **After:** `const baseUrl = 'http://192.168.1.101:8000/api/v1';`

### 3. Payment Service
**File:** `lib/services/payment_service.dart`
- **Before:** `static const String _baseUrl = 'http://192.168.100.105:8000/api/v1';`
- **After:** `static const String _baseUrl = 'http://192.168.1.101:8000/api/v1';`

### 4. Donation Service
**File:** `lib/services/donation_service.dart`
- **Before:** `return 'http://192.168.100.105:8000/api/v1';`
- **After:** `return 'http://192.168.1.101:8000/api/v1';`
- **Comment Updated:** `// الأجهزة الفعلية استخدمي IP الشبكة (مثال: 192.168.1.101)`

## API Endpoints Affected - نقاط النهاية المتأثرة

All API endpoints now use the new base URL:
- ✅ `POST /api/v1/auth/login`
- ✅ `POST /api/v1/auth/register`
- ✅ `GET /api/v1/auth/me`
- ✅ `POST /api/v1/donations/with-payment`
- ✅ `POST /api/v1/payments/create`
- ✅ `GET /api/v1/payments/status/{sessionId}`

## Testing - اختبار التطبيق

### 1. Verify API Connection
```bash
# Test the new API endpoint
curl http://192.168.1.101:8000/api/v1/auth/me
```

### 2. Run the Application
```bash
flutter run
```

### 3. Monitor Console Output
Look for the debug message confirming the new API URL:
```
API Base URL: http://192.168.1.101:8000/api/v1
AuthService: Using base URL: http://192.168.1.101:8000/api/v1
```

### 4. Test Key Features
- ✅ User Registration
- ✅ User Login
- ✅ Profile Management
- ✅ Donation Creation
- ✅ Payment Processing
- ✅ Payment Status Checking

## Network Configuration - إعدادات الشبكة

### For Development
- **Local Development:** `http://192.168.1.101:8000/api/v1`
- **Android Emulator:** Uses `10.0.2.2:8000/api/v1` (localhost mapping)
- **iOS Simulator:** Uses `localhost:8000/api/v1`

### For Production
Update the base URL in all service files to point to your production server.

## Notes - ملاحظات

1. **Backward Compatibility:** All existing API calls will continue to work with the new URL
2. **Authentication:** Token-based authentication remains unchanged
3. **Error Handling:** All error handling mechanisms remain intact
4. **Platform Support:** The app maintains support for both Android and iOS platforms

## Troubleshooting - استكشاف الأخطاء

### Connection Issues
If you encounter connection issues:
1. Verify the server is running on `192.168.1.101:8000`
2. Check network connectivity
3. Ensure firewall allows connections on port 8000
4. Verify the API endpoints are accessible

### Debug Information
The app includes debug prints that show the current API base URL in the console output.

---

**Date:** $(date)
**Updated by:** AI Assistant
**Version:** 1.0