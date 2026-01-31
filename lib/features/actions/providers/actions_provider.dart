import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/models/action_model.dart';

/// Provider for all actions
final actionsProvider = FutureProvider<List<ActionModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final actionsData = await firestoreService.getActions();
  
  if (actionsData.isEmpty) {
    // Return default actions if none in database
    return _defaultActions;
  }
  
  return actionsData
      .map((data) => ActionModel.fromMap(data, data['id'] as String))
      .toList();
});

/// Provider for actions by category
final actionsByCategoryProvider = FutureProvider.family<List<ActionModel>, String>(
  (ref, category) async {
    final firestoreService = ref.watch(firestoreServiceProvider);
    final actionsData = await firestoreService.getActionsByCategory(category);
    
    return actionsData
        .map((data) => ActionModel.fromMap(data, data['id'] as String))
        .toList();
  },
);

/// Default actions for fallback
final List<ActionModel> _defaultActions = [
  ActionModel(
    id: 'action_1',
    title: 'Make Your Bed',
    description: 'Start your day with a small win. Making your bed sets the tone for a productive day.',
    category: 'Morning',
    difficulty: 'easy',
    estimatedMinutes: 2,
    xpReward: 50,
    iconName: 'bed',
    tips: [
      'Do it right after waking up',
      'Keep it simple - just straighten the covers',
      'This creates momentum for bigger tasks',
    ],
  ),
  ActionModel(
    id: 'action_2',
    title: 'Drink a Glass of Water',
    description: 'Hydrate your body first thing in the morning to boost energy and focus.',
    category: 'Morning',
    difficulty: 'easy',
    estimatedMinutes: 1,
    xpReward: 50,
    iconName: 'water',
    tips: [
      'Keep a glass by your bedside',
      'Room temperature water is easier to drink',
      'Add lemon for extra freshness',
    ],
  ),
  ActionModel(
    id: 'action_3',
    title: 'Write 3 Priorities',
    description: 'Identify your top 3 priorities for today. Focus beats multitasking.',
    category: 'Planning',
    difficulty: 'easy',
    estimatedMinutes: 3,
    xpReward: 75,
    iconName: 'list',
    tips: [
      'Choose tasks that move the needle',
      'Be specific about what "done" looks like',
      'Put the hardest task first',
    ],
  ),
  ActionModel(
    id: 'action_4',
    title: 'Send One Thank You Message',
    description: 'Express gratitude to someone who helped you recently. Small acts strengthen relationships.',
    category: 'Social',
    difficulty: 'easy',
    estimatedMinutes: 2,
    xpReward: 100,
    iconName: 'message',
    tips: [
      'Be specific about what you appreciate',
      'Text, email, or voice message all work',
      'Genuine beats perfect',
    ],
  ),
  ActionModel(
    id: 'action_5',
    title: 'Take a 5-Minute Walk',
    description: 'Step away from your desk and move. Brief walks boost creativity and reduce stress.',
    category: 'Wellness',
    difficulty: 'easy',
    estimatedMinutes: 5,
    xpReward: 75,
    iconName: 'walk',
    tips: [
      'Leave your phone behind',
      'Notice 3 things around you',
      'Breathe deeply as you walk',
    ],
  ),
  ActionModel(
    id: 'action_6',
    title: 'Clear Your Desk',
    description: 'Spend 5 minutes organizing your workspace. A clear desk leads to a clear mind.',
    category: 'Productivity',
    difficulty: 'easy',
    estimatedMinutes: 5,
    xpReward: 75,
    iconName: 'desk',
    tips: [
      'Put away items you are not using today',
      'Throw away or recycle clutter',
      'Wipe down surfaces for a fresh feel',
    ],
  ),
  ActionModel(
    id: 'action_7',
    title: 'Complete One Dreaded Task',
    description: 'Pick that task you have been avoiding and do it now. Relief awaits on the other side.',
    category: 'Productivity',
    difficulty: 'medium',
    estimatedMinutes: 15,
    xpReward: 150,
    iconName: 'task',
    tips: [
      'Start with just 2 minutes - momentum builds',
      'Reward yourself after completing it',
      'Remember: done is better than perfect',
    ],
  ),
  ActionModel(
    id: 'action_8',
    title: 'Do 10 Pushups',
    description: 'Quick physical exercise to boost energy and build strength over time.',
    category: 'Wellness',
    difficulty: 'medium',
    estimatedMinutes: 2,
    xpReward: 100,
    iconName: 'fitness',
    tips: [
      'Modify on knees if needed',
      'Focus on form over speed',
      'Breathe out as you push up',
    ],
  ),
  ActionModel(
    id: 'action_9',
    title: 'Read for 10 Minutes',
    description: 'Pick up that book you have been meaning to read. Small reading sessions add up.',
    category: 'Learning',
    difficulty: 'easy',
    estimatedMinutes: 10,
    xpReward: 100,
    iconName: 'book',
    tips: [
      'Keep your book visible and accessible',
      'Read before reaching for your phone',
      'Fiction or non-fiction both count',
    ],
  ),
  ActionModel(
    id: 'action_10',
    title: 'Unsubscribe from 3 Emails',
    description: 'Reduce digital clutter by unsubscribing from newsletters you never read.',
    category: 'Digital',
    difficulty: 'easy',
    estimatedMinutes: 3,
    xpReward: 75,
    iconName: 'email',
    tips: [
      'Check your promotions/spam folder',
      'Be ruthless - you can always resubscribe',
      'This saves time every day',
    ],
  ),
  ActionModel(
    id: 'action_11',
    title: 'Plan Tomorrow Tonight',
    description: 'Spend 5 minutes planning tomorrow before bed. Wake up with clarity and purpose.',
    category: 'Evening',
    difficulty: 'easy',
    estimatedMinutes: 5,
    xpReward: 100,
    iconName: 'calendar',
    tips: [
      'Review what you accomplished today',
      'Set 1-3 priorities for tomorrow',
      'Lay out clothes or prep items you need',
    ],
  ),
  ActionModel(
    id: 'action_12',
    title: 'Practice Deep Breathing',
    description: '5 deep breaths to calm your nervous system and regain focus.',
    category: 'Wellness',
    difficulty: 'easy',
    estimatedMinutes: 2,
    xpReward: 50,
    iconName: 'breath',
    tips: [
      'Inhale for 4 counts, hold for 4, exhale for 6',
      'Close your eyes if comfortable',
      'Do this whenever you feel stressed',
    ],
  ),
];
