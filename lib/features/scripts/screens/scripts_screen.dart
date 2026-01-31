import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/script_model.dart';
import '../providers/scripts_provider.dart';
import 'script_detail_screen.dart';

/// Audacity Scripts library screen
class ScriptsScreen extends ConsumerStatefulWidget {
  const ScriptsScreen({super.key});

  @override
  ConsumerState<ScriptsScreen> createState() => _ScriptsScreenState();
}

class _ScriptsScreenState extends ConsumerState<ScriptsScreen> {
  String _searchQuery = '';
  String? _selectedCategory;

  final List<String> _categories = [
    'All',
    'Work',
    'Social',
    'Shopping',
    'Relationships',
    'Self-improvement',
  ];

  @override
  Widget build(BuildContext context) {
    final scriptsAsync = ref.watch(scriptsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
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
                'Audacity Scripts',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppTheme.shadowSmall,
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.audacityColor,
                      size: 20,
                    ),
                  ),
                  onPressed: _showInfoDialog,
                ),
              ),
            ],
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              child: Column(
                children: [
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      boxShadow: AppTheme.shadowSmall,
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search scripts...',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppTheme.textMuted,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: AppTheme.textMuted,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ).animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.1, end: 0),
                  
                  const SizedBox(height: AppTheme.spacingMd),
                  
                  // Category filters
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacingSm),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category ||
                            (category == 'All' && _selectedCategory == null);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category == 'All' ? null : category;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppTheme.audacityGradient : null,
                              color: isSelected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: AppTheme.audacityColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ] : AppTheme.shadowSmall,
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ).animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms),
                ],
              ),
            ),
          ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: AppTheme.spacingMd),
          ),

          // Scripts list
          scriptsAsync.when(
            data: (scripts) {
              final filtered = _filterScripts(scripts);

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.textMuted.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          'No scripts found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try a different search term',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(
                  left: AppTheme.spacingMd,
                  right: AppTheme.spacingMd,
                  bottom: 100, // Space for floating nav
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final script = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                        child: _buildScriptCard(script)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 200 + (index * 80)), duration: 400.ms)
                          .slideX(begin: 0.1, end: 0),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.audacityColor,
                ),
              ),
            ),
            error: (error, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  List<ScriptModel> _filterScripts(List<ScriptModel> scripts) => scripts.where((script) {
      final matchesSearch = _searchQuery.isEmpty ||
          script.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          script.template.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == null ||
          script.category.toLowerCase() == _selectedCategory!.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();

  Widget _buildScriptCard(ScriptModel script) {
    final riskColor = _getRiskColor(script.riskLevel);
    final riskGradient = _getRiskGradient(script.riskLevel);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ScriptDetailScreen(script: script),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: AppTheme.shadowSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: riskGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      script.riskLevel.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      script.category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: riskColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${script.estimatedMinutes}m',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: riskColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                script.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                script.template,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.audacityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 14,
                          color: AppTheme.audacityColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+200 XP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.audacityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: riskColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
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

  LinearGradient _getRiskGradient(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return AppTheme.actionGradient;
      case 'medium':
        return AppTheme.enjoyGradient;
      case 'high':
        return AppTheme.audacityGradient;
      default:
        return AppTheme.primaryGradient;
    }
  }

  void _showInfoDialog() {
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
                      gradient: AppTheme.audacityGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'About Audacity',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'Audacity scripts are pre-written templates to help you ask boldly in various situations.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              _buildRiskLegend('Low', AppTheme.actionColor, AppTheme.actionGradient, 'Easy asks with high success rate'),
              _buildRiskLegend('Medium', AppTheme.accentColor, AppTheme.enjoyGradient, 'Moderate challenge, moderate risk'),
              _buildRiskLegend('High', AppTheme.audacityColor, AppTheme.audacityGradient, 'Bold asks, potentially big rewards'),
              const SizedBox(height: AppTheme.spacingLg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.audacityColor,
                  ),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskLegend(String label, Color color, LinearGradient gradient, String description) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 20,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
}
