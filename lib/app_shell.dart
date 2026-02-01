import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_providers.dart';
import 'features/home/screens/home_screen.dart';
import 'features/actions/screens/actions_screen.dart';
import 'features/scripts/screens/scripts_screen.dart';
import 'features/rituals/screens/rituals_screen.dart';
import 'features/progress/screens/progress_screen.dart';
import 'features/profile/screens/profile_screen.dart';

/// Main navigation index provider
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// App shell with bottom navigation
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  static const _screenNames = ['Home', 'Actions', 'Audacity', 'Rituals', 'Progress', 'Profile'];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start session and track initial screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = ref.read(analyticsServiceProvider);
      analytics.startSession();
      analytics.trackScreenView('Home');
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final analytics = ref.read(analyticsServiceProvider);
    if (state == AppLifecycleState.paused) {
      analytics.endSession();
    } else if (state == AppLifecycleState.resumed) {
      analytics.startSession();
    }
  }
  
  void _onNavTap(int index) {
    ref.read(navigationIndexProvider.notifier).state = index;
    ref.read(analyticsServiceProvider).trackScreenView(_screenNames[index]);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationIndexProvider);

    final screens = [
      const HomeScreen(),
      const ActionsScreen(),
      const ScriptsScreen(),
      const RitualsScreen(),
      const ProgressScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  currentIndex: currentIndex,
                  onTap: () => _onNavTap(0),
                ),
                _NavItem(
                  index: 1,
                  icon: Icons.bolt_outlined,
                  activeIcon: Icons.bolt_rounded,
                  label: 'Action',
                  currentIndex: currentIndex,
                  color: AppTheme.actionColor,
                  onTap: () => _onNavTap(1),
                ),
                _NavItem(
                  index: 2,
                  icon: Icons.local_fire_department_outlined,
                  activeIcon: Icons.local_fire_department_rounded,
                  label: 'Audacity',
                  currentIndex: currentIndex,
                  color: AppTheme.audacityColor,
                  onTap: () => _onNavTap(2),
                ),
                _NavItem(
                  index: 3,
                  icon: Icons.favorite_outline,
                  activeIcon: Icons.favorite_rounded,
                  label: 'Enjoy',
                  currentIndex: currentIndex,
                  color: AppTheme.enjoyColor,
                  onTap: () => _onNavTap(3),
                ),
                _NavItem(
                  index: 4,
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart_rounded,
                  label: 'Progress',
                  currentIndex: currentIndex,
                  onTap: () => _onNavTap(4),
                ),
                _NavItem(
                  index: 5,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  currentIndex: currentIndex,
                  onTap: () => _onNavTap(5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int currentIndex;
  final Color? color;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.currentIndex,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    final activeColor = color ?? AppTheme.primaryColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeColor : AppTheme.textMuted,
              size: 22,
            ).animate(target: isActive ? 1 : 0)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: 200.ms,
              ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: activeColor,
                ),
              ).animate()
                .fadeIn(duration: 200.ms)
                .slideX(begin: -0.2, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}
