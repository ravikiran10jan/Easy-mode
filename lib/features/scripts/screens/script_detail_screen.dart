import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/script_model.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/constants/app_constants.dart';

/// Script detail screen with practice and logging
class ScriptDetailScreen extends ConsumerStatefulWidget {
  final ScriptModel script;

  const ScriptDetailScreen({required this.script, super.key});

  @override
  ConsumerState<ScriptDetailScreen> createState() => _ScriptDetailScreenState();
}

class _ScriptDetailScreenState extends ConsumerState<ScriptDetailScreen> {
  late TextEditingController _templateController;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _templateController = TextEditingController(text: widget.script.template);
    // Track script view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).trackScriptView(widget.script.id, widget.script.riskLevel);
    });
  }

  @override
  void dispose() {
    _templateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _logAttempt(String outcome) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final analytics = ref.read(analyticsServiceProvider);

      // Calculate XP
      int xpEarned = AppConstants.xpAudacityAttempt;
      if (outcome == 'success') {
        xpEarned += AppConstants.xpAudacitySuccess;
      }

      // Log the attempt
      await firestoreService.logUserScript(user.uid, {
        'scriptId': widget.script.id,
        'attemptDate': DateTime.now().toIso8601String(),
        'outcome': outcome,
        'customText': _templateController.text,
        'notes': _notesController.text,
        'xpEarned': xpEarned,
      });

      // Update user XP
      await firestoreService.updateUserXp(user.uid, xpEarned);

      // Track script attempt analytics
      await analytics.trackScriptAttempt(
        widget.script.id,
        outcome,
        xpEarned,
        widget.script.riskLevel,
      );

      if (mounted) {
        _showResultDialog(outcome, xpEarned);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showResultDialog(String outcome, int xpEarned) {
    final isSuccess = outcome == 'success';
    
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
                color: isSuccess
                    ? AppTheme.successColor.withOpacity(0.1)
                    : AppTheme.audacityColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.celebration : Icons.military_tech,
                color: isSuccess ? AppTheme.successColor : AppTheme.audacityColor,
                size: 48,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              isSuccess ? 'Amazing!' : 'Brave move!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'You earned $xpEarned XP',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.audacityColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              isSuccess
                  ? 'Your audacity paid off!'
                  : 'The courage to try matters most. Keep pushing boundaries!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.audacityColor,
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Color get _riskColor {
    switch (widget.script.riskLevel.toLowerCase()) {
      case 'low':
        return AppTheme.actionColor;
      case 'medium':
        return AppTheme.accentColor;
      case 'high':
        return AppTheme.audacityColor;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Script Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: _riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: _riskColor,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.script.riskLevel.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _riskColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Chip(
                  label: Text(widget.script.category),
                  backgroundColor: AppTheme.textMuted.withOpacity(0.1),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // Title
            Text(
              widget.script.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // Editable template
            Text(
              'Your Script',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Edit the template to personalize it for your situation.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _templateController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Your script...',
              ),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // Tips
            if (widget.script.tips != null) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppTheme.accentColor,
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pro Tip',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(widget.script.tips!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
            ],

            // Example outcomes
            Text(
              'Possible Outcomes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ...widget.script.exampleOutcomes.map((outcome) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: AppTheme.actionColor,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(child: Text(outcome)),
                ],
              ),
            )),

            const SizedBox(height: AppTheme.spacingLg),

            // Notes
            Text(
              'Reflection Notes (optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'How did it go? What did you learn?',
              ),
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // Action buttons
            Text(
              'Log Your Attempt',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'How did it go? You earn XP just for trying!',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppTheme.spacingMd),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _logAttempt('success'),
                      icon: const Icon(Icons.celebration),
                      label: const Text('They said YES! (+300 XP)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _logAttempt('partial'),
                          child: const Text('Partial (+200 XP)'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(AppTheme.spacingMd),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _logAttempt('declined'),
                          child: const Text('Declined (+200 XP)'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(AppTheme.spacingMd),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
}
