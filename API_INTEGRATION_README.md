# تحديثات API - ربط التطبيق مع الخادم

## البنية الجديدة للـ API

### **نظامان منفصلان**:

#### 1. برامج الدعم الطلابي (الموجودة):
1. **GET /api/v1/programs** - جميع البرامج الطلابية
2. **GET /api/v1/programs/{id}** - تفاصيل البرنامج الطلابي
3. **GET /api/v1/categories** - فئات البرامج

#### 2. حملات التبرع الخيرية (الجديدة):
4. **GET /api/v1/campaigns** - جميع الحملات الخيرية
5. **GET /api/v1/campaigns/urgent** - الحملات العاجلة
6. **GET /api/v1/campaigns/featured** - الحملات المميزة
7. **GET /api/v1/campaigns/{id}** - تفاصيل الحملة الخيرية

#### 3. نظام التبرعات الموحد:
8. **POST /api/v1/donations** - إنشاء تبرع (للبرامج أو الحملات)
9. **GET /api/v1/donations/quick-amounts** - المبالغ السريعة

## التحديثات المطبقة

### 1. تحديث CampaignService

#### أ. الخدمات الجديدة للبرامج الطلابية:
```dart
class CampaignService {
  // جلب جميع برامج الدعم الطلابي
  Future<List<Campaign>> getStudentPrograms()
  
  // جلب تفاصيل برنامج طلابي
  Future<Campaign?> getStudentProgramDetails(String programId)
  
  // جلب جميع الحملات الخيرية
  Future<List<Campaign>> getCharityCampaigns()
  
  // جلب الحملات العاجلة
  Future<List<Campaign>> getUrgentCampaigns()
  
  // جلب الحملات المميزة
  Future<List<Campaign>> getFeaturedCampaigns()
  
  // جلب تفاصيل حملة خيرية
  Future<Campaign?> getCharityCampaignDetails(String campaignId)
  
  // جلب الفئات
  Future<List<Map<String, dynamic>>> getCategories()
  
  // إنشاء تبرع (نظام موحد)
  Future<Map<String, dynamic>> createDonation({
    required String itemId,
    required String itemType, // 'program' or 'campaign'
    required double amount,
    String? donorName,
    String? donorPhone,
    String? donorEmail,
    String? message,
  })
  
  // جلب المبالغ السريعة
  Future<List<double>> getQuickDonationAmounts()
}
```

#### ب. معالجة الأخطاء:
- ✅ Fallback للبيانات الثابتة عند فشل API
- ✅ رسائل خطأ واضحة للمستخدم
- ✅ Debug logging شامل

### 2. تحديث الصفحة الرئيسية

#### أ. تحميل البرامج والحملات من API:
```dart
Future<void> _loadCampaignsFromAPI() async {
  try {
    // تحميل البرامج الطلابية والحملات الخيرية
    final studentPrograms = await _campaignService.getStudentPrograms();
    final charityCampaigns = await _campaignService.getCharityCampaigns();
    
    // دمج القائمتين
    final allCampaigns = [...studentPrograms, ...charityCampaigns];
    
    setState(() {
      _campaigns = allCampaigns;
      _allCampaigns = List.from(allCampaigns);
    });
  } catch (error) {
    // Fallback to sample data
    _loadSampleCampaigns();
  }
}
```

#### ب. معالجة حالات التحميل:
- ✅ مؤشر تحميل أثناء جلب البيانات
- ✅ رسائل خطأ واضحة
- ✅ بيانات احتياطية عند الفشل

### 3. تحديث صفحة التبرع السريع

#### أ. تحميل البيانات من API:
```dart
Future<void> _loadDataFromAPI() async {
  // Load categories from API
  final categories = await _campaignService.getCategories();
  
  // Load quick amounts from API
  final amounts = await _campaignService.getQuickDonationAmounts();
}
```

#### ب. معالجة البيانات:
- ✅ تحويل بيانات API إلى التنسيق المطلوب
- ✅ Fallback للبيانات الثابتة
- ✅ تحديث UI تلقائياً

## بنية البيانات المتوقعة

