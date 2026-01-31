import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../app_shell.dart';
import '../providers/home_provider.dart';
import '../widgets/daily_task_card.dart';
import '../widgets/xp_header.dart';
import '../widgets/ai_insight_card.dart';

/// Home screen - Daily Command Center
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _showConfetti() {
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(currentUserDataProvider);
    final dailyTask = ref.watch(dailyTaskProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            height: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEEF2FF),
                  Color(0xFFF5F3FF),
                  AppTheme.backgroundColor,
                ],
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                left: AppTheme.spacingMd,
                right: AppTheme.spacingMd,
                top: AppTheme.spacingMd,
                bottom: 100, // Space for floating nav
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting and XP Header
                  userData.when(
                    data: (user) => XpHeader(user: user)
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: -0.1, end: 0),
                    loading: () => _buildHeaderSkeleton(),
                    error: (_, __) => const SizedBox(height: 100),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingLg),
                  
                  // Today's Easy Mode Moment
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Easy Mode Moment",
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'Your daily challenge awaits',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideX(begin: -0.1, end: 0),
                  
                  const SizedBox(height: AppTheme.spacingMd),
                  
                  // Daily Task Card
                  dailyTask.when(
                    data: (recommendation) => DailyTaskCard(
                      task: recommendation.task,
                      aiReasoning: recommendation.reasoning,
                      behaviorInsights: recommendation.insights,
                      onComplete: _showConfetti,
                    ).animate()
                      .fadeIn(delay: 300.ms, duration: 500.ms)
                      .slideY(begin: 0.1, end: 0),
                    loading: () => _buildTaskSkeleton(),
                    error: (error, _) => _buildErrorCard(error.toString()),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXl),
                  
                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ).animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms),
                  
                  const SizedBox(height: AppTheme.spacingMd),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          icon: Icons.local_fire_department_rounded,
                          label: 'Try Audacity',
                          gradient: AppTheme.audacityGradient,
                          onTap: () {
                            ref.read(navigationIndexProvider.notifier).state = 1;
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          icon: Icons.favorite_rounded,
                          label: 'Joy Ritual',
                          gradient: AppTheme.enjoyGradient,
                          onTap: () {
                            ref.read(navigationIndexProvider.notifier).state = 2;
                          },
                        ),
                      ),
                    ],
                  ).animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: AppTheme.spacingXl),
                  
                  // AI Insight Card (replaces static quote)
                  const AiInsightCard()
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 500.ms)
                    .slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ),
          
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppTheme.primaryColor,
                AppTheme.secondaryColor,
                AppTheme.accentColor,
                AppTheme.actionColor,
                AppTheme.audacityColor,
              ],
              numberOfParticles: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) => Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: AppTheme.shadowSmall,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.textMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );

  Widget _buildHeaderSkeleton() => Container(
    height: 140,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
    ),
    child: const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppTheme.primaryColor,
      ),
    ),
  );

  Widget _buildTaskSkeleton() => Container(
    height: 200,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      boxShadow: AppTheme.shadowSmall,
    ),
    child: const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppTheme.primaryColor,
      ),
    ),
  );

  Widget _buildErrorCard(String error) => Container(
    padding: const EdgeInsets.all(AppTheme.spacingLg),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      boxShadow: AppTheme.shadowSmall,
      border: Border.all(
        color: AppTheme.errorColor.withOpacity(0.2),
      ),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.errorColor,
            size: 32,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          'Something went wrong',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          'Unable to load your daily task',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
