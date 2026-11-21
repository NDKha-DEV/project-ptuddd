import 'package:flutter/foundation.dart';

/// Trạng thái đăng nhập dùng cho go_router redirect.
///
/// Hiện là bản tạm: `signInAsGuest` cho phép vào app khi chưa có Firebase.
/// M1 thay bằng FirebaseAuth (email/mật khẩu, Google, quên mật khẩu).
class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.firebaseReady});

  final bool firebaseReady;

  String? _uid;

  String? get uid => _uid;
  bool get isSignedIn => _uid != null;

  void signInAsGuest() {
    _uid = 'guest';
    notifyListeners();
  }

  void signOut() {
    _uid = null;
    notifyListeners();
  }
}
