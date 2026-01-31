import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti_widget/confetti_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/home_provider.dart';
import '../widgets/daily_task_card.dart';
import '../widgets/xp_header.dart';

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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting and XP Header
                  userData.when(
                    data: (user) => XpHeader(user: user),
                    loading: () => const SizedBox(height: 100),
                    error: (_, __) => const SizedBox(height: 100),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingLg),
                  
                  // Today's Easy Mode Moment
                  Text(
                    "Today's Easy Mode Moment",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  
                  const SizedBox(height: AppTheme.spacingMd),
                  
                  // Daily Task Card
                  dailyTask.when(
                    data: (task) => DailyTaskCard(
                      task: task,
                      onComplete: _showConfetti,
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, _) => Center(
                      child: Text('Error: $error'),
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXl),
                  
                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  
                  const SizedBox(height: AppTheme.spacingMd),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          icon: Icons.local_fire_department_rounded,
                          label: 'Try Audacity',
                          color: AppTheme.audacityColor,
                          onTap: () {
                            // Navigate to audacity
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          icon: Icons.favorite_rounded,
                          label: 'Joy Ritual',
                          color: AppTheme.enjoyColor,
                          onTap: () {
                            // Navigate to rituals
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXl),
                  
                  // Motivation quote
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.1),
                          AppTheme.secondaryColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.format_quote_rounded,
                          color: AppTheme.primaryColor.withOpacity(0.5),
                          size: 32,
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          '"The secret of getting ahead is getting started. The secret of getting started is breaking your complex, overwhelming tasks into small manageable tasks, and starting on the first one."',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          '— Mark Twain',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
