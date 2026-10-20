import 'package:drift/drift.dart';
import 'exercises_table.dart';
import 'workout_sessions_table.dart';

@DataClassName('SessionExerciseData')
@TableIndex(name: 'session_exercises_session_idx', columns: {#sessionId})
@TableIndex(name: 'session_exercises_exercise_idx', columns: {#exerciseId})
class SessionExercises extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()
      .named('session_id')
      .references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text()
      .named('exercise_id')
      .references(Exercises, #id, onDelete: KeyAction.restrict)();
  IntColumn get position => integer()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
