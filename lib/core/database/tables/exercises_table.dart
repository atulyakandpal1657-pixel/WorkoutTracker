import 'package:drift/drift.dart';
import 'users_table.dart';

@DataClassName('ExerciseData')
@TableIndex(name: 'exercises_name_idx', columns: {#name}, unique: true)
class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get muscleGroup => text().named('muscle_group')();
  TextColumn get equipment => text()();
  TextColumn get exerciseType => text()
      .named('exercise_type')
      .withDefault(const Constant('weight_reps'))();
  BoolColumn get isCustom =>
      boolean().named('is_custom').withDefault(const Constant(false))();
  TextColumn get userId => text()
      .named('user_id')
      .nullable()
      .references(Users, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {id};
}
