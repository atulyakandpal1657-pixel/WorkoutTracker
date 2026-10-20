import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:replog/core/database/app_database.dart';
import 'package:replog/features/exercises/data/exercise_repository.dart';
import 'package:replog/features/templates/data/template_repository.dart';
import 'package:replog/features/workout/data/workout_session_repository.dart';

void main() {
  late AppDatabase db;
  late ExerciseRepository exerciseRepo;
  late TemplateRepository templateRepo;
  late WorkoutSessionRepository sessionRepo;

  setUp(() {
    db = AppDatabase.inMemory();
    exerciseRepo = ExerciseRepository(db);
    templateRepo = TemplateRepository(db);
    sessionRepo = WorkoutSessionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Session Lifecycle - Starting & Resuming', () {
    test('startOrResumeSession creates a new active session for empty workout', () async {
      final sessionId = await sessionRepo.startOrResumeSession(
        userId: 'user-friend-1',
        name: 'Afternoon Freestyle',
      );

      final active = await sessionRepo.getActiveSessionForUser('user-friend-1');
      expect(active, isNotNull);
      expect(active!.id, sessionId);
      expect(active.name, 'Afternoon Freestyle');
      expect(active.status, 'active');
    });

    test('Repeated start calls resume existing unfinished session to prevent duplicates', () async {
      final sessionId1 = await sessionRepo.startOrResumeSession(
        userId: 'user-friend-1',
        name: 'First Tap',
      );

      // User accidentally double-taps or taps start again
      final sessionId2 = await sessionRepo.startOrResumeSession(
        userId: 'user-friend-1',
        name: 'Second Tap',
      );

      expect(sessionId2, equals(sessionId1));

      final sessions = await sessionRepo.getSessionsForUser('user-friend-1');
      final activeSessions = sessions.where((s) => s.status == 'active').toList();
      expect(activeSessions.length, 1);
    });

    test('startOrResumeSession from template populates exercises and target sets without altering template', () async {
      final templates = await templateRepo.getTemplatesForUser('user-friend-1');
      final pushTpl = templates.firstWhere((t) => t.name.startsWith('Push'));

      final sessionId = await sessionRepo.startOrResumeSession(
        userId: 'user-friend-1',
        name: pushTpl.name,
        templateId: pushTpl.id,
      );

      final details = await sessionRepo.getSessionDetails(sessionId);
      expect(details, isNotNull);
      expect(details!.exercises.length, 5);

      for (final ex in details.exercises) {
        expect(ex.sets.isNotEmpty, isTrue);
        for (final s in ex.sets) {
          expect(s.completed, isFalse);
          expect(s.setType, 'normal');
        }
      }

      // Verify original template is untouched
      final templateCheck = await templateRepo.getTemplateWithExercises(pushTpl.id);
      expect(templateCheck, isNotNull);
      expect(templateCheck!.exercises.length, 5);
    });
  });

  group('Session Lifecycle - Set Logging, Validation & Editing', () {
    test('Logs sets with various weights, reps, and set types', () async {
      final exercises = await exerciseRepo.getExercises();
      final bench = exercises.firstWhere((e) => e.name == 'Barbell Bench Press');

      final sessionId = await sessionRepo.startOrResumeSession(
        userId: 'user-friend-1',
        name: 'Heavy Bench Day',
      );

      final seId = await sessionRepo.addExerciseToSession(
        sessionId: sessionId,
        exerciseId: bench.id,
      );

      // Default set 1 exists from adding exercise
      final details1 = await sessionRepo.getSessionDetails(sessionId);
      final initialSet = details1!.exercises.first.sets.first;

      // Update set 1 to warm-up
      await sessionRepo.updateSet(
        setId: initialSet.id,
        weightKg: 40.0,
        reps: 12,
        setType: 'warmup',
        completed: true,
      );

      // Add set 2 (normal working set)
      final set2Id = await sessionRepo.addSet(
        sessionExerciseId: seId,
        weightKg: 80.0,
        reps: 8,
        setType: 'normal',
      );
      await sessionRepo.updateSet(setId: set2Id, completed: true);

      // Add set 3 (failure set)
      final set3Id = await sessionRepo.addSet(
        sessionExerciseId: seId,
        weightKg: 85.0,
        reps: 5,
        setType: 'failure',
      );
      await sessionRepo.updateSet(setId: set3Id, completed: true);

      // Add set 4 (zero weight / bodyweight)
      final set4Id = await sessionRepo.addSet(
        sessionExerciseId: seId,
        weightKg: 0.0,
        reps: 15,
        setType: 'normal',
      );
      await sessionRepo.updateSet(setId: set4Id, completed: true);

      final updatedDetails = await sessionRepo.getSessionDetails(sessionId);
      final sets = updatedDetails!.exercises.first.sets;
      expect(sets.length, 4);

      expect(sets[0].setType, 'warmup');
      expect(sets[0].weightKg, 40.0);
      expect(sets[0].reps, 12);

      expect(sets[1].setType, 'normal');
      expect(sets[1].weightKg, 80.0);

      expect(sets[2].setType, 'failure');
      expect(sets[2].weightKg, 85.0);

      expect(sets[3].weightKg, 0.0);
      expect(sets[3].reps, 15);
    });

    test('updateSet validates non-negative weight and repetitions', () async {
      final exercises = await exerciseRepo.getExercises();
      final sessionId = await sessionRepo.startOrResumeSession(
        userId: 'user-friend-1',
        name: 'Validation Test',
      );
      final seId = await sessionRepo.addExerciseToSession(
        sessionId: sessionId,
        exerciseId: exercises.first.id,
      );
      final details = await sessionRepo.getSessionDetails(sessionId);
      final setId = details!.exercises.first.sets.first.id;

      // Negative weight should throw ArgumentError
      expect(
        () => sessionRepo.updateSet(setId: setId, weightKg: -5.0),
        throwsA(isA<ArgumentError>()),
      );

      // Negative reps should throw ArgumentError
      expect(
        () => sessionRepo.updateSet(setId: setId, reps: -2),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('deleteSet deletes set and automatically renumbers remaining sets', () async {
      final exercises = await exerciseRepo.getExercises();
      final sessionId = await sessionRepo.startOrResumeSession(
        userId: 'user-friend-1',
        name: 'Delete Set Test',
      );
      final seId = await sessionRepo.addExerciseToSession(
        sessionId: sessionId,
        exerciseId: exercises.first.id,
      );

      final set2Id = await sessionRepo.addSet(sessionExerciseId: seId, weightKg: 50, reps: 10);
      await sessionRepo.addSet(sessionExerciseId: seId, weightKg: 60, reps: 8);

      final before = await sessionRepo.getSessionDetails(sessionId);
      expect(before!.exercises.first.sets.length, 3);
      expect(before.exercises.first.sets.map((s) => s.setNumber).toList(), [1, 2, 3]);

      // Delete set 2
      await sessionRepo.deleteSet(set2Id);

      final after = await sessionRepo.getSessionDetails(sessionId);
      final remainingSets = after!.exercises.first.sets;
      expect(remainingSets.length, 2);
      expect(remainingSets[0].setNumber, 1);
      expect(remainingSets[1].setNumber, 2);
      expect(remainingSets[1].weightKg, 60);
    });
  });

  group('Session Lifecycle - Exercise Reordering & Removal', () {
    test('removeExerciseFromSession deletes exercise and sets, then reindexes positions', () async {
      final exercises = await exerciseRepo.getExercises();
      final sessionId = await sessionRepo.startOrResumeSession(
        userId: 'user-friend-1',
        name: 'Multi Exercise Session',
      );

      final se1 = await sessionRepo.addExerciseToSession(
        sessionId: sessionId,
        exerciseId: exercises[0].id,
      );
      final se2 = await sessionRepo.addExerciseToSession(
        sessionId: sessionId,
        exerciseId: exercises[1].id,
      );
      final se3 = await sessionRepo.addExerciseToSession(
        sessionId: sessionId,
        exerciseId: exercises[2].id,
      );

      // Remove middle exercise (se2)
      await sessionRepo.removeExerciseFromSession(se2);

      final details = await sessionRepo.getSessionDetails(sessionId);
      expect(details!.exercises.length, 2);
      expect(details.exercises[0].sessionExercise.id, se1);
      expect(details.exercises[0].sessionExercise.position, 0);
      expect(details.exercises[1].sessionExercise.id, se3);
      expect(details.exercises[1].sessionExercise.position, 1);
    });

    test('reorderSessionExercises updates ordering properly', () async {
      final exercises = await exerciseRepo.getExercises();
      final sessionId = await sessionRepo.startOrResumeSession(
        userId: 'user-friend-1',
        name: 'Reorder Test',
      );

      final se1 = await sessionRepo.addExerciseToSession(
        sessionId: sessionId,
        exerciseId: exercises[0].id,
      );
      final se2 = await sessionRepo.addExerciseToSession(
        sessionId: sessionId,
        exerciseId: exercises[1].id,
      );

      // Reorder se2 before se1
      await sessionRepo.reorderSessionExercises(
        sessionId: sessionId,
        orderedSessionExerciseIds: [se2, se1],
      );

      final details = await sessionRepo.getSessionDetails(sessionId);
      expect(details!.exercises[0].sessionExercise.id, se2);
      expect(details.exercises[0].sessionExercise.position, 0);
      expect(details.exercises[1].sessionExercise.id, se1);
      expect(details.exercises[1].sessionExercise.position, 1);
    });
  });

  group('Session Lifecycle - Previous Performance & Summary Calculations', () {
    test('getPreviousPerformanceForExercise displays best set from last completed workout', () async {
      final exercises = await exerciseRepo.getExercises();
      final squat = exercises.firstWhere((e) => e.name == 'Barbell Back Squat');

      // 1. First completed workout
      final sess1Id = await sessionRepo.startOrResumeSession(
        userId: 'user-friend-1',
        name: 'Leg Day 1',
      );
      final se1 = await sessionRepo.addExerciseToSession(
        sessionId: sess1Id,
        exerciseId: squat.id,
      );
      final set1 = (await sessionRepo.getSessionDetails(sess1Id))!.exercises.first.sets.first;
      await sessionRepo.updateSet(setId: set1.id, weightKg: 100.0, reps: 5, completed: true);

      final set2 = await sessionRepo.addSet(sessionExerciseId: se1, weightKg: 110.0, reps: 5);
      await sessionRepo.updateSet(setId: set2, completed: true);

      await sessionRepo.completeSession(sess1Id);

      // 2. Start new workout
      final sess2Id = await sessionRepo.startOrResumeSession(
        userId: 'user-friend-1',
        name: 'Leg Day 2',
      );

      final prevPerf = await sessionRepo.getPreviousPerformanceForExercise(
        'user-friend-1',
        squat.id,
        excludeSessionId: sess2Id,
      );

      expect(prevPerf, '110 kg × 5');
    });

    test('Workout summary calculates duration, completed sets, and volume only from completed sets', () async {
      final exercises = await exerciseRepo.getExercises();
      final sessionId = await sessionRepo.startOrResumeSession(
        userId: 'user-friend-1',
        name: 'Volume Calculation Test',
      );

      final se1 = await sessionRepo.addExerciseToSession(
        sessionId: sessionId,
        exerciseId: exercises[0].id,
      );

      final set1 = (await sessionRepo.getSessionDetails(sessionId))!.exercises.first.sets.first;
      // Set 1: 50kg x 10 = 500 volume (completed)
      await sessionRepo.updateSet(setId: set1.id, weightKg: 50.0, reps: 10, completed: true);

      // Set 2: 60kg x 10 = 600 volume (completed)
      final set2Id = await sessionRepo.addSet(sessionExerciseId: se1, weightKg: 60.0, reps: 10);
      await sessionRepo.updateSet(setId: set2Id, completed: true);

      // Set 3: 70kg x 10 = 700 volume (UNCOMPLETED - must NOT count towards volume)
      await sessionRepo.addSet(sessionExerciseId: se1, weightKg: 70.0, reps: 10);

      await sessionRepo.completeSession(sessionId);

      final details = await sessionRepo.getSessionDetails(sessionId);
      expect(details, isNotNull);
      expect(details!.totalSets, 3);
      expect(details.completedSets, 2);
      expect(details.totalVolumeKg, 1100.0); // 500 + 600, excluding uncompleted 700
      expect(details.duration, isNotNull);
    });

    test('Repeated finish calls cannot corrupt the session or recreate records', () async {
      final sessionId = await sessionRepo.startOrResumeSession(
        userId: 'user-friend-1',
        name: 'Idempotency Test',
      );

      final finished1 = await sessionRepo.completeSession(sessionId, notes: 'Done');
      expect(finished1!.status, 'completed');
      final completedAt1 = finished1.completedAt;

      // Second finish call
      final finished2 = await sessionRepo.completeSession(sessionId, notes: 'Different note');
      expect(finished2!.status, 'completed');
      expect(finished2.completedAt, equals(completedAt1));
    });

    test('discardSession cleans up incomplete session and its children', () async {
      final sessionId = await sessionRepo.startOrResumeSession(
        userId: 'user-friend-1',
        name: 'To Discard',
      );
      final exercises = await exerciseRepo.getExercises();
      await sessionRepo.addExerciseToSession(
        sessionId: sessionId,
        exerciseId: exercises.first.id,
      );

      expect(await sessionRepo.getSessionDetails(sessionId), isNotNull);

      await sessionRepo.discardSession(sessionId);

      expect(await sessionRepo.getSessionDetails(sessionId), isNull);
      expect(await sessionRepo.getActiveSessionForUser('user-friend-1'), isNull);
    });

    test('Profile isolation: sessions and active states are strictly segregated by user ID', () async {
      // User 1 starts session
      final u1SessionId = await sessionRepo.startOrResumeSession(
        userId: 'user-friend-1',
        name: 'Alex Session',
      );

      // User 2 has no active session
      final u2Active = await sessionRepo.getActiveSessionForUser('user-friend-2');
      expect(u2Active, isNull);

      // User 2 starts session
      final u2SessionId = await sessionRepo.startOrResumeSession(
        userId: 'user-friend-2',
        name: 'Sam Session',
      );

      expect(u2SessionId, isNot(equals(u1SessionId)));

      final u1Active = await sessionRepo.getActiveSessionForUser('user-friend-1');
      expect(u1Active!.id, u1SessionId);
      final u2ActiveNow = await sessionRepo.getActiveSessionForUser('user-friend-2');
      expect(u2ActiveNow!.id, u2SessionId);
    });
  });

  group('Session Lifecycle - Persistence Across Reopening', () {
    test('Session in-progress and completed survive closing and reopening database', () async {
      final tempDir = await Directory.systemTemp.createTemp('replog_sess_persist_');
      final dbPath = p.join(tempDir.path, 'session_persist.sqlite');
      final dbFile = File(dbPath);

      try {
        var db1 = AppDatabase(NativeDatabase.createInBackground(dbFile));
        var repo1 = WorkoutSessionRepository(db1);
        var exRepo1 = ExerciseRepository(db1);

        final exercises = await exRepo1.getExercises();
        final sessionId = await repo1.startOrResumeSession(
          userId: 'user-friend-1',
          name: 'Interrupted Workout',
        );

        final seId = await repo1.addExerciseToSession(
          sessionId: sessionId,
          exerciseId: exercises.first.id,
        );

        final set1 = (await repo1.getSessionDetails(sessionId))!.exercises.first.sets.first;
        await repo1.updateSet(setId: set1.id, weightKg: 75.0, reps: 10, completed: true);

        // Add incomplete set 2
        await repo1.addSet(sessionExerciseId: seId, weightKg: 80.0, reps: 8);

        // Simulate app closing / terminating
        await db1.close();

        // Simulate app restarting and reopening SQLite database
        var db2 = AppDatabase(NativeDatabase.createInBackground(dbFile));
        var repo2 = WorkoutSessionRepository(db2);

        // Verify active session was restored seamlessly
        final restoredActive = await repo2.getActiveSessionForUser('user-friend-1');
        expect(restoredActive, isNotNull);
        expect(restoredActive!.id, sessionId);
        expect(restoredActive.name, 'Interrupted Workout');
        expect(restoredActive.status, 'active');

        // Verify sets and progress were preserved intact
        final restoredDetails = await repo2.getSessionDetails(sessionId);
        expect(restoredDetails, isNotNull);
        expect(restoredDetails!.exercises.length, 1);
        expect(restoredDetails.exercises.first.sets.length, 2);
        expect(restoredDetails.exercises.first.sets[0].weightKg, 75.0);
        expect(restoredDetails.exercises.first.sets[0].completed, isTrue);
        expect(restoredDetails.exercises.first.sets[1].weightKg, 80.0);
        expect(restoredDetails.exercises.first.sets[1].completed, isFalse);

        await db2.close();
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
