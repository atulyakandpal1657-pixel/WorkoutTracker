import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

class TemplateExerciseItem {
  final TemplateExerciseData item;
  final ExerciseData exercise;

  const TemplateExerciseItem({required this.item, required this.exercise});
}

class TemplateWithExercises {
  final WorkoutTemplateData template;
  final List<TemplateExerciseItem> exercises;

  const TemplateWithExercises({
    required this.template,
    required this.exercises,
  });
}

class CreateTemplateExerciseInput {
  final String exerciseId;
  final int position;
  final int targetSets;
  final int? targetRepsMin;
  final int? targetRepsMax;
  final double? targetWeightKg;

  const CreateTemplateExerciseInput({
    required this.exerciseId,
    required this.position,
    this.targetSets = 3,
    this.targetRepsMin,
    this.targetRepsMax,
    this.targetWeightKg,
  });
}

class TemplateRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  TemplateRepository(this._db);

  Stream<List<WorkoutTemplateData>> watchTemplatesForUser(String userId) {
    return (_db.select(_db.workoutTemplates)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  Future<List<WorkoutTemplateData>> getTemplatesForUser(String userId) {
    return (_db.select(_db.workoutTemplates)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  Future<TemplateWithExercises?> getTemplateWithExercises(
    String templateId,
  ) async {
    final template = await (_db.select(
      _db.workoutTemplates,
    )..where((t) => t.id.equals(templateId))).getSingleOrNull();

    if (template == null) return null;

    final query =
        _db.select(_db.templateExercises).join([
            innerJoin(
              _db.exercises,
              _db.exercises.id.equalsExp(_db.templateExercises.exerciseId),
            ),
          ])
          ..where(_db.templateExercises.templateId.equals(templateId))
          ..orderBy([OrderingTerm(expression: _db.templateExercises.position)]);

    final rows = await query.get();
    final items = rows.map((row) {
      final tplEx = row.readTable(_db.templateExercises);
      final exercise = row.readTable(_db.exercises);
      return TemplateExerciseItem(item: tplEx, exercise: exercise);
    }).toList();

    return TemplateWithExercises(template: template, exercises: items);
  }

  Stream<TemplateWithExercises?> watchTemplateWithExercises(String templateId) {
    final templateStream = (_db.select(
      _db.workoutTemplates,
    )..where((t) => t.id.equals(templateId))).watchSingleOrNull();

    final itemsStream =
        (_db.select(_db.templateExercises).join([
                innerJoin(
                  _db.exercises,
                  _db.exercises.id.equalsExp(_db.templateExercises.exerciseId),
                ),
              ])
              ..where(_db.templateExercises.templateId.equals(templateId))
              ..orderBy([
                OrderingTerm(expression: _db.templateExercises.position),
              ]))
            .watch();

    return templateStream.asyncExpand((template) {
      if (template == null) {
        return Stream.value(null);
      }
      return itemsStream.map((rows) {
        final items = rows.map((row) {
          final tplEx = row.readTable(_db.templateExercises);
          final exercise = row.readTable(_db.exercises);
          return TemplateExerciseItem(item: tplEx, exercise: exercise);
        }).toList();
        return TemplateWithExercises(template: template, exercises: items);
      });
    });
  }

  Future<String> createTemplate({
    required String userId,
    required String name,
    String? description,
    required List<CreateTemplateExerciseInput> exercises,
  }) async {
    final now = DateTime.now();
    final templateId = _uuid.v4();

    await _db.transaction(() async {
      await _db
          .into(_db.workoutTemplates)
          .insert(
            WorkoutTemplatesCompanion.insert(
              id: templateId,
              userId: userId,
              name: name.trim(),
              description: Value(description?.trim()),
              createdAt: now,
              updatedAt: now,
            ),
          );

      for (int i = 0; i < exercises.length; i++) {
        final item = exercises[i];
        await _db
            .into(_db.templateExercises)
            .insert(
              TemplateExercisesCompanion.insert(
                id: _uuid.v4(),
                templateId: templateId,
                exerciseId: item.exerciseId,
                position: item.position >= 0 ? item.position : i,
                targetSets: Value(item.targetSets),
                targetRepsMin: Value(item.targetRepsMin),
                targetRepsMax: Value(item.targetRepsMax),
                targetWeightKg: Value(item.targetWeightKg),
              ),
            );
      }
    });

    return templateId;
  }

  Future<void> updateTemplate({
    required String templateId,
    required String name,
    String? description,
    required List<CreateTemplateExerciseInput> exercises,
  }) async {
    final now = DateTime.now();

    await _db.transaction(() async {
      await (_db.update(
        _db.workoutTemplates,
      )..where((t) => t.id.equals(templateId))).write(
        WorkoutTemplatesCompanion(
          name: Value(name.trim()),
          description: Value(description?.trim()),
          updatedAt: Value(now),
        ),
      );

      // Replace template exercises
      await (_db.delete(
        _db.templateExercises,
      )..where((te) => te.templateId.equals(templateId))).go();

      for (int i = 0; i < exercises.length; i++) {
        final item = exercises[i];
        await _db
            .into(_db.templateExercises)
            .insert(
              TemplateExercisesCompanion.insert(
                id: _uuid.v4(),
                templateId: templateId,
                exerciseId: item.exerciseId,
                position: item.position >= 0 ? item.position : i,
                targetSets: Value(item.targetSets),
                targetRepsMin: Value(item.targetRepsMin),
                targetRepsMax: Value(item.targetRepsMax),
                targetWeightKg: Value(item.targetWeightKg),
              ),
            );
      }
    });
  }

  Future<void> deleteTemplate(String templateId) async {
    await (_db.delete(
      _db.workoutTemplates,
    )..where((t) => t.id.equals(templateId))).go();
  }

  Future<String> duplicateTemplate(String templateId, String newName) async {
    final existing = await getTemplateWithExercises(templateId);
    if (existing == null) {
      throw StateError('Template with ID $templateId not found');
    }

    final inputs = existing.exercises
        .map(
          (e) => CreateTemplateExerciseInput(
            exerciseId: e.exercise.id,
            position: e.item.position,
            targetSets: e.item.targetSets,
            targetRepsMin: e.item.targetRepsMin,
            targetRepsMax: e.item.targetRepsMax,
            targetWeightKg: e.item.targetWeightKg,
          ),
        )
        .toList();

    return createTemplate(
      userId: existing.template.userId,
      name: newName,
      description: existing.template.description != null
          ? 'Copy of ${existing.template.description}'
          : null,
      exercises: inputs,
    );
  }
}

final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  return TemplateRepository(ref.watch(appDatabaseProvider));
});

final userTemplatesStreamProvider = StreamProvider<List<WorkoutTemplateData>>((
  ref,
) {
  final userId = ref.watch(activeUserIdProvider);
  return ref.watch(templateRepositoryProvider).watchTemplatesForUser(userId);
});
