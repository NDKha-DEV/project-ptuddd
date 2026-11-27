import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.supabaseReady});

  final bool supabaseReady;

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
