import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/task_model.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/constants/app_constants.dart';

/// Daily task card with timer and completion
class DailyTaskCard extends ConsumerStatefulWidget {
  final TaskModel task;
  final VoidCallback? onComplete;

  const DailyTaskCard({
    super.key,
    required this.task,
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
    int xpEarned = widget.task.xpReward;
    
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
                size: 48,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Great job!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'You earned $xpEarned XP',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Keep up the momentum!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFailureDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text('No worries!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Setbacks happen to everyone. Let's pick a simpler next step:",
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _buildResilienceOption(
              'Take 3 deep breaths',
              Icons.air,
            ),
            _buildResilienceOption(
              'Write down one thing you learned',
              Icons.edit_note,
            ),
            _buildResilienceOption(
              'Try a smaller version of this task',
              Icons.minimize,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe later'),
          ),
        ],
      ),
    );
  }

  Widget _buildResilienceOption(String text, IconData icon) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        // Could implement micro-task logging here
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(child: Text(text)),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final taskColor = AppTheme.getTaskTypeColor(widget.task.type);
    final taskIcon = AppTheme.getTaskTypeIcon(widget.task.type);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: taskColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with task type badge
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: taskColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusXLarge),
                topRight: Radius.circular(AppTheme.radiusXLarge),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: taskColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(taskIcon, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        widget.task.type.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '~${widget.task.estimatedMinutes} min',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
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
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  widget.task.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                
                // Timer display
                if (_isRunning || _elapsed > Duration.zero)
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _formatDuration(_elapsed),
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: taskColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          _isRunning ? 'Keep going!' : 'Paused',
                          style: Theme.of(context).textTheme.bodyMedium,
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
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.successColor,
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                          Text(
                            'Completed! +${widget.task.xpReward} XP',
                            style: const TextStyle(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _showFailureDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: const BorderSide(color: AppTheme.textMuted),
                          ),
                          child: const Text("I couldn't"),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isRunning ? _completeTask : _startTimer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: taskColor,
                          ),
                          child: Text(_isRunning ? 'I did it!' : 'Start Now'),
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
}
