import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/widgets/action_button.dart';
import '../../../core/widgets/badge_pill.dart';
import '../../../core/widgets/gym_card.dart';
import '../data/user_repository.dart';

class ProfileSelectionScreen extends ConsumerWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUserId = ref.watch(activeUserIdProvider);
    final usersAsync = ref.watch(allUsersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Select Profile',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy Advisory Banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppSpacing.roundedMd,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: AppColors.accent,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Private & Local-Only',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Profiles are stored 100% locally on this device with zero cloud sync or external tracking. Note: Profile selection is designed for convenient shared device usage between workout partners, not as a cryptographic security boundary.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'Switch Active Profile',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return const Center(child: Text('No profiles found.'));
                }
                return Column(
                  children: users.map((user) {
                    final isCurrent = user.id == activeUserId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GymCard(
                        color: isCurrent
                            ? AppColors.surfaceElevated
                            : AppColors.card,
                        border: Border.all(
                          color: isCurrent
                              ? AppColors.accent
                              : AppColors.cardBorder,
                          width: isCurrent ? 1.5 : 1.0,
                        ),
                        onTap: () {
                          ref
                              .read(activeUserIdProvider.notifier)
                              .selectUser(user.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Switched active profile to ${user.displayName}',
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppColors.accentMuted
                                    : AppColors.surfaceHighlight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: isCurrent
                                    ? AppColors.accent
                                    : AppColors.textSecondary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Profile ID: ${user.id}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrent)
                              const BadgePill(
                                text: 'ACTIVE',
                                backgroundColor: AppColors.accent,
                                textColor: AppColors.textOnAccent,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
              error: (err, stack) =>
                  Center(child: Text('Error loading profiles: $err')),
            ),

            const SizedBox(height: AppSpacing.lg),

            ActionButton(
              label: 'Add New Profile',
              icon: Icons.person_add_outlined,
              variant: ActionButtonVariant.secondary,
              onPressed: () {
                _showAddProfileDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProfileDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            hintText: 'e.g. Jordan',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ActionButton(
            label: 'Create',
            width: 100,
            height: 38,
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final newUser = await ref
                    .read(userRepositoryProvider)
                    .createUser(name);
                ref.read(activeUserIdProvider.notifier).selectUser(newUser.id);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
