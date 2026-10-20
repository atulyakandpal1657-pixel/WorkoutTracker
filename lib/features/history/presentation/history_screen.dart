import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/badge_pill.dart';
import '../../../core/widgets/gym_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All Time', 'This Month', 'This Week'];

  final List<Map<String, dynamic>> _demoHistory = [
    {
      'id': 'session-101',
      'title': 'Push Day (Chest, Shoulders & Triceps)',
      'date': 'Today, 6:30 PM',
      'duration': '52 mins',
      'volume': '8,420 kg',
      'sets': 18,
      'prs': 1,
      'exercises':
          'Bench Press, Incline Dumbbell Press, Cable Fly, Lateral Raise, Triceps Pushdown',
    },
    {
      'id': 'session-102',
      'title': 'Pull Day (Back & Biceps)',
      'date': 'Friday, Oct 17',
      'duration': '58 mins',
      'volume': '9,150 kg',
      'sets': 19,
      'prs': 2,
      'exercises':
          'Barbell Deadlift, Lat Pulldown, Chest Supported Row, Barbell Curl',
    },
    {
      'id': 'session-103',
      'title': 'Leg Day - Quads & Calves',
      'date': 'Wednesday, Oct 15',
      'duration': '64 mins',
      'volume': '11,200 kg',
      'sets': 20,
      'prs': 0,
      'exercises':
          'Barbell Back Squat, Leg Press, Romanian Deadlift, Standing Calf Raise',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Workout History',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: List.generate(_filters.length, (index) {
                final isSelected = _selectedFilterIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_filters[index]),
                    selected: isSelected,
                    selectedColor: AppColors.accent,
                    backgroundColor: AppColors.surfaceElevated,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.textOnAccent
                          : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.roundedPill,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.cardBorder,
                      ),
                    ),
                    showCheckmark: false,
                    onSelected: (val) {
                      if (val) setState(() => _selectedFilterIndex = index);
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),

          // Workout list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _demoHistory.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _demoHistory[index];
                return GymCard(
                  onTap: () =>
                      context.push(RoutePaths.sessionDetailsPath(item['id'])),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['title'],
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          BadgePill(
                            text: item['date'],
                            backgroundColor: AppColors.surfaceElevated,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['exercises'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _HistoryStat(
                            icon: Icons.timer_outlined,
                            text: item['duration'],
                          ),
                          const SizedBox(width: 14),
                          _HistoryStat(
                            icon: Icons.scale_outlined,
                            text: item['volume'],
                          ),
                          const SizedBox(width: 14),
                          _HistoryStat(
                            icon: Icons.check_circle_outline,
                            text: '${item['sets']} sets',
                          ),
                          if (item['prs'] > 0) ...[
                            const Spacer(),
                            BadgePill(
                              text: '${item['prs']} PR',
                              icon: Icons.star,
                              backgroundColor: AppColors.accentMuted,
                              textColor: AppColors.accent,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryStat extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HistoryStat({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
