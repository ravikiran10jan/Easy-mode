import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_providers.dart';
import '../providers/progress_provider.dart';

/// Progress screen showing XP, badges, and stats
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(currentUserDataProvider);
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
      ),
      body: userData.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No user data'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Level and XP Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${user.level}',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        'Level ${user.level}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        _getLevelTitle(user.level),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      // XP Progress
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${user.xpTotal} XP',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${user.xpForNextLevel} XP to Level ${user.level + 1}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: user.levelProgress,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              minHeight: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // Streak Card
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 32,
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
                            Text(
                              user.streak >= 3
                                  ? '+${((user.streak - 2) * 10).clamp(0, 50)}% XP bonus active!'
                                  : 'Keep going to unlock streak bonuses!',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

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
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        context,
                        icon: Icons.flash_on,
                        color: AppTheme.actionColor,
                        value: '${stats['actionsCompleted'] ?? 0}',
                        label: 'Actions Taken',
                      ),
                      _buildStatCard(
                        context,
                        icon: Icons.local_fire_department,
                        color: AppTheme.audacityColor,
                        value: '${stats['audacityAttempts'] ?? 0}',
                        label: 'Bold Asks',
                      ),
                      _buildStatCard(
                        context,
                        icon: Icons.favorite,
                        color: AppTheme.enjoyColor,
                        value: '${stats['ritualsCompleted'] ?? 0}',
                        label: 'Joy Rituals',
                      ),
                      _buildStatCard(
                        context,
                        icon: Icons.calendar_today,
                        color: AppTheme.primaryColor,
                        value: '${stats['activeDays'] ?? 0}',
                        label: 'Active Days',
                      ),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context) {
    // Sample badges - in a real app, these would come from Firestore
    final badges = [
      {'name': 'First Step', 'icon': Icons.star, 'earned': true},
      {'name': 'Week Warrior', 'icon': Icons.military_tech, 'earned': true},
      {'name': 'Bold Beginner', 'icon': Icons.local_fire_department, 'earned': false},
      {'name': 'Joy Seeker', 'icon': Icons.favorite, 'earned': false},
      {'name': 'Streak Master', 'icon': Icons.whatshot, 'earned': false},
      {'name': 'Level 10', 'icon': Icons.emoji_events, 'earned': false},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: AppTheme.spacingSm,
        mainAxisSpacing: AppTheme.spacingSm,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final isEarned = badge['earned'] as bool;

        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: isEarned ? AppTheme.accentColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                badge['icon'] as IconData,
                size: 32,
                color: isEarned ? AppTheme.accentColor : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                badge['name'] as String,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isEarned ? AppTheme.textPrimary : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
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
