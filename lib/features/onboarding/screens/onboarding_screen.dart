import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_providers.dart';
import '../providers/onboarding_provider.dart';

/// Onboarding screen with aspirations-first approach
/// Implements "Frame, Don't Change" strategy for hackathon judges
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const _stepNames = ['Welcome', 'Aspirations', 'Intent', 'Time'];

  // Onboarding data - new aspiration-based model
  final Set<String> _selectedAspirations = {};
  String? _selectedIntent;
  String? _customResolution;
  bool _hasResolution = false;
  int _selectedDailyTime = 10;

  // "What does Easy Mode feel like for you?"
  final List<Map<String, dynamic>> _aspirationOptions = [
    {
      'key': 'speak_up',
      'label': 'I speak up for what I want',
      'icon': Icons.record_voice_over_rounded,
    },
    {
      'key': 'take_action',
      'label': 'I take action without overthinking',
      'icon': Icons.flash_on_rounded,
    },
    {
      'key': 'find_joy',
      'label': 'I find joy in ordinary moments',
      'icon': Icons.favorite_rounded,
    },
    {
      'key': 'create_regularly',
      'label': 'I write/create regularly',
      'icon': Icons.edit_rounded,
    },
    {
      'key': 'move_body',
      'label': 'I move my body with ease',
      'icon': Icons.directions_run_rounded,
    },
    {
      'key': 'manage_time',
      'label': 'I manage my time without stress',
      'icon': Icons.schedule_rounded,
    },
  ];

  // "What brings you to Easy Mode?"
  final List<Map<String, dynamic>> _intentOptions = [
    {
      'key': 'feel_less_stuck',
      'label': 'I want to feel less stuck',
      'subtitle': 'Break through mental barriers',
    },
    {
      'key': 'be_bolder',
      'label': 'I want to be bolder in my asks',
      'subtitle': 'Speak up with confidence',
    },
    {
      'key': 'enjoy_more',
      'label': 'I want to enjoy life more',
      'subtitle': 'Find joy in the everyday',
    },
    {
      'key': 'resolution',
      'label': 'I have a New Year\'s resolution',
      'subtitle': 'Let\'s make it happen together',
      'isResolution': true,
    },
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
      if (_currentPage == 1) selection = {'aspirations': _selectedAspirations.toList()};
      if (_currentPage == 2) selection = {'intent': _selectedIntent, 'hasResolution': _hasResolution};
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
        return _selectedAspirations.isNotEmpty;
      case 2:
        // Intent page - must have intent selected, and if resolution path, must have text
        if (_selectedIntent == null) return false;
        if (_hasResolution && (_customResolution == null || _customResolution!.trim().isEmpty)) {
          return false;
        }
        return true;
      case 3:
        return true; // Time has default
      default:
        return false;
    }
  }

  Future<void> _completeOnboarding() async {
    if (_selectedAspirations.isEmpty || _selectedIntent == null) return;

    final profile = UserProfile(
      focusAreas: _selectedAspirations.toList(),
      intent: _hasResolution ? _customResolution : _selectedIntent,
      hasResolution: _hasResolution,
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
        'focusAreas': _selectedAspirations.toList(),
        'intent': _selectedIntent,
        'hasResolution': _hasResolution,
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
                  _buildAspirationsPage(),
                  _buildIntentPage(),
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
          
          // Bottom spacing to prevent cut-off
          const SizedBox(height: AppTheme.spacingXxl),
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

  Widget _buildAspirationsPage() => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What does Easy Mode feel like for you?',
            style: Theme.of(context).textTheme.headlineLarge,
          ).animate()
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.1, end: 0),
          
          const SizedBox(height: AppTheme.spacingSm),
          
          Text(
            'Select all that resonate with you',
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate()
            .fadeIn(delay: 100.ms, duration: 400.ms),
          
          const SizedBox(height: AppTheme.spacingLg),
          
          ...List.generate(_aspirationOptions.length, (index) {
            final option = _aspirationOptions[index];
            final key = option['key'] as String;
            final isSelected = _selectedAspirations.contains(key);
            
            return _buildAspirationCard(
              option['label'] as String,
              option['icon'] as IconData,
              isSelected,
              () => setState(() {
                if (isSelected) {
                  _selectedAspirations.remove(key);
                } else {
                  _selectedAspirations.add(key);
                }
              }),
            ).animate()
              .fadeIn(delay: Duration(milliseconds: 150 + (index * 80)), duration: 400.ms)
              .slideX(begin: 0.1, end: 0);
          }),
          
          const SizedBox(height: AppTheme.spacingMd),
          
          // Hint text
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text(
                    'We\'ll build that version of you—one small action at a time.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ).animate()
            .fadeIn(delay: 700.ms, duration: 400.ms),
        ],
      ),
    );

  Widget _buildAspirationCard(
    String text,
    IconData icon,
    bool isSelected,
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
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ] : AppTheme.shadowSmall,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    color: isSelected ? null : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isSelected ? Colors.white : AppTheme.textMuted,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );

  Widget _buildIntentPage() => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What brings you to Easy Mode?',
            style: Theme.of(context).textTheme.headlineLarge,
          ).animate()
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.1, end: 0),
          
          const SizedBox(height: AppTheme.spacingSm),
          
          Text(
            'No plans, no pressure. Just daily micro-shifts.',
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate()
            .fadeIn(delay: 100.ms, duration: 400.ms),
          
          const SizedBox(height: AppTheme.spacingLg),
          
          ...List.generate(_intentOptions.length, (index) {
            final option = _intentOptions[index];
            final key = option['key'] as String;
            final isSelected = _selectedIntent == key;
            final isResolutionOption = option['isResolution'] == true;
            
            return _buildIntentCard(
              option['label'] as String,
              option['subtitle'] as String,
              isSelected,
              isResolutionOption,
              () => setState(() {
                _selectedIntent = key;
                _hasResolution = isResolutionOption;
                if (!isResolutionOption) {
                  _customResolution = null;
                }
              }),
            ).animate()
              .fadeIn(delay: Duration(milliseconds: 150 + (index * 100)), duration: 400.ms)
              .slideX(begin: 0.1, end: 0);
          }),
          
          // Resolution text field (shown only when resolution is selected)
          if (_hasResolution) ...[
            const SizedBox(height: AppTheme.spacingMd),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What\'s your resolution?',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextField(
                    onChanged: (value) => setState(() => _customResolution = value),
                    decoration: InputDecoration(
                      hintText: 'e.g., Write 5 blog posts, Exercise 3x/week',
                      hintStyle: TextStyle(color: AppTheme.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide(color: AppTheme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide(color: AppTheme.accentColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingSm,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'We\'ll break that into small, low-pressure actions.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ).animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: -0.1, end: 0),
          ],
        ],
      ),
    );

  Widget _buildIntentCard(
    String label,
    String subtitle,
    bool isSelected,
    bool isResolutionOption,
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
              color: isSelected 
                  ? (isResolutionOption ? AppTheme.accentColor : AppTheme.secondaryColor).withOpacity(0.1) 
                  : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: isSelected 
                    ? (isResolutionOption ? AppTheme.accentColor : AppTheme.secondaryColor) 
                    : AppTheme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: (isResolutionOption ? AppTheme.accentColor : AppTheme.secondaryColor).withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ] : AppTheme.shadowSmall,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected 
                                  ? (isResolutionOption ? AppTheme.accentColor : AppTheme.secondaryColor) 
                                  : AppTheme.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                          if (isResolutionOption) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'optional',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected 
                        ? (isResolutionOption ? AppTheme.accentColor : AppTheme.secondaryColor) 
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected 
                          ? (isResolutionOption ? AppTheme.accentColor : AppTheme.secondaryColor) 
                          : AppTheme.textMuted,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
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
