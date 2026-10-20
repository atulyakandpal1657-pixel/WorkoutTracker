import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'seed_data.dart';
import 'tables/exercises_table.dart';
import 'tables/personal_records_table.dart';
import 'tables/session_exercises_table.dart';
import 'tables/template_exercises_table.dart';
import 'tables/users_table.dart';
import 'tables/workout_sessions_table.dart';
import 'tables/workout_sets_table.dart';
import 'tables/workout_templates_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    Exercises,
    WorkoutSessions,
    SessionExercises,
    WorkoutSets,
    WorkoutTemplates,
    TemplateExercises,
    PersonalRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  factory AppDatabase.inMemory({bool logStatements = false}) {
    return AppDatabase(NativeDatabase.memory(logStatements: logStatements));
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        // Enforce SQLite Foreign Key constraints
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onCreate: (m) async {
        await m.createAll();
        await seedInitialData();
      },
    );
  }

  Future<void> seedInitialData() async {
    const uuid = Uuid();
    final now = DateTime.now();

    // 1. Seed Friend 1 and Friend 2 default profiles
    const friend1Id = 'user-friend-1';
    const friend2Id = 'user-friend-2';

    await into(users).insert(
      UsersCompanion.insert(
        id: friend1Id,
        displayName: 'Friend 1 (Alex)',
        createdAt: now,
        settingsJson: const Value('{"unit": "kg", "rest_timer_sec": 90}'),
      ),
    );

    await into(users).insert(
      UsersCompanion.insert(
        id: friend2Id,
        displayName: 'Friend 2 (Sam)',
        createdAt: now,
        settingsJson: const Value('{"unit": "kg", "rest_timer_sec": 90}'),
      ),
    );

    // 2. Seed catalogue exercises
    final Map<String, String> exerciseIdByName = {};
    for (final se in SeedData.initialExercises) {
      final exId = uuid.v4();
      exerciseIdByName[se.name] = exId;
      await into(exercises).insert(
        ExercisesCompanion.insert(
          id: exId,
          name: se.name,
          muscleGroup: se.muscleGroup,
          equipment: se.equipment,
          exerciseType: Value(se.exerciseType),
          isCustom: const Value(false),
          userId: const Value(null),
        ),
      );
    }

    // 3. Seed starter routines for Friend 1 and Friend 2
    for (final uid in [friend1Id, friend2Id]) {
      // Routine 1: Push Day
      final pushId = uuid.v4();
      await into(workoutTemplates).insert(
        WorkoutTemplatesCompanion.insert(
          id: pushId,
          userId: uid,
          name: 'Push (Chest, Delts & Triceps)',
          description: const Value(
            'Compound barbell pressing followed by dumbbell and cable isolation work',
          ),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final pushExercises = [
        'Barbell Bench Press',
        'Incline Dumbbell Press',
        'Standing Overhead Press',
        'Dumbbell Lateral Raise',
        'Triceps Rope Pushdown',
      ];
      for (int i = 0; i < pushExercises.length; i++) {
        final exId = exerciseIdByName[pushExercises[i]];
        if (exId != null) {
          await into(templateExercises).insert(
            TemplateExercisesCompanion.insert(
              id: uuid.v4(),
              templateId: pushId,
              exerciseId: exId,
              position: i,
              targetSets: const Value(3),
              targetRepsMin: const Value(8),
              targetRepsMax: const Value(12),
            ),
          );
        }
      }

      // Routine 2: Pull Day
      final pullId = uuid.v4();
      await into(workoutTemplates).insert(
        WorkoutTemplatesCompanion.insert(
          id: pullId,
          userId: uid,
          name: 'Pull (Back & Biceps)',
          description: const Value(
            'Vertical pull, horizontal rows, and direct arm development',
          ),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final pullExercises = [
        'Deadlift (Conventional)',
        'Barbell Bent Over Row',
        'Lat Pulldown',
        'Face Pull',
        'Barbell Biceps Curl',
      ];
      for (int i = 0; i < pullExercises.length; i++) {
        final exId = exerciseIdByName[pullExercises[i]];
        if (exId != null) {
          await into(templateExercises).insert(
            TemplateExercisesCompanion.insert(
              id: uuid.v4(),
              templateId: pullId,
              exerciseId: exId,
              position: i,
              targetSets: const Value(3),
              targetRepsMin: const Value(8),
              targetRepsMax: const Value(12),
            ),
          );
        }
      }

      // Routine 3: Legs & Core
      final legId = uuid.v4();
      await into(workoutTemplates).insert(
        WorkoutTemplatesCompanion.insert(
          id: legId,
          userId: uid,
          name: 'Legs & Core',
          description: const Value(
            'Squats, posterior chain, and abdominal stability',
          ),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final legExercises = [
        'Barbell Back Squat',
        'Romanian Deadlift (RDL)',
        'Leg Press',
        'Standing Calf Raise',
        'Hanging Leg Raise',
      ];
      for (int i = 0; i < legExercises.length; i++) {
        final exId = exerciseIdByName[legExercises[i]];
        if (exId != null) {
          await into(templateExercises).insert(
            TemplateExercisesCompanion.insert(
              id: uuid.v4(),
              templateId: legId,
              exerciseId: exId,
              position: i,
              targetSets: const Value(3),
              targetRepsMin: const Value(8),
              targetRepsMax: const Value(12),
            ),
          );
        }
      }
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'replog.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
