import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/widgets/action_button.dart';
import '../../../core/widgets/badge_pill.dart';
import '../../../core/widgets/gym_card.dart';
import '../data/exercise_repository.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  final bool pickingMode;

  const ExerciseLibraryScreen({super.key, this.pickingMode = false});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState
    extends ConsumerState<ExerciseLibraryScreen> {
  bool get _pickingMode => widget.pickingMode;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _muscleFilters = [
    'All',
    'Chest',
    'Back',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Legs',
    'Core',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(exerciseFilterProvider);
    final exercisesAsync = ref.watch(filteredExercisesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _pickingMode ? 'Select Exercise' : 'Exercise Library',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (!_pickingMode)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Custom Exercise',
              onPressed: () => _showAddExerciseDialog(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                ref.read(exerciseFilterProvider.notifier).setQuery(val);
              },
              decoration: InputDecoration(
                hintText: 'Search exercise by name...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: filterState.query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(exerciseFilterProvider.notifier)
                              .setQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Muscle Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: List.generate(_muscleFilters.length, (index) {
                final muscle = _muscleFilters[index];
                final isSelected = filterState.muscleGroup == muscle;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(muscle),
                    selected: isSelected,
                    selectedColor: AppColors.accent,
                    backgroundColor: AppColors.surfaceElevated,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
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
                      if (val) {
                        ref
                            .read(exerciseFilterProvider.notifier)
                            .setMuscleGroup(muscle);
                      }
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),

          // Exercises List
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.fitness_center_outlined,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No exercises found',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try adjusting your search or muscle group filter',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: exercises.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = exercises[index];
                    return GymCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      onTap: () {
                        if (_pickingMode) {
                          Navigator.of(context).pop(item.id);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${item.name} selected')),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: AppSpacing.roundedSm,
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              size: 20,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (item.isCustom)
                                      const BadgePill(
                                        text: 'CUSTOM',
                                        backgroundColor: AppColors.accentMuted,
                                        textColor: AppColors.accent,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    BadgePill(
                                      text: item.muscleGroup,
                                      backgroundColor:
                                          AppColors.surfaceHighlight,
                                    ),
                                    const SizedBox(width: 6),
                                    BadgePill(
                                      text: item.equipment,
                                      backgroundColor:
                                          AppColors.surfaceElevated,
                                      textColor: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (item.isCustom)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                              onPressed: () =>
                                  _confirmDeleteExercise(context, item),
                            )
                          else
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textTertiary,
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (err, stack) =>
                  Center(child: Text('Error loading exercises: $err')),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExercise(BuildContext context, ExerciseData item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text('Are you sure you want to remove "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(exerciseRepositoryProvider)
                  .deleteCustomExercise(item.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    String selectedMuscle = 'Chest';
    String selectedEquipment = 'Barbell';
    String? errorMessage;

    final muscles = [
      'Chest',
      'Back',
      'Shoulders',
      'Biceps',
      'Triceps',
      'Legs',
      'Core',
    ];

    final equipments = [
      'Barbell',
      'Dumbbell',
      'Cable',
      'Machine',
      'Bodyweight',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Custom Exercise'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Exercise Name',
                    hintText: 'e.g. Bulgarian Split Squat',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedMuscle,
                  decoration: const InputDecoration(labelText: 'Muscle Group'),
                  items: muscles
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedMuscle = val);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedEquipment,
                  decoration: const InputDecoration(labelText: 'Equipment'),
                  items: equipments
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedEquipment = val);
                    }
                  },
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ActionButton(
              label: 'Save',
              width: 90,
              height: 38,
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                try {
                  final activeUserId = ref.read(activeUserIdProvider);
                  await ref
                      .read(exerciseRepositoryProvider)
                      .addCustomExercise(
                        name: name,
                        muscleGroup: selectedMuscle,
                        equipment: selectedEquipment,
                        userId: activeUserId,
                      );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                } on DuplicateExerciseException catch (e) {
                  setDialogState(() {
                    errorMessage = e.toString();
                  });
                } catch (e) {
                  setDialogState(() {
                    errorMessage = 'Failed to add exercise: $e';
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
