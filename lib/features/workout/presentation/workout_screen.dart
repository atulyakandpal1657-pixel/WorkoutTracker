import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/action_button.dart';
import '../../../core/widgets/gym_card.dart';
import '../../templates/data/template_repository.dart';
import '../data/workout_session_repository.dart';
import 'active_workout_state.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSessionId = ref.watch(activeSessionProvider);
    final activeDetailsAsync = ref.watch(activeSessionDetailsProvider);
    final templatesAsync = ref.watch(userTemplatesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Workout',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fitness_center),
            tooltip: 'Exercise Library',
            onPressed: () => context.push(RoutePaths.exercises),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active session resume card
            if (activeSessionId != null)
              activeDetailsAsync.when(
                data: (details) {
                  if (details == null) return const SizedBox.shrink();
                  return _ActiveSessionBanner(
                    details: details,
                    onResume: () => context.push(RoutePaths.activeWorkout),
                    onDiscard: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Discard Workout?'),
                          content: const Text(
                              'All logged sets will be permanently deleted.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Discard',
                                    style:
                                        TextStyle(color: AppColors.error))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref
                            .read(activeSessionProvider.notifier)
                            .discardSession();
                      }
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(color: AppColors.accent),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),

            // Quick Start Section
            Text(
              'Quick Start',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GymCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentMuted,
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: const Icon(Icons.add,
                            color: AppColors.accent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Empty Workout',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Log exercises and sets freely on the fly',
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
                    label: activeSessionId != null
                        ? 'Resume Current Session'
                        : 'Start Empty Workout',
                    onPressed: () async {
                      if (activeSessionId != null) {
                        context.push(RoutePaths.activeWorkout);
                        return;
                      }
                      await ref
                          .read(activeSessionProvider.notifier)
                          .startOrResume(name: 'Freestyle Workout');
                      if (!context.mounted) return;
                      context.push(RoutePaths.activeWorkout);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Start From Routines Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Start from Routines',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push(RoutePaths.templateEditor),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Routine'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            templatesAsync.when(
              data: (templates) {
                if (templates.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No routines yet — create one in the Templates tab.',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    ...templates.map(
                      (tpl) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RoutineStartCard(
                          template: tpl,
                          isSessionActive: activeSessionId != null,
                          onStart: () async {
                            final sid = await ref
                                .read(activeSessionProvider.notifier)
                                .startOrResume(
                                  name: tpl.name,
                                  templateId: tpl.id,
                                );
                            if (!context.mounted) return;
                            context.push(RoutePaths.activeWorkout);
                            _ = sid; // used above
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
              error: (err, _) =>
                  Center(child: Text('Error: $err')),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active Session Banner
// ---------------------------------------------------------------------------
class _ActiveSessionBanner extends StatelessWidget {
  final WorkoutSessionDetails details;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  const _ActiveSessionBanner({
    required this.details,
    required this.onResume,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final session = details.session;
    final completed = details.completedSets;
    final total = details.totalSets;

    final elapsed = DateTime.now().difference(session.startedAt);
    final m = elapsed.inMinutes.toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppSpacing.roundedLg,
            border: Border.all(color: AppColors.accent, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.12),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        'SESSION ACTIVE',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$m:$s',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                session.name,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$completed / $total sets completed',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      label: 'Resume Session',
                      icon: Icons.play_arrow,
                      onPressed: onResume,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ActionButton(
                    label: 'Discard',
                    variant: ActionButtonVariant.danger,
                    icon: Icons.close,
                    width: 110,
                    onPressed: onDiscard,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Routine Start Card
// ---------------------------------------------------------------------------
class _RoutineStartCard extends StatelessWidget {
  final WorkoutTemplateData template;
  final bool isSessionActive;
  final VoidCallback onStart;

  const _RoutineStartCard({
    required this.template,
    required this.isSessionActive,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return GymCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (template.description != null &&
                    template.description!.isNotEmpty)
                  Text(
                    template.description!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.play_circle_fill,
              color: AppColors.accent,
              size: 36,
            ),
            tooltip: isSessionActive ? 'Resume Current Session' : 'Start Routine',
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}
