import 'package:drift/drift.dart';
import 'users_table.dart';

@DataClassName('WorkoutSessionData')
@TableIndex(name: 'sessions_user_idx', columns: {#userId})
@TableIndex(name: 'sessions_status_idx', columns: {#status})
@TableIndex(name: 'sessions_started_at_idx', columns: {#startedAt})
class WorkoutSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()
      .named('user_id')
      .references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  DateTimeColumn get startedAt => dateTime().named('started_at')();
  DateTimeColumn get completedAt =>
      dateTime().named('completed_at').nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
