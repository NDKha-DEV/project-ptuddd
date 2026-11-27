import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/b1_materials/presentation/screens/material_detail_screen.dart';
import '../../features/b1_materials/presentation/screens/materials_screen.dart';
import '../../features/exercises/presentation/screens/exercise_detail_screen.dart';
import '../../features/exercises/presentation/screens/exercises_screen.dart';
import '../../features/habit_stats/presentation/screens/habit_dashboard_screen.dart';
import '../../features/learning_path/presentation/screens/learning_path_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../shell/home_shell.dart';
import 'app_routes.dart';

GoRouter createAppRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: auth,
    redirect: (context, state) {
      final atLogin = state.matchedLocation == AppRoutes.login;
      final atRegister = state.matchedLocation == AppRoutes.register;
      final atAuthScreen = atLogin || atRegister;
      if (auth.isInitializing) return atAuthScreen ? null : AppRoutes.login;
      if (!auth.isSignedIn) return atAuthScreen ? null : AppRoutes.login;
      if (atAuthScreen) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HabitDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.materials,
                builder: (context, state) => const MaterialsScreen(),
                routes: [
                  GoRoute(
                    path: ':materialId',
                    builder: (context, state) => MaterialDetailScreen(
                      materialId: state.pathParameters['materialId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.exercises,
                builder: (context, state) => const ExercisesScreen(),
                routes: [
                  GoRoute(
                    path: ':exerciseId',
                    builder: (context, state) => ExerciseDetailScreen(
                      exerciseId: state.pathParameters['exerciseId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.learningPath,
                builder: (context, state) => const LearningPathScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Không tìm thấy trang: ${state.uri}')),
    ),
  );
}
