import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tlu_b1_daily/app.dart';
import 'package:tlu_b1_daily/features/auth/presentation/providers/auth_provider.dart';
import 'package:tlu_b1_daily/features/learning_path/data/repositories/learning_path_repository.dart';
import 'package:tlu_b1_daily/features/learning_path/presentation/providers/learning_path_provider.dart';

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

Widget _buildApp(AuthProvider auth) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => auth),
    ChangeNotifierProxyProvider<AuthProvider, LearningPathProvider>(
      create: (_) => LearningPathProvider(
        repository: LearningPathRepository(supabaseReady: false),
      ),
      update: (_, auth, pathProvider) {
        final provider =
            pathProvider ??
            LearningPathProvider(
              repository: LearningPathRepository(supabaseReady: false),
            );
        Future.microtask(() => provider.syncUid(auth.uid));
        return provider;
      },
    ),
  ],
  child: const TluB1DailyApp(),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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
    expect(find.text('Lộ trình học tập'), findsOneWidget);

    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    expect(find.text('M1 - Nền tảng và tài khoản'), findsOneWidget);
  });

  testWidgets('Login có entry Forgot Password và quay lại được', (
    tester,
  ) async {
    final auth = AuthProvider(supabaseReady: false);
    await auth.initialize();

    await tester.pumpWidget(_buildApp(auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pumpAndSettle();

    expect(find.text('Khôi phục mật khẩu'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);

    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng trở lại'), findsOneWidget);
  });

  testWidgets('Recovery state mở Reset Password và không gây redirect loop', (
    tester,
  ) async {
    final controller = StreamController<AuthState>();
    final auth = AuthProvider(
      supabaseReady: false,
      authStateStream: controller.stream,
    );
    await auth.initialize();

    controller.add(
      AuthState(AuthChangeEvent.passwordRecovery, _session('recovery-uid')),
    );
    await tester.pump();

    await tester.pumpWidget(_buildApp(auth));
    await tester.pumpAndSettle();

    expect(find.text('Đặt mật khẩu mới'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('M5 - Thói quen và thống kê tiến độ'), findsNothing);

    controller.add(AuthState(AuthChangeEvent.signedOut, null));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Khôi phục mật khẩu'), findsOneWidget);
    expect(find.text('Đặt mật khẩu mới'), findsNothing);
    await controller.close();
  });
  testWidgets(
    'Luồng M4 đầy đủ qua GoRouter với session Supabase: Khảo sát -> Lộ trình -> Tour tiếng Anh',
    (tester) async {
      final auth = AuthProvider(
        supabaseReady: false,
        authStateStream: Stream.value(
          AuthState(AuthChangeEvent.signedIn, _session('test-uid-m4')),
        ),
      );
      await auth.initialize();
      await tester.pump();

      await tester.pumpWidget(_buildApp(auth));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lộ trình'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có lộ trình B1 cá nhân'), findsOneWidget);

      await tester.tap(find.text('Bắt đầu khảo sát tạo lộ trình'));
      await tester.pumpAndSettle();
      expect(find.text('Khảo sát đầu vào B1'), findsOneWidget);

      final skipBtn = find.text('Bỏ qua & tạo lộ trình nền tảng');
      await tester.scrollUntilVisible(
        skipBtn,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(skipBtn);
      await tester.pumpAndSettle();

      expect(find.text('Tiến độ tổng thể: 0%'), findsOneWidget);

      await tester.tap(find.textContaining('Tour dẫn tiếng Anh'));
      await tester.pumpAndSettle();
      expect(find.text('Tour dẫn tiếng Anh & CLB'), findsOneWidget);
    },
  );
}
