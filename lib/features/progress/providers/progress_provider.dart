import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_providers.dart';

/// Provider for user statistics
final userStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return {
      'actionsCompleted': 0,
      'audacityAttempts': 0,
      'ritualsCompleted': 0,
      'activeDays': 0,
    };
  }

  final firestoreService = ref.watch(firestoreServiceProvider);

  // Get user tasks
  final tasks = await firestoreService.getUserTasks(user.uid);
  
  // Count by type
  int actionsCompleted = 0;
  int audacityAttempts = 0;
  int ritualsCompleted = 0;
  final Set<String> activeDays = {};

  for (final task in tasks) {
    if (task['completed'] == true) {
      final type = task['type'] as String?;
      final date = task['date'] as String?;
      
      if (date != null) {
        activeDays.add(date.substring(0, 10)); // Just the date part
      }
      
      switch (type) {
        case 'action':
          actionsCompleted++;
          break;
        case 'audacity':
          audacityAttempts++;
          break;
        case 'enjoy':
          ritualsCompleted++;
          break;
      }
    }
  }

  return {
    'actionsCompleted': actionsCompleted,
    'audacityAttempts': audacityAttempts,
    'ritualsCompleted': ritualsCompleted,
    'activeDays': activeDays.length,
  };
});

/// Provider for user badges
final userBadgesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final firestoreService = ref.watch(firestoreServiceProvider);
  final badges = await firestoreService.getBadges();
  
  // TODO: Cross-reference with user's earned badges
  return badges;
});
