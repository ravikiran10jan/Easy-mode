import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_providers.dart';

/// Provider for user statistics
/// Aggregates data from userTasks, userActions, userScripts, and userRituals collections
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
  final Set<String> activeDays = {};

  // Get user tasks (daily tasks from home screen)
  final tasks = await firestoreService.getUserTasks(user.uid);
  
  // Get user actions (from Action Library)
  final userActions = await firestoreService.getUserActions(user.uid);
  
  // Get user scripts (from Audacity Scripts)
  final userScripts = await firestoreService.getUserScripts(user.uid);
  
  // Get user rituals (from Joy Rituals)
  final userRituals = await firestoreService.getUserRituals(user.uid);

  // Count actions completed from daily tasks
  int actionsFromTasks = 0;
  int audacityFromTasks = 0;
  int ritualsFromTasks = 0;

  for (final task in tasks) {
    if (task['completed'] == true) {
      final type = task['type'] as String?;
      final date = task['date'] as String?;
      
      if (date != null && date.length >= 10) {
        activeDays.add(date.substring(0, 10));
      }
      
      switch (type) {
        case 'action':
          actionsFromTasks++;
          break;
        case 'audacity':
          audacityFromTasks++;
          break;
        case 'enjoy':
          ritualsFromTasks++;
          break;
      }
    }
  }

  // Count actions from Action Library
  int actionsFromLibrary = 0;
  for (final action in userActions) {
    if (action['completed'] == true) {
      actionsFromLibrary++;
      final date = action['completedDate'] as String?;
      if (date != null && date.length >= 10) {
        activeDays.add(date.substring(0, 10));
      }
    }
  }

  // Count audacity attempts from Scripts
  int audacityFromScripts = userScripts.length;
  for (final script in userScripts) {
    final date = script['attemptDate'] as String?;
    if (date != null && date.length >= 10) {
      activeDays.add(date.substring(0, 10));
    }
  }

  // Count rituals from Joy Rituals
  int ritualsFromLibrary = 0;
  for (final ritual in userRituals) {
    if (ritual['completed'] == true) {
      ritualsFromLibrary++;
      final date = ritual['date'] as String?;
      if (date != null && date.length >= 10) {
        activeDays.add(date.substring(0, 10));
      }
    }
  }

  return {
    'actionsCompleted': actionsFromTasks + actionsFromLibrary,
    'audacityAttempts': audacityFromTasks + audacityFromScripts,
    'ritualsCompleted': ritualsFromTasks + ritualsFromLibrary,
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
