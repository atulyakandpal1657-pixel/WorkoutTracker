import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/action_button.dart';
import '../../../core/widgets/badge_pill.dart';
import '../../../core/widgets/gym_card.dart';
import '../../workout/presentation/active_workout_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWorkout = ref.watch(activeWorkoutProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'RepLog',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Profile Switcher Chip
          InkWell(
            onTap: () => context.push(RoutePaths.profileSelection),
            borderRadius: AppSpacing.roundedPill,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppSpacing.roundedPill,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Profile 1',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.fitness_center,
              size: 20,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Exercise Library',
            onPressed: () => context.push(RoutePaths.exercises),
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Settings',
            onPressed: () => context.push(RoutePaths.settings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Workout Banner if session exists
            if (activeWorkout != null) ...[
              _ActiveResumeHeroCard(
                workout: activeWorkout,
                onResume: () => context.push(RoutePaths.activeWorkout),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Quick Start Hero Card
            GymCard(
              color: AppColors.surfaceElevated,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.4),
                width: 1.5,
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentMuted,
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: const Icon(
                          Icons.bolt,
                          color: AppColors.accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Session',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'No preset needed, start tracking live',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ActionButton(
                    label: activeWorkout != null
                        ? 'Resume Active Workout'
                        : 'Start Empty Workout',
                    icon: Icons.play_arrow,
                    onPressed: () {
                      if (activeWorkout == null) {
                        ref
                            .read(activeWorkoutProvider.notifier)
                            .startWorkout(name: 'Freestyle Workout');
                      }
                      context.push(RoutePaths.activeWorkout);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Weekly Summary Stats
            Text(
              'Weekly Overview',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _StatMetricCard(
                    title: 'Workouts',
                    value: '4',
                    subtitle: 'This week',
                    icon: Icons.calendar_today,
                    accentColor: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatMetricCard(
                    title: 'Volume',
                    value: '14.2k',
                    subtitle: 'kg lifted',
                    icon: Icons.fitness_center,
                    accentColor: AppColors.info,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatMetricCard(
                    title: 'New PRs',
                    value: '2',
                    subtitle: 'Personal records',
                    icon: Icons.emoji_events,
                    accentColor: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Quick Routines Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Routines',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(RoutePaths.templates),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            _RoutinePreviewTile(
              title: 'Push - Chest & Triceps',
              exercises:
                  'Bench Press, Incline Dumbbell, Dips, Triceps Pushdown',
              onTap: () {
                ref
                    .read(activeWorkoutProvider.notifier)
                    .startWorkout(name: 'Push - Chest & Triceps');
                context.push(RoutePaths.activeWorkout);
              },
            ),
            const SizedBox(height: 10),
            _RoutinePreviewTile(
              title: 'Pull - Back & Biceps',
              exercises: 'Deadlift, Lat Pulldown, Barbell Row, Biceps Curl',
              onTap: () {
                ref
                    .read(activeWorkoutProvider.notifier)
                    .startWorkout(name: 'Pull - Back & Biceps');
                context.push(RoutePaths.activeWorkout);
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Recent Sessions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(RoutePaths.history),
                  child: const Text('All History'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            GymCard(
              onTap: () =>
                  context.push(RoutePaths.sessionDetailsPath('recent-1')),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Leg Day - Heavy Squats',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const BadgePill(
                        text: 'Yesterday',
                        backgroundColor: AppColors.surfaceElevated,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Squat, Romanian Deadlift, Leg Press, Calf Raises',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      _StatChip(icon: Icons.timer_outlined, label: '54 mins'),
                      SizedBox(width: 14),
                      _StatChip(icon: Icons.scale_outlined, label: '7,820 kg'),
                      SizedBox(width: 14),
                      _StatChip(
                        icon: Icons.check_circle_outline,
                        label: '16 sets',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _ActiveResumeHeroCard extends StatelessWidget {
  final ActiveWorkoutInfo workout;
  final VoidCallback onResume;

  const _ActiveResumeHeroCard({required this.workout, required this.onResume});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ACTIVE SESSION IN PROGRESS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            workout.workoutName,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ActionButton(
            label: 'Resume Workout',
            icon: Icons.play_arrow,
            onPressed: onResume,
          ),
        ],
      ),
    );
  }
}

class _StatMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _StatMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GymCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutinePreviewTile extends StatelessWidget {
  final String title;
  final String exercises;
  final VoidCallback onTap;

  const _RoutinePreviewTile({
    required this.title,
    required this.exercises,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GymCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exercises,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: AppSpacing.roundedSm,
            ),
            child: const Icon(
              Icons.play_arrow,
              size: 18,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
