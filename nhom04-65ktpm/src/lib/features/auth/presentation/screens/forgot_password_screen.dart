import 'package:flutter/material.dart';

import '../widgets/auth_form.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: AuthForm(mode: AuthFormMode.forgotPassword));
  }
}
