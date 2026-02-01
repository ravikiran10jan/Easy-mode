import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_providers.dart';
import '../providers/onboarding_provider.dart';

/// Onboarding screen with swipeable quiz
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const _stepNames = ['Welcome', 'Challenge', 'Goal', 'Time'];

  // Onboarding data
  String? _selectedPain;
  String? _selectedGoal;
  int _selectedDailyTime = 10;

  final List<String> _painOptions = [
    'I struggle to ask for what I want',
    'I procrastinate on important tasks',
    'I feel stuck after setbacks',
    'I don\'t enjoy daily moments',
  ];

  final List<String> _goalOptions = [
    'Be more assertive and confident',
    'Take consistent action daily',
    'Bounce back from failures faster',
    'Find more joy in everyday life',
  ];

  final List<int> _timeOptions = [5, 10, 15, 20];

  @override
  void initState() {
    super.initState();
    // Track initial onboarding step view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).trackOnboardingStepView(0, _stepNames[0]);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      // Track step completion before moving
      final analytics = ref.read(analyticsServiceProvider);
      Map<String, dynamic>? selection;
      if (_currentPage == 1) selection = {'pain': _selectedPain};
      if (_currentPage == 2) selection = {'goal': _selectedGoal};
      analytics.trackOnboardingStepComplete(_currentPage, _stepNames[_currentPage], selection);
      
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return true; // Welcome page
      case 1:
        return _selectedPain != null;
      case 2:
        return _selectedGoal != null;
      case 3:
        return true; // Time has default
      default:
        return false;
    }
  }

  Future<void> _completeOnboarding() async {
    if (_selectedPain == null || _selectedGoal == null) return;

    final profile = UserProfile(
      pain: _selectedPain!,
      goal: _selectedGoal!,
      dailyTimeMinutes: _selectedDailyTime,
      createdAt: DateTime.now(),
    );

    final user = ref.read(currentUserProvider);
    if (user != null) {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateUserProfile(user.uid, profile);
      
      // Track final step completion and onboarding complete
      final analytics = ref.read(analyticsServiceProvider);
      await analytics.trackOnboardingStepComplete(3, _stepNames[3], {'dailyTime': _selectedDailyTime});
      await analytics.trackOnboardingComplete({
        'pain': _selectedPain,
        'goal': _selectedGoal,
        'dailyTime': _selectedDailyTime,
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Row(
                children: List.generate(4, (index) {
                  final isActive = index <= _currentPage;
                  final isCompleted = index < _currentPage;
                  
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        gradient: isActive ? AppTheme.primaryGradient : null,
                        color: isActive ? null : AppTheme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: isCompleted ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ] : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  // Track step view
                  ref.read(analyticsServiceProvider).trackOnboardingStepView(index, _stepNames[index]);
                },
                children: [
                  _buildWelcomePage(),
                  _buildPainPage(),
                  _buildGoalPage(),
                  _buildTimePage(),
                ],
              ),
            ),
            
            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      TextButton.icon(
                        onPressed: _previousPage,
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Back'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                        ),
                      )
                    else
                      const SizedBox(width: 80),
                    
                    const Spacer(),
                    
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: _canProceed() ? AppTheme.primaryGradient : null,
                        color: _canProceed() ? null : AppTheme.dividerColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        boxShadow: _canProceed() ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ] : null,
                      ),
                      child: ElevatedButton(
                        onPressed: _canProceed()
                            ? (_currentPage == 3 ? _completeOnboarding : _nextPage)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPage == 3 ? 'Get Started' : 'Continue',
                              style: TextStyle(
                                color: _canProceed() ? Colors.white : AppTheme.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_currentPage < 3) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: _canProceed() ? Colors.white : AppTheme.textMuted,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildWelcomePage() => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppTheme.spacingXl),
          
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(40),
              boxShadow: AppTheme.shadowColored(AppTheme.primaryColor),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              size: 72,
              color: Colors.white,
            ),
          ).animate()
            .fadeIn(duration: 600.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              curve: Curves.easeOutBack,
            ),
          
          const SizedBox(height: AppTheme.spacingXl),
          
          Text(
            'Welcome to Easy Mode',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ).animate()
            .fadeIn(delay: 200.ms, duration: 500.ms)
            .slideY(begin: 0.2, end: 0),
          
          const SizedBox(height: AppTheme.spacingMd),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: Text(
              'Your AI life coach for building confidence through action, audacity, and enjoyment.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate()
            .fadeIn(delay: 300.ms, duration: 500.ms),
          
          const SizedBox(height: AppTheme.spacingXxl),
          
          // Three principles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPrincipleChip(
                'Action',
                AppTheme.actionColor,
                AppTheme.actionGradient,
                Icons.flash_on_rounded,
              ).animate()
                .fadeIn(delay: 400.ms, duration: 400.ms)
                .slideY(begin: 0.3, end: 0),
              _buildPrincipleChip(
                'Audacity',
                AppTheme.audacityColor,
                AppTheme.audacityGradient,
                Icons.local_fire_department_rounded,
              ).animate()
                .fadeIn(delay: 500.ms, duration: 400.ms)
                .slideY(begin: 0.3, end: 0),
              _buildPrincipleChip(
                'Enjoy',
                AppTheme.enjoyColor,
                AppTheme.enjoyGradient,
                Icons.favorite_rounded,
              ).animate()
                .fadeIn(delay: 600.ms, duration: 400.ms)
                .slideY(begin: 0.3, end: 0),
            ],
          ),
        ],
      ),
    );

  Widget _buildPrincipleChip(
    String label,
    Color color,
    LinearGradient gradient,
    IconData icon,
  ) => Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 14,
          ),
        ),
      ],
    );

  Widget _buildPainPage() => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s your biggest challenge?',
            style: Theme.of(context).textTheme.headlineLarge,
          ).animate()
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.1, end: 0),
          
          const SizedBox(height: AppTheme.spacingSm),
          
          Text(
            'This helps us personalize your experience',
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate()
            .fadeIn(delay: 100.ms, duration: 400.ms),
          
          const SizedBox(height: AppTheme.spacingLg),
          
          ...List.generate(_painOptions.length, (index) {
            final option = _painOptions[index];
            final isSelected = _selectedPain == option;
            
            return _buildOptionCard(
              option,
              isSelected,
              AppTheme.primaryColor,
              () => setState(() => _selectedPain = option),
            ).animate()
              .fadeIn(delay: Duration(milliseconds: 150 + (index * 100)), duration: 400.ms)
              .slideX(begin: 0.1, end: 0);
          }),
        ],
      ),
    );

  Widget _buildGoalPage() => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you want to achieve?',
            style: Theme.of(context).textTheme.headlineLarge,
          ).animate()
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.1, end: 0),
          
          const SizedBox(height: AppTheme.spacingSm),
          
          Text(
            'Pick your primary goal',
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate()
            .fadeIn(delay: 100.ms, duration: 400.ms),
          
          const SizedBox(height: AppTheme.spacingLg),
          
          ...List.generate(_goalOptions.length, (index) {
            final option = _goalOptions[index];
            final isSelected = _selectedGoal == option;
            
            return _buildOptionCard(
              option,
              isSelected,
              AppTheme.secondaryColor,
              () => setState(() => _selectedGoal = option),
            ).animate()
              .fadeIn(delay: Duration(milliseconds: 150 + (index * 100)), duration: 400.ms)
              .slideX(begin: 0.1, end: 0);
          }),
        ],
      ),
    );

  Widget _buildOptionCard(
    String text,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) => Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: isSelected ? color : AppTheme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ] : AppTheme.shadowSmall,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? color : AppTheme.textMuted,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? color : AppTheme.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

  Widget _buildTimePage() => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How much time can you spare daily?',
            style: Theme.of(context).textTheme.headlineLarge,
          ).animate()
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.1, end: 0),
          
          const SizedBox(height: AppTheme.spacingSm),
          
          Text(
            'Even 5 minutes can make a difference',
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate()
            .fadeIn(delay: 100.ms, duration: 400.ms),
          
          const SizedBox(height: AppTheme.spacingXl),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _timeOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final time = entry.value;
              final isSelected = _selectedDailyTime == time;
              
              return _buildTimeOption(time, isSelected)
                .animate()
                .fadeIn(delay: Duration(milliseconds: 200 + (index * 100)), duration: 400.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                );
            }).toList(),
          ),
          
          const SizedBox(height: AppTheme.spacingXl),
          
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppTheme.accentColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_rounded,
                    color: AppTheme.accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text(
                    'You can always adjust this later in settings.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ).animate()
            .fadeIn(delay: 600.ms, duration: 400.ms),
        ],
      ),
    );

  Widget _buildTimeOption(int time, bool isSelected) => GestureDetector(
      onTap: () {
        setState(() {
          _selectedDailyTime = time;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 76,
        height: 90,
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: isSelected
              ? null
              : Border.all(color: AppTheme.dividerColor),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ] : AppTheme.shadowSmall,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$time',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            Text(
              'min',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white.withOpacity(0.9)
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
}
