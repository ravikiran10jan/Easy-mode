import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_providers.dart';

/// Profile and Settings screen
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(currentUserDataProvider);

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
                    'Profile',
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
                    bottom: 100, // Space for floating nav
                  ),
                  child: Column(
                    children: [
                      // Profile Header
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingLg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                          boxShadow: AppTheme.shadowMedium,
                        ),
                        child: Column(
                          children: [
                            // Avatar
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: user.photoUrl == null 
                                    ? AppTheme.primaryGradient 
                                    : null,
                                boxShadow: AppTheme.shadowColored(AppTheme.primaryColor),
                              ),
                              child: user.photoUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        user.photoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildAvatarFallback(user.name),
                                      ),
                                    )
                                  : _buildAvatarFallback(user.name),
                            ).animate()
                              .fadeIn(duration: 500.ms)
                              .scale(
                                begin: const Offset(0.9, 0.9),
                                end: const Offset(1, 1),
                              ),
                            
                            const SizedBox(height: AppTheme.spacingMd),
                            
                            Text(
                              user.name ?? 'User',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email ?? '',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            
                            const SizedBox(height: AppTheme.spacingLg),
                            
                            // Stats row
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingMd),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildProfileStat(
                                    context,
                                    value: '${user.level}',
                                    label: 'Level',
                                    color: AppTheme.primaryColor,
                                  ),
                                  Container(
                                    height: 40,
                                    width: 1,
                                    color: AppTheme.dividerColor,
                                  ),
                                  _buildProfileStat(
                                    context,
                                    value: '${user.xpTotal}',
                                    label: 'Total XP',
                                    color: AppTheme.secondaryColor,
                                  ),
                                  Container(
                                    height: 40,
                                    width: 1,
                                    color: AppTheme.dividerColor,
                                  ),
                                  _buildProfileStat(
                                    context,
                                    value: '${user.streak}',
                                    label: 'Streak',
                                    color: AppTheme.audacityColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: AppTheme.spacingLg),

                      // Settings Sections
                      _buildSettingsSection(
                        context,
                        title: 'Preferences',
                        items: [
                          _SettingItem(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            subtitle: 'Daily reminder settings',
                            onTap: () => _showNotificationSettings(context),
                          ),
                          _SettingItem(
                            icon: Icons.timer_outlined,
                            title: 'Daily Time',
                            subtitle: '${user.profile?.dailyTimeMinutes ?? 10} minutes',
                            onTap: () => _showTimeSettings(context),
                          ),
                          _SettingItem(
                            icon: Icons.refresh_rounded,
                            title: 'Reset Streak',
                            subtitle: 'Start fresh',
                            onTap: () => _confirmResetStreak(context, ref),
                          ),
                        ],
                      ).animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: AppTheme.spacingMd),

                      _buildSettingsSection(
                        context,
                        title: 'About',
                        items: [
                          _SettingItem(
                            icon: Icons.info_outline_rounded,
                            title: 'About Easy Mode',
                            subtitle: 'Version 1.0.0',
                            onTap: () => _showAbout(context),
                          ),
                          _SettingItem(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            onTap: () {},
                          ),
                          _SettingItem(
                            icon: Icons.description_outlined,
                            title: 'Terms of Service',
                            onTap: () {},
                          ),
                        ],
                      ).animate()
                        .fadeIn(delay: 300.ms, duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: AppTheme.spacingMd),

                      _buildSettingsSection(
                        context,
                        title: 'Account',
                        items: [
                          _SettingItem(
                            icon: Icons.logout_rounded,
                            title: 'Sign Out',
                            textColor: AppTheme.textSecondary,
                            onTap: () => _confirmSignOut(context, ref),
                          ),
                          _SettingItem(
                            icon: Icons.delete_outline_rounded,
                            title: 'Delete Account',
                            textColor: AppTheme.errorColor,
                            onTap: () => _confirmDeleteAccount(context, ref),
                          ),
                        ],
                      ).animate()
                        .fadeIn(delay: 400.ms, duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),
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

  Widget _buildAvatarFallback(String? name) => Center(
    child: Text(
      (name ?? 'U')[0].toUpperCase(),
      style: const TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );

  Widget _buildProfileStat(
    BuildContext context, {
    required String value,
    required String label,
    required Color color,
  }) => Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<_SettingItem> items,
  }) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppTheme.spacingSm,
            bottom: AppTheme.spacingSm,
          ),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.textMuted,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: AppTheme.shadowSmall,
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: 4,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (item.textColor ?? AppTheme.primaryColor).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.icon,
                          color: item.textColor ?? AppTheme.primaryColor,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: item.textColor ?? AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: item.subtitle != null
                          ? Text(
                              item.subtitle!,
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          : null,
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textMuted,
                        size: 22,
                      ),
                      onTap: item.onTap,
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 70,
                      color: AppTheme.dividerColor,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Notification Settings',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            SwitchListTile(
              title: const Text('Daily Reminder'),
              subtitle: const Text('Get a nudge to complete your daily task'),
              value: true,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {},
            ),
            ListTile(
              title: const Text('Reminder Time'),
              subtitle: const Text('9:00 AM'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
            const SizedBox(height: AppTheme.spacingMd),
          ],
        ),
      ),
    );
  }

  void _showTimeSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Daily Time Commitment',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'How much time can you spare daily?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              children: [5, 10, 15, 20].map((mins) => ChoiceChip(
                  label: Text('$mins min'),
                  selected: mins == 10,
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: mins == 10 ? AppTheme.primaryColor : AppTheme.textSecondary,
                    fontWeight: mins == 10 ? FontWeight.w600 : FontWeight.normal,
                  ),
                  onSelected: (_) {},
                )).toList(),
            ),
            const SizedBox(height: AppTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  void _confirmResetStreak(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        title: const Text('Reset Streak?'),
        content: const Text(
          'This will reset your streak to 0. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Reset streak logic
              Navigator.pop(context);
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Easy Mode',
      applicationVersion: '1.0.0',
      applicationLegalese: '2024 Easy Mode. All rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text(
          'Your AI Life Coach for building confidence through Action, Audacity, and Enjoyment.',
        ),
      ],
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(authServiceProvider).signOut();
              Navigator.pop(context);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account and all associated data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(authServiceProvider).deleteAccount();
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? textColor;
  final VoidCallback onTap;

  _SettingItem({
    required this.icon,
    required this.title,
    required this.onTap, this.subtitle,
    this.textColor,
  });
}
