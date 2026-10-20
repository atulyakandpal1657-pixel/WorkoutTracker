import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:replog/app.dart';
import 'package:replog/core/constants/app_colors.dart';
import 'package:replog/features/workout/presentation/active_workout_state.dart';

void main() {
  testWidgets('RepLog Home tab renders correctly with quick start', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: RepLogApp()));
    await tester.pumpAndSettle();

    expect(find.text('RepLog'), findsOneWidget);
    expect(find.text('Quick Session'), findsOneWidget);
    expect(find.text('Start Empty Workout'), findsWidgets);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });

  testWidgets('RepLog switches to Workout tab', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: RepLogApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();

    expect(find.text('Start from Routines'), findsOneWidget);
    expect(find.text('Push (Chest, Shoulders & Triceps)'), findsOneWidget);
  });

  testWidgets('RepLog switches to History tab', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: RepLogApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();

    expect(find.text('Workout History'), findsOneWidget);
    expect(find.text('All Time'), findsOneWidget);
  });

  testWidgets('RepLog switches to Progress tab', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: RepLogApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(NavigationDestination).at(3));
    await tester.pumpAndSettle();

    expect(find.text('Progress & Records'), findsOneWidget);
    expect(find.text('Personal Records (PRs)'), findsOneWidget);
  });

  testWidgets('RepLog switches to Templates tab', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: RepLogApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(NavigationDestination).at(4));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Create New Routine'), findsOneWidget);
  });

  testWidgets('RepLog active workout banner reactivity test', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const RepLogApp()),
    );
    await tester.pumpAndSettle();

    // Initially no active workout
    expect(find.text('ACTIVE SESSION IN PROGRESS'), findsNothing);

    // Start workout in memory
    container
        .read(activeWorkoutProvider.notifier)
        .startWorkout(name: 'Leg Day Blast');
    await tester.pumpAndSettle();

    // Verify active workout banner now appears on Home screen
    expect(find.text('ACTIVE SESSION IN PROGRESS'), findsOneWidget);
    expect(find.text('Leg Day Blast'), findsWidgets);
  });

  test('RepLog design system color tokens follow dark gym aesthetic', () {
    expect(AppColors.background, const Color(0xFF0E1012));
    expect(AppColors.accent, const Color(0xFFCCFF00));
    expect(AppColors.surface, const Color(0xFF16191D));
    expect(AppColors.card, const Color(0xFF191D23));
    expect(AppColors.textPrimary, const Color(0xFFF9FAFB));
    expect(AppColors.textSecondary, const Color(0xFF9CA3AF));
  });
}
