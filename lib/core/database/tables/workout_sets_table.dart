import 'package:drift/drift.dart';
import 'session_exercises_table.dart';

@DataClassName('WorkoutSetData')
@TableIndex(name: 'sets_session_exercise_idx', columns: {#sessionExerciseId})
@TableIndex(name: 'sets_completed_idx', columns: {#completed})
class WorkoutSets extends Table {
  TextColumn get id => text()();
  TextColumn get sessionExerciseId => text()
      .named('session_exercise_id')
      .references(SessionExercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get setNumber => integer().named('set_number')();
  RealColumn get weightKg => real().named('weight_kg').nullable()();
  IntColumn get reps => integer().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get setType =>
      text().named('set_type').withDefault(const Constant('normal'))();
  DateTimeColumn get loggedAt => dateTime().named('logged_at')();

  @override
  Set<Column> get primaryKey => {id};
}
