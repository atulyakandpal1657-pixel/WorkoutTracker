import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/workout_session_repository.dart';

/// The active session ID tracked in memory; synced with DB.
class ActiveSessionNotifier extends Notifier<String?> {
  @override
  String? build() {
    // On startup, check for an existing active session in the DB.
    // We schedule the async work and update state once available.
    _restoreFromDb();
    return null;
  }

  Future<void> _restoreFromDb() async {
    final userId = ref.read(activeUserIdProvider);
    final active = await ref
        .read(workoutSessionRepositoryProvider)
        .getActiveSessionForUser(userId);
    if (active != null) {
      state = active.id;
    }
  }

  /// Start a new session (or resume existing) and return the session ID.
  Future<String> startOrResume({
    required String name,
    String? templateId,
  }) async {
    final userId = ref.read(activeUserIdProvider);
    final sessionId = await ref
        .read(workoutSessionRepositoryProvider)
        .startOrResumeSession(
          userId: userId,
          name: name,
          templateId: templateId,
        );
    state = sessionId;
    return sessionId;
  }

  /// Finish the active session and clear state.
  Future<void> finishSession({String? notes}) async {
    final sid = state;
    if (sid == null) return;
    await ref
        .read(workoutSessionRepositoryProvider)
        .completeSession(sid, notes: notes);
    state = null;
  }

  /// Discard and permanently delete the active session.
  Future<void> discardSession() async {
    final sid = state;
    if (sid == null) return;
    await ref
        .read(workoutSessionRepositoryProvider)
        .discardSession(sid);
    state = null;
  }

  void clear() => state = null;
}

final activeSessionProvider =
    NotifierProvider<ActiveSessionNotifier, String?>(
  ActiveSessionNotifier.new,
);

/// Reactive stream of full session details for the active session.
final activeSessionDetailsProvider =
    StreamProvider<WorkoutSessionDetails?>((ref) {
  final sid = ref.watch(activeSessionProvider);
  if (sid == null) return Stream.value(null);
  return ref
      .watch(workoutSessionRepositoryProvider)
      .watchSessionDetails(sid);
});

/// Simple provider to check if there is any active session (for banner).
final hasActiveSessionProvider = Provider<bool>((ref) {
  return ref.watch(activeSessionProvider) != null;
});
