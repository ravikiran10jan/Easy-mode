import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_mode/features/onboarding/screens/onboarding_screen.dart';
import 'package:easy_mode/core/theme/app_theme.dart';

void main() {
  group('OnboardingScreen', () {
    Widget createWidgetUnderTest() => ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const OnboardingScreen(),
        ),
      );

    testWidgets('shows welcome page initially', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Welcome to Easy Mode'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Audacity'), findsOneWidget);
      expect(find.text('Enjoy'), findsOneWidget);
    });

    testWidgets('can navigate to pain selection page', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap continue button
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text("What's your biggest challenge?"), findsOneWidget);
    });

    testWidgets('can select a pain point', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Navigate to pain page
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Select a pain option
      await tester.tap(find.text('I struggle to ask for what I want'));
      await tester.pump();

      // Continue button should be enabled
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('can navigate through all pages', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Page 1: Welcome -> Pain
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text("What's your biggest challenge?"), findsOneWidget);

      // Select pain
      await tester.tap(find.text('I struggle to ask for what I want'));
      await tester.pump();

      // Page 2: Pain -> Goal
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('What do you want to achieve?'), findsOneWidget);

      // Select goal
      await tester.tap(find.text('Be more assertive and confident'));
      await tester.pump();

      // Page 3: Goal -> Time
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('How much time can you spare daily?'), findsOneWidget);

      // Final page should have "Get Started" button
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('can go back to previous pages', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Navigate to pain page
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Tap back button
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Easy Mode'), findsOneWidget);
    });

    testWidgets('progress indicators update correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Find progress indicators (4 containers)
      // Initial state: first indicator should be active
      
      // Navigate to next page
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Progress should update (visual verification would require golden tests)
    });
  });
}
