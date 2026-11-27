import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/supabase_bootstrap.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseReady = await SupabaseBootstrap.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(supabaseReady: supabaseReady),
        ),
        // Mỗi module đăng ký provider của mình tại đây.
      ],
      child: const TluB1DailyApp(),
    ),
  );
}
