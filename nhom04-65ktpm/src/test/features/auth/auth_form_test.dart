import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tlu_b1_daily/features/auth/presentation/providers/auth_provider.dart';
import 'package:tlu_b1_daily/features/auth/presentation/widgets/auth_form.dart';

Future<AuthProvider> _buildAuth() async {
  final auth = AuthProvider(supabaseReady: false);
  await auth.initialize();
  return auth;
}

Widget _buildForm(AuthProvider auth, AuthFormMode mode) {
  return ChangeNotifierProvider<AuthProvider>(
    create: (_) => auth,
    child: MaterialApp(home: Scaffold(body: AuthForm(mode: mode))),
  );
}

void main() {
  testWidgets('Login validate email và mật khẩu trước khi gửi', (tester) async {
    final auth = await _buildAuth();
    await tester.pumpWidget(_buildForm(auth, AuthFormMode.login));

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Vui lòng nhập email.'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Email không hợp lệ.'), findsOneWidget);
    expect(find.text('Mật khẩu phải có ít nhất 6 ký tự.'), findsOneWidget);
  });

  testWidgets('Register validate xác nhận mật khẩu và hiển thị lỗi gửi',
      (tester) async {
    final auth = await _buildAuth();
    await tester.pumpWidget(_buildForm(auth, AuthFormMode.register));

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3));

    await tester.enterText(fields.at(0), 'user@example.com');
    await tester.enterText(fields.at(1), '123456');
    await tester.enterText(fields.at(2), '654321');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Mật khẩu xác nhận không khớp.'), findsOneWidget);

    await tester.enterText(fields.at(2), '123456');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Chưa cấu hình Supabase.'), findsOneWidget);
  });

  testWidgets('Google button chỉ xuất hiện ở Login và gọi AuthProvider',
      (tester) async {
    final loginAuth = await _buildAuth();
    await tester.pumpWidget(_buildForm(loginAuth, AuthFormMode.login));

    expect(find.text('OR'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.text('Chưa cấu hình Supabase.'), findsOneWidget);

    final registerAuth = await _buildAuth();
    await tester.pumpWidget(_buildForm(registerAuth, AuthFormMode.register));

    expect(find.text('OR'), findsNothing);
    expect(find.text('Continue with Google'), findsNothing);
  });
}
