import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Test credentials for integration testing
class TestCredentials {
  static const testEmail = 'test@example.com';
  static const testPassword = 'TestPass123!';
  static const testName = 'Test User';
}

/// Helper class for setting up integration tests
class TestHelper {
  /// Pump the app widget with necessary providers
  static Widget createTestApp(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: child,
      ),
    );
  }

  /// Wait for widget to settle with animations
  static Future<void> pumpAndSettle(
    WidgetTester tester, {
    Duration duration = const Duration(milliseconds: 100),
  }) async {
    await tester.pumpAndSettle(duration);
  }

  /// Find and tap a widget by key
  static Future<void> tapByKey(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Find and tap a widget by text
  static Future<void> tapByText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Enter text in a text field by key
  static Future<void> enterTextByKey(
    WidgetTester tester,
    Key key,
    String text,
  ) async {
    final finder = find.byKey(key);
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Enter text in a text field by hint text
  static Future<void> enterTextByHint(
    WidgetTester tester,
    String hint,
    String text,
  ) async {
    final finder = find.widgetWithText(TextField, hint);
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Verify widget exists
  static void expectWidgetExists(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verify text exists on screen
  static void expectTextExists(String text) {
    expect(find.text(text), findsWidgets);
  }
}
