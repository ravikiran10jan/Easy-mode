import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/models/ritual_model.dart';

/// Provider for all rituals
final ritualsProvider = FutureProvider<List<RitualModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final ritualsData = await firestoreService.getRituals();
  
  if (ritualsData.isEmpty) {
    // Return default rituals if none in database
    return _defaultRituals;
  }
  
  return ritualsData
      .map((data) => RitualModel.fromMap(data, data['id'] as String))
      .toList();
});

/// Default rituals for fallback
final List<RitualModel> _defaultRituals = [
  RitualModel(
    id: 'ritual_1',
    title: 'Morning Playlist',
    description: 'Start your day with 5 minutes of your favorite upbeat music while you prepare.',
    steps: [
      'Open your music app',
      'Pick 2-3 songs that make you feel good',
      'Let the music play while you get ready',
      'Dance or move if you feel like it!',
    ],
    estimatedMinutes: 5,
    category: 'Morning',
    iconName: 'music',
  ),
  RitualModel(
    id: 'ritual_2',
    title: 'Mindful Coffee',
    description: 'Transform your coffee break into a mini meditation moment.',
    steps: [
      'Make your favorite hot drink',
      'Sit somewhere comfortable',
      'Notice the warmth of the cup',
      'Take slow sips and savor each one',
      'Appreciate this moment of peace',
    ],
    estimatedMinutes: 10,
    category: 'Morning',
    iconName: 'coffee',
  ),
  RitualModel(
    id: 'ritual_3',
    title: 'Sunshine Break',
    description: 'Step outside for a brief moment of natural light and fresh air.',
    steps: [
      'Step outside or open a window',
      'Look up at the sky',
      'Take 5 deep breaths',
      'Notice something beautiful around you',
      'Feel grateful for this moment',
    ],
    estimatedMinutes: 3,
    category: 'Anytime',
    iconName: 'sun',
  ),
  RitualModel(
    id: 'ritual_4',
    title: 'Gratitude Note',
    description: 'Write a quick thank you message to someone who made your day better.',
    steps: [
      'Think of someone who helped you today',
      'Write a quick message thanking them',
      'Send it via text, email, or say it in person',
      'Notice how it makes you feel',
    ],
    estimatedMinutes: 5,
    category: 'Evening',
    iconName: 'heart',
  ),
  RitualModel(
    id: 'ritual_5',
    title: 'Photo Walk',
    description: 'Take a short walk and capture one beautiful thing with your phone camera.',
    steps: [
      'Go for a 5-minute walk',
      'Look for something beautiful or interesting',
      'Take a photo of it',
      'Appreciate the beauty in everyday things',
    ],
    estimatedMinutes: 10,
    category: 'Anytime',
    iconName: 'photo',
  ),
  RitualModel(
    id: 'ritual_6',
    title: 'Evening Wind-Down',
    description: 'A simple routine to transition from work mode to rest mode.',
    steps: [
      'Light a candle or dim the lights',
      'Put away your phone for 10 minutes',
      'Stretch your body gently',
      'Think of one good thing from today',
      'Take 5 slow, deep breaths',
    ],
    estimatedMinutes: 10,
    category: 'Evening',
    iconName: 'candle',
  ),
  RitualModel(
    id: 'ritual_7',
    title: 'Mini Plant Check',
    description: 'Spend a moment caring for a plant or appreciating nature.',
    steps: [
      'Find a plant or go near some greenery',
      'Look at it closely - notice the details',
      'Water it if it needs it',
      'Say something kind to it (really!)',
    ],
    estimatedMinutes: 3,
    category: 'Anytime',
    iconName: 'plant',
  ),
  RitualModel(
    id: 'ritual_8',
    title: 'One Page Read',
    description: 'Read just one page of a book you enjoy - no pressure for more.',
    steps: [
      'Pick up a book you enjoy',
      'Read just one page',
      'Really absorb what you read',
      'Put it down with no guilt',
    ],
    estimatedMinutes: 5,
    category: 'Anytime',
    iconName: 'book',
  ),
];
