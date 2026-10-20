import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

class UserRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  UserRepository(this._db);

  Stream<List<UserData>> watchAllUsers() {
    return (_db.select(
      _db.users,
    )..orderBy([(u) => OrderingTerm(expression: u.createdAt)])).watch();
  }

  Future<List<UserData>> getAllUsers() {
    return (_db.select(
      _db.users,
    )..orderBy([(u) => OrderingTerm(expression: u.createdAt)])).get();
  }

  Stream<UserData?> watchUserById(String id) {
    return (_db.select(
      _db.users,
    )..where((u) => u.id.equals(id))).watchSingleOrNull();
  }

  Future<UserData?> getUserById(String id) {
    return (_db.select(
      _db.users,
    )..where((u) => u.id.equals(id))).getSingleOrNull();
  }

  Future<UserData> createUser(String displayName) async {
    final user = UserData(
      id: _uuid.v4(),
      displayName: displayName.trim(),
      createdAt: DateTime.now(),
      settingsJson: '{"unit": "kg", "rest_timer_sec": 90}',
    );
    await _db.into(_db.users).insert(user);
    return user;
  }

  Future<void> updateUser(
    String id, {
    String? displayName,
    String? settingsJson,
  }) async {
    final companion = UsersCompanion(
      displayName: displayName != null
          ? Value(displayName.trim())
          : const Value.absent(),
      settingsJson: settingsJson != null
          ? Value(settingsJson)
          : const Value.absent(),
    );
    await (_db.update(
      _db.users,
    )..where((u) => u.id.equals(id))).write(companion);
  }

  Future<void> deleteUser(String id) async {
    await (_db.delete(_db.users)..where((u) => u.id.equals(id))).go();
  }

  Future<int> getUserWorkoutCount(String userId) async {
    final count = _db.workoutSessions.id.count();
    final query = _db.selectOnly(_db.workoutSessions)
      ..addColumns([count])
      ..where(_db.workoutSessions.userId.equals(userId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(appDatabaseProvider));
});

final allUsersStreamProvider = StreamProvider<List<UserData>>((ref) {
  return ref.watch(userRepositoryProvider).watchAllUsers();
});

final activeUserProvider = StreamProvider<UserData?>((ref) {
  final activeId = ref.watch(activeUserIdProvider);
  return ref.watch(userRepositoryProvider).watchUserById(activeId);
});