### 1. البرامج (Programs):
```json
{
  "data": [
    {
      "id": 1,
      "title": "مساعدة كبار السن",
      "description": "مساعدة كبار السن في الحصول على الرعاية الصحية",
      "image_url": "https://example.com/image.jpg",
      "goal_amount": 50000,
      "raised_amount": 35000,
      "created_at": "2024-01-01T00:00:00Z",
      "end_date": "2024-03-01T00:00:00Z",
      "status": "active",
      "category": {
        "id": 1,
        "name": "الإعانة الشهرية"
      },
      "donor_count": 245
    }
  ]
}
```

### 2. الفئات (Categories):
```json
{
  "data": [
    {
      "id": 1,
      "name": "فرص التعليم",
      "description": "توفير التعليم والكتب الدراسية"
    }
  ]
}
```

### 3. التبرعات (Donations):
```json
{
  "program_id": 1,
  "amount": 100.0,
  "donor_name": "أحمد محمد",
  "donor_phone": "+96812345678",
  "donor_email": "ahmed@example.com",
  "message": "تبرع خيري"
}
```

### 4. المبالغ السريعة (Quick Amounts):
```json
{
  "data": [10.0, 25.0, 50.0, 100.0, 200.0, 500.0]
}
```

## المزايا

### 1. البيانات الواقعية:
- ✅ برامج حقيقية من قاعدة البيانات
- ✅ صور عالية الجودة ومناسبة
- ✅ إحصائيات دقيقة للتبرعات

### 2. الأداء المحسن:
- ✅ تحميل سريع للبيانات
- ✅ معالجة ذكية للأخطاء
- ✅ تجربة مستخدم سلسة

### 3. المرونة:
- ✅ Fallback للبيانات الثابتة
- ✅ معالجة شاملة للأخطاء
- ✅ تحديث تلقائي للبيانات

## الاختبار

### 1. اختبار البرامج الطلابية:
```bash
# اختبار جلب البرامج الطلابية
curl http://192.168.100.249:8000/api/v1/programs

# اختبار جلب الفئات
curl http://192.168.100.249:8000/api/v1/categories
```

### 2. اختبار الحملات الخيرية:
```bash
# اختبار جلب جميع الحملات
curl http://192.168.100.249:8000/api/v1/campaigns

# اختبار جلب الحملات العاجلة
curl http://192.168.100.249:8000/api/v1/campaigns/urgent

# اختبار جلب الحملات المميزة
curl http://192.168.100.249:8000/api/v1/campaigns/featured
```

### 3. اختبار نظام التبرعات:
```bash
# اختبار جلب المبالغ السريعة
curl http://192.168.100.249:8000/api/v1/donations/quick-amounts

# اختبار إنشاء تبرع
curl -X POST http://192.168.100.249:8000/api/v1/donations \
  -H "Content-Type: application/json" \
  -d '{
    "item_id": 1,
    "item_type": "campaign",
    "amount": 100.0,
    "donor_name": "أحمد محمد",
    "donor_phone": "+96812345678",
    "donor_email": "ahmed@example.com",
    "message": "تبرع خيري"
  }'
```

### 2. مراقبة السجلات:
```bash
flutter run --debug
```

البحث عن الرسائل التالية:
- `CampaignService: Fetching programs from API...`
- `HomeScreen: Loading campaigns from API...`
- `QuickDonate: Successfully loaded X categories from API`

## النتيجة النهائية

بعد تطبيق التحديثات:
- ✅ النظام يدعم برامج الدعم الطلابي والحملات الخيرية
- ✅ نظام تبرعات موحد يعمل مع كلا النوعين
- ✅ عرض البرامج والحملات مع الصور والإحصائيات
- ✅ دعم الحملات العاجلة والمميزة
- ✅ إمكانية التبرع مع تتبع المبالغ
- ✅ واجهة مستخدم محسنة مع مؤشرات التحميل
- ✅ تجربة مستخدم محسنة وواقعية
- ✅ معالجة شاملة للأخطاء والاستثناءات
- ✅ بنية مرنة قابلة للتوسع
