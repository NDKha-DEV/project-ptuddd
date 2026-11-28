import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/supabase_bootstrap.dart';
import 'features/assessment/presentation/providers/attempt_history_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/exercises/presentation/providers/exercises_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseReady = await SupabaseBootstrap.init();
  final auth = AuthProvider(supabaseReady: supabaseReady);
  await auth.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => auth),
        // Mỗi module đăng ký provider của mình tại đây.
        // M3: ngân hàng đề + lịch sử làm bài theo uid đăng nhập.
        ChangeNotifierProvider(create: (_) => ExercisesProvider()),
        ChangeNotifierProxyProvider<AuthProvider, AttemptHistoryProvider>(
          create: (_) => AttemptHistoryProvider(),
          update: (_, auth, history) => history!..loadFor(auth.uid),
        ),
      ],
      child: const TluB1DailyApp(),
    ),
  );
}
