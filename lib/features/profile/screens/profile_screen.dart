import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_providers.dart';

/// Profile and Settings screen
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(currentUserDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: userData.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No user data'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                (user.name ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              )
                            : null,
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
                      const SizedBox(height: AppTheme.spacingMd),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildProfileStat(
                            context,
                            value: '${user.level}',
                            label: 'Level',
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: AppTheme.textMuted.withOpacity(0.3),
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingLg,
                            ),
                          ),
                          _buildProfileStat(
                            context,
                            value: '${user.xpTotal}',
                            label: 'Total XP',
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: AppTheme.textMuted.withOpacity(0.3),
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingLg,
                            ),
                          ),
                          _buildProfileStat(
                            context,
                            value: '${user.streak}',
                            label: 'Streak',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

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
                      icon: Icons.refresh,
                      title: 'Reset Streak',
                      subtitle: 'Start fresh',
                      onTap: () => _confirmResetStreak(context, ref),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingMd),

                _buildSettingsSection(
                  context,
                  title: 'About',
                  items: [
                    _SettingItem(
                      icon: Icons.info_outline,
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
                ),

                const SizedBox(height: AppTheme.spacingMd),

                _buildSettingsSection(
                  context,
                  title: 'Account',
                  items: [
                    _SettingItem(
                      icon: Icons.logout,
                      title: 'Sign Out',
                      textColor: AppTheme.textSecondary,
                      onTap: () => _confirmSignOut(context, ref),
                    ),
                    _SettingItem(
                      icon: Icons.delete_outline,
                      title: 'Delete Account',
                      textColor: AppTheme.errorColor,
                      onTap: () => _confirmDeleteAccount(context, ref),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingXl),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildProfileStat(
    BuildContext context, {
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<_SettingItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppTheme.spacingSm,
            bottom: AppTheme.spacingSm,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Container(
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
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  ListTile(
                    leading: Icon(
                      item.icon,
                      color: item.textColor ?? AppTheme.textPrimary,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color: item.textColor ?? AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: item.subtitle != null
                        ? Text(item.subtitle!)
                        : null,
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppTheme.textMuted,
                    ),
                    onTap: item.onTap,
                  ),
                  if (!isLast)
                    const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            SwitchListTile(
              title: const Text('Daily Reminder'),
              subtitle: const Text('Get a nudge to complete your daily task'),
              value: true,
              onChanged: (value) {},
            ),
            ListTile(
              title: const Text('Reminder Time'),
              subtitle: const Text('9:00 AM'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Time Commitment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            const Text('How much time can you spare daily?'),
            const SizedBox(height: AppTheme.spacingMd),
            Wrap(
              spacing: AppTheme.spacingSm,
              children: [5, 10, 15, 20].map((mins) {
                return ChoiceChip(
                  label: Text('$mins min'),
                  selected: mins == 10,
                  onSelected: (_) {},
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmResetStreak(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
    this.subtitle,
    this.textColor,
    required this.onTap,
  });
}
