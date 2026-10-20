import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/action_button.dart';
import '../../../core/widgets/gym_card.dart';

class TemplateEditorScreen extends StatefulWidget {
  final String? templateId;

  const TemplateEditorScreen({super.key, this.templateId});

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  final _titleController = TextEditingController(text: 'Upper Power');
  final _descController = TextEditingController(
    text: 'Upper body power & strength routine',
  );

  final List<String> _exercises = [
    'Barbell Bench Press (4 sets, 6-8 reps)',
    'Bent-Over Barbell Row (4 sets, 6-8 reps)',
    'Standing Overhead Press (3 sets, 8-10 reps)',
    'Incline Dumbbell Curl (3 sets, 10-12 reps)',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.templateId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Routine' : 'Create Routine',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionButton(
              label: 'Save',
              height: 36,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Routine saved successfully')),
                );
                context.pop();
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Routine Name Input
            Text(
              'Routine Name',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                hintText: 'e.g. Push Hypertrophy',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Description Input
            Text(
              'Notes / Description',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              maxLines: 2,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Add instructions, warm-up reminders, or notes',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Exercise List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercises (${_exercises.length})',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push(RoutePaths.exercises),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Exercise'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            ...List.generate(_exercises.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GymCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.drag_indicator,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _exercises[index],
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _exercises.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),

            ActionButton(
              label: 'Add Exercise to Routine',
              icon: Icons.add,
              variant: ActionButtonVariant.secondary,
              onPressed: () => context.push(RoutePaths.exercises),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
