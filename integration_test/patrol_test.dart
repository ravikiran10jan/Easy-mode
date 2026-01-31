import 'package:patrol/patrol.dart';
import 'package:easy_mode/main.dart' as app;

/// Patrol tests for native iOS interactions
/// 
/// Run with: patrol test -t integration_test/patrol_test.dart
/// 
/// Patrol can interact with native OS elements like:
/// - Google Sign-In picker
/// - Permission dialogs
/// - System alerts
/// - Native file pickers
void main() {
  patrolTest(
    'Google Sign-In flow',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      // Wait for sign in screen to load
      await $.pump(const Duration(seconds: 2));

      // Tap on Google Sign-In button
      await $.tap(find.text('Continue with Google'));
      await $.pumpAndSettle();

      // Wait for native Google Sign-In picker to appear
      await $.pump(const Duration(seconds: 2));

      // Patrol can interact with native iOS UI
      // This will find and tap on Google account in the native picker
      if (await $.native.isPermissionDialogVisible()) {
        await $.native.grantPermissionWhenInUse();
      }

      // Note: For actual Google Sign-In, you need:
      // 1. A real Google account signed into the iOS device
      // 2. The native Google Sign-In sheet will appear
      // 3. Use $.native methods to interact with it
      
      // Wait for authentication to complete
      await $.pumpAndSettle(const Duration(seconds: 5));
    },
  );

  patrolTest(
    'Full app flow - login and navigate',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      // Wait for app to initialize
      await $.pump(const Duration(seconds: 3));

      // Test email/password login
      await $.enterText(
        find.widgetWithText($.tester.widget, 'Email'),
        'test@example.com',
      );

      await $.enterText(
        find.widgetWithText($.tester.widget, 'Password'),
        'TestPass123!',
      );

      await $.tap(find.text('Sign In'));
      await $.pumpAndSettle(const Duration(seconds: 5));

      // If login successful, verify home screen
      // Note: This requires valid Firebase credentials
    },
  );

  patrolTest(
    'Handle notification permission',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      // If notification permission dialog appears
      if (await $.native.isPermissionDialogVisible()) {
        // Grant notification permission
        await $.native.grantPermissionWhenInUse();
        await $.pumpAndSettle();
      }
    },
  );

  patrolTest(
    'Sign up flow',
    ($) async {
      app.main();
      await $.pumpAndSettle();
      await $.pump(const Duration(seconds: 2));

      // Navigate to Sign Up
      await $.tap(find.text('Sign Up'));
      await $.pumpAndSettle();

      // Verify Sign Up screen
      expect(find.text('Create Account'), findsOneWidget);

      // Fill in sign up form
      // Note: Update selectors based on actual widget keys/labels
    },
  );
}
