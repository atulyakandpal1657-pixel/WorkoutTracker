import 'package:drift/drift.dart';
import 'exercises_table.dart';
import 'users_table.dart';
import 'workout_sets_table.dart';

@DataClassName('PersonalRecordData')
@TableIndex(name: 'prs_user_exercise_idx', columns: {#userId, #exerciseId})
@TableIndex(name: 'prs_record_type_idx', columns: {#recordType})
class PersonalRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()
      .named('user_id')
      .references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text()
      .named('exercise_id')
      .references(Exercises, #id, onDelete: KeyAction.cascade)();
  TextColumn get recordType => text().named('record_type')();
  RealColumn get value => real()();
  TextColumn get workoutSetId => text()
      .named('workout_set_id')
      .nullable()
      .references(WorkoutSets, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get achievedAt => dateTime().named('achieved_at')();

  @override
  Set<Column> get primaryKey => {id};
}
