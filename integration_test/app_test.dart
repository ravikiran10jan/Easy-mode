import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:easy_mode/main.dart' as app;
import 'test_helper.dart';

/// Integration tests for Easy Mode app
/// 
/// Run with: flutter test integration_test/app_test.dart
/// Run on device: flutter test integration_test/app_test.dart -d <device_id>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Helper to wait for app initialization (Firebase, animations)
  Future<void> waitForAppInit(WidgetTester tester) async {
    // Wait for Firebase initialization
    await tester.pump(const Duration(seconds: 2));
    // Allow multiple frames to settle
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    // Final settle
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  group('Authentication Flow Tests', () {
    testWidgets('Sign in screen displays correctly', (tester) async {
      app.main();
      await waitForAppInit(tester);

      // Verify sign in screen elements exist (at least one)
      final welcomeText = find.text('Welcome Back');
      final signInButton = find.text('Sign In');
      final googleButton = find.text('Continue with Google');
      
      // Check if we're on the sign in screen
      final hasSignInUI = welcomeText.evaluate().isNotEmpty || 
                          signInButton.evaluate().isNotEmpty ||
                          googleButton.evaluate().isNotEmpty;
      
      expect(hasSignInUI, isTrue, reason: 'Sign in screen should be displayed');
    });

    testWidgets('Form fields are present', (tester) async {
      app.main();
      await waitForAppInit(tester);

      // Look for text input fields
      final textFields = find.byType(TextFormField);
      expect(textFields.evaluate().length, greaterThanOrEqualTo(1), 
             reason: 'Should have at least one text field');
    });

    testWidgets('Sign Up link exists', (tester) async {
      app.main();
      await waitForAppInit(tester);

      // Look for Sign Up text
      final signUpText = find.textContaining('Sign Up');
      final hasSignUp = signUpText.evaluate().isNotEmpty;
      
      expect(hasSignUp, isTrue, reason: 'Sign Up link should exist');
    });
  });

  group('UI Element Tests', () {
    testWidgets('App launches without crashing', (tester) async {
      app.main();
      await waitForAppInit(tester);
      
      // If we get here without exception, app launched successfully
      expect(true, isTrue);
    });

    testWidgets('Material app is rendered', (tester) async {
      app.main();
      await waitForAppInit(tester);
      
      // Check for MaterialApp or Scaffold
      final scaffold = find.byType(Scaffold);
      expect(scaffold.evaluate().isNotEmpty, isTrue, 
             reason: 'App should render a Scaffold');
    });
  });
}
