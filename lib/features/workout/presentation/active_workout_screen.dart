import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/action_button.dart';
import '../../../core/widgets/badge_pill.dart';
import '../../../core/widgets/gym_card.dart';
import '../data/workout_session_repository.dart';
import 'active_workout_state.dart';

// ---------------------------------------------------------------------------
// Exercise Picker Screen (push over active workout to pick exercise)
// ---------------------------------------------------------------------------
class _ExercisePicker extends ConsumerWidget {
  const _ExercisePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(activeSessionDetailsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Add Exercise',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: const Center(
        child: Text(
          'Tap the exercise library icon to select exercises.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rest Timer Notifier
// ---------------------------------------------------------------------------
class _RestTimerNotifier extends StateNotifier<int> {
  _RestTimerNotifier(int seconds) : super(seconds) {
    _remaining = seconds;
  }

  int _remaining;
  Timer? _timer;
  bool _running = false;

  void start(int seconds) {
    _timer?.cancel();
    _remaining = seconds;
    state = seconds;
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 0) {
        _remaining--;
        state = _remaining;
      } else {
        _timer?.cancel();
        _running = false;
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _running = false;
  }

  bool get isRunning => _running;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final _restTimerProvider =
    StateNotifierProvider<_RestTimerNotifier, int>((ref) {
  return _RestTimerNotifier(0);
});

// ---------------------------------------------------------------------------
// Active Workout Screen
// ---------------------------------------------------------------------------
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState
    extends ConsumerState<ActiveWorkoutScreen> {
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;
  DateTime? _sessionStart;

  // Rest timer config in seconds
  int _restTimerSeconds = 90;
  bool _showRestTimer = false;

  @override
  void initState() {
    super.initState();
    _startElapsedTimer();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_sessionStart != null) {
        setState(() {
          _elapsed = DateTime.now().difference(_sessionStart!);
        });
      }
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final sessionId = ref.watch(activeSessionProvider);
    if (sessionId == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final detailsAsync = ref.watch(activeSessionDetailsProvider);
    final restTimerValue = ref.watch(_restTimerProvider);

    return detailsAsync.when(
      data: (details) {
        if (details == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  Text('Session not found.',
                      style: GoogleFonts.outfit(color: AppColors.textPrimary)),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            ),
          );
        }

        // Track session start for elapsed timer
        if (_sessionStart == null) {
          _sessionStart = details.session.startedAt;
          _elapsed = DateTime.now().difference(_sessionStart!);
        }

        final completedSets = details.completedSets;
        final totalSets = details.totalSets;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 28),
              tooltip: 'Minimize',
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.session.name,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 12, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(_elapsed),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$completedSets / $totalSets sets',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ActionButton(
                  label: 'FINISH',
                  height: 36,
                  onPressed: () => _confirmFinish(context, sessionId),
                ),
              ),
            ],
          ),
          body: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Rest Timer Card
              _RestTimerCard(
                secondsLeft: restTimerValue,
                restSeconds: _restTimerSeconds,
                isVisible: _showRestTimer,
                onStart: (s) {
                  setState(() {
                    _restTimerSeconds = s;
                    _showRestTimer = true;
                  });
                  ref.read(_restTimerProvider.notifier).start(s);
                },
                onDismiss: () {
                  ref.read(_restTimerProvider.notifier).stop();
                  setState(() => _showRestTimer = false);
                },
                onChangeSeconds: (s) =>
                    setState(() => _restTimerSeconds = s),
              ),
              const SizedBox(height: AppSpacing.md),

              // Exercise Cards
              ...details.exercises.map((ex) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ExerciseCard(
                    exerciseWithSets: ex,
                    sessionId: sessionId,
                    onSetCompleted: () {
                      ref.read(_restTimerProvider.notifier).start(_restTimerSeconds);
                      setState(() => _showRestTimer = true);
                    },
                  ),
                );
              }),

              // Add Exercise Button
              ActionButton(
                label: 'Add Exercise',
                icon: Icons.add,
                variant: ActionButtonVariant.secondary,
                onPressed: () => _showExercisePicker(context, sessionId),
              ),
              const SizedBox(height: AppSpacing.md),

              // Discard Button
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: AppColors.error),
                  label: Text(
                    'Cancel & Discard Workout',
                    style:
                        GoogleFonts.inter(color: AppColors.error, fontSize: 13),
                  ),
                  onPressed: () => _confirmDiscard(context),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _showExercisePicker(
      BuildContext context, String sessionId) async {
    final exerciseId = await context.push<String>(
      '${RoutePaths.exercises}?picking=true',
    );
    if (exerciseId == null) return;

    await ref
        .read(workoutSessionRepositoryProvider)
        .addExerciseToSession(
          sessionId: sessionId,
          exerciseId: exerciseId,
        );
  }

  Future<void> _confirmFinish(BuildContext context, String sessionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish Workout?'),
        content:
            const Text('This will complete your session and save all sets.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Going'),
          ),
          ActionButton(
            label: 'Finish',
            height: 38,
            width: 100,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    await ref.read(activeSessionProvider.notifier).finishSession();
    if (!context.mounted) return;
    context.pushReplacement(RoutePaths.workoutSummaryPath(sessionId));
  }

  Future<void> _confirmDiscard(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Workout?'),
        content:
            const Text('All logged sets will be permanently deleted. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Discard',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    await ref.read(activeSessionProvider.notifier).discardSession();
    if (!context.mounted) return;
    context.pop();
  }
}

