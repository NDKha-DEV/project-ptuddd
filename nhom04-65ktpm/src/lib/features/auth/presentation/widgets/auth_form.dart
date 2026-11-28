import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../providers/auth_provider.dart';

enum AuthFormMode { login, register, forgotPassword, resetPassword }

class AuthForm extends StatefulWidget {
  const AuthForm({super.key, required this.mode});

  final AuthFormMode mode;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Vui lòng nhập email.';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) return 'Email không hợp lệ.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu.';
    if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự.';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu.';
    if (value != _passwordController.text) return 'Mật khẩu xác nhận không khớp.';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (widget.mode == AuthFormMode.login) {
      await auth.signInWithPassword(email: email, password: password);
    } else if (widget.mode == AuthFormMode.register) {
      await auth.signUp(email: email, password: password);
    } else if (widget.mode == AuthFormMode.forgotPassword) {
      await auth.sendPasswordResetEmail(email);
    } else {
      final updated = await auth.updatePassword(password);
      if (updated && mounted) context.go(AppRoutes.login);
    }
  }

  Future<void> _backToLogin() async {
    if (widget.mode == AuthFormMode.resetPassword) {
      await context.read<AuthProvider>().signOut();
    }
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLogin = widget.mode == AuthFormMode.login;
    final isRegister = widget.mode == AuthFormMode.register;
    final isForgotPassword = widget.mode == AuthFormMode.forgotPassword;
    final isResetPassword = widget.mode == AuthFormMode.resetPassword;
    final busy = auth.isLoading || auth.isGoogleSignInPending;
    final colorScheme = Theme.of(context).colorScheme;
    final title = switch (widget.mode) {
      AuthFormMode.login => 'Chào mừng trở lại',
      AuthFormMode.register => 'Tạo tài khoản mới',
      AuthFormMode.forgotPassword => 'Khôi phục mật khẩu',
      AuthFormMode.resetPassword => 'Đặt mật khẩu mới',
    };
    final subtitle = switch (widget.mode) {
      AuthFormMode.login => 'Ôn luyện tiếng Anh B1 mỗi ngày.',
      AuthFormMode.register => 'Đăng ký để bắt đầu ôn luyện tiếng Anh B1.',
      AuthFormMode.forgotPassword =>
        'Nhập email để nhận liên kết đặt lại mật khẩu.',
      AuthFormMode.resetPassword => 'Chọn mật khẩu mới cho tài khoản của bạn.',
    };
    final submitLabel = switch (widget.mode) {
      AuthFormMode.login => 'Đăng nhập',
      AuthFormMode.register => 'Đăng ký',
      AuthFormMode.forgotPassword => 'Gửi liên kết',
      AuthFormMode.resetPassword => 'Cập nhật mật khẩu',
    };

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppConstants.appName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(subtitle, textAlign: TextAlign.center),
                const SizedBox(height: 32),
                if (!isResetPassword) ...[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    validator: _validateEmail,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (!isForgotPassword) ...[
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    autocorrect: false,
                    validator: _validatePassword,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  if (isLogin) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: busy
                            ? null
                            : () => context.go(AppRoutes.forgotPassword),
                        child: const Text('Quên mật khẩu?'),
                      ),
                    ),
                  ],
                ],
                if (isRegister || isResetPassword) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: true,
                    autocorrect: false,
                    validator: _validateConfirmPassword,
                    decoration: const InputDecoration(
                      labelText: 'Xác nhận mật khẩu',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (auth.error != null) ...[
                  Text(
                    auth.error!,
                    style: TextStyle(color: colorScheme.error),
                  ),
                  const SizedBox(height: 12),
                ],
                if (auth.notice != null) ...[
                  Text(
                    auth.notice!,
                    style: TextStyle(color: colorScheme.primary),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  onPressed: busy ? null : _submit,
                  child: busy
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Text(submitLabel),
                ),
                if (isLogin) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: busy ? null : _signInWithGoogle,
                    icon: const Icon(Icons.account_circle_outlined),
                    label: auth.isGoogleSignInPending
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : const Text('Continue with Google'),
                  ),
                ],
                const SizedBox(height: 12),
                if (isForgotPassword || isResetPassword)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isResetPassword
                            ? 'Hủy và đăng nhập?'
                            : 'Đã nhớ mật khẩu?',
                      ),
                      TextButton(
                        onPressed: busy ? null : _backToLogin,
                        child: const Text('Đăng nhập'),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isRegister
                            ? 'Đã có tài khoản?'
                            : 'Chưa có tài khoản?',
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => context.go(
                                isRegister ? AppRoutes.login : AppRoutes.register,
                              ),
                        child: Text(isRegister ? 'Đăng nhập' : 'Đăng ký'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (widget.mode != AuthFormMode.login) return;
    FocusScope.of(context).unfocus();
    await context.read<AuthProvider>().signInWithGoogle();
  }
}
