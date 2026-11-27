import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// M1 - Đăng nhập. Bản tạm, M1 thay bằng form email/mật khẩu và Google.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ôn luyện tiếng Anh B1 mỗi ngày',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const FilledButton(
                onPressed: null,
                child: Text('Đăng nhập sẽ triển khai ở M1-03'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
