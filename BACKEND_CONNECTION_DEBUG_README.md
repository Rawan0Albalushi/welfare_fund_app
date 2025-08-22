# تشخيص اتصال الباكند - Backend Connection Debug

## ✅ النتائج الأولية

### 1. اختبار الاتصال
```bash
ping 192.168.1.21
# النتيجة: متصل بنجاح (0% loss)
```

### 2. اختبار نقاط النهاية
```bash
# برامج الطلاب
Invoke-WebRequest -Uri "http://192.168.1.21:8000/api/v1/programs" -Method GET
# النتيجة: StatusCode: 200, Content: {"message":"Programs retrieved successfully","data":[...]}

# الحملات الخيرية  
Invoke-WebRequest -Uri "http://192.168.1.21:8000/api/v1/campaigns" -Method GET
# النتيجة: StatusCode: 200, Content: {"message":"Campaigns retrieved successfully","data":[...]}
```

## 🔍 المشكلة المحتملة

### إعدادات API Client
```dart
// في lib/services/api_client.dart
const baseUrl = 'http://192.168.1.21:8000/api';
```

### نقاط النهاية المحاولة
```dart
// في lib/services/campaign_service.dart
List<String> endpoints = [
  '/v1/programs',        // http://192.168.1.21:8000/api/v1/programs ✅
  '/programs',           // http://192.168.1.21:8000/api/programs ❌
  '/api/v1/programs',    // http://192.168.1.21:8000/api/api/v1/programs ❌
  '/api/programs',       // http://192.168.1.21:8000/api/api/programs ❌
  '/v1/programs/support', // http://192.168.1.21:8000/api/v1/programs/support ❓
  '/programs/support'    // http://192.168.1.21:8000/api/programs/support ❓
];
```

## 🛠️ الحلول المطبقة

### 1. تحسين التسجيل
```dart
print('CampaignService: Full URL: ${_apiClient.dio.options.baseUrl}$endpoint');
print('CampaignService: Response data length: ${response.data.toString().length}');
```

### 2. إضافة نقاط نهاية إضافية
```dart
// إضافة نقاط نهاية بديلة
'/v1/programs/support',
'/programs/support',
'/v1/charity-campaigns',
'/charity-campaigns'
```

## 🧪 خطوات الاختبار

### 1. تشغيل التطبيق
```bash
flutter run
```

### 2. مراقبة Console
ابحث عن هذه الرسائل:
```
API Base URL: http://192.168.1.21:8000/api
CampaignService: Trying endpoint: /v1/programs
CampaignService: Full URL: http://192.168.1.21:8000/api/v1/programs
CampaignService: Student Programs API Response status: 200
CampaignService: Response data length: 5634
```

### 3. النتائج المتوقعة

#### ✅ إذا نجح الاتصال:
```
CampaignService: Successfully parsed X student programs from endpoint: /v1/programs
HomeScreen: Successfully loaded X total campaigns from API
```

#### ❌ إذا فشل الاتصال:
```
CampaignService: Failed to fetch from endpoint /v1/programs: DioException
CampaignService: All endpoints failed for student programs, returning empty list
HomeScreen: No data from API, using fallback sample data
```

## 🔧 إصلاحات إضافية محتملة

### 1. إذا كانت المشكلة في CORS
```dart
// إضافة headers إضافية
headers: {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Access-Control-Allow-Origin': '*',
}
```

### 2. إذا كانت المشكلة في Timeout
```dart
// زيادة timeout
connectTimeout: const Duration(seconds: 60),
receiveTimeout: const Duration(seconds: 60),
```

### 3. إذا كانت المشكلة في SSL/HTTP
```dart
// إضافة إعدادات SSL
_dio = Dio(BaseOptions(
  baseUrl: baseUrl,
  validateStatus: (status) => status! < 500,
));
```

## 📊 البيانات المتوقعة من الباكند

### برامج الطلاب
```json
{
  "message": "Programs retrieved successfully",
  "data": [
    {
      "id": 22,
      "title": "برنامج الإعانة الشهرية",
      "description": "...",
      "goal_amount": 50000,
      "raised_amount": 35000,
      "status": "active",
      "category": "الإعانة الشهرية"
    }
  ]
}
```

### الحملات الخيرية
```json
{
  "message": "Campaigns retrieved successfully", 
  "data": [
    {
      "id": 9,
      "title": "حملة إغاثة ضحايا الزلزال",
      "description": "...",
      "goal_amount": 100000,
      "raised_amount": 75000,
      "status": "active",
      "category": "الإغاثة"
    }
  ]
}
```

## 🎯 الخطوات التالية

1. **تشغيل التطبيق ومراقبة Console**
2. **تحديد أي نقاط نهاية تعمل**
3. **إصلاح أي مشاكل في معالجة البيانات**
4. **تحديث نقاط النهاية حسب الحاجة**

---

**تاريخ التشخيص:** ديسمبر 2024  
**المطور:** فريق صندوق رعاية الطلاب
