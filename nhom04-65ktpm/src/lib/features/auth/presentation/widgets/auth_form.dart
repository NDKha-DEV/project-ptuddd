import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../providers/auth_provider.dart';

enum AuthFormMode { login, register }

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
    } else {
      await auth.signUp(email: email, password: password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isRegister = widget.mode == AuthFormMode.register;
    final colorScheme = Theme.of(context).colorScheme;

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
                  isRegister ? 'Tạo tài khoản mới' : 'Chào mừng trở lại',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  isRegister
                      ? 'Đăng ký để bắt đầu ôn luyện tiếng Anh B1.'
                      : 'Ôn luyện tiếng Anh B1 mỗi ngày.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
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
                if (isRegister) ...[
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
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Text(isRegister ? 'Đăng ký' : 'Đăng nhập'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(isRegister ? 'Đã có tài khoản?' : 'Chưa có tài khoản?'),
                    TextButton(
                      onPressed: auth.isLoading
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
}
