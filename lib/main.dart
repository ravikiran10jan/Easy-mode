import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_providers.dart';
import 'features/auth/screens/sign_in_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    const ProviderScope(
      child: EasyModeApp(),
    ),
  );
}

class EasyModeApp extends ConsumerWidget {
  const EasyModeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
      title: 'Easy Mode',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
}

/// Wrapper that handles auth state and onboarding routing
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      data: (user) {
        if (user == null) {
          return const SignInScreen();
        }
        
        // User is authenticated, check if onboarding is complete
        final userData = ref.watch(currentUserDataProvider);
        
        return userData.when(
          data: (userModel) {
            if (userModel == null) {
              // User doc not created yet, show loading
              return const _LoadingScreen();
            }
            
            if (!userModel.hasCompletedOnboarding) {
              return const OnboardingScreen();
            }
            
            return const AppShell();
          },
          loading: () => const _LoadingScreen(),
          error: (error, stack) => _ErrorScreen(error: error.toString()),
        );
      },
      loading: () => const _LoadingScreen(),
      error: (error, stack) => _ErrorScreen(error: error.toString()),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.backgroundColor,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppTheme.shadowColored(AppTheme.primaryColor),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              size: 52,
              color: Colors.white,
            ),
          ).animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          ).scaleXY(
            begin: 1,
            end: 1.05,
            duration: 1000.ms,
            curve: Curves.easeInOut,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ErrorScreen extends StatelessWidget {
  final String error;
  
  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.backgroundColor,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Trigger a rebuild
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    ),
  );
}
