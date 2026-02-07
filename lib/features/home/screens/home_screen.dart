import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/ai_service.dart';
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
                  
                  // Coach Decides Button - Agentic Feature
                  _CoachDecidesButton()
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),
                  
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

/// Coach Decides Button - Agentic AI feature
/// When tapped, the AI coach makes a decision for the user
class _CoachDecidesButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coachState = ref.watch(coachDecidesStateProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: coachState.isLoading
            ? null
            : () => _handleCoachDecides(context, ref),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: AppTheme.shadowMedium,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: coachState.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Let Coach Decide',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                    ),
                    Text(
                      'AI picks the perfect task for right now',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCoachDecides(BuildContext context, WidgetRef ref) async {
    await ref.read(coachDecidesStateProvider.notifier).letCoachDecide();
    final state = ref.read(coachDecidesStateProvider);

    if (!context.mounted) return;

    if (state.response?.success == true && state.response?.task != null) {
      _showCoachDecisionDialog(context, ref, state.response!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Coach is thinking... try again'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showCoachDecisionDialog(
    BuildContext context,
    WidgetRef ref,
    CoachDecidesResponse response,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CoachDecisionSheet(response: response),
    );
  }
}

/// Bottom sheet showing the Coach's decision with full reasoning
class _CoachDecisionSheet extends StatelessWidget {
  final CoachDecidesResponse response;

  const _CoachDecisionSheet({required this.response});

  @override
  Widget build(BuildContext context) {
    final task = response.task;
    final reasoning = response.reasoning;
    final coachContext = response.context;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // Coach Avatar and Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coach Decision',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (reasoning?.confidenceLevel != null)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: reasoning!.confidenceLevel == 'HIGH'
                                  ? AppTheme.successColor.withOpacity(0.1)
                                  : AppTheme.warningColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${reasoning.confidenceLevel} Confidence',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: reasoning.confidenceLevel == 'HIGH'
                                        ? AppTheme.successColor
                                        : AppTheme.warningColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // Headline Decision
              if (reasoning?.headline != null)
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          reasoning!.headline,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppTheme.spacingLg),

              // Task Card
              if (task != null)
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildTaskTypeBadge(context, task.type),
                          const SizedBox(width: 8),
                          Text(
                            '${task.estimatedMinutes} min',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppTheme.spacingMd),

              // Why Now Section
              if (reasoning?.whyNow != null) ...[
                Text(
                  'Why This Task, Right Now?',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  reasoning!.whyNow,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],

              const SizedBox(height: AppTheme.spacingMd),

              // Expected Outcome
              if (reasoning?.expectedOutcome != null)
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        color: AppTheme.successColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reasoning!.expectedOutcome,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.successColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Context Pills
              if (coachContext != null) ...[
                const SizedBox(height: AppTheme.spacingMd),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildContextPill(
                      context,
                      Icons.local_fire_department_rounded,
                      '${coachContext.streak} day streak',
                    ),
                    _buildContextPill(
                      context,
                      Icons.schedule_rounded,
                      coachContext.timeOfDay,
                    ),
                    if (coachContext.energyAlignment == 'peak')
                      _buildContextPill(
                        context,
                        Icons.bolt_rounded,
                        'Peak Energy',
                        highlight: true,
                      ),
                  ],
                ),
              ],

              // Coach Message
              if (response.coachMessage != null) ...[
                const SizedBox(height: AppTheme.spacingLg),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.chat_bubble_rounded,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          response.coachMessage!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppTheme.spacingXl),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Optionally navigate to task or trigger task start
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  child: const Text(
                    'Got It - Let\'s Do This!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTypeBadge(BuildContext context, String type) {
    Color color;
    IconData icon;
    String label;

    switch (type.toLowerCase()) {
      case 'audacity':
        color = AppTheme.audacityColor;
        icon = Icons.local_fire_department_rounded;
        label = 'Audacity';
        break;
      case 'enjoy':
        color = AppTheme.enjoyColor;
        icon = Icons.favorite_rounded;
        label = 'Enjoy';
        break;
      default:
        color = AppTheme.actionColor;
        icon = Icons.bolt_rounded;
        label = 'Action';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextPill(
    BuildContext context,
    IconData icon,
    String label, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.accentColor.withOpacity(0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: highlight
            ? Border.all(color: AppTheme.accentColor.withOpacity(0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlight ? AppTheme.accentColor : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: highlight ? AppTheme.accentColor : Colors.grey[600],
                  fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }
}
