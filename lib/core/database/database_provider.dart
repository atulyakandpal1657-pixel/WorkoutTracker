import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

/// Provider for the single AppDatabase instance across the app.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Manages the currently selected profile / user ID.
/// Defaults to 'user-friend-1' (Friend 1 / Alex).
class ActiveUserNotifier extends Notifier<String> {
  @override
  String build() => 'user-friend-1';

  void selectUser(String userId) {
    state = userId;
  }
}

final activeUserIdProvider = NotifierProvider<ActiveUserNotifier, String>(
  ActiveUserNotifier.new,
);
