import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:replog/core/database/app_database.dart';
import 'package:replog/core/database/seed_data.dart';

void main() {
  group('Drift AppDatabase & Seeding Tests', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.inMemory();
    });

    tearDown(() async {
      await db.close();
    });

    test('Initial seeding populates Friend 1 and Friend 2 profiles', () async {
      final users = await db.select(db.users).get();
      expect(users.length, 2);

      final friend1 = users.firstWhere((u) => u.id == 'user-friend-1');
      final friend2 = users.firstWhere((u) => u.id == 'user-friend-2');

      expect(friend1.displayName, contains('Friend 1'));
      expect(friend2.displayName, contains('Friend 2'));
    });

    test(
      'Initial seeding populates comprehensive exercise catalogue across all target muscle groups',
      () async {
        final exercises = await db.select(db.exercises).get();
        expect(exercises.length, SeedData.initialExercises.length);
        expect(exercises.length, greaterThanOrEqualTo(25));

        final muscleGroups = exercises.map((e) => e.muscleGroup).toSet();
        expect(
          muscleGroups,
          containsAll([
            'Chest',
            'Back',
            'Shoulders',
            'Biceps',
            'Triceps',
            'Legs',
            'Core',
          ]),
        );

        // Verify all seed exercises are marked isCustom = false
        for (final ex in exercises) {
          expect(ex.isCustom, isFalse);
        }
      },
    );

    test(
      'Initial seeding creates starter templates for both profiles',
      () async {
        final friend1Templates = await (db.select(
          db.workoutTemplates,
        )..where((t) => t.userId.equals('user-friend-1'))).get();
        final friend2Templates = await (db.select(
          db.workoutTemplates,
        )..where((t) => t.userId.equals('user-friend-2'))).get();

        expect(friend1Templates.length, 3);
        expect(friend2Templates.length, 3);

        final templateNames = friend1Templates.map((t) => t.name).toList();
        expect(templateNames, contains('Push (Chest, Delts & Triceps)'));
        expect(templateNames, contains('Pull (Back & Biceps)'));
        expect(templateNames, contains('Legs & Core'));

        // Verify template exercises are populated
        final firstTpl = friend1Templates.first;
        final tplExercises = await (db.select(
          db.templateExercises,
        )..where((te) => te.templateId.equals(firstTpl.id))).get();
        expect(tplExercises.length, 5);
      },
    );

    test(
      'Foreign key constraints are enforced (PRAGMA foreign_keys = ON)',
      () async {
        // Inserting template with non-existent user ID should fail
        expect(() async {
          await db
              .into(db.workoutTemplates)
              .insert(
                WorkoutTemplatesCompanion.insert(
                  id: 'invalid-tpl-1',
                  userId: 'non-existent-user',
                  name: 'Orphan Routine',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
        }, throwsA(isA<SqliteException>()));

        // Inserting template exercise with non-existent exercise ID should fail
        final validTemplate =
            (await db.select(db.workoutTemplates).get()).first;
        expect(() async {
          await db
              .into(db.templateExercises)
              .insert(
                TemplateExercisesCompanion.insert(
                  id: 'invalid-te-1',
                  templateId: validTemplate.id,
                  exerciseId: 'non-existent-exercise-id',
                  position: 0,
                ),
              );
        }, throwsA(isA<SqliteException>()));
      },
    );

    test('Deleting user cascades to their templates and sessions', () async {
      // Verify friend 1 has templates
      final tplsBefore = await (db.select(
        db.workoutTemplates,
      )..where((t) => t.userId.equals('user-friend-1'))).get();
      expect(tplsBefore.isNotEmpty, isTrue);

      // Delete friend 1
      await (db.delete(
        db.users,
      )..where((u) => u.id.equals('user-friend-1'))).go();

      // Check templates are gone
      final tplsAfter = await (db.select(
        db.workoutTemplates,
      )..where((t) => t.userId.equals('user-friend-1'))).get();
      expect(tplsAfter.isEmpty, isTrue);

      // Friend 2's templates remain intact
      final friend2Templates = await (db.select(
        db.workoutTemplates,
      )..where((t) => t.userId.equals('user-friend-2'))).get();
      expect(friend2Templates.length, 3);
    });

    test(
      'Exercise uniqueness constraint rejects duplicate names at database level',
      () async {
        // Inserting an exercise with a name identical to an existing seed exercise should violate unique index
        expect(() async {
          await db
              .into(db.exercises)
              .insert(
                ExercisesCompanion.insert(
                  id: 'dup-1',
                  name: 'Barbell Bench Press',
                  muscleGroup: 'Chest',
                  equipment: 'Barbell',
                ),
              );
        }, throwsA(isA<SqliteException>()));
      },
    );

    test(
      'Profile isolation: templates and sessions are strictly scoped by user ID',
      () async {
        const friend1Id = 'user-friend-1';
        const friend2Id = 'user-friend-2';

        // Insert session for Friend 1
        const session1Id = 'sess-f1-1';
        await db
            .into(db.workoutSessions)
            .insert(
              WorkoutSessionsCompanion.insert(
                id: session1Id,
                userId: friend1Id,
                name: 'Alex Morning Session',
                startedAt: DateTime.now(),
              ),
            );

        // Insert session for Friend 2
        const session2Id = 'sess-f2-1';
        await db
            .into(db.workoutSessions)
            .insert(
              WorkoutSessionsCompanion.insert(
                id: session2Id,
                userId: friend2Id,
                name: 'Sam Evening Session',
                startedAt: DateTime.now(),
              ),
            );

        // Query Friend 1 sessions
        final f1Sessions = await (db.select(
          db.workoutSessions,
        )..where((s) => s.userId.equals(friend1Id))).get();
        expect(f1Sessions.length, 1);
        expect(f1Sessions.first.name, 'Alex Morning Session');

        // Query Friend 2 sessions
        final f2Sessions = await (db.select(
          db.workoutSessions,
        )..where((s) => s.userId.equals(friend2Id))).get();
        expect(f2Sessions.length, 1);
        expect(f2Sessions.first.name, 'Sam Evening Session');
      },
    );
  });

  group('Drift File-Backed Persistence Tests', () {
    test('Data persists across database reopenings', () async {
      final tempDir = await Directory.systemTemp.createTemp('replog_test_db_');
      final dbPath = p.join(tempDir.path, 'persisted_replog.sqlite');
      final dbFile = File(dbPath);

      try {
        // 1. Open database instance 1
        var db1 = AppDatabase(NativeDatabase.createInBackground(dbFile));

        // Let onCreate and seedInitialData finish
        final initialUsers = await db1.select(db1.users).get();
        expect(initialUsers.length, 2);

        // Add custom exercise
        const customExId = 'custom-hip-thrust';
        await db1
            .into(db1.exercises)
            .insert(
              ExercisesCompanion.insert(
                id: customExId,
                name: 'Barbell Hip Thrust',
                muscleGroup: 'Legs',
                equipment: 'Barbell',
                isCustom: const Value(true),
                userId: const Value('user-friend-1'),
              ),
            );

        // Add custom template
        const customTplId = 'custom-glute-day';
        await db1
            .into(db1.workoutTemplates)
            .insert(
              WorkoutTemplatesCompanion.insert(
                id: customTplId,
                userId: 'user-friend-1',
                name: 'Glute Hypertrophy',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

        // Close db1
        await db1.close();

        // 2. Open database instance 2 on the exact same file
        var db2 = AppDatabase(NativeDatabase.createInBackground(dbFile));

        // Verify users still exist
        final reopenedUsers = await db2.select(db2.users).get();
        expect(reopenedUsers.length, 2);

        // Verify custom exercise survived closing and reopening
        final reopenedCustomEx = await (db2.select(
          db2.exercises,
        )..where((e) => e.id.equals(customExId))).getSingleOrNull();
        expect(reopenedCustomEx, isNotNull);
        expect(reopenedCustomEx!.name, 'Barbell Hip Thrust');
        expect(reopenedCustomEx.isCustom, isTrue);

        // Verify custom template survived
        final reopenedTpl = await (db2.select(
          db2.workoutTemplates,
        )..where((t) => t.id.equals(customTplId))).getSingleOrNull();
        expect(reopenedTpl, isNotNull);
        expect(reopenedTpl!.name, 'Glute Hypertrophy');

        await db2.close();
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
