import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

class DuplicateExerciseException implements Exception {
  final String name;
  const DuplicateExerciseException(this.name);

  @override
  String toString() => 'An exercise named "$name" already exists.';
}

class ExerciseRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  ExerciseRepository(this._db);

  Stream<List<ExerciseData>> watchExercises({
    String? muscleGroup,
    String? query,
  }) {
    final statement = _db.select(_db.exercises)
      ..orderBy([(e) => OrderingTerm(expression: e.name)]);

    if (muscleGroup != null &&
        muscleGroup.isNotEmpty &&
        muscleGroup.toLowerCase() != 'all') {
      statement.where((e) => e.muscleGroup.equals(muscleGroup));
    }

    if (query != null && query.trim().isNotEmpty) {
      final sanitized = '%${query.trim()}%';
      statement.where((e) => e.name.like(sanitized));
    }

    return statement.watch();
  }

  Future<List<ExerciseData>> getExercises({
    String? muscleGroup,
    String? query,
  }) {
    final statement = _db.select(_db.exercises)
      ..orderBy([(e) => OrderingTerm(expression: e.name)]);

    if (muscleGroup != null &&
        muscleGroup.isNotEmpty &&
        muscleGroup.toLowerCase() != 'all') {
      statement.where((e) => e.muscleGroup.equals(muscleGroup));
    }

    if (query != null && query.trim().isNotEmpty) {
      final sanitized = '%${query.trim()}%';
      statement.where((e) => e.name.like(sanitized));
    }

    return statement.get();
  }

  Future<ExerciseData?> getExerciseById(String id) {
    return (_db.select(
      _db.exercises,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
  }

  Future<ExerciseData> addCustomExercise({
    required String name,
    required String muscleGroup,
    required String equipment,
    String exerciseType = 'weight_reps',
    String? userId,
  }) async {
    final trimmedName = name.trim();

    // Prevent duplicates by checking case-insensitively
    final existing =
        await (_db.select(_db.exercises)
              ..where((e) => e.name.lower().equals(trimmedName.toLowerCase())))
            .getSingleOrNull();

    if (existing != null) {
      throw DuplicateExerciseException(trimmedName);
    }

    final newExercise = ExerciseData(
      id: _uuid.v4(),
      name: trimmedName,
      muscleGroup: muscleGroup.trim(),
      equipment: equipment.trim(),
      exerciseType: exerciseType,
      isCustom: true,
      userId: userId,
    );

    await _db.into(_db.exercises).insert(newExercise);
    return newExercise;
  }

  Future<void> deleteCustomExercise(String id) async {
    final exercise = await getExerciseById(id);
    if (exercise == null) return;
    if (!exercise.isCustom) {
      throw UnsupportedError('Built-in seed exercises cannot be deleted.');
    }
    await (_db.delete(_db.exercises)..where((e) => e.id.equals(id))).go();
  }
}

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository(ref.watch(appDatabaseProvider));
});

class ExerciseFilterState {
  final String muscleGroup;
  final String query;

  const ExerciseFilterState({this.muscleGroup = 'All', this.query = ''});

  ExerciseFilterState copyWith({String? muscleGroup, String? query}) {
    return ExerciseFilterState(
      muscleGroup: muscleGroup ?? this.muscleGroup,
      query: query ?? this.query,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseFilterState &&
          other.muscleGroup == muscleGroup &&
          other.query == query;

  @override
  int get hashCode => Object.hash(muscleGroup, query);
}

class ExerciseFilterNotifier extends Notifier<ExerciseFilterState> {
  @override
  ExerciseFilterState build() => const ExerciseFilterState();

  void setMuscleGroup(String muscleGroup) {
    state = state.copyWith(muscleGroup: muscleGroup);
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }
}

final exerciseFilterProvider =
    NotifierProvider<ExerciseFilterNotifier, ExerciseFilterState>(
      ExerciseFilterNotifier.new,
    );

final filteredExercisesProvider = StreamProvider<List<ExerciseData>>((ref) {
  final filter = ref.watch(exerciseFilterProvider);
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.watchExercises(
    muscleGroup: filter.muscleGroup,
    query: filter.query,
  );
});
