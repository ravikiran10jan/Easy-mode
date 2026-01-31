import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_mode/features/home/widgets/daily_task_card.dart';
import 'package:easy_mode/core/models/task_model.dart';
import 'package:easy_mode/core/theme/app_theme.dart';

void main() {
  group('DailyTaskCard', () {
    final testTask = TaskModel(
      id: 'test_task_1',
      title: 'Test Task Title',
      description: 'This is a test task description',
      type: 'action',
      estimatedMinutes: 5,
      xpReward: 100,
    );

    Widget createWidgetUnderTest({VoidCallback? onComplete}) {
      return ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DailyTaskCard(
              task: testTask,
              onComplete: onComplete,
            ),
          ),
        ),
      );
    }

    testWidgets('displays task title and description', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Test Task Title'), findsOneWidget);
      expect(find.text('This is a test task description'), findsOneWidget);
    });

    testWidgets('displays task type badge', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('ACTION'), findsOneWidget);
    });

    testWidgets('displays estimated time', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('~5 min'), findsOneWidget);
    });

    testWidgets('shows Start Now button initially', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Start Now'), findsOneWidget);
    });

    testWidgets('shows I did it button after starting timer', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap Start Now
      await tester.tap(find.text('Start Now'));
      await tester.pump();

      expect(find.text('I did it!'), findsOneWidget);
    });

    testWidgets('shows I couldn\'t button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text("I couldn't"), findsOneWidget);
    });

    testWidgets('timer updates when running', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Start timer
      await tester.tap(find.text('Start Now'));
      await tester.pump();

      // Initial time should be 00:00
      expect(find.text('00:00'), findsOneWidget);

      // Wait 1 second
      await tester.pump(const Duration(seconds: 1));

      // Time should update to 00:01
      expect(find.text('00:01'), findsOneWidget);
    });

    testWidgets('shows failure dialog on I couldn\'t tap', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text("I couldn't"));
      await tester.pumpAndSettle();

      expect(find.text('No worries!'), findsOneWidget);
      expect(find.text('Take 3 deep breaths'), findsOneWidget);
    });
  });

  group('DailyTaskCard with different task types', () {
    Widget createCardWithType(String type) {
      final task = TaskModel(
        id: 'test_$type',
        title: '$type Task',
        description: 'Description for $type',
        type: type,
        estimatedMinutes: 5,
        xpReward: type == 'audacity' ? 200 : 100,
      );

      return ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DailyTaskCard(task: task),
          ),
        ),
      );
    }

    testWidgets('displays ACTION badge for action type', (tester) async {
      await tester.pumpWidget(createCardWithType('action'));
      expect(find.text('ACTION'), findsOneWidget);
    });

    testWidgets('displays AUDACITY badge for audacity type', (tester) async {
      await tester.pumpWidget(createCardWithType('audacity'));
      expect(find.text('AUDACITY'), findsOneWidget);
    });

    testWidgets('displays ENJOY badge for enjoy type', (tester) async {
      await tester.pumpWidget(createCardWithType('enjoy'));
      expect(find.text('ENJOY'), findsOneWidget);
    });
  });
}