// ---------------------------------------------------------------------------
// Rest Timer Card
// ---------------------------------------------------------------------------
class _RestTimerCard extends StatelessWidget {
  final int secondsLeft;
  final int restSeconds;
  final bool isVisible;
  final void Function(int) onStart;
  final VoidCallback onDismiss;
  final void Function(int) onChangeSeconds;

  const _RestTimerCard({
    required this.secondsLeft,
    required this.restSeconds,
    required this.isVisible,
    required this.onStart,
    required this.onDismiss,
    required this.onChangeSeconds,
  });

  String _formatSecs(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return GymCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_top, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                isVisible
                    ? 'Rest: ${_formatSecs(secondsLeft)}'
                    : 'Rest Timer: ${restSeconds}s',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isVisible && secondsLeft <= 10
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (isVisible)
                IconButton(
                  icon: const Icon(Icons.close, size: 18,
                      color: AppColors.textSecondary),
                  onPressed: onDismiss,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              // Config options
              PopupMenuButton<int>(
                icon: const Icon(Icons.timer_outlined,
                    size: 18, color: AppColors.textSecondary),
                color: AppColors.surfaceElevated,
                onSelected: (v) => onStart(v),
                itemBuilder: (_) => [30, 60, 90, 120, 180, 240]
                    .map((s) => PopupMenuItem(
                          value: s,
                          child: Text('${s}s',
                              style:
                                  GoogleFonts.inter(color: AppColors.textPrimary)),
                        ))
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise Card
// ---------------------------------------------------------------------------
class _ExerciseCard extends ConsumerWidget {
  final SessionExerciseWithSets exerciseWithSets;
  final String sessionId;
  final VoidCallback onSetCompleted;

  const _ExerciseCard({
    required this.exerciseWithSets,
    required this.sessionId,
    required this.onSetCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ex = exerciseWithSets.exercise;
    final se = exerciseWithSets.sessionExercise;
    final sets = exerciseWithSets.sets;
    final prevPerf = exerciseWithSets.previousPerformance;

    return GymCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.name,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    Text(
                      '${ex.muscleGroup} • ${ex.equipment}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    color: AppColors.textSecondary),
                color: AppColors.surfaceElevated,
                onSelected: (val) async {
                  if (val == 'remove') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Remove Exercise?'),
                        content: Text(
                            'Remove "${ex.name}" and its sets from this workout?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Remove',
                                  style: TextStyle(color: AppColors.error))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref
                          .read(workoutSessionRepositoryProvider)
                          .removeExerciseFromSession(se.id);
                    }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove Exercise',
                        style: GoogleFonts.inter(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),

          // Previous performance hint
          if (prevPerf != null) ...[
            const SizedBox(height: 4),
            Text(
              'Previous best: $prevPerf',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.accentSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Sets Table Header
          Row(
            children: [
              _headerText('SET', 44),
              _headerText('PREV', 72),
              Expanded(child: _headerText('KG', null, center: true)),
              Expanded(child: _headerText('REPS', null, center: true)),
              const SizedBox(width: 40),
            ],
          ),
          const Divider(color: AppColors.divider, height: 16),

          // Set Rows
          ...sets.map((s) => _SetRow(
                setData: s,
                sessionExerciseId: se.id,
                previousPerf: prevPerf,
                onCompleted: onSetCompleted,
              )),

          const SizedBox(height: AppSpacing.sm),

          // Add Set Button
          ActionButton(
            label: '+ Add Set',
            variant: ActionButtonVariant.ghost,
            height: 38,
            onPressed: () async {
              await ref
                  .read(workoutSessionRepositoryProvider)
                  .addSet(sessionExerciseId: se.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _headerText(String text, double? width, {bool center = false}) {
    final t = Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textTertiary,
      ),
    );
    return width != null ? SizedBox(width: width, child: t) : t;
  }
}

// ---------------------------------------------------------------------------
// Set Row – each set independently edits weight + reps in SQLite on change
// ---------------------------------------------------------------------------
class _SetRow extends ConsumerStatefulWidget {
  final WorkoutSetData setData;
  final String sessionExerciseId;
  final String? previousPerf;
  final VoidCallback onCompleted;

  const _SetRow({
    required this.setData,
    required this.sessionExerciseId,
    required this.previousPerf,
    required this.onCompleted,
  });

  @override
  ConsumerState<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<_SetRow> {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.setData;
    _weightCtrl = TextEditingController(
      text: s.weightKg != null
          ? (s.weightKg! % 1 == 0
              ? s.weightKg!.toInt().toString()
              : s.weightKg.toString())
          : '',
    );
    _repsCtrl = TextEditingController(
      text: s.reps?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  // Save to DB on field change with validation
  Future<void> _saveSet({double? weight, int? reps}) async {
    final repo = ref.read(workoutSessionRepositoryProvider);
    try {
      await repo.updateSet(
        setId: widget.setData.id,
        weightKg: weight,
        reps: reps,
      );
    } on ArgumentError {
      // Ignore validation errors silently (user still typing)
    }
  }

  Future<void> _toggleComplete() async {
    final repo = ref.read(workoutSessionRepositoryProvider);
    final newCompleted = !widget.setData.completed;

    // Auto-save current field values before marking complete
    double? weight;
    int? reps;
    final wText = _weightCtrl.text.trim();
    final rText = _repsCtrl.text.trim();
    if (wText.isNotEmpty) weight = double.tryParse(wText);
    if (rText.isNotEmpty) reps = int.tryParse(rText);

    try {
      await repo.updateSet(
        setId: widget.setData.id,
        weightKg: weight,
        reps: reps,
        completed: newCompleted,
      );
    } on ArgumentError {
      return;
    }

    if (newCompleted) {
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.setData;
    final isCompleted = s.completed;
    final setType = s.setType;

    String setLabel;
    Color labelBg;
    Color labelFg;

    switch (setType) {
      case 'warmup':
        setLabel = 'W';
        labelBg = AppColors.warmup.withValues(alpha: 0.18);
        labelFg = AppColors.warmup;
        break;
      case 'failure':
        setLabel = 'F';
        labelBg = AppColors.error.withValues(alpha: 0.18);
        labelFg = AppColors.error;
        break;
      default:
        setLabel = '${s.setNumber}';
        labelBg = isCompleted
            ? AppColors.accent.withValues(alpha: 0.18)
            : AppColors.surfaceHighlight;
        labelFg = isCompleted ? AppColors.accent : AppColors.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // Set type badge
          GestureDetector(
            onLongPress: () => _showSetTypeMenu(context),
            child: SizedBox(
              width: 44,
              child: BadgePill(
                text: setLabel,
                backgroundColor: labelBg,
                textColor: labelFg,
              ),
            ),
          ),
          // Previous perf
          SizedBox(
            width: 72,
            child: Text(
              widget.previousPerf ?? '-',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Weight field
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _EditableSetField(
                controller: _weightCtrl,
                hint: '0',
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                onSubmitted: (val) {
                  final w = double.tryParse(val.trim());
                  if (w != null && w >= 0) _saveSet(weight: w);
                },
                isCompleted: isCompleted,
              ),
            ),
          ),
          // Reps field
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _EditableSetField(
                controller: _repsCtrl,
                hint: '0',
                keyboardType: TextInputType.number,
                onSubmitted: (val) {
                  final r = int.tryParse(val.trim());
                  if (r != null && r >= 0) _saveSet(reps: r);
                },
                isCompleted: isCompleted,
              ),
            ),
          ),
          // Complete / delete controls
          SizedBox(
            width: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _toggleComplete,
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color:
                        isCompleted ? AppColors.accent : AppColors.surfaceHighlight,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSetTypeMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Change Set Type',
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
            ...['normal', 'warmup', 'failure'].map((type) {
              final labels = {
                'normal': 'Working Set',
                'warmup': 'Warm-up Set',
                'failure': 'Failure Set',
              };
              return ListTile(
                title: Text(labels[type]!,
                    style: GoogleFonts.inter(color: AppColors.textPrimary)),
                leading: Icon(
                  Icons.circle,
                  color: type == 'warmup'
                      ? AppColors.warmup
                      : type == 'failure'
                          ? AppColors.error
                          : AppColors.accent,
                  size: 16,
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await ref
                      .read(workoutSessionRepositoryProvider)
                      .updateSet(setId: widget.setData.id, setType: type);
                },
              );
            }),
            ListTile(
              title: Text('Delete Set',
                  style:
                      GoogleFonts.inter(color: AppColors.error)),
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              onTap: () async {
                Navigator.pop(context);
                await ref
                    .read(workoutSessionRepositoryProvider)
                    .deleteSet(widget.setData.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Editable Set Field
// ---------------------------------------------------------------------------
class _EditableSetField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final void Function(String) onSubmitted;
  final bool isCompleted;

  const _EditableSetField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    required this.onSubmitted,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.accent.withValues(alpha: 0.08)
            : AppColors.surfaceElevated,
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(
          color: isCompleted ? AppColors.accent.withValues(alpha: 0.4) : AppColors.cardBorder,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
        ],
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isCompleted ? AppColors.accent : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            fontSize: 15,
            color: AppColors.textTertiary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        onSubmitted: onSubmitted,
        onEditingComplete: () {
          onSubmitted(controller.text);
          FocusScope.of(context).nextFocus();
        },
      ),
    );
  }
}
