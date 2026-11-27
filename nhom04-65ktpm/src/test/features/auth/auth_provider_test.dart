import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  test('Trạng thái khởi tạo được giải quyết khi không có Supabase', () async {
    final auth = AuthProvider(supabaseReady: false);

    expect(auth.isInitializing, isTrue);
    expect(auth.isLoading, isTrue);
    expect(auth.user, isNull);

    await auth.initialize();

    expect(auth.isInitializing, isFalse);
    expect(auth.isLoading, isFalse);
    expect(auth.isSignedIn, isFalse);
  });

  test('AuthState cập nhật user, loading và error', () async {
    final controller = StreamController<AuthState>();
    final auth = AuthProvider(
      supabaseReady: false,
      authStateStream: controller.stream,
    );
    await auth.initialize();

    controller.add(AuthState(AuthChangeEvent.signedIn, _session('user-1')));
    await pumpEventQueue();

    expect(auth.user?.id, 'user-1');
    expect(auth.uid, 'user-1');
    expect(auth.isSignedIn, isTrue);
    expect(auth.isInitializing, isFalse);
    expect(auth.isLoading, isFalse);
    expect(auth.error, isNull);

    controller.add(AuthState(AuthChangeEvent.signedOut, null));
    await pumpEventQueue();

    expect(auth.user, isNull);
    expect(auth.isSignedIn, isFalse);

    controller.addError('stream failed');
    await pumpEventQueue();

    expect(auth.error, 'stream failed');
    controller.close();
  });
}
