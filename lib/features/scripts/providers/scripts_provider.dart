import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/models/script_model.dart';

/// Provider for all scripts
final scriptsProvider = FutureProvider<List<ScriptModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final scriptsData = await firestoreService.getScripts();
  
  if (scriptsData.isEmpty) {
    // Return default scripts if none in database
    return _defaultScripts;
  }
  
  return scriptsData
      .map((data) => ScriptModel.fromMap(data, data['id'] as String))
      .toList();
});

/// Provider for scripts by category
final scriptsByCategoryProvider = FutureProvider.family<List<ScriptModel>, String>(
  (ref, category) async {
    final firestoreService = ref.watch(firestoreServiceProvider);
    final scriptsData = await firestoreService.getScriptsByCategory(category);
    
    return scriptsData
        .map((data) => ScriptModel.fromMap(data, data['id'] as String))
        .toList();
  },
);

/// Default scripts for fallback
final List<ScriptModel> _defaultScripts = [
  ScriptModel(
    id: 'script_1',
    title: 'Ask for a Small Discount',
    category: 'Shopping',
    template: 'Hi! I love this product. Are there any promotions or discounts available today? I\'m ready to buy if so.',
    riskLevel: 'low',
    exampleOutcomes: [
      'You might get 10-15% off',
      'They might throw in a freebie',
      'Worst case: polite "no" and you still buy',
    ],
    estimatedMinutes: 2,
    tips: 'Smile and be friendly. Most retail staff have some discount authority.',
  ),
  ScriptModel(
    id: 'script_2',
    title: 'Request a Meeting with Your Manager',
    category: 'Work',
    template: 'Hi [Manager], I\'d love to schedule 15 minutes to discuss my recent work and get your feedback on how I can grow in my role. Would you have time this week?',
    riskLevel: 'low',
    exampleOutcomes: [
      'Get valuable career feedback',
      'Show initiative and interest in growth',
      'Build a stronger relationship with your manager',
    ],
    estimatedMinutes: 3,
    tips: 'Come prepared with specific questions or topics to discuss.',
  ),
  ScriptModel(
    id: 'script_3',
    title: 'Ask for a Referral',
    category: 'Work',
    template: 'Hi [Name], I really enjoyed working with you on [project]. I\'m currently looking for opportunities in [field]. Would you be comfortable referring me or connecting me with anyone in your network?',
    riskLevel: 'medium',
    exampleOutcomes: [
      'Get a warm introduction to new opportunities',
      'Strengthen your professional relationship',
      'Expand your network',
    ],
    estimatedMinutes: 5,
    tips: 'Make it easy for them by being specific about what you\'re looking for.',
  ),
  ScriptModel(
    id: 'script_4',
    title: 'Negotiate Your Salary',
    category: 'Work',
    template: 'Thank you for the offer. I\'m very excited about this opportunity. Based on my research and experience, I was hoping for a salary in the range of [X-Y]. Is there flexibility to discuss this?',
    riskLevel: 'high',
    exampleOutcomes: [
      'Potentially significant increase in compensation',
      'Demonstrates confidence and market awareness',
      'Sets the tone for future negotiations',
    ],
    estimatedMinutes: 10,
    tips: 'Research market rates beforehand. Have specific accomplishments ready to justify your ask.',
  ),
  ScriptModel(
    id: 'script_5',
    title: 'Ask Someone to Coffee',
    category: 'Social',
    template: 'Hey [Name], I\'ve really enjoyed our conversations about [topic]. Would you want to grab coffee sometime? I\'d love to continue the discussion.',
    riskLevel: 'medium',
    exampleOutcomes: [
      'Make a new friend or connection',
      'Learn something new',
      'Expand your social circle',
    ],
    estimatedMinutes: 2,
    tips: 'Be genuine and specific about why you want to connect.',
  ),
  ScriptModel(
    id: 'script_6',
    title: 'Request a Deadline Extension',
    category: 'Work',
    template: 'Hi [Name], I wanted to give you an update on [project]. I\'ve encountered [specific challenge] and want to ensure I deliver quality work. Would it be possible to extend the deadline by [time]?',
    riskLevel: 'medium',
    exampleOutcomes: [
      'Get more time to deliver quality work',
      'Show professionalism by communicating proactively',
      'Build trust through transparency',
    ],
    estimatedMinutes: 5,
    tips: 'Ask early, explain the reason, and propose a specific new deadline.',
  ),
];
