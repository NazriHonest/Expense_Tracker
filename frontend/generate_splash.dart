import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  // Load your original high-res image
  final original = File('assets/icons/original_logo.png');
  if (!await original.exists()) {
    print('Please place your logo at assets/icons/original_logo.png');
    return;
  }

  final image = img.decodeImage(await original.readAsBytes())!;

  // Create Android 12+ version (400x400)
  final android12 = img.copyResize(image, width: 400, height: 400);
  await File(
    'assets/icons/android12_splash.png',
  ).writeAsBytes(img.encodePng(android12));

  // Create standard splash version (1152x1152)
  final standard = img.copyResize(image, width: 1152, height: 1152);
  await File(
    'assets/icons/splash_icon.png',
  ).writeAsBytes(img.encodePng(standard));

  // Create app icon (1024x1024)
  final appIcon = img.copyResize(image, width: 1024, height: 1024);
  await File('assets/icons/app_icon.png').writeAsBytes(img.encodePng(appIcon));

  print('✅ All images generated successfully!');
} // RUN THIS SCRIPTS WITH THIS COMMAND: dart run generate_splash.dart
