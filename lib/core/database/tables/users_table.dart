import 'package:drift/drift.dart';

@DataClassName('UserData')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text().named('display_name')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  TextColumn get settingsJson =>
      text().named('settings_json').withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}
