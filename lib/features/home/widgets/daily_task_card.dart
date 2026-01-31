import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/task_model.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/ai_service.dart';

/// Daily task card with timer, completion, and AI personalization
class DailyTaskCard extends ConsumerStatefulWidget {
  final TaskModel task;
  final VoidCallback? onComplete;

  const DailyTaskCard({
    required this.task, super.key,
    this.onComplete,
  });

  @override
  ConsumerState<DailyTaskCard> createState() => _DailyTaskCardState();
}

class _DailyTaskCardState extends ConsumerState<DailyTaskCard> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isRunning = false;
  bool _isCompleted = false;
  
  // AI personalization state
  PersonalizedTaskResponse? _personalization;
  bool _isLoadingPersonalization = false;

  @override
  void initState() {
    super.initState();
    _loadPersonalization();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPersonalization() async {
    final userData = ref.read(currentUserDataProvider).value;
    if (userData == null) return;

    setState(() {
      _isLoadingPersonalization = true;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final result = await aiService.personalizeTask(
        task: widget.task,
        user: userData,
      );
      
      if (mounted) {
        setState(() {
          _personalization = result;
          _isLoadingPersonalization = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPersonalization = false;
        });
      }
    }
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _completeTask() async {
    _stopTimer();
    
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    final firestoreService = ref.read(firestoreServiceProvider);
    
    // Calculate XP
    final int xpEarned = widget.task.xpReward;
    
    // Log the task completion
    await firestoreService.logUserTask(user.uid, {
      'taskId': widget.task.id,
      'type': widget.task.type,
      'date': DateTime.now().toIso8601String(),
      'completed': true,
      'xpEarned': xpEarned,
      'duration': _elapsed.inSeconds,
      'completedAt': DateTime.now().toIso8601String(),
    });
    
    // Update user XP
    await firestoreService.updateUserXp(user.uid, xpEarned);
    
    // Log analytics
    await firestoreService.logAnalyticsEvent('daily_task_completed', {
      'taskType': widget.task.type,
      'xpEarned': xpEarned,
      'duration': _elapsed.inSeconds,
    });
    
    setState(() {
      _isCompleted = true;
    });
    
    widget.onComplete?.call();
    
    // Show completion dialog
    if (mounted) {
      _showCompletionDialog(xpEarned);
    }
  }

  void _showCompletionDialog(int xpEarned) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.successColor.withOpacity(0.2),
                      AppTheme.successColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: AppTheme.successColor,
                  size: 48,
                ),
              ).animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                'Awesome Work!',
                style: Theme.of(context).textTheme.headlineMedium,
              ).animate()
                .fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: AppTheme.spacingSm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                ),
                child: Text(
                  '+$xpEarned XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ).animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'Keep building momentum!',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ).animate()
                .fadeIn(delay: 400.ms, duration: 400.ms),
              const SizedBox(height: AppTheme.spacingLg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Continue'),
                ),
              ).animate()
                .fadeIn(delay: 500.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  void _showFailureDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.sentiment_satisfied_alt_rounded,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No Worries!',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                "Setbacks happen to everyone. Let's pick a simpler next step:",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _buildResilienceOption(
                'Take 3 deep breaths',
                Icons.air_rounded,
                AppTheme.actionColor,
              ),
              _buildResilienceOption(
                'Write down one thing you learned',
                Icons.edit_note_rounded,
                AppTheme.primaryColor,
              ),
              _buildResilienceOption(
                'Try a smaller version of this task',
                Icons.crop_rounded,
                AppTheme.secondaryColor,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("I'll try again later"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResilienceOption(String text, IconData icon, Color color) => InkWell(
      onTap: () {
        Navigator.of(context).pop();
        // Could implement micro-task logging here
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final taskColor = AppTheme.getTaskTypeColor(widget.task.type);
    final taskGradient = AppTheme.getTaskTypeGradient(widget.task.type);
    final taskIcon = AppTheme.getTaskTypeIcon(widget.task.type);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: AppTheme.shadowColored(taskColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with task type badge
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  taskColor.withOpacity(0.15),
                  taskColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusXLarge),
                topRight: Radius.circular(AppTheme.radiusXLarge),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: taskGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                    boxShadow: [
                      BoxShadow(
                        color: taskColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(taskIcon, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        widget.task.type.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: taskColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '~${widget.task.estimatedMinutes} min',
                        style: TextStyle(
                          color: taskColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                
                // Show personalized description or original
                if (_isLoadingPersonalization)
                  _buildPersonalizationLoader(taskColor)
                else
                  Text(
                    _personalization?.personalizedDescription ?? widget.task.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                
                // AI Coach Tip
                if (_personalization != null && _personalization!.coachTip.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildCoachTip(taskColor),
                ],
                
                const SizedBox(height: AppTheme.spacingLg),
                
                // Timer display
                if (_isRunning || _elapsed > Duration.zero)
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: taskColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                          ),
                          child: Text(
                            _formatDuration(_elapsed),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: taskColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ).animate(target: _isRunning ? 1 : 0)
                          .shimmer(
                            duration: 2000.ms,
                            color: taskColor.withOpacity(0.3),
                          ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isRunning ? AppTheme.successColor : AppTheme.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ).animate(
                              target: _isRunning ? 1 : 0,
                              onPlay: (controller) => controller.repeat(reverse: true),
                            ).scaleXY(end: 1.3, duration: 800.ms),
                            const SizedBox(width: 8),
                            Text(
                              _isRunning ? 'In Progress' : 'Paused',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _isRunning ? AppTheme.successColor : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: AppTheme.spacingLg),
                
                // Action buttons
                if (_isCompleted)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLg,
                        vertical: AppTheme.spacingMd,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.successColor.withOpacity(0.15),
                            AppTheme.successColor.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        border: Border.all(
                          color: AppTheme.successColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                          Text(
                            'Completed! +${widget.task.xpReward} XP',
                            style: const TextStyle(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ).animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _showFailureDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: BorderSide(
                              color: AppTheme.dividerColor,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                          ),
                          child: const Text(
                            "I couldn't",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: taskGradient,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            boxShadow: [
                              BoxShadow(
                                color: taskColor.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isRunning ? _completeTask : _startTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isRunning ? Icons.check_circle_outline_rounded : Icons.play_arrow_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isRunning ? 'I did it!' : 'Start Now',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizationLoader(Color taskColor) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: taskColor.withOpacity(0.5),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Personalizing for you...',
          style: TextStyle(
            color: taskColor.withOpacity(0.7),
            fontStyle: FontStyle.italic,
            fontSize: 14,
          ),
        ),
      ],
    ),
  ).animate()
    .fadeIn(duration: 300.ms);

  Widget _buildCoachTip(Color taskColor) => Container(
    padding: const EdgeInsets.all(AppTheme.spacingMd),
    decoration: BoxDecoration(
      color: taskColor.withOpacity(0.08),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      border: Border.all(
        color: taskColor.withOpacity(0.15),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: taskColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.auto_awesome,
            color: taskColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Coach Tip',
                style: TextStyle(
                  color: taskColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _personalization!.coachTip,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ).animate()
    .fadeIn(duration: 400.ms)
    .slideY(begin: 0.1, end: 0);
}
