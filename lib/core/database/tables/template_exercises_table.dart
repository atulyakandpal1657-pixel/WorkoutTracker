import 'package:drift/drift.dart';
import 'exercises_table.dart';
import 'workout_templates_table.dart';

@DataClassName('TemplateExerciseData')
@TableIndex(name: 'template_exercises_template_idx', columns: {#templateId})
@TableIndex(name: 'template_exercises_exercise_idx', columns: {#exerciseId})
class TemplateExercises extends Table {
  TextColumn get id => text()();
  TextColumn get templateId => text()
      .named('template_id')
      .references(WorkoutTemplates, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text()
      .named('exercise_id')
      .references(Exercises, #id, onDelete: KeyAction.restrict)();
  IntColumn get position => integer()();
  IntColumn get targetSets =>
      integer().named('target_sets').withDefault(const Constant(3))();
  IntColumn get targetRepsMin =>
      integer().named('target_reps_min').nullable()();
  IntColumn get targetRepsMax =>
      integer().named('target_reps_max').nullable()();
  RealColumn get targetWeightKg =>
      real().named('target_weight_kg').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
