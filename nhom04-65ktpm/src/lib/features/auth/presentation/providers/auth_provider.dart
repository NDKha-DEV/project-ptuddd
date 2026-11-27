import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required this.supabaseReady,
    Stream<AuthState>? authStateStream,
  }) {
    final stream = authStateStream ??
        (supabaseReady ? Supabase.instance.client.auth.onAuthStateChange : null);
    _authSubscription = stream?.listen(
      _applyAuthState,
      onError: _handleAuthError,
    );
  }

  final bool supabaseReady;

  StreamSubscription<AuthState>? _authSubscription;
  User? _user;
  bool _isInitializing = true;
  bool _isLoading = true;
  String? _error;
  String? _notice;

  User? get user => _user;
  String? get uid => _user?.id;
  bool get isSignedIn => _user != null;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get notice => _notice;

  Future<void> initialize() async {
    if (!supabaseReady) {
      _isInitializing = false;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final session = Supabase.instance.client.auth.currentSession;
      _user = session?.user;
      _error = null;
    } catch (e) {
      _error = _authMessage(e);
    } finally {
      _isInitializing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (_isLoading) return false;
    if (!supabaseReady) {
      _error = 'Chưa cấu hình Supabase.';
      _notice = null;
      notifyListeners();
      return false;
    }

    _startAction();
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session == null) {
        _error = 'Đăng nhập không thành công. Vui lòng thử lại.';
        return false;
      }
      _user = response.session!.user;
      _clearMessages();
      return true;
    } catch (e) {
      _error = _authMessage(e);
      return false;
    } finally {
      _finishAction();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    if (_isLoading) return false;
    if (!supabaseReady) {
      _error = 'Chưa cấu hình Supabase.';
      _notice = null;
      notifyListeners();
      return false;
    }

    _startAction();
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.session != null) {
        _user = response.session!.user;
        _clearMessages();
        return true;
      }
      _error = null;
      _notice = response.user == null
          ? 'Đăng ký chưa thành công. Vui lòng thử lại.'
          : 'Đăng ký thành công. Vui lòng xác nhận email trước khi đăng nhập.';
      return false;
    } catch (e) {
      _error = _authMessage(e);
      return false;
    } finally {
      _finishAction();
    }
  }

  Future<void> signOut() async {
    if (!supabaseReady) return;

    _isLoading = true;
    _error = null;
    _notice = null;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      _error = _authMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyAuthState(AuthState state) {
    _user = state.session?.user;
    _clearMessages();
    _isInitializing = false;
    _isLoading = false;
    notifyListeners();
  }

  void _handleAuthError(Object error) {
    _error = _authMessage(error);
    _notice = null;
    _isInitializing = false;
    _isLoading = false;
    notifyListeners();
  }

  void _startAction() {
    _isLoading = true;
    _clearMessages();
    notifyListeners();
  }

  void _finishAction() {
    _isLoading = false;
    notifyListeners();
  }

  void _clearMessages() {
    _error = null;
    _notice = null;
  }

  String _authMessage(Object error) {
    if (error is! AuthException) return error.toString();
    switch (error.code) {
      case 'invalid_login_credentials':
        return 'Email hoặc mật khẩu không đúng.';
      case 'email_exists':
        return 'Email này đã được đăng ký.';
      case 'email_not_confirmed':
        return 'Vui lòng xác nhận email trước khi đăng nhập.';
      case 'weak_password':
        return 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu khác.';
      case 'over_email_send_rate_limit':
        return 'Gửi email quá nhanh. Vui lòng thử lại sau.';
      default:
        return error.message;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
