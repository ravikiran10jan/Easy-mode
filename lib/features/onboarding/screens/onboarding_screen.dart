import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
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
      
      // Log analytics event
      await firestoreService.logAnalyticsEvent('onboarding_complete', {
        'pain': _selectedPain,
        'goal': _selectedGoal,
        'dailyTime': _selectedDailyTime,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? AppTheme.primaryColor
                            : AppTheme.textMuted.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
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
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 80),
                  
                  const Spacer(),
                  
                  ElevatedButton(
                    onPressed: _canProceed()
                        ? (_currentPage == 3 ? _completeOnboarding : _nextPage)
                        : null,
                    child: Text(_currentPage == 3 ? 'Get Started' : 'Continue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              size: 64,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingXl),
          
          Text(
            'Welcome to Easy Mode',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppTheme.spacingMd),
          
          Text(
            'Your AI life coach for building confidence through action, audacity, and enjoyment.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppTheme.spacingXl),
          
          // Three principles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPrincipleChip('Action', AppTheme.actionColor, Icons.flash_on),
              _buildPrincipleChip('Audacity', AppTheme.audacityColor, Icons.local_fire_department),
              _buildPrincipleChip('Enjoy', AppTheme.enjoyColor, Icons.favorite),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrincipleChip(String label, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPainPage() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacingLg),
          
          Text(
            'What\'s your biggest challenge?',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          
          const SizedBox(height: AppTheme.spacingSm),
          
          Text(
            'This helps us personalize your experience',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          
          const SizedBox(height: AppTheme.spacingXl),
          
          ...List.generate(_painOptions.length, (index) {
            final option = _painOptions[index];
            final isSelected = _selectedPain == option;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedPain = option;
                  });
                },
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textMuted.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textMuted,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGoalPage() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacingLg),
          
          Text(
            'What do you want to achieve?',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          
          const SizedBox(height: AppTheme.spacingSm),
          
          Text(
            'Pick your primary goal',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          
          const SizedBox(height: AppTheme.spacingXl),
          
          ...List.generate(_goalOptions.length, (index) {
            final option = _goalOptions[index];
            final isSelected = _selectedGoal == option;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedGoal = option;
                  });
                },
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.secondaryColor.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.secondaryColor
                          : AppTheme.textMuted.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppTheme.secondaryColor
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.secondaryColor
                                : AppTheme.textMuted,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.secondaryColor
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimePage() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacingLg),
          
          Text(
            'How much time can you spare daily?',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          
          const SizedBox(height: AppTheme.spacingSm),
          
          Text(
            'Even 5 minutes can make a difference',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          
          const SizedBox(height: AppTheme.spacingXl),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _timeOptions.map((time) {
              final isSelected = _selectedDailyTime == time;
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDailyTime = time;
                  });
                },
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: AppTheme.textMuted.withOpacity(0.3),
                          ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$time',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'min',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: AppTheme.spacingXl),
          
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text(
                    'You can always adjust this later in settings.',
                    style: TextStyle(
                      color: AppTheme.accentColor.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
