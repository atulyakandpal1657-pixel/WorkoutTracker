import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/badge_pill.dart';
import '../../../core/widgets/gym_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedUnit = 'kg';
  int _defaultRestSeconds = 90;
  bool _soundEnabled = true;
  bool _vibrateEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Units Section
            _sectionHeader('TRAINING PREFERENCES'),
            GymCard(
              child: Column(
                children: [
                  _settingRow(
                    title: 'Weight Units',
                    subtitle: 'Preferred measurement system',
                    trailing: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'kg', label: Text('kg')),
                        ButtonSegment(value: 'lbs', label: Text('lbs')),
                      ],
                      selected: {_selectedUnit},
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.accent;
                          }
                          return AppColors.surfaceElevated;
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.textOnAccent;
                          }
                          return AppColors.textPrimary;
                        }),
                      ),
                      onSelectionChanged: (val) {
                        setState(() => _selectedUnit = val.first);
                      },
                    ),
                  ),
                  const Divider(color: AppColors.divider),
                  _settingRow(
                    title: 'Default Rest Timer',
                    subtitle: '$_defaultRestSeconds seconds between sets',
                    trailing: DropdownButton<int>(
                      value: _defaultRestSeconds,
                      dropdownColor: AppColors.surfaceElevated,
                      underline: const SizedBox(),
                      style: GoogleFonts.inter(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                      items: const [
                        DropdownMenuItem(value: 60, child: Text('60s')),
                        DropdownMenuItem(value: 90, child: Text('90s')),
                        DropdownMenuItem(value: 120, child: Text('120s')),
                        DropdownMenuItem(value: 180, child: Text('180s')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _defaultRestSeconds = val);
                        }
                      },
                    ),
                  ),
                  const Divider(color: AppColors.divider),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Timer Sound Alert',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Play tone when rest expires',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    activeThumbColor: AppColors.accent,
                    value: _soundEnabled,
                    onChanged: (val) => setState(() => _soundEnabled = val),
                  ),
                  const Divider(color: AppColors.divider),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Timer Vibration',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Haptic buzz when rest is done',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    activeThumbColor: AppColors.accent,
                    value: _vibrateEnabled,
                    onChanged: (val) => setState(() => _vibrateEnabled = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Privacy & Backup Section
            _sectionHeader('LOCAL DATA & PRIVACY'),
            GymCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.people_outline,
                      color: AppColors.accent,
                    ),
                    title: Text(
                      'Manage Profiles',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Switch between Friend 1 and Friend 2',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiary,
                    ),
                    onTap: () => context.push(RoutePaths.profileSelection),
                  ),
                  const Divider(color: AppColors.divider),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.file_upload_outlined,
                      color: AppColors.info,
                    ),
                    title: Text(
                      'Export Workout Data',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Export profile history to portable JSON file',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const BadgePill(
                      text: 'JSON',
                      backgroundColor: AppColors.surfaceElevated,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Export functionality is ready for Phase 7 integration',
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(color: AppColors.divider),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.file_download_outlined,
                      color: AppColors.warning,
                    ),
                    title: Text(
                      'Import Workout Data',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Restore from JSON backup with validation',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const BadgePill(
                      text: 'RESTORE',
                      backgroundColor: AppColors.surfaceElevated,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Import functionality is ready for Phase 7 integration',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // About Section
            _sectionHeader('ABOUT'),
            GymCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RepLog',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                      const BadgePill(
                        text: 'v1.0.0 (MVP)',
                        backgroundColor: AppColors.surfaceElevated,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Built for lifters who prioritize private, local-first workout tracking without subscriptions, forced cloud accounts, or social distractions.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
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

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _settingRow({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
