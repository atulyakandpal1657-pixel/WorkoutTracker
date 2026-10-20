import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/action_button.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/gym_card.dart';
import '../../workout/presentation/active_workout_state.dart';
import '../data/template_repository.dart';

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(userTemplatesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Workout Templates',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Routine',
            onPressed: () => context.push(RoutePaths.templateEditor),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ActionButton(
              label: 'Create New Routine',
              icon: Icons.add,
              onPressed: () => context.push(RoutePaths.templateEditor),
            ),
            const SizedBox(height: 16),
            templatesAsync.when(
              data: (templates) {
                if (templates.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.fitness_center_outlined,
                    title: 'No routines yet',
                    description:
                        'Create your custom workout routine or duplicate an existing one to track sets easily.',
                  );
                }

                return Column(
                  children: templates.map((tpl) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GymCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    tpl.name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () {
                                    context.push(
                                      RoutePaths.templateEditorPath(
                                        templateId: tpl.id,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            if (tpl.description != null &&
                                tpl.description!.isNotEmpty) ...[
                              Text(
                                tpl.description!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Profile routine',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.play_circle_fill,
                                    color: AppColors.accent,
                                    size: 32,
                                  ),
                                  tooltip: 'Start Routine',
                                  onPressed: () {
                                    ref
                                        .read(activeWorkoutProvider.notifier)
                                        .startWorkout(name: tpl.name);
                                    context.push(RoutePaths.activeWorkout);
                                  },
                                ),
                              ],
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
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
              error: (err, stack) =>
                  Center(child: Text('Error loading routines: $err')),
            ),
          ],
        ),
      ),
    );
  }
}
