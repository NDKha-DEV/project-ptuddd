
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/firebase_bootstrap.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/learning_path/data/repositories/learning_path_repository.dart';
import 'features/learning_path/presentation/providers/learning_path_provider.dart';
import 'features/habit_stats/data/repositories/habit_repository.dart';
import 'features/habit_stats/presentation/providers/habit_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await FirebaseBootstrap.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(firebaseReady: firebaseReady),
        ),
        ChangeNotifierProxyProvider<AuthProvider, LearningPathProvider>(
          create: (_) => LearningPathProvider(
            repository: LearningPathRepository(firebaseReady: firebaseReady),
          ),
          update: (_, auth, pathProvider) {
            final provider =
                pathProvider ??
                LearningPathProvider(
                  repository: LearningPathRepository(
                    firebaseReady: firebaseReady,
                  ),
                );
            if (auth.isSignedIn) {
              Future.microtask(() => provider.syncUid(auth.uid));
            }
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => HabitProvider(HabitRepository()),
        ),
      ],
      child: const TluB1DailyApp(),
    ),
  );
}
