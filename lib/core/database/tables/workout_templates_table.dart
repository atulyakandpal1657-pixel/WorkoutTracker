import 'package:drift/drift.dart';
import 'users_table.dart';

@DataClassName('WorkoutTemplateData')
@TableIndex(name: 'templates_user_idx', columns: {#userId})
class WorkoutTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()
      .named('user_id')
      .references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
