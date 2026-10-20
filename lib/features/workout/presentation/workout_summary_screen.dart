import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/badge_pill.dart';
import '../../../core/widgets/gym_card.dart';
import '../data/workout_session_repository.dart';

class WorkoutSummaryScreen extends ConsumerWidget {
  final String sessionId;

  const WorkoutSummaryScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(sessionDetailsStreamProvider(sessionId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Workout Summary',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go(RoutePaths.home),
          ),
        ],
      ),
      body: detailsAsync.when(
        data: (details) {
          if (details == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Session not found.',
                    style: GoogleFonts.outfit(color: AppColors.textPrimary),
                  ),
                  TextButton(
                    onPressed: () => context.go(RoutePaths.home),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            );
          }
          return _SummaryBody(details: details);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _SummaryBody extends StatelessWidget {
  final WorkoutSessionDetails details;
  const _SummaryBody({required this.details});

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${s}s';
  }

  String _formatVolume(double kg) {
    if (kg >= 1000) {
      return '${(kg / 1000).toStringAsFixed(1)}t';
    }
    return kg % 1 == 0
        ? '${kg.toInt()} kg'
        : '${kg.toStringAsFixed(1)} kg';
  }

  @override
  Widget build(BuildContext context) {
    final session = details.session;
    final dur = details.duration;
    final completedSets = details.completedSets;
    final totalVol = details.totalVolumeKg;
    final exerciseCount = details.exercises.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Trophy badge
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.accentMuted,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: AppColors.accent,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            completedSets > 0 ? 'Session Crushed!' : 'Session Saved',
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            session.name,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _SummaryMetricCard(
                  title: 'Duration',
                  value: _formatDuration(dur),
                  icon: Icons.timer_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetricCard(
                  title: 'Volume',
                  value: _formatVolume(totalVol),
                  icon: Icons.fitness_center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryMetricCard(
                  title: 'Sets Done',
                  value: '$completedSets sets',
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetricCard(
                  title: 'Exercises',
                  value: '$exerciseCount',
                  icon: Icons.list_alt,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Per-exercise breakdown
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Exercise Breakdown',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          ...details.exercises.map((ex) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GymCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.exercise.name,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ex.exercise.muscleGroup} • ${ex.exercise.equipment}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Completed sets table
                      ...ex.sets.where((s) => s.completed).map((s) {
                        final wStr = s.weightKg != null
                            ? (s.weightKg! % 1 == 0
                                ? '${s.weightKg!.toInt()} kg'
                                : '${s.weightKg} kg')
                            : '— kg';
                        final rStr =
                            s.reps != null ? '${s.reps} reps' : '— reps';

                        Color typeBg;
                        Color typeFg;
                        String typeLabel;
                        switch (s.setType) {
                          case 'warmup':
                            typeBg = AppColors.warmup.withValues(alpha: 0.18);
                            typeFg = AppColors.warmup;
                            typeLabel = 'W';
                            break;
                          case 'failure':
                            typeBg = AppColors.error.withValues(alpha: 0.18);
                            typeFg = AppColors.error;
                            typeLabel = 'F';
                            break;
                          default:
                            typeBg = AppColors.accentMuted;
                            typeFg = AppColors.accent;
                            typeLabel = '${s.setNumber}';
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              BadgePill(
                                text: typeLabel,
                                backgroundColor: typeBg,
                                textColor: typeFg,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$wStr × $rStr',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (ex.sets.where((s) => s.completed).isEmpty)
                        Text(
                          'No completed sets',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textTertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              )),

          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: () => context.go(RoutePaths.home),
            icon: const Icon(Icons.home_outlined, color: AppColors.accent),
            label: Text(
              'Back to Home',
              style: GoogleFonts.inter(color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SummaryMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryMetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GymCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
