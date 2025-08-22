# الفرق بين برامج الدعم والحملات الخيرية - Programs vs Campaigns

## 📊 الفرق الأساسي

### 🎓 برامج الدعم الطلابي (Student Support Programs)
- **العدد**: 4 برامج
- **الهدف**: للطلبة الذين يريدون التسجيل في صندوق الدعم
- **المستخدمون**: الطلاب المسجلين
- **الوظيفة**: تسجيل الطلاب للحصول على الدعم
- **المكان**: شاشة تسجيل الطلاب (`student_registration_screen.dart`)

### 🎗️ حملات التبرع الخيرية (Charity Campaigns)
- **العدد**: 8 حملات
- **الهدف**: للمستخدمين العامين في الصفحة الرئيسية
- **المستخدمون**: أي شخص يريد التبرع
- **الوظيفة**: التبرع المباشر بدون تسجيل
- **المكان**: الصفحة الرئيسية (`home_screen.dart`)

## 🔧 التنفيذ في التطبيق

### 1. الصفحة الرئيسية (Home Screen)
```dart
// في lib/screens/home_screen.dart
Future<void> _loadCampaignsFromAPI() async {
  List<Campaign> allCampaigns = [];
  
  // تحميل حملات التبرع الخيرية فقط (للمستخدمين العامين)
  try {
    final charityCampaigns = await _campaignService.getCharityCampaigns();
    allCampaigns.addAll(charityCampaigns);
    print('HomeScreen: Successfully loaded ${charityCampaigns.length} charity campaigns from API');
    print('HomeScreen: Charity campaigns are for general users to donate directly');
  } catch (error) {
    print('HomeScreen: Failed to load charity campaigns: $error');
  }
  
  // ملاحظة: برامج الدعم الطلابي تُحمل في شاشات تسجيل الطلاب منفصلة
  // وهي للطلاب الذين يريدون التسجيل للحصول على الدعم، وليس للتبرع العام
}
```

### 2. شاشة تسجيل الطلاب (Student Registration Screen)
```dart
// في lib/screens/student_registration_screen.dart
Future<void> _loadPrograms() async {
  try {
    final programs = await _studentService.getSupportPrograms();
    
    // تحميل برامج الدعم الطلابي (للطلاب المسجلين)
    final validPrograms = programs.where((program) {
      final hasId = program['id'] != null;
      final hasName = program['title'] != null;
      return hasId && hasName;
    }).map((program) {
      return {
        'id': program['id'],
        'name': program['title'],
        'description': program['description'] ?? '',
      };
    }).toList();
    
    setState(() {
      _programs = validPrograms;
      _isLoadingPrograms = false;
    });
    
    print('Loaded ${validPrograms.length} valid student support programs');
  } catch (error) {
    print('Error loading student programs: $error');
  }
}
```

## 🎯 نقاط النهاية (API Endpoints)

### برامج الدعم الطلابي
```dart
// في lib/services/campaign_service.dart
Future<List<Campaign>> getStudentPrograms() async {
  List<String> endpoints = [
    '/v1/programs',        // http://192.168.1.21:8000/api/v1/programs
    '/programs',           // http://192.168.1.21:8000/api/programs
    '/api/v1/programs',    // http://192.168.1.21:8000/api/api/v1/programs
    '/api/programs',       // http://192.168.1.21:8000/api/api/programs
    '/v1/programs/support', // http://192.168.1.21:8000/api/v1/programs/support
    '/programs/support'    // http://192.168.1.21:8000/api/programs/support
  ];
  
  // النتيجة المتوقعة: 4 برامج للطلاب
}
```

### حملات التبرع الخيرية
```dart
// في lib/services/campaign_service.dart
Future<List<Campaign>> getCharityCampaigns() async {
  List<String> endpoints = [
    '/v1/campaigns',        // http://192.168.1.21:8000/api/v1/campaigns
    '/campaigns',           // http://192.168.1.21:8000/api/campaigns
    '/api/v1/campaigns',    // http://192.168.1.21:8000/api/api/v1/campaigns
    '/api/campaigns',       // http://192.168.1.21:8000/api/api/campaigns
    '/v1/charity-campaigns', // http://192.168.1.21:8000/api/v1/charity-campaigns
    '/charity-campaigns'    // http://192.168.1.21:8000/api/charity-campaigns
  ];
  
  // النتيجة المتوقعة: 8 حملات للمستخدمين العامين
}
```

## 📱 تدفق المستخدم

### للمستخدمين العامين (الصفحة الرئيسية):
1. **فتح التطبيق** → الصفحة الرئيسية
2. **رؤية حملات التبرع** → 8 حملات خيرية
3. **اختيار حملة** → التبرع المباشر
4. **إدخال بيانات التبرع** → إتمام التبرع

### للطلاب (تسجيل الدعم):
1. **فتح التطبيق** → الصفحة الرئيسية
2. **الذهاب لتسجيل الطلاب** → شاشة التسجيل
3. **رؤية برامج الدعم** → 4 برامج للطلاب
4. **اختيار برنامج** → تسجيل للحصول على الدعم
5. **إدخال بيانات الطالب** → إتمام التسجيل

## 🔍 البيانات المتوقعة

### برامج الدعم الطلابي (4 برامج):
```json
{
  "message": "Programs retrieved successfully",
  "data": [
    {
      "id": 22,
      "title": "برنامج الإعانة الشهرية",
      "description": "دعم شهري للطلاب المحتاجين",
      "goal_amount": 50000,
      "raised_amount": 35000,
      "status": "active",
      "category": "الإعانة الشهرية"
    },
    // ... 3 برامج أخرى
  ]
}
```

### حملات التبرع الخيرية (8 حملات):
```json
{
  "message": "Campaigns retrieved successfully",
  "data": [
    {
      "id": 9,
      "title": "حملة إغاثة ضحايا الزلزال",
      "description": "مساعدة ضحايا الكوارث الطبيعية",
      "goal_amount": 100000,
      "raised_amount": 75000,
      "status": "active",
      "category": "الإغاثة"
    },
    // ... 7 حملات أخرى
  ]
}
```

## ✅ النتائج المتوقعة بعد التصحيح

### الصفحة الرئيسية:
- **8 حملات خيرية فقط** (للمستخدمين العامين)
- **لا توجد برامج طلابية**

### شاشة تسجيل الطلاب:
- **4 برامج دعم طلابية فقط** (للطلاب المسجلين)
- **لا توجد حملات خيرية**

---

**تاريخ التحديث:** ديسمبر 2024  
**المطور:** فريق صندوق رعاية الطلاب
