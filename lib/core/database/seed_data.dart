class SeedExercise {
  final String name;
  final String muscleGroup;
  final String equipment;
  final String exerciseType;

  const SeedExercise({
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    this.exerciseType = 'weight_reps',
  });
}

class SeedData {
  SeedData._();

  static const List<SeedExercise> initialExercises = [
    // Chest
    SeedExercise(
      name: 'Barbell Bench Press',
      muscleGroup: 'Chest',
      equipment: 'Barbell',
    ),
    SeedExercise(
      name: 'Incline Dumbbell Press',
      muscleGroup: 'Chest',
      equipment: 'Dumbbell',
    ),
    SeedExercise(
      name: 'Dumbbell Bench Press',
      muscleGroup: 'Chest',
      equipment: 'Dumbbell',
    ),
    SeedExercise(
      name: 'Incline Barbell Bench Press',
      muscleGroup: 'Chest',
      equipment: 'Barbell',
    ),
    SeedExercise(
      name: 'Cable Chest Fly',
      muscleGroup: 'Chest',
      equipment: 'Cable',
    ),
    SeedExercise(
      name: 'Push Up',
      muscleGroup: 'Chest',
      equipment: 'Bodyweight',
      exerciseType: 'reps_only',
    ),
    SeedExercise(
      name: 'Chest Dip',
      muscleGroup: 'Chest',
      equipment: 'Bodyweight',
    ),

    // Back
    SeedExercise(
      name: 'Deadlift (Conventional)',
      muscleGroup: 'Back',
      equipment: 'Barbell',
    ),
    SeedExercise(
      name: 'Barbell Bent Over Row',
      muscleGroup: 'Back',
      equipment: 'Barbell',
    ),
    SeedExercise(name: 'Lat Pulldown', muscleGroup: 'Back', equipment: 'Cable'),
    SeedExercise(name: 'Pull Up', muscleGroup: 'Back', equipment: 'Bodyweight'),
    SeedExercise(
      name: 'Seated Cable Row',
      muscleGroup: 'Back',
      equipment: 'Cable',
    ),
    SeedExercise(
      name: 'Single Arm Dumbbell Row',
      muscleGroup: 'Back',
      equipment: 'Dumbbell',
    ),
    SeedExercise(name: 'T-Bar Row', muscleGroup: 'Back', equipment: 'Barbell'),

    // Shoulders
    SeedExercise(
      name: 'Standing Overhead Press',
      muscleGroup: 'Shoulders',
      equipment: 'Barbell',
    ),
    SeedExercise(
      name: 'Dumbbell Shoulder Press',
      muscleGroup: 'Shoulders',
      equipment: 'Dumbbell',
    ),
    SeedExercise(
      name: 'Dumbbell Lateral Raise',
      muscleGroup: 'Shoulders',
      equipment: 'Dumbbell',
    ),
    SeedExercise(
      name: 'Cable Lateral Raise',
      muscleGroup: 'Shoulders',
      equipment: 'Cable',
    ),
    SeedExercise(
      name: 'Face Pull',
      muscleGroup: 'Shoulders',
      equipment: 'Cable',
    ),
    SeedExercise(
      name: 'Reverse Pec Deck Fly',
      muscleGroup: 'Shoulders',
      equipment: 'Machine',
    ),

    // Biceps
    SeedExercise(
      name: 'Barbell Biceps Curl',
      muscleGroup: 'Biceps',
      equipment: 'Barbell',
    ),
    SeedExercise(
      name: 'Dumbbell Incline Curl',
      muscleGroup: 'Biceps',
      equipment: 'Dumbbell',
    ),
    SeedExercise(
      name: 'Hammer Curl',
      muscleGroup: 'Biceps',
      equipment: 'Dumbbell',
    ),
    SeedExercise(
      name: 'Preacher Curl',
      muscleGroup: 'Biceps',
      equipment: 'Barbell',
    ),
    SeedExercise(
      name: 'EZ-Bar Curl',
      muscleGroup: 'Biceps',
      equipment: 'Barbell',
    ),

    // Triceps
    SeedExercise(
      name: 'Triceps Rope Pushdown',
      muscleGroup: 'Triceps',
      equipment: 'Cable',
    ),
    SeedExercise(
      name: 'Barbell Skull Crusher',
      muscleGroup: 'Triceps',
      equipment: 'Barbell',
    ),
    SeedExercise(
      name: 'Close-Grip Bench Press',
      muscleGroup: 'Triceps',
      equipment: 'Barbell',
    ),
    SeedExercise(
      name: 'Overhead Dumbbell Triceps Extension',
      muscleGroup: 'Triceps',
      equipment: 'Dumbbell',
    ),
    SeedExercise(
      name: 'Triceps Dips',
      muscleGroup: 'Triceps',
      equipment: 'Bodyweight',
    ),

    // Legs
    SeedExercise(
      name: 'Barbell Back Squat',
      muscleGroup: 'Legs',
      equipment: 'Barbell',
    ),
    SeedExercise(
      name: 'Barbell Front Squat',
      muscleGroup: 'Legs',
      equipment: 'Barbell',
    ),
    SeedExercise(
      name: 'Romanian Deadlift (RDL)',
      muscleGroup: 'Legs',
      equipment: 'Barbell',
    ),
    SeedExercise(name: 'Leg Press', muscleGroup: 'Legs', equipment: 'Machine'),
    SeedExercise(
      name: 'Leg Extension',
      muscleGroup: 'Legs',
      equipment: 'Machine',
    ),
    SeedExercise(
      name: 'Seated Leg Curl',
      muscleGroup: 'Legs',
      equipment: 'Machine',
    ),
    SeedExercise(
      name: 'Standing Calf Raise',
      muscleGroup: 'Legs',
      equipment: 'Machine',
    ),
    SeedExercise(
      name: 'Bulgarian Split Squat',
      muscleGroup: 'Legs',
      equipment: 'Dumbbell',
    ),

    // Core
    SeedExercise(
      name: 'Hanging Leg Raise',
      muscleGroup: 'Core',
      equipment: 'Bodyweight',
      exerciseType: 'reps_only',
    ),
    SeedExercise(
      name: 'Plank',
      muscleGroup: 'Core',
      equipment: 'Bodyweight',
      exerciseType: 'duration_only',
    ),
    SeedExercise(
      name: 'Cable Woodchopper',
      muscleGroup: 'Core',
      equipment: 'Cable',
    ),
    SeedExercise(
      name: 'Ab Wheel Rollout',
      muscleGroup: 'Core',
      equipment: 'Bodyweight',
      exerciseType: 'reps_only',
    ),
  ];
}
