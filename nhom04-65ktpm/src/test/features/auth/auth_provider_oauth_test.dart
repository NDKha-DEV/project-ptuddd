import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tlu_b1_daily/core/config/app_env.dart';
import 'package:tlu_b1_daily/core/services/supabase_bootstrap.dart';
import 'package:tlu_b1_daily/features/auth/presentation/providers/auth_provider.dart';

Session _session(String uid) {
  final user = User(
    id: uid,
    appMetadata: const <String, dynamic>{},
    userMetadata: const <String, dynamic>{},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00Z',
  );
  return Session(
    accessToken: 'test-access-token',
    refreshToken: 'test-refresh-token',
    tokenType: 'bearer',
    expiresIn: 3600,
    user: user,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall call) async {
        if (call.method == 'getAll') return <String, Object>{};
        if (call.method == 'setString' ||
            call.method == 'remove' ||
            call.method == 'clear') {
          return true;
        }
        return null;
      },
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (MethodCall call) async {
        if (call.method == 'launch' || call.method == 'canLaunch') return true;
        return null;
      },
    );

    if (AppEnv.isSupabaseConfigured) {
      await SupabaseBootstrap.init();
    }
  });

  test('Google OAuth pending được giải phóng bởi auth state và chặn request lặp',
      () async {
    if (!AppEnv.isSupabaseConfigured) return;

    final controller = StreamController<AuthState>();
    final auth = AuthProvider(
      supabaseReady: true,
      authStateStream: controller.stream,
      oauthTimeout: const Duration(seconds: 30),
    );
    await auth.initialize();

    final launched = await auth.signInWithGoogle();

    expect(launched, isTrue);
    expect(auth.isGoogleSignInPending, isTrue);
    expect(await auth.signInWithGoogle(), isFalse);

    controller.add(AuthState(AuthChangeEvent.signedIn, _session('oauth-user')));
    await pumpEventQueue();

    expect(auth.isGoogleSignInPending, isFalse);
    expect(auth.uid, 'oauth-user');
    expect(auth.isSignedIn, isTrue);
    expect(auth.notice, isNull);

    await controller.close();
    auth.dispose();
  });

  test('Timeout OAuth chỉ giải phóng pending UI và giữ notice không khuyến khích retry',
      () async {
    if (!AppEnv.isSupabaseConfigured) return;

    final auth = AuthProvider(
      supabaseReady: true,
      oauthTimeout: const Duration(milliseconds: 50),
    );
    await auth.initialize();

    final launched = await auth.signInWithGoogle();

    expect(launched, isTrue);
    expect(auth.isGoogleSignInPending, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(auth.isGoogleSignInPending, isFalse);
    expect(auth.error, isNull);
    expect(auth.notice, contains('có thể được cập nhật khi quay lại'));
    expect(auth.notice, isNot(contains('thử lại')));

    auth.dispose();
  });
}
