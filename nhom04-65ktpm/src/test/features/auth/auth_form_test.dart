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

class FakeRecoveryAuthProvider extends AuthProvider {
  FakeRecoveryAuthProvider({required this.shouldSucceed})
      : super(supabaseReady: false);

  final bool shouldSucceed;
  String? _fakeNotice;
  String? _fakeError;

  @override
  String? get notice => _fakeNotice ?? super.notice;

  @override
  String? get error => _fakeError ?? super.error;

  @override
  Future<bool> sendPasswordResetEmail(String email) async {
    _fakeNotice = shouldSucceed
        ? 'Nếu email tồn tại, liên kết đặt lại mật khẩu đã được gửi. Vui lòng kiểm tra hộp thư.'
        : null;
    _fakeError =
        shouldSucceed ? null : 'Không gửi được email. Vui lòng thử lại.';
    notifyListeners();
    return shouldSucceed;
  }

  @override
  Future<bool> updatePassword(String password) async {
    _fakeNotice = shouldSucceed
        ? 'Mật khẩu đã được cập nhật. Vui lòng đăng nhập lại.'
        : null;
    _fakeError = shouldSucceed ? null : 'Không cập nhật được mật khẩu.';
    notifyListeners();
    return shouldSucceed;
  }
}

Future<FakeRecoveryAuthProvider> _buildRecoveryAuth(bool shouldSucceed) async {
  final auth = FakeRecoveryAuthProvider(shouldSucceed: shouldSucceed);
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

  testWidgets('Forgot Password validate email và hiển thị thông báo trung tính',
      (tester) async {
    final auth = await _buildRecoveryAuth(true);
    await tester.pumpWidget(_buildForm(auth, AuthFormMode.forgotPassword));

    expect(find.byType(TextFormField), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.text('Vui lòng nhập email.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.text('Email không hợp lệ.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Nếu email tồn tại, liên kết đặt lại mật khẩu đã được gửi. Vui lòng kiểm tra hộp thư.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Submit bị vô hiệu hóa khi AuthProvider đang loading',
      (tester) async {
    final auth = AuthProvider(supabaseReady: false);
    await tester.pumpWidget(_buildForm(auth, AuthFormMode.forgotPassword));

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('Reset Password validate xác nhận và hiển thị lỗi cập nhật',
      (tester) async {
    final auth = await _buildRecoveryAuth(false);
    await tester.pumpWidget(_buildForm(auth, AuthFormMode.resetPassword));

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));
    expect(find.text('Email'), findsNothing);

    await tester.enterText(fields.at(0), '123456');
    await tester.enterText(fields.at(1), '654321');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Mật khẩu xác nhận không khớp.'), findsOneWidget);

    await tester.enterText(fields.at(1), '123456');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Không cập nhật được mật khẩu.'), findsOneWidget);
  });
}
