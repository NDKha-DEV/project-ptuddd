import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Khởi tạo Firebase.
///
/// Khi chưa chạy `flutterfire configure` (chưa có google-services.json /
/// firebase_options.dart), app vẫn chạy được ở chế độ offline để các module
/// làm giao diện song song. M1 sẽ thay bằng
/// `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<bool> init() async {
    try {
      await Firebase.initializeApp();
      return true;
    } catch (e) {
      debugPrint('[Firebase] Chưa cấu hình, chạy offline: $e');
      return false;
    }
  }
}
