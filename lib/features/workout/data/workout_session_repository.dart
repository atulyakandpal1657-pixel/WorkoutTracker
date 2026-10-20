import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

class SessionExerciseWithSets {
  final SessionExerciseData sessionExercise;
  final ExerciseData exercise;
  final List<WorkoutSetData> sets;
  final String? previousPerformance;

  const SessionExerciseWithSets({
    required this.sessionExercise,
    required this.exercise,
    required this.sets,
    this.previousPerformance,
  });

  SessionExerciseWithSets copyWith({
    SessionExerciseData? sessionExercise,
    ExerciseData? exercise,
    List<WorkoutSetData>? sets,
    String? previousPerformance,
  }) {
    return SessionExerciseWithSets(
      sessionExercise: sessionExercise ?? this.sessionExercise,
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      previousPerformance: previousPerformance ?? this.previousPerformance,
    );
  }
}

class WorkoutSessionDetails {
  final WorkoutSessionData session;
  final List<SessionExerciseWithSets> exercises;

  const WorkoutSessionDetails({
    required this.session,
    required this.exercises,
  });

  int get totalSets =>
      exercises.fold(0, (sum, e) => sum + e.sets.length);

  int get completedSets => exercises.fold(
      0, (sum, e) => sum + e.sets.where((s) => s.completed).length);

  double get totalVolumeKg {
    double total = 0.0;
    for (final ex in exercises) {
      for (final s in ex.sets) {
        if (s.completed) {
          final w = s.weightKg ?? 0.0;
          final r = s.reps ?? 0;
          total += (w * r);
        }
      }
    }
    return total;
  }

  Duration get duration {
    final end = session.completedAt ?? DateTime.now();
    final d = end.difference(session.startedAt);
    return d.isNegative ? Duration.zero : d;
  }
}

class WorkoutSessionRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  WorkoutSessionRepository(this._db);

  Stream<List<WorkoutSessionData>> watchSessionsForUser(String userId) {
    return (_db.select(_db.workoutSessions)
          ..where((s) => s.userId.equals(userId))
          ..orderBy([
            (s) => OrderingTerm(
                expression: s.startedAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<List<WorkoutSessionData>> getSessionsForUser(String userId) {
    return (_db.select(_db.workoutSessions)
          ..where((s) => s.userId.equals(userId))
          ..orderBy([
            (s) => OrderingTerm(
                expression: s.startedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<WorkoutSessionData?> getActiveSessionForUser(String userId) {
    return (_db.select(_db.workoutSessions)
          ..where((s) => s.userId.equals(userId) & s.status.equals('active'))
          ..orderBy([
            (s) => OrderingTerm(
                expression: s.startedAt, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<WorkoutSessionData?> watchActiveSessionForUser(String userId) {
    return (_db.select(_db.workoutSessions)
          ..where((s) => s.userId.equals(userId) & s.status.equals('active'))
          ..orderBy([
            (s) => OrderingTerm(
                expression: s.startedAt, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<String> startOrResumeSession({
    required String userId,
    required String name,
    String? templateId,
  }) async {
    return await _db.transaction(() async {
      // 1. Resume existing active session to prevent duplicate sessions
      final existingActive = await (_db.select(_db.workoutSessions)
            ..where((s) => s.userId.equals(userId) & s.status.equals('active'))
            ..orderBy([
              (s) => OrderingTerm(
                  expression: s.startedAt, mode: OrderingMode.desc),
            ])
            ..limit(1))
          .getSingleOrNull();

      if (existingActive != null) {
        return existingActive.id;
      }

      // 2. Start new session
      final sessionId = _uuid.v4();
      final now = DateTime.now();

      await _db.into(_db.workoutSessions).insert(
            WorkoutSessionsCompanion.insert(
              id: sessionId,
              userId: userId,
              name: name.trim(),
              startedAt: now,
              status: const Value('active'),
            ),
          );

      // 3. If starting from template, populate exercises and starter sets
      if (templateId != null) {
        final tplExercises = await (_db.select(_db.templateExercises)
              ..where((te) => te.templateId.equals(templateId))
              ..orderBy([(te) => OrderingTerm(expression: te.position)]))
            .get();

        for (int i = 0; i < tplExercises.length; i++) {
          final tplEx = tplExercises[i];
          final seId = _uuid.v4();

          await _db.into(_db.sessionExercises).insert(
                SessionExercisesCompanion.insert(
                  id: seId,
                  sessionId: sessionId,
                  exerciseId: tplEx.exerciseId,
                  position: i,
                ),
              );

          final targetSets = tplEx.targetSets > 0 ? tplEx.targetSets : 3;
          final targetWeight = tplEx.targetWeightKg;
          final targetReps = tplEx.targetRepsMin ?? tplEx.targetRepsMax ?? 10;

          for (int s = 1; s <= targetSets; s++) {
            await _db.into(_db.workoutSets).insert(
                  WorkoutSetsCompanion.insert(
                    id: _uuid.v4(),
                    sessionExerciseId: seId,
                    setNumber: s,
                    weightKg: Value(targetWeight),
                    reps: Value(targetReps),
                    completed: const Value(false),
                    setType: const Value('normal'),
                    loggedAt: now,
                  ),
                );
          }
        }
      }

      return sessionId;
    });
  }

  Stream<WorkoutSessionDetails?> watchSessionDetails(String sessionId) {
    final sessionStream = (_db.select(_db.workoutSessions)
          ..where((s) => s.id.equals(sessionId)))
        .watchSingleOrNull();

    return sessionStream.asyncExpand((session) {
      if (session == null) {
        return Stream.value(null);
      }

      final seQuery = _db.select(_db.sessionExercises).join([
        innerJoin(
          _db.exercises,
          _db.exercises.id.equalsExp(_db.sessionExercises.exerciseId),
        ),
      ])
        ..where(_db.sessionExercises.sessionId.equals(sessionId))
        ..orderBy([OrderingTerm(expression: _db.sessionExercises.position)]);

      return seQuery.watch().asyncMap((rows) async {
        final List<SessionExerciseWithSets> exercises = [];

        for (final row in rows) {
          final se = row.readTable(_db.sessionExercises);
          final ex = row.readTable(_db.exercises);

          final sets = await (_db.select(_db.workoutSets)
                ..where((s) => s.sessionExerciseId.equals(se.id))
                ..orderBy([(s) => OrderingTerm(expression: s.setNumber)]))
              .get();

          final prevPerf = await getPreviousPerformanceForExercise(
            session.userId,
            ex.id,
            excludeSessionId: sessionId,
          );

          exercises.add(
            SessionExerciseWithSets(
              sessionExercise: se,
              exercise: ex,
              sets: sets,
              previousPerformance: prevPerf,
            ),
          );
        }

        return WorkoutSessionDetails(
          session: session,
          exercises: exercises,
        );
      });
    });
  }

  Future<WorkoutSessionDetails?> getSessionDetails(String sessionId) async {
    final session = await (_db.select(_db.workoutSessions)
          ..where((s) => s.id.equals(sessionId)))
        .getSingleOrNull();

    if (session == null) return null;

    final seQuery = _db.select(_db.sessionExercises).join([
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.sessionExercises.exerciseId),
      ),
    ])
      ..where(_db.sessionExercises.sessionId.equals(sessionId))
      ..orderBy([OrderingTerm(expression: _db.sessionExercises.position)]);

    final rows = await seQuery.get();
    final List<SessionExerciseWithSets> exercises = [];

    for (final row in rows) {
      final se = row.readTable(_db.sessionExercises);
      final ex = row.readTable(_db.exercises);

      final sets = await (_db.select(_db.workoutSets)
            ..where((s) => s.sessionExerciseId.equals(se.id))
            ..orderBy([(s) => OrderingTerm(expression: s.setNumber)]))
          .get();

      final prevPerf = await getPreviousPerformanceForExercise(
        session.userId,
        ex.id,
        excludeSessionId: sessionId,
      );

      exercises.add(
        SessionExerciseWithSets(
          sessionExercise: se,
          exercise: ex,
          sets: sets,
          previousPerformance: prevPerf,
        ),
      );
    }

    return WorkoutSessionDetails(
      session: session,
      exercises: exercises,
    );
  }

  Future<String?> getPreviousPerformanceForExercise(
    String userId,
    String exerciseId, {
    String? excludeSessionId,
  }) async {
    final query = _db.select(_db.workoutSessions).join([
      innerJoin(
        _db.sessionExercises,
        _db.sessionExercises.sessionId.equalsExp(_db.workoutSessions.id),
      ),
    ])
      ..where(_db.workoutSessions.userId.equals(userId) &
          _db.workoutSessions.status.equals('completed') &
          _db.sessionExercises.exerciseId.equals(exerciseId));

    if (excludeSessionId != null) {
      query.where(_db.workoutSessions.id.isNotValue(excludeSessionId));
    }

    query.orderBy([
      OrderingTerm(
        expression: _db.workoutSessions.completedAt,
        mode: OrderingMode.desc,
      ),
    ]);
    query.limit(1);

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final se = row.readTable(_db.sessionExercises);
    final completedSets = await (_db.select(_db.workoutSets)
          ..where((s) =>
              s.sessionExerciseId.equals(se.id) & s.completed.equals(true))
          ..orderBy([(s) => OrderingTerm(expression: s.setNumber)]))
        .get();

    if (completedSets.isEmpty) return null;

    final bestSet = completedSets.reduce((curr, next) {
      final currVal = (curr.weightKg ?? 0.0) * (curr.reps ?? 0);
      final nextVal = (next.weightKg ?? 0.0) * (next.reps ?? 0);
      return currVal >= nextVal ? curr : next;
    });

    final w = bestSet.weightKg ?? 0.0;
    final r = bestSet.reps ?? 0;
    final wStr = w % 1 == 0 ? w.toInt().toString() : w.toString();
    return '$wStr kg × $r';
  }

  Future<String> addExerciseToSession({
    required String sessionId,
    required String exerciseId,
    int? position,
    String? notes,
  }) async {
    return await _db.transaction(() async {
      int pos = position ?? 0;
      if (position == null) {
        final currentExercises = await (_db.select(_db.sessionExercises)
              ..where((se) => se.sessionId.equals(sessionId)))
            .get();
        pos = currentExercises.length;
      }

      final seId = _uuid.v4();
      await _db.into(_db.sessionExercises).insert(
            SessionExercisesCompanion.insert(
              id: seId,
              sessionId: sessionId,
              exerciseId: exerciseId,
              position: pos,
              notes: Value(notes),
            ),
          );

      // Add default 1st working set
      await _db.into(_db.workoutSets).insert(
            WorkoutSetsCompanion.insert(
              id: _uuid.v4(),
              sessionExerciseId: seId,
              setNumber: 1,
              weightKg: const Value(null),
              reps: const Value(null),
              completed: const Value(false),
              setType: const Value('normal'),
              loggedAt: DateTime.now(),
            ),
          );

      return seId;
    });
  }

  Future<void> removeExerciseFromSession(String sessionExerciseId) async {
    await _db.transaction(() async {
      final se = await (_db.select(_db.sessionExercises)
            ..where((s) => s.id.equals(sessionExerciseId)))
          .getSingleOrNull();

      if (se == null) return;

      // Delete sets and session exercise
      await (_db.delete(_db.workoutSets)
            ..where((s) => s.sessionExerciseId.equals(sessionExerciseId)))
          .go();

      await (_db.delete(_db.sessionExercises)
            ..where((s) => s.id.equals(sessionExerciseId)))
          .go();

      // Re-index remaining exercises in session
      final remaining = await (_db.select(_db.sessionExercises)
            ..where((s) => s.sessionId.equals(se.sessionId))
            ..orderBy([(s) => OrderingTerm(expression: s.position)]))
          .get();

      for (int i = 0; i < remaining.length; i++) {
        if (remaining[i].position != i) {
          await (_db.update(_db.sessionExercises)
                ..where((s) => s.id.equals(remaining[i].id)))
              .write(SessionExercisesCompanion(position: Value(i)));
        }
      }
    });
  }

  Future<void> reorderSessionExercises({
    required String sessionId,
    required List<String> orderedSessionExerciseIds,
  }) async {
    await _db.transaction(() async {
      for (int i = 0; i < orderedSessionExerciseIds.length; i++) {
        final seId = orderedSessionExerciseIds[i];
        await (_db.update(_db.sessionExercises)
              ..where((se) =>
                  se.id.equals(seId) & se.sessionId.equals(sessionId)))
            .write(SessionExercisesCompanion(position: Value(i)));
      }
    });
  }

  Future<String> addSet({
    required String sessionExerciseId,
    double? weightKg,
    int? reps,
    String setType = 'normal',
  }) async {
    return await _db.transaction(() async {
      final existingSets = await (_db.select(_db.workoutSets)
            ..where((s) => s.sessionExerciseId.equals(sessionExerciseId))
            ..orderBy([(s) => OrderingTerm(expression: s.setNumber)]))
          .get();

      final nextNumber = existingSets.length + 1;
      final setId = _uuid.v4();

      // Default to previous set values if available
      final lastSet = existingSets.isNotEmpty ? existingSets.last : null;
      final defaultWeight = weightKg ?? lastSet?.weightKg;
      final defaultReps = reps ?? lastSet?.reps;

      await _db.into(_db.workoutSets).insert(
            WorkoutSetsCompanion.insert(
              id: setId,
              sessionExerciseId: sessionExerciseId,
              setNumber: nextNumber,
              weightKg: Value(defaultWeight),
              reps: Value(defaultReps),
              completed: const Value(false),
              setType: Value(setType),
              loggedAt: DateTime.now(),
            ),
          );

      return setId;
    });
  }

  Future<void> updateSet({
    required String setId,
    double? weightKg,
    int? reps,
    bool? completed,
    String? setType,
  }) async {
    // Validate inputs
    if (weightKg != null && weightKg < 0) {
      throw ArgumentError('Weight must be non-negative.');
    }
    if (reps != null && reps < 0) {
      throw ArgumentError('Reps must be non-negative.');
    }

    await (_db.update(_db.workoutSets)..where((s) => s.id.equals(setId))).write(
      WorkoutSetsCompanion(
        weightKg: weightKg != null ? Value(weightKg) : const Value.absent(),
        reps: reps != null ? Value(reps) : const Value.absent(),
        completed: completed != null ? Value(completed) : const Value.absent(),
        setType: setType != null ? Value(setType) : const Value.absent(),
        loggedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteSet(String setId) async {
    await _db.transaction(() async {
      final set = await (_db.select(_db.workoutSets)
            ..where((s) => s.id.equals(setId)))
          .getSingleOrNull();

      if (set == null) return;

      await (_db.delete(_db.workoutSets)..where((s) => s.id.equals(setId))).go();

      // Renumber remaining sets for this exercise
      final remaining = await (_db.select(_db.workoutSets)
            ..where((s) => s.sessionExerciseId.equals(set.sessionExerciseId))
            ..orderBy([(s) => OrderingTerm(expression: s.setNumber)]))
          .get();

      for (int i = 0; i < remaining.length; i++) {
        final expectedNum = i + 1;
        if (remaining[i].setNumber != expectedNum) {
          await (_db.update(_db.workoutSets)
                ..where((s) => s.id.equals(remaining[i].id)))
              .write(WorkoutSetsCompanion(setNumber: Value(expectedNum)));
        }
      }
    });
  }

  Future<WorkoutSessionData?> completeSession(
    String sessionId, {
    String? notes,
  }) async {
    return await _db.transaction(() async {
      final session = await (_db.select(_db.workoutSessions)
            ..where((s) => s.id.equals(sessionId)))
          .getSingleOrNull();

      if (session == null) return null;

      // Prevent repeated finishes or double-completion
      if (session.status == 'completed') {
        return session;
      }

      final completedTime = DateTime.now();
      await (_db.update(_db.workoutSessions)
            ..where((s) => s.id.equals(sessionId)))
          .write(
        WorkoutSessionsCompanion(
          completedAt: Value(completedTime),
          status: const Value('completed'),
          notes: notes != null ? Value(notes.trim()) : const Value.absent(),
        ),
      );

      return await (_db.select(_db.workoutSessions)
            ..where((s) => s.id.equals(sessionId)))
          .getSingleOrNull();
    });
  }

  Future<void> discardSession(String sessionId) async {
    await _db.transaction(() async {
      // Discard deletes the session and all its children via cascades
      await (_db.delete(_db.workoutSessions)
            ..where((s) => s.id.equals(sessionId)))
          .go();
    });
  }

  Future<void> deleteSession(String sessionId) async {
    await (_db.delete(_db.workoutSessions)
          ..where((s) => s.id.equals(sessionId)))
        .go();
  }
}

final workoutSessionRepositoryProvider =
    Provider<WorkoutSessionRepository>((ref) {
  return WorkoutSessionRepository(ref.watch(appDatabaseProvider));
});

final userSessionsStreamProvider =
    StreamProvider<List<WorkoutSessionData>>((ref) {
  final userId = ref.watch(activeUserIdProvider);
  return ref
      .watch(workoutSessionRepositoryProvider)
      .watchSessionsForUser(userId);
});

final activeSessionStreamProvider =
    StreamProvider<WorkoutSessionData?>((ref) {
  final userId = ref.watch(activeUserIdProvider);
  return ref
      .watch(workoutSessionRepositoryProvider)
      .watchActiveSessionForUser(userId);
});

final sessionDetailsStreamProvider =
    StreamProvider.family<WorkoutSessionDetails?, String>((ref, sessionId) {
  return ref
      .watch(workoutSessionRepositoryProvider)
      .watchSessionDetails(sessionId);
});
