import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      appBar: AppBar(
        title: const Text('Audacity Scripts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search scripts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Category filters
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacingSm),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category ||
                    (category == 'All' && _selectedCategory == null);

                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category == 'All' ? null : category;
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppTheme.audacityColor.withOpacity(0.2),
                  checkmarkColor: AppTheme.audacityColor,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.audacityColor : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Scripts list
          Expanded(
            child: scriptsAsync.when(
              data: (scripts) {
                final filtered = _filterScripts(scripts);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppTheme.textMuted.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          'No scripts found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingMd),
                  itemBuilder: (context, index) {
                    final script = filtered[index];
                    return _buildScriptCard(script);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  List<ScriptModel> _filterScripts(List<ScriptModel> scripts) {
    return scripts.where((script) {
      final matchesSearch = _searchQuery.isEmpty ||
          script.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          script.template.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == null ||
          script.category.toLowerCase() == _selectedCategory!.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Widget _buildScriptCard(ScriptModel script) {
    final riskColor = _getRiskColor(script.riskLevel);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ScriptDetailScreen(script: script),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    script.riskLevel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    script.category,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 2),
                    Text(
                      '${script.estimatedMinutes}m',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              script.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              script.template,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              children: [
                Text(
                  '+200 XP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.audacityColor,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ],
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

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text('About Audacity Scripts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Audacity scripts are pre-written templates to help you ask boldly in various situations.',
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _buildRiskLegend('Low', AppTheme.actionColor, 'Easy asks with high success rate'),
            _buildRiskLegend('Medium', AppTheme.accentColor, 'Moderate challenge, moderate risk'),
            _buildRiskLegend('High', AppTheme.audacityColor, 'Bold asks, potentially big rewards'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskLegend(String label, Color color, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
}
