import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/exercises/presentation/exercise_library_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/history/presentation/session_details_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/navigation/presentation/main_shell_screen.dart';
import '../../features/profile/presentation/profile_selection_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/templates/presentation/template_editor_screen.dart';
import '../../features/templates/presentation/templates_screen.dart';
import '../../features/workout/presentation/active_workout_screen.dart';
import '../../features/workout/presentation/workout_screen.dart';
import '../../features/workout/presentation/workout_summary_screen.dart';
import 'route_paths.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');
  final homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'homeNav');
  final workoutNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'workoutNav',
  );
  final historyNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'historyNav',
  );
  final progressNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'progressNav',
  );
  final templatesNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'templatesNav',
  );

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.home,
    routes: [
      // 5-Tab Stateful Bottom Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Home
          StatefulShellBranch(
            navigatorKey: homeNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Tab 1: Workout
          StatefulShellBranch(
            navigatorKey: workoutNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.workout,
                builder: (context, state) => const WorkoutScreen(),
              ),
            ],
          ),
          // Tab 2: History
          StatefulShellBranch(
            navigatorKey: historyNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.history,
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          // Tab 3: Progress
          StatefulShellBranch(
            navigatorKey: progressNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.progress,
                builder: (context, state) => const ProgressScreen(),
              ),
            ],
          ),
          // Tab 4: Templates
          StatefulShellBranch(
            navigatorKey: templatesNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.templates,
                builder: (context, state) => const TemplatesScreen(),
              ),
            ],
          ),
        ],
      ),

      // Full-screen Subroutes outside Bottom Nav
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.activeWorkout,
        builder: (context, state) => const ActiveWorkoutScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.workoutSummary,
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId'] ?? 'unknown';
          return WorkoutSummaryScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.sessionDetails,
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId'] ?? 'unknown';
          return SessionDetailsScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.templateEditor,
        builder: (context, state) {
          final templateId = state.uri.queryParameters['id'];
          return TemplateEditorScreen(templateId: templateId);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.exercises,
        builder: (context, state) {
          final picking = state.uri.queryParameters['picking'] == 'true';
          return ExerciseLibraryScreen(pickingMode: picking);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.profileSelection,
        builder: (context, state) => const ProfileSelectionScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
