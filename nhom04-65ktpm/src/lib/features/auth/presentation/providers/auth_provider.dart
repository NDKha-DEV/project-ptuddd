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

  User? get user => _user;
  String? get uid => _user?.id;
  bool get isSignedIn => _user != null;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
      _error = e.toString();
    } finally {
      _isInitializing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (!supabaseReady) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyAuthState(AuthState state) {
    _user = state.session?.user;
    _error = null;
    _isInitializing = false;
    _isLoading = false;
    notifyListeners();
  }

  void _handleAuthError(Object error) {
    _error = error.toString();
    _isInitializing = false;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
