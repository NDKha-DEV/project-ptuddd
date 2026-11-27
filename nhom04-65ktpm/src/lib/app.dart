import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

class TluB1DailyApp extends StatefulWidget {
  const TluB1DailyApp({super.key});

  @override
  State<TluB1DailyApp> createState() => _TluB1DailyAppState();
}

class _TluB1DailyAppState extends State<TluB1DailyApp> {
  late final GoRouter _router = createAppRouter(context.read<AuthProvider>());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
