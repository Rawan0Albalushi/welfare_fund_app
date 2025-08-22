# البنية الجديدة للـ API - نظام منفصل للبرامج والحملات

## نظرة عامة

تم تحديث النظام ليدعم بنية جديدة تتضمن نظامين منفصلين:

### 1. برامج الدعم الطلابي (Student Support Programs)
- **الموجودة مسبقاً** في النظام
- تخدم الطلاب المحتاجين
- تدعم التسجيل الطلابي

### 2. حملات التبرع الخيرية (Charity Campaigns)
- **جديدة** في النظام
- تخدم المجتمع العام
- تدعم التبرعات الخيرية

## API Endpoints الجديدة

### برامج الدعم الطلابي (الموجودة)
```
GET /api/v1/programs          # جميع البرامج
GET /api/v1/programs/{id}     # تفاصيل البرنامج
GET /api/v1/categories        # فئات البرامج
```

### حملات التبرع الخيرية (الجديدة)
```
GET /api/v1/campaigns         # جميع الحملات
GET /api/v1/campaigns/urgent  # الحملات العاجلة
GET /api/v1/campaigns/featured # الحملات المميزة
GET /api/v1/campaigns/{id}    # تفاصيل الحملة
```

### نظام التبرعات الموحد
```
POST /api/v1/donations        # التبرع (للبرامج أو الحملات)
GET /api/v1/donations/quick-amounts # المبالغ السريعة
```

## التحديثات المطبقة في التطبيق

### 1. تحديث CampaignService

#### أ. الدوال الجديدة للبرامج الطلابية:
```dart
// جلب جميع برامج الدعم الطلابي
Future<List<Campaign>> getStudentPrograms()

// جلب تفاصيل برنامج طلابي
Future<Campaign?> getStudentProgramDetails(String programId)
```

#### ب. الدوال الجديدة للحملات الخيرية:
```dart
// جلب جميع الحملات الخيرية
Future<List<Campaign>> getCharityCampaigns()

// جلب الحملات العاجلة
Future<List<Campaign>> getUrgentCampaigns()

// جلب الحملات المميزة
Future<List<Campaign>> getFeaturedCampaigns()

// جلب تفاصيل حملة خيرية
Future<Campaign?> getCharityCampaignDetails(String campaignId)
```

#### ج. نظام التبرعات الموحد:
```dart
// إنشاء تبرع (للبرامج أو الحملات)
Future<Map<String, dynamic>> createDonation({
  required String itemId,
  required String itemType, // 'program' or 'campaign'
  required double amount,
  String? donorName,
  String? donorPhone,
  String? donorEmail,
  String? message,
})
```

### 2. تحديث نموذج Campaign

#### أ. الحقول الجديدة:
```dart
class Campaign {
  // ... الحقول الموجودة
  final String? type; // 'student_program' or 'charity_campaign'
  final bool? isUrgentFlag; // للحملات العاجلة
  final bool? isFeatured; // للحملات المميزة
}
```

#### ب. Getter محسن:
```dart
bool get isUrgent {
  // إذا كان محدد كعاجل، إرجاع true
  if (isUrgentFlag == true) return true;
  // وإلا، التحقق من الأيام المتبقية <= 7
  return remainingDays <= 7;
}
```

### 3. تحديث الصفحة الرئيسية

#### أ. تحميل البيانات المدمجة:
```dart
Future<void> _loadCampaignsFromAPI() async {
  // تحميل البرامج الطلابية والحملات الخيرية
  final studentPrograms = await _campaignService.getStudentPrograms();
  final charityCampaigns = await _campaignService.getCharityCampaigns();
  
  // دمج القائمتين
  final allCampaigns = [...studentPrograms, ...charityCampaigns];
  
  setState(() {
    _campaigns = allCampaigns;
    _allCampaigns = List.from(allCampaigns);
  });
}
```

### 4. تحديث صفحة التبرع

#### أ. نظام التبرعات الموحد:
```dart
Future<void> _proceedToDonation() async {
  // تحديد نوع العنصر بناءً على نوع الحملة
  final itemType = widget.campaign.type == 'student_program' ? 'program' : 'campaign';
  
  // إنشاء التبرع باستخدام النظام الموحد
  await _campaignService.createDonation(
    itemId: widget.campaign.id,
    itemType: itemType,
    amount: _selectedAmount,
    donorName: 'متبرع',
    donorPhone: '+96812345678',
    donorEmail: 'donor@example.com',
    message: 'تبرع خيري',
  );
}
```

#### ب. مؤشر التحميل:
- إضافة `_isProcessingDonation` للتحكم في حالة التحميل
- عرض `CircularProgressIndicator` أثناء معالجة التبرع
- تعطيل الزر أثناء المعالجة

## بنية البيانات المتوقعة

### 1. برامج الدعم الطلابي:
```json
{
  "data": [
    {
      "id": 1,
      "title": "برنامج فرص التعليم العالي",
      "description": "دعم الطلاب في الحصول على التعليم العالي",
      "goal_amount": 50000,
      "raised_amount": 35000,
      "status": "active",
      "category": {
        "id": 1,
        "name": "فرص التعليم"
      }
    }
  ]
}
```

### 2. الحملات الخيرية:
```json
{
  "data": [
    {
      "id": 1,
      "title": "مساعدة الأسر المحتاجة",
      "description": "توفير الغذاء والملابس للأسر المحتاجة",
      "goal_amount": 25000,
      "raised_amount": 18000,
      "status": "active",
      "is_urgent": true,
      "is_featured": false,
      "category": {
        "id": 2,
        "name": "الإعانة الشهرية"
      }
    }
  ]
}
```

### 3. نظام التبرعات الموحد:
```json
{
  "item_id": 1,
  "item_type": "campaign", // or "program"
  "amount": 100.0,
  "donor_name": "أحمد محمد",
  "donor_phone": "+96812345678",
  "donor_email": "ahmed@example.com",
  "message": "تبرع خيري"
}
```

## المزايا الجديدة

### 1. الفصل الواضح:
- ✅ برامج الدعم الطلابي منفصلة عن الحملات الخيرية
- ✅ كل نظام له endpoints خاصة به
- ✅ إدارة مستقلة للبيانات

### 2. المرونة:
- ✅ نظام تبرعات موحد يعمل مع كلا النوعين
- ✅ دعم الحملات العاجلة والمميزة
- ✅ إمكانية التوسع المستقبلي

### 3. التوافقية:
- ✅ الحفاظ على التوافق مع الكود الموجود
- ✅ Legacy methods للدعم العكسي
- ✅ تحديث تدريجي بدون كسر الوظائف

## الاختبار

### 1. اختبار البرامج الطلابية:
```bash
curl http://192.168.100.249:8000/api/v1/programs
```

### 2. اختبار الحملات الخيرية:
```bash
curl http://192.168.100.249:8000/api/v1/campaigns
curl http://192.168.100.249:8000/api/v1/campaigns/urgent
curl http://192.168.100.249:8000/api/v1/campaigns/featured
```

### 3. اختبار نظام التبرعات:
```bash
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

## النتيجة النهائية

بعد تطبيق التحديثات:
- ✅ النظام يدعم برامج الدعم الطلابي والحملات الخيرية
- ✅ نظام تبرعات موحد يعمل مع كلا النوعين
- ✅ واجهة مستخدم محسنة مع مؤشرات التحميل
- ✅ بنية مرنة قابلة للتوسع
- ✅ توافق كامل مع الكود الموجود
