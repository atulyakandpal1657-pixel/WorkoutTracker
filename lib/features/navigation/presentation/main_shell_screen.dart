import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/route_paths.dart';
import '../../workout/data/workout_session_repository.dart';
import '../../workout/presentation/active_workout_state.dart';

class MainShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({super.key, required this.navigationShell});

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveSession = ref.watch(hasActiveSessionProvider);
    final activeDetailsAsync = ref.watch(activeSessionDetailsProvider);
    final isWorkoutTab = navigationShell.currentIndex == 1;

    String? workoutName;
    if (hasActiveSession) {
      activeDetailsAsync.whenData((d) => workoutName = d?.session.name);
      // Also handle the loaded state synchronously
      if (activeDetailsAsync is AsyncData<WorkoutSessionDetails?>) {
        workoutName = (activeDetailsAsync as AsyncData<WorkoutSessionDetails?>).value?.session.name;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          navigationShell,
          // Floating Resume Bar visible on all non-workout tabs
          if (hasActiveSession && !isWorkoutTab)
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: _FloatingWorkoutBanner(
                workoutName: workoutName ?? 'Active Workout',
                onTap: () {
                  context.push(RoutePaths.activeWorkout);
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => _onTap(context, index),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.accent),
              label: 'Home',
            ),
            NavigationDestination(
              icon: hasActiveSession
                  ? const Badge(
                      backgroundColor: AppColors.accent,
                      smallSize: 8,
                      child: Icon(Icons.fitness_center_outlined),
                    )
                  : const Icon(Icons.fitness_center_outlined),
              selectedIcon: hasActiveSession
                  ? const Badge(
                      backgroundColor: AppColors.accent,
                      smallSize: 8,
                      child: Icon(Icons.fitness_center, color: AppColors.accent),
                    )
                  : const Icon(Icons.fitness_center, color: AppColors.accent),
              label: 'Workout',
            ),
            const NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon:
                  Icon(Icons.calendar_month, color: AppColors.accent),
              label: 'History',
            ),
            const NavigationDestination(
              icon: Icon(Icons.show_chart_outlined),
              selectedIcon: Icon(Icons.show_chart, color: AppColors.accent),
              label: 'Progress',
            ),
            const NavigationDestination(
              icon: Icon(Icons.format_list_bulleted_outlined),
              selectedIcon: Icon(
                Icons.format_list_bulleted,
                color: AppColors.accent,
              ),
              label: 'Templates',
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingWorkoutBanner extends StatelessWidget {
  final String workoutName;
  final VoidCallback onTap;

  const _FloatingWorkoutBanner({
    required this.workoutName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedMd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: AppColors.accent, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE SESSION IN PROGRESS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      workoutName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
