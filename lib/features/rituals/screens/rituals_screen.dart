import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      backgroundColor: AppTheme.backgroundColor,
      body: ritualsAsync.when(
        data: (rituals) => CustomScrollView(
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
                  'Joy Rituals',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.enjoyColor.withOpacity(0.15),
                            AppTheme.accentColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                        border: Border.all(
                          color: AppTheme.enjoyColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: AppTheme.enjoyGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.enjoyColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Romanticize Your Life',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
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
                    ).animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: -0.1, end: 0),

                    const SizedBox(height: AppTheme.spacingLg),

                    // Today's ritual selection
                    Text(
                      "Today's Joy Ritual",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
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
                        childAspectRatio: 0.9,
                        crossAxisSpacing: AppTheme.spacingMd,
                        mainAxisSpacing: AppTheme.spacingMd,
                      ),
                      itemCount: rituals.length,
                      itemBuilder: (context, index) {
                        final ritual = rituals[index];
                        final isSelected = _selectedRitual?.id == ritual.id;

                        return _buildRitualCard(ritual, isSelected)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 200 + (index * 100)), duration: 400.ms)
                          .scale(
                            begin: const Offset(0.95, 0.95),
                            end: const Offset(1, 1),
                          );
                      },
                    ),

                    if (_selectedRitual != null) ...[
                      const SizedBox(height: AppTheme.spacingXl),
                      _buildSelectedRitualDetail()
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.enjoyColor,
          ),
        ),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildRitualCard(RitualModel ritual, bool isSelected) {
    final iconData = _getIconForRitual(ritual.iconName);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRitual = isSelected ? null : ritual;
        });
        // Track ritual view when selected
        if (!isSelected) {
          ref.read(analyticsServiceProvider).trackRitualView(ritual.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected ? AppTheme.enjoyColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? AppTheme.shadowColored(AppTheme.enjoyColor)
              : AppTheme.shadowSmall,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.enjoyGradient : null,
                color: isSelected ? null : AppTheme.textMuted.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppTheme.enjoyColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Icon(
                iconData,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                size: 32,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              ritual.title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isSelected ? AppTheme.enjoyColor : AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.enjoyColor.withOpacity(0.1)
                    : AppTheme.textMuted.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: isSelected ? AppTheme.enjoyColor : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ritual.estimatedMinutes} min',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppTheme.enjoyColor : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
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
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: AppTheme.shadowColored(AppTheme.enjoyColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.enjoyGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getIconForRitual(_selectedRitual!.iconName),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Text(
                  _selectedRitual!.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.enjoyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+100 XP',
                  style: TextStyle(
                    color: AppTheme.enjoyColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMd),

          Text(
            _selectedRitual!.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),

          const SizedBox(height: AppTheme.spacingLg),

          Text(
            'Steps',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          ...List.generate(_selectedRitual!.steps.length, (index) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: AppTheme.enjoyGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _selectedRitual!.steps[index],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ),
            )),

          const SizedBox(height: AppTheme.spacingSm),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppTheme.enjoyGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.enjoyColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _completeRitual,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Complete Ritual'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
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
    final analytics = ref.read(analyticsServiceProvider);

    // Log the ritual completion
    await firestoreService.logUserRitual(user.uid, {
      'ritualId': _selectedRitual!.id,
      'date': DateTime.now().toIso8601String(),
      'completed': true,
    });

    // Update user XP
    await firestoreService.updateUserXp(user.uid, 100);

    // Track ritual completion analytics
    await analytics.trackRitualComplete(_selectedRitual!.id, 100);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ritual complete! +100 XP',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppTheme.enjoyColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  IconData _getIconForRitual(String? iconName) {
    switch (iconName) {
      case 'music':
        return Icons.music_note_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      case 'walk':
        return Icons.directions_walk_rounded;
      case 'sun':
        return Icons.wb_sunny_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      case 'plant':
        return Icons.local_florist_rounded;
      case 'candle':
        return Icons.local_fire_department_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'heart':
        return Icons.favorite_rounded;
      case 'photo':
        return Icons.photo_camera_rounded;
      default:
        return Icons.favorite_rounded;
    }
  }
}
