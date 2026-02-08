import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_providers.dart';
import '../providers/progress_provider.dart';
import '../widgets/momentum_tracker_card.dart';

/// Progress screen showing XP, badges, and stats
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(currentUserDataProvider);
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: userData.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No user data'));
          }

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Custom App Bar
              SliverAppBar(
                expandedHeight: 100,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.backgroundColor,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Your Progress',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                ),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppTheme.spacingMd,
                    right: AppTheme.spacingMd,
                    bottom: 140, // Increased space for floating nav and badges
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Level and XP Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.spacingLg),
                        decoration: BoxDecoration(
                          gradient: AppTheme.heroGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                          boxShadow: AppTheme.shadowColored(AppTheme.primaryColor),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 3,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${user.level}',
                                          style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'LEVEL',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withOpacity(0.8),
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ).animate()
                                  .scale(
                                    begin: const Offset(0.9, 0.9),
                                    end: const Offset(1, 1),
                                    duration: 500.ms,
                                    curve: Curves.easeOutBack,
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            Text(
                              _getLevelTitle(user.level),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.95),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingLg),
                            // XP Progress
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${user.xpTotal} XP',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${user.xpForNextLevel} XP to Level ${user.level + 1}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spacingMd),
                                Stack(
                                  children: [
                                    Container(
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: user.levelProgress.clamp(0.0, 1.0),
                                      child: Container(
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(7),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white.withOpacity(0.5),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ).animate()
                                      .scaleX(
                                        begin: 0,
                                        end: 1,
                                        duration: 800.ms,
                                        delay: 300.ms,
                                        curve: Curves.easeOutCubic,
                                        alignment: Alignment.centerLeft,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: AppTheme.spacingLg),

                      // Streak Card
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                          boxShadow: AppTheme.shadowSmall,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: AppTheme.streakGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF6B6B).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${user.streak} Day Streak',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.streak >= 3
                                        ? '+${((user.streak - 2) * 10).clamp(0, 50)}% XP bonus active!'
                                        : 'Keep going to unlock streak bonuses!',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            if (user.streak >= 3)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: AppTheme.successColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ).animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideX(begin: -0.1, end: 0),

                      const SizedBox(height: AppTheme.spacingLg),

                      // Momentum Tracker - "Your Momentum Journal"
                      const MomentumTrackerCard()
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 500.ms)
                        .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: AppTheme.spacingLg),

                      // Stats Grid
                      Text(
                        'Your Stats',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),

                      statsAsync.when(
                        data: (stats) => GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: AppTheme.spacingMd,
                          crossAxisSpacing: AppTheme.spacingMd,
                          childAspectRatio: 1.4,
                          children: [
                            _buildStatCard(
                              context,
                              icon: Icons.flash_on_rounded,
                              gradient: AppTheme.actionGradient,
                              value: '${stats['actionsCompleted'] ?? 0}',
                              label: 'Actions Taken',
                            ).animate()
                              .fadeIn(delay: 300.ms, duration: 400.ms)
                              .slideY(begin: 0.1, end: 0),
                            _buildStatCard(
                              context,
                              icon: Icons.local_fire_department_rounded,
                              gradient: AppTheme.audacityGradient,
                              value: '${stats['audacityAttempts'] ?? 0}',
                              label: 'Bold Asks',
                            ).animate()
                              .fadeIn(delay: 400.ms, duration: 400.ms)
                              .slideY(begin: 0.1, end: 0),
                            _buildStatCard(
                              context,
                              icon: Icons.favorite_rounded,
                              gradient: AppTheme.enjoyGradient,
                              value: '${stats['ritualsCompleted'] ?? 0}',
                              label: 'Joy Rituals',
                            ).animate()
                              .fadeIn(delay: 500.ms, duration: 400.ms)
                              .slideY(begin: 0.1, end: 0),
                            _buildStatCard(
                              context,
                              icon: Icons.calendar_today_rounded,
                              gradient: AppTheme.primaryGradient,
                              value: '${stats['activeDays'] ?? 0}',
                              label: 'Active Days',
                            ).animate()
                              .fadeIn(delay: 600.ms, duration: 400.ms)
                              .slideY(begin: 0.1, end: 0),
                          ],
                        ),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        error: (_, __) => const Text('Error loading stats'),
                      ),

                      const SizedBox(height: AppTheme.spacingLg),

                      // Badges Section
                      Text(
                        'Badges',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),

                      _buildBadgesSection(context),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor,
          ),
        ),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required LinearGradient gradient,
    required String value,
    required String label,
  }) => Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

  Widget _buildBadgesSection(BuildContext context) {
    // Sample badges - in a real app, these would come from Firestore
    final badges = [
      {'name': 'First Step', 'icon': Icons.star_rounded, 'earned': true},
      {'name': 'Week Warrior', 'icon': Icons.military_tech_rounded, 'earned': true},
      {'name': 'Bold Beginner', 'icon': Icons.local_fire_department_rounded, 'earned': false},
      {'name': 'Joy Seeker', 'icon': Icons.favorite_rounded, 'earned': false},
      {'name': 'Streak Master', 'icon': Icons.whatshot_rounded, 'earned': false},
      {'name': 'Level 10', 'icon': Icons.emoji_events_rounded, 'earned': false},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: AppTheme.spacingMd,
        mainAxisSpacing: AppTheme.spacingMd,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final isEarned = badge['earned'] as bool;

        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: isEarned ? AppTheme.shadowColored(AppTheme.accentColor) : AppTheme.shadowSmall,
            border: isEarned ? Border.all(
              color: AppTheme.accentColor.withOpacity(0.3),
              width: 2,
            ) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isEarned 
                      ? AppTheme.accentColor.withOpacity(0.15) 
                      : AppTheme.textMuted.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  badge['icon'] as IconData,
                  size: 26,
                  color: isEarned ? AppTheme.accentColor : AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge['name'] as String,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isEarned ? AppTheme.textPrimary : AppTheme.textMuted,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ).animate()
          .fadeIn(delay: Duration(milliseconds: 600 + (index * 100)), duration: 400.ms)
          .scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1, 1),
          );
      },
    );
  }

  String _getLevelTitle(int level) {
    if (level < 5) return 'Beginner';
    if (level < 10) return 'Apprentice';
    if (level < 20) return 'Practitioner';
    if (level < 30) return 'Expert';
    if (level < 40) return 'Master';
    return 'Legend';
  }
}
