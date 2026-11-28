import 'package:flutter/material.dart';

import '../widgets/auth_form.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: AuthForm(mode: AuthFormMode.resetPassword));
  }
}
