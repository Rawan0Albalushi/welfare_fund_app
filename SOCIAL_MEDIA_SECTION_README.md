# قسم "تابعنا" - وسائل التواصل الاجتماعي

## نظرة عامة
تم إضافة قسم "تابعنا" في أسفل صفحة الإعدادات لجميع المستخدمين (المسجلين وغير المسجلين) لتعزيز التواصل مع المستخدمين عبر منصات التواصل الاجتماعي. تم إعادة تصميم القسم بطريقة أكثر عصرية وبساطة لتحسين تجربة المستخدم.

## الميزات

### 1. التصميم العصري والبسيط
- **تصميم أفقي**: تخطيط أفقي أنيق مع النص على اليسار والأيقونات على اليمين
- **أيقونات بسيطة**: أيقونات صغيرة مع خلفية شفافة وحدود رفيعة
- **ألوان هادئة**: ألوان خفيفة ومريحة للعين
- **تباعد مثالي**: مسافات متوازنة بين العناصر

### 2. المنصات المدعومة

#### انستغرام (Instagram)
- **الأيقونة**: `Icons.camera_alt_outlined`
- **اللون**: `#E4405F` (اللون الرسمي لانستغرام)
- **الوظيفة**: فتح صفحة انستغرام الرسمية

#### يوتيوب (YouTube)
- **الأيقونة**: `Icons.play_circle_outline`
- **اللون**: `#FF0000` (اللون الرسمي ليوتيوب)
- **الوظيفة**: فتح قناة يوتيوب الرسمية

#### تويتر (Twitter)
- **الأيقونة**: `Icons.flutter_dash` (مؤقتة - يمكن تغييرها)
- **اللون**: `#1DA1F2` (اللون الرسمي لتويتر)
- **الوظيفة**: فتح حساب تويتر الرسمي

### 3. التفاعل
- **Haptic Feedback**: تأثيرات لمسية عند الضغط
- **تصميم بسيط**: بدون ظلال معقدة أو تدرجات
- **استجابة سريعة**: تفاعل فوري مع المستخدم
- **سهولة الاستخدام**: أزرار واضحة وسهلة الضغط

## الكود

### الدالة الرئيسية (التصميم الجديد)
```dart
Widget _buildFollowUsSection() {
  return Column(
    children: [
      _buildSectionTitle('تابعنا'),
      const SizedBox(height: 15),
      Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.surfaceVariant,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تابعنا',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'كن على تواصل معنا',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildSimpleSocialButton(
                    icon: Icons.camera_alt_outlined,
                    color: const Color(0xFFE4405F),
                    onTap: () {
                      // TODO: Add Instagram link
                      HapticFeedback.lightImpact();
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildSimpleSocialButton(
                    icon: Icons.play_circle_outline,
                    color: const Color(0xFFFF0000),
                    onTap: () {
                      // TODO: Add YouTube link
                      HapticFeedback.lightImpact();
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildSimpleSocialButton(
                    icon: Icons.flutter_dash,
                    color: const Color(0xFF1DA1F2),
                    onTap: () {
                      // TODO: Add Twitter link
                      HapticFeedback.lightImpact();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
```

### دالة بناء الأزرار البسيطة (التصميم الجديد)
```dart
Widget _buildSimpleSocialButton({
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 22,
      ),
    ),
  );
}
```

### دالة بناء الأزرار القديمة (للرجوع إليها)
```dart
Widget _buildSocialMediaButton({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppColors.surface,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.surface,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    ),
  );
}
```

## التكامل مع الصفحة

### للمستخدمين غير المسجلين
- يظهر قسم "تابعنا" بعد قسم الدعم والمساعدة
- يوفر طريقة للتواصل حتى قبل التسجيل

### للمستخدمين المسجلين
- يظهر قسم "تابعنا" قبل زر تسجيل الخروج
- يبقى متاحاً حتى بعد تسجيل الخروج

## الخطوات المستقبلية

### 1. إضافة الروابط الفعلية
```dart
// مثال لإضافة رابط انستغرام
onTap: () async {
  const url = 'https://instagram.com/your_account';
  if (await canLaunch(url)) {
    await launch(url);
  }
},
```

### 2. إضافة المزيد من المنصات
- فيسبوك (Facebook)
- تيك توك (TikTok)
- لينكد إن (LinkedIn)
- سناب شات (Snapchat)

### 3. تحسينات إضافية
- إحصائيات المتابعين
- مشاركة المحتوى مباشرة
- إشعارات للمنشورات الجديدة

## المتطلبات

### الحزم المطلوبة
```yaml
dependencies:
  url_launcher: ^6.1.14
```

### الأذونات المطلوبة
```xml
<!-- Android -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- iOS -->
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>https</string>
  <string>http</string>
</array>
```

## الاختبار

- ✅ عرض القسم لجميع المستخدمين
- ✅ تأثيرات التفاعل تعمل بشكل صحيح
- ✅ التصميم متجاوب مع مختلف أحجام الشاشات
- ✅ الألوان والأنماط متناسقة مع التطبيق

## ملاحظات التطوير

- تم استخدام `HapticFeedback.lightImpact()` لتأثيرات اللمس
- الألوان مطابقة للألوان الرسمية لكل منصة
- التصميم متوافق مع Material Design 3
- يمكن إضافة المزيد من المنصات بسهولة
- التصميم الجديد أكثر بساطة وعصرية
- الأيقونات أصغر حجماً وأكثر أناقة
- التخطيط الأفقي يوفر مساحة أفضل
