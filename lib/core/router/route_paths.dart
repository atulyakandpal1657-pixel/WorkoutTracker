class RoutePaths {
  RoutePaths._();

  // Bottom Nav Shell Routes
  static const String home = '/';
  static const String workout = '/workout';
  static const String history = '/history';
  static const String progress = '/progress';
  static const String templates = '/templates';

  // Sub-routes & Modals
  static const String activeWorkout = '/active-workout';
  static const String workoutSummary = '/workout-summary/:sessionId';
  static const String sessionDetails = '/session/:sessionId';
  static const String templateEditor = '/template-editor';
  static const String exercises = '/exercises';
  static const String profileSelection = '/profiles';
  static const String settings = '/settings';

  // Helpers for parameterised paths
  static String workoutSummaryPath(String sessionId) =>
      '/workout-summary/$sessionId';
  static String sessionDetailsPath(String sessionId) => '/session/$sessionId';
  static String templateEditorPath({String? templateId}) => templateId != null
      ? '/template-editor?id=$templateId'
      : '/template-editor';
}
