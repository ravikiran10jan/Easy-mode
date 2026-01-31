import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/ritual_model.dart';
import '../../../core/providers/auth_providers.dart';
import '../providers/rituals_provider.dart';

/// Enjoyment Rituals screen
class RitualsScreen extends ConsumerStatefulWidget {
  const RitualsScreen({super.key});

  @override
  ConsumerState<RitualsScreen> createState() => _RitualsScreenState();
}

class _RitualsScreenState extends ConsumerState<RitualsScreen> {
  RitualModel? _selectedRitual;

  @override
  Widget build(BuildContext context) {
    final ritualsAsync = ref.watch(ritualsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Joy Rituals'),
      ),
      body: ritualsAsync.when(
        data: (rituals) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.enjoyColor.withOpacity(0.1),
                      AppTheme.accentColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AppTheme.enjoyColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: AppTheme.enjoyColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Romanticize Your Life',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Small rituals that bring joy to everyday moments.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // Today's ritual selection
              Text(
                "Today's Joy Ritual",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Pick one ritual to brighten your day',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Rituals grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: AppTheme.spacingMd,
                  mainAxisSpacing: AppTheme.spacingMd,
                ),
                itemCount: rituals.length,
                itemBuilder: (context, index) {
                  final ritual = rituals[index];
                  final isSelected = _selectedRitual?.id == ritual.id;

                  return _buildRitualCard(ritual, isSelected);
                },
              ),

              if (_selectedRitual != null) ...[
                const SizedBox(height: AppTheme.spacingXl),
                _buildSelectedRitualDetail(),
              ],
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildRitualCard(RitualModel ritual, bool isSelected) {
    final iconData = _getIconForRitual(ritual.iconName);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRitual = isSelected ? null : ritual;
        });
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.enjoyColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? AppTheme.enjoyColor : AppTheme.textMuted.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.enjoyColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.enjoyColor.withOpacity(0.2)
                    : AppTheme.textMuted.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: isSelected ? AppTheme.enjoyColor : AppTheme.textSecondary,
                size: 32,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              ritual.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.enjoyColor : AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${ritual.estimatedMinutes} min',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedRitualDetail() {
    if (_selectedRitual == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.enjoyColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: AppTheme.enjoyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  _getIconForRitual(_selectedRitual!.iconName),
                  color: AppTheme.enjoyColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Text(
                  _selectedRitual!.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMd),

          Text(
            _selectedRitual!.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: AppTheme.spacingLg),

          Text(
            'Steps',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),

          ...List.generate(_selectedRitual!.steps.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.enjoyColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: AppTheme.enjoyColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(_selectedRitual!.steps[index]),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: AppTheme.spacingLg),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _completeRitual(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.enjoyColor,
                padding: const EdgeInsets.all(AppTheme.spacingMd),
              ),
              child: const Text('Complete Ritual (+100 XP)'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeRitual() async {
    if (_selectedRitual == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final firestoreService = ref.read(firestoreServiceProvider);

    // Log the ritual completion
    await firestoreService.logUserRitual(user.uid, {
      'ritualId': _selectedRitual!.id,
      'date': DateTime.now().toIso8601String(),
      'completed': true,
    });

    // Update user XP
    await firestoreService.updateUserXp(user.uid, 100);

    // Log analytics
    await firestoreService.logAnalyticsEvent('ritual_completed', {
      'ritualId': _selectedRitual!.id,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.celebration, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Ritual complete! +100 XP'),
            ],
          ),
          backgroundColor: AppTheme.enjoyColor,
        ),
      );
    }
  }

  IconData _getIconForRitual(String? iconName) {
    switch (iconName) {
      case 'music':
        return Icons.music_note;
      case 'coffee':
        return Icons.coffee;
      case 'walk':
        return Icons.directions_walk;
      case 'sun':
        return Icons.wb_sunny;
      case 'book':
        return Icons.book;
      case 'plant':
        return Icons.local_florist;
      case 'candle':
        return Icons.local_fire_department;
      case 'star':
        return Icons.star;
      case 'heart':
        return Icons.favorite;
      case 'photo':
        return Icons.photo_camera;
      default:
        return Icons.favorite;
    }
  }
}
