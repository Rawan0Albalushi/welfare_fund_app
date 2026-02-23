// سكربت لإنشاء أيقونة iOS بخلفية بيضاء
// التشغيل: dart run tool/add_white_bg_to_icon.dart
import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final projectRoot = Directory.current.path;
  final logoPath = '$projectRoot/assets/image/logo (2).png';
  final outPath =
      '$projectRoot/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png';

  final logoFile = File(logoPath);
  if (!await logoFile.exists()) {
    print('الملف غير موجود: $logoPath');
    exit(1);
  }

  final bytes = await logoFile.readAsBytes();
  final logo = img.decodeImage(bytes);
  if (logo == null) {
    print('فشل قراءة الصورة');
    exit(1);
  }

  // خلفية بيضاء بنفس أبعاد الشعار
  final whiteBg = img.Image(width: logo.width, height: logo.height);
  img.fill(whiteBg, color: img.ColorRgba8(255, 255, 255, 255));

  // وضع الشعار فوق الخلفية البيضاء
  img.compositeImage(whiteBg, logo, center: true);

  // تغيير الحجم إلى 1024x1024 إذا لزم الأمر (مطلوب لأيقونة iOS)
  img.Image output = whiteBg;
  if (whiteBg.width != 1024 || whiteBg.height != 1024) {
    output = img.copyResize(whiteBg, width: 1024, height: 1024);
  }

  await File(outPath).writeAsBytes(img.encodePng(output));
  print('تم حفظ الأيقونة بخلفية بيضاء: $outPath');
}
