import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/badge_pill.dart';
import '../../../core/widgets/gym_card.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Progress & Records',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big 3 / Main PR Highlights
            Text(
              'Personal Records (PRs)',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: const [
                Expanded(
                  child: _PrCard(
                    exercise: 'Bench Press',
                    weight: '100 kg',
                    reps: '1 rep (Est. 1RM: 100 kg)',
                    date: 'Oct 12',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _PrCard(
                    exercise: 'Back Squat',
                    weight: '140 kg',
                    reps: '3 reps (Est. 1RM: 153 kg)',
                    date: 'Oct 15',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
                Expanded(
                  child: _PrCard(
                    exercise: 'Deadlift',
                    weight: '175 kg',
                    reps: '1 rep (Est. 1RM: 175 kg)',
                    date: 'Oct 8',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _PrCard(
                    exercise: 'Overhead Press',
                    weight: '62.5 kg',
                    reps: '5 reps (Est. 1RM: 72 kg)',
                    date: 'Oct 16',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Weekly Volume Chart Card
            Text(
              'Weekly Training Volume',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GymCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Volume (kg)',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const BadgePill(
                        text: 'Last 6 Weeks',
                        backgroundColor: AppColors.surfaceElevated,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Bar visual representation
                  SizedBox(
                    height: 120,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _VolumeBar(
                          label: 'W37',
                          heightFactor: 0.5,
                          value: '18k',
                        ),
                        _VolumeBar(
                          label: 'W38',
                          heightFactor: 0.65,
                          value: '22k',
                        ),
                        _VolumeBar(
                          label: 'W39',
                          heightFactor: 0.72,
                          value: '25k',
                        ),
                        _VolumeBar(
                          label: 'W40',
                          heightFactor: 0.6,
                          value: '20k',
                        ),
                        _VolumeBar(
                          label: 'W41',
                          heightFactor: 0.85,
                          value: '29k',
                        ),
                        _VolumeBar(
                          label: 'W42',
                          heightFactor: 1.0,
                          value: '34k',
                          isCurrent: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Analytics by Exercise
            Text(
              'Exercise Progression',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GymCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Barbell Bench Press',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estimated 1RM trend: +7.5 kg over the last 30 days',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _PrCard extends StatelessWidget {
  final String exercise;
  final String weight;
  final String reps;
  final String date;

  const _PrCard({
    required this.exercise,
    required this.weight,
    required this.reps,
    required this.date,
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
              const Icon(Icons.emoji_events, size: 16, color: AppColors.accent),
              Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            weight,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            exercise,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            reps,
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

class _VolumeBar extends StatelessWidget {
  final String label;
  final double heightFactor;
  final String value;
  final bool isCurrent;

  const _VolumeBar({
    required this.label,
    required this.heightFactor,
    required this.value,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isCurrent ? AppColors.accent : AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 22,
          height: 70 * heightFactor,
          decoration: BoxDecoration(
            color: isCurrent ? AppColors.accent : AppColors.surfaceHighlight,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isCurrent ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
