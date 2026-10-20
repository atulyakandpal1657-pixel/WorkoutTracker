import 'package:flutter_test/flutter_test.dart';
import 'package:replog/core/database/app_database.dart';
import 'package:replog/features/exercises/data/exercise_repository.dart';
import 'package:replog/features/profile/data/user_repository.dart';
import 'package:replog/features/templates/data/template_repository.dart';
import 'package:replog/features/workout/data/workout_session_repository.dart';

void main() {
  late AppDatabase db;
  late UserRepository userRepo;
  late ExerciseRepository exerciseRepo;
  late TemplateRepository templateRepo;
  late WorkoutSessionRepository sessionRepo;

  setUp(() {
    db = AppDatabase.inMemory();
    userRepo = UserRepository(db);
    exerciseRepo = ExerciseRepository(db);
    templateRepo = TemplateRepository(db);
    sessionRepo = WorkoutSessionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('UserRepository Tests', () {
    test('getAllUsers returns seeded users', () async {
      final users = await userRepo.getAllUsers();
      expect(users.length, 2);
      expect(users[0].displayName, contains('Friend 1'));
      expect(users[1].displayName, contains('Friend 2'));
    });

    test('createUser adds a new profile and retrieves it by id', () async {
      final newUser = await userRepo.createUser('Jordan');
      expect(newUser.displayName, 'Jordan');

      final fetched = await userRepo.getUserById(newUser.id);
      expect(fetched, isNotNull);
      expect(fetched!.displayName, 'Jordan');

      final all = await userRepo.getAllUsers();
      expect(all.length, 3);
    });

    test('updateUser modifies profile display name', () async {
      await userRepo.updateUser('user-friend-1', displayName: 'Alex The Great');
      final updated = await userRepo.getUserById('user-friend-1');
      expect(updated!.displayName, 'Alex The Great');
    });

    test('deleteUser deletes user from database', () async {
      final user = await userRepo.createUser('Temp User');
      expect(await userRepo.getUserById(user.id), isNotNull);

      await userRepo.deleteUser(user.id);
      expect(await userRepo.getUserById(user.id), isNull);
    });
  });

  group('ExerciseRepository Tests', () {
    test('getExercises filters by muscle group', () async {
      final chestExercises = await exerciseRepo.getExercises(
        muscleGroup: 'Chest',
      );
      expect(chestExercises.isNotEmpty, isTrue);
      for (final e in chestExercises) {
        expect(e.muscleGroup, 'Chest');
      }

      final legsExercises = await exerciseRepo.getExercises(
        muscleGroup: 'Legs',
      );
      expect(legsExercises.isNotEmpty, isTrue);
      for (final e in legsExercises) {
        expect(e.muscleGroup, 'Legs');
      }
    });

    test('getExercises filters by query string case-insensitively', () async {
      final benchResults = await exerciseRepo.getExercises(query: 'bench');
      expect(benchResults.any((e) => e.name.contains('Bench')), isTrue);
    });

    test(
      'addCustomExercise successfully creates custom exercise with isCustom = true',
      () async {
        final newEx = await exerciseRepo.addCustomExercise(
          name: 'Incline Dumbbell Hex Press',
          muscleGroup: 'Chest',
          equipment: 'Dumbbell',
        );

        expect(newEx.isCustom, isTrue);
        expect(newEx.name, 'Incline Dumbbell Hex Press');

        final fetched = await exerciseRepo.getExerciseById(newEx.id);
        expect(fetched, isNotNull);
        expect(fetched!.name, 'Incline Dumbbell Hex Press');
      },
    );

    test(
      'addCustomExercise throws DuplicateExerciseException on duplicate name (exact and case-insensitive)',
      () async {
        // Seed exercise exists: "Barbell Bench Press"
        expect(
          () => exerciseRepo.addCustomExercise(
            name: 'Barbell Bench Press',
            muscleGroup: 'Chest',
            equipment: 'Barbell',
          ),
          throwsA(isA<DuplicateExerciseException>()),
        );

        // Case-insensitive test: "barbell bench press"
        expect(
          () => exerciseRepo.addCustomExercise(
            name: 'barbell bench press',
            muscleGroup: 'Chest',
            equipment: 'Barbell',
          ),
          throwsA(isA<DuplicateExerciseException>()),
        );
      },
    );

    test(
      'deleteCustomExercise removes custom exercise, but throws UnsupportedError for built-in exercises',
      () async {
        // 1. Cannot delete built-in exercise
        final seedExercises = await exerciseRepo.getExercises();
        final builtIn = seedExercises.firstWhere((e) => !e.isCustom);

        expect(
          () => exerciseRepo.deleteCustomExercise(builtIn.id),
          throwsA(isA<UnsupportedError>()),
        );

        // 2. Can delete custom exercise
        final custom = await exerciseRepo.addCustomExercise(
          name: 'Zercher Squat',
          muscleGroup: 'Legs',
          equipment: 'Barbell',
        );
        expect(await exerciseRepo.getExerciseById(custom.id), isNotNull);

        await exerciseRepo.deleteCustomExercise(custom.id);
        expect(await exerciseRepo.getExerciseById(custom.id), isNull);
      },
    );
  });

  group('TemplateRepository Tests', () {
    test('getTemplatesForUser isolates routines by user ID', () async {
      final f1Templates = await templateRepo.getTemplatesForUser(
        'user-friend-1',
      );
      final f2Templates = await templateRepo.getTemplatesForUser(
        'user-friend-2',
      );

      expect(f1Templates.length, 3);
      expect(f2Templates.length, 3);

      for (final t in f1Templates) {
        expect(t.userId, 'user-friend-1');
      }
      for (final t in f2Templates) {
        expect(t.userId, 'user-friend-2');
      }
    });

    test(
      'getTemplateWithExercises loads template with mapped exercise entities',
      () async {
        final f1Templates = await templateRepo.getTemplatesForUser(
          'user-friend-1',
        );
        final pushTpl = f1Templates.firstWhere(
          (t) => t.name.startsWith('Push'),
        );

        final details = await templateRepo.getTemplateWithExercises(pushTpl.id);
        expect(details, isNotNull);
        expect(details!.template.name, pushTpl.name);
        expect(details.exercises.isNotEmpty, isTrue);

        final exNames = details.exercises.map((e) => e.exercise.name).toList();
        expect(exNames, contains('Barbell Bench Press'));
        expect(exNames, contains('Incline Dumbbell Press'));
      },
    );

    test('createTemplate persists routine with ordered exercises', () async {
      final allExercises = await exerciseRepo.getExercises();
      final ex1 = allExercises[0];
      final ex2 = allExercises[1];

      final newTplId = await templateRepo.createTemplate(
        userId: 'user-friend-1',
        name: 'Arms Blitz',
        description: 'Biceps and triceps supersets',
        exercises: [
          CreateTemplateExerciseInput(
            exerciseId: ex1.id,
            position: 0,
            targetSets: 4,
            targetRepsMin: 10,
            targetRepsMax: 12,
          ),
          CreateTemplateExerciseInput(
            exerciseId: ex2.id,
            position: 1,
            targetSets: 3,
            targetRepsMin: 12,
            targetRepsMax: 15,
          ),
        ],
      );

      final loaded = await templateRepo.getTemplateWithExercises(newTplId);
      expect(loaded, isNotNull);
      expect(loaded!.template.name, 'Arms Blitz');
      expect(loaded.exercises.length, 2);
      expect(loaded.exercises[0].exercise.id, ex1.id);
      expect(loaded.exercises[0].item.targetSets, 4);
      expect(loaded.exercises[1].exercise.id, ex2.id);
      expect(loaded.exercises[1].item.targetSets, 3);
    });

    test(
      'duplicateTemplate creates deep copy of routine and exercises',
      () async {
        final f1Templates = await templateRepo.getTemplatesForUser(
          'user-friend-1',
        );
        final original = f1Templates.first;

        final copyId = await templateRepo.duplicateTemplate(
          original.id,
          'Push Day Copy',
        );
        final copyDetails = await templateRepo.getTemplateWithExercises(copyId);

        expect(copyDetails, isNotNull);
        expect(copyDetails!.template.name, 'Push Day Copy');
        expect(copyDetails.template.id, isNot(original.id));

        final originalDetails = await templateRepo.getTemplateWithExercises(
          original.id,
        );
        expect(copyDetails.exercises.length, originalDetails!.exercises.length);
      },
    );

    test(
      'deleteTemplate removes routine and cascades to template exercises',
      () async {
        final allExercises = await exerciseRepo.getExercises();
        final tplId = await templateRepo.createTemplate(
          userId: 'user-friend-1',
          name: 'To Be Deleted',
          exercises: [
            CreateTemplateExerciseInput(
              exerciseId: allExercises[0].id,
              position: 0,
            ),
          ],
        );

        expect(await templateRepo.getTemplateWithExercises(tplId), isNotNull);
        await templateRepo.deleteTemplate(tplId);
        expect(await templateRepo.getTemplateWithExercises(tplId), isNull);
      },
    );
  });

  group('WorkoutSessionRepository Tests', () {
    test(
      'Logs full workout session lifecycle with exercises and sets',
      () async {
        const userId = 'user-friend-1';
        final exercises = await exerciseRepo.getExercises();
        final benchEx = exercises.firstWhere(
          (e) => e.name == 'Barbell Bench Press',
        );

        // 1. Start session
        final sessionId = await sessionRepo.startSession(
          userId: userId,
          name: 'Chest & Delts Blast',
        );
        expect(sessionId, isNotEmpty);

        // 2. Add exercise to session
        final seId = await sessionRepo.addExerciseToSession(
          sessionId: sessionId,
          exerciseId: benchEx.id,
          position: 0,
          notes: 'Felt strong, good arch',
        );
        expect(seId, isNotEmpty);

        // 3. Log sets
        final set1Id = await sessionRepo.logSet(
          sessionExerciseId: seId,
          setNumber: 1,
          weightKg: 80.0,
          reps: 10,
          completed: true,
        );
        final set2Id = await sessionRepo.logSet(
          sessionExerciseId: seId,
          setNumber: 2,
          weightKg: 85.0,
          reps: 8,
          completed: true,
        );
        final set3Id = await sessionRepo.logSet(
          sessionExerciseId: seId,
          setNumber: 3,
          weightKg: 90.0,
          reps: 5,
          completed: true,
        );

        expect(set1Id, isNotEmpty);
        expect(set2Id, isNotEmpty);
        expect(set3Id, isNotEmpty);

        // 4. Complete session
        await sessionRepo.completeSession(sessionId, notes: 'Great pump');

        // 5. Query session details
        final details = await sessionRepo.getSessionDetails(sessionId);
        expect(details, isNotNull);
        expect(details!.session.status, 'completed');
        expect(details.session.notes, 'Great pump');
        expect(details.exercises.length, 1);
        expect(details.exercises[0].exercise.name, 'Barbell Bench Press');
        expect(details.exercises[0].sets.length, 3);
        expect(details.exercises[0].sets[0].weightKg, 80.0);
        expect(details.exercises[0].sets[1].weightKg, 85.0);
        expect(details.exercises[0].sets[2].weightKg, 90.0);

        // 6. Verify user isolation
        final f1Sessions = await sessionRepo.getSessionsForUser(
          'user-friend-1',
        );
        expect(f1Sessions.any((s) => s.id == sessionId), isTrue);

        final f2Sessions = await sessionRepo.getSessionsForUser(
          'user-friend-2',
        );
        expect(f2Sessions.any((s) => s.id == sessionId), isFalse);
      },
    );
  });
}
