import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tlu_b1_daily/app.dart';
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

Widget _buildApp(AuthProvider auth) => ChangeNotifierProvider(
      create: (_) => auth,
      child: const TluB1DailyApp(),
    );

void main() {
  testWidgets('Không có session Supabase thì vào màn Login', (tester) async {
    final auth = AuthProvider(supabaseReady: false);
    await auth.initialize();

    await tester.pumpWidget(_buildApp(auth));
    await tester.pumpAndSettle();

    expect(find.text('TLU B1 Daily'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Chưa có tài khoản?'), findsOneWidget);
  });

  testWidgets('Chuyển qua lại giữa Login và Register', (tester) async {
    final auth = AuthProvider(supabaseReady: false);
    await auth.initialize();

    await tester.pumpWidget(_buildApp(auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('Xác nhận mật khẩu'), findsOneWidget);

    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('Session Supabase cập nhật thì vào được 5 tab', (tester) async {
    final auth = AuthProvider(
      supabaseReady: false,
      authStateStream: Stream.value(
        AuthState(AuthChangeEvent.signedIn, _session('test-uid')),
      ),
    );
    await auth.initialize();
    await tester.pump();

    await tester.pumpWidget(_buildApp(auth));
    await tester.pumpAndSettle();
    expect(find.text('M5 - Thói quen và thống kê tiến độ'), findsOneWidget);

    await tester.tap(find.text('Tài liệu'));
    await tester.pumpAndSettle();
    expect(find.text('M2 - Tài liệu tiếng Anh B1'), findsOneWidget);

    await tester.tap(find.text('Luyện tập'));
    await tester.pumpAndSettle();
    expect(find.text('M3 - Bài tập và đánh giá'), findsOneWidget);

    await tester.tap(find.text('Lộ trình'));
    await tester.pumpAndSettle();
    expect(find.text('M4 - Lộ trình học tập'), findsOneWidget);

    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    expect(find.text('M1 - Nền tảng và tài khoản'), findsOneWidget);
  });
}
