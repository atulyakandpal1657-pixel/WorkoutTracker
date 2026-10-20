import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/badge_pill.dart';
import '../../../core/widgets/gym_card.dart';

class SessionDetailsScreen extends StatelessWidget {
  final String sessionId;

  const SessionDetailsScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Session Details',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Session',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session editing enabled in Phase 3'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete Session',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Session?'),
                  content: const Text(
                    'Are you sure you want to delete this workout? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.pop();
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Hero
            GymCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Push Day (Chest & Triceps)',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const BadgePill(
                        text: 'Completed',
                        backgroundColor: AppColors.surfaceElevated,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Monday, Oct 19, 2026 • 6:30 PM - 7:22 PM',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      _DetailMetric(label: 'Duration', value: '52 mins'),
                      SizedBox(width: 24),
                      _DetailMetric(label: 'Volume', value: '8,420 kg'),
                      SizedBox(width: 24),
                      _DetailMetric(label: 'Sets', value: '18 sets'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              'Exercises & Sets',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Exercise 1
            _ExerciseDetailCard(
              exerciseName: 'Barbell Bench Press',
              muscle: 'Chest',
              sets: const [
                {
                  'set': '1 (W)',
                  'weight': '60 kg',
                  'reps': '10 reps',
                  'isPr': false,
                },
                {
                  'set': '2',
                  'weight': '80 kg',
                  'reps': '8 reps',
                  'isPr': false,
                },
                {
                  'set': '3',
                  'weight': '82.5 kg',
                  'reps': '8 reps',
                  'isPr': true,
                },
                {
                  'set': '4',
                  'weight': '80 kg',
                  'reps': '7 reps',
                  'isPr': false,
                },
              ],
            ),
            const SizedBox(height: 12),

            // Exercise 2
            _ExerciseDetailCard(
              exerciseName: 'Incline Dumbbell Press',
              muscle: 'Upper Chest',
              sets: const [
                {
                  'set': '1',
                  'weight': '26 kg',
                  'reps': '10 reps',
                  'isPr': false,
                },
                {
                  'set': '2',
                  'weight': '28 kg',
                  'reps': '10 reps',
                  'isPr': false,
                },
                {
                  'set': '3',
                  'weight': '28 kg',
                  'reps': '9 reps',
                  'isPr': false,
                },
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  final String label;
  final String value;

  const _DetailMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ExerciseDetailCard extends StatelessWidget {
  final String exerciseName;
  final String muscle;
  final List<Map<String, dynamic>> sets;

  const _ExerciseDetailCard({
    required this.exerciseName,
    required this.muscle,
    required this.sets,
  });

  @override
  Widget build(BuildContext context) {
    return GymCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                exerciseName,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
              BadgePill(
                text: muscle,
                backgroundColor: AppColors.surfaceElevated,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...sets.map((s) {
            final isPr = s['isPr'] as bool;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      'Set ${s['set']}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${s['weight']} × ${s['reps']}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (isPr) ...[
                    const Spacer(),
                    const BadgePill(
                      text: 'PR',
                      backgroundColor: AppColors.accentMuted,
                      textColor: AppColors.accent,
                      icon: Icons.star,
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
