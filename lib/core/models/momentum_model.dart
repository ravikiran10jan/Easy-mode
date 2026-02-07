import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper to parse DateTime from Firestore
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Weekly momentum data - "Your Momentum Journal"
/// Replaces rigid "weekly plans" with encouraging reflection
class WeeklyMomentum {
  final String id;
  final String userId;
  final DateTime weekStart; // Monday of the week
  final DateTime weekEnd; // Sunday of the week
  
  // Auto-generated theme based on user's focus areas
  final String weeklyTheme;
  
  // Activity counts
  final int actionsCompleted;
  final int boldMoments; // Audacity scripts attempted
  final int joyCaptured; // Rituals logged
  
  // Streak tracking
  final int streakDays;
  final int maxStreakThisWeek;
  
  // AI-generated weekly summary (generated on Sunday)
  final String? aiSummary;
  final DateTime? summaryGeneratedAt;
  
  // Momentum indicators
  final MomentumLevel momentumLevel;
  
  WeeklyMomentum({
    required this.id,
    required this.userId,
    required this.weekStart,
    required this.weekEnd,
    required this.weeklyTheme,
    this.actionsCompleted = 0,
    this.boldMoments = 0,
    this.joyCaptured = 0,
    this.streakDays = 0,
    this.maxStreakThisWeek = 0,
    this.aiSummary,
    this.summaryGeneratedAt,
    this.momentumLevel = MomentumLevel.building,
  });

  factory WeeklyMomentum.fromMap(Map<String, dynamic> map, String id) => WeeklyMomentum(
      id: id,
      userId: map['userId'] as String? ?? '',
      weekStart: _parseDateTime(map['weekStart']) ?? DateTime.now(),
      weekEnd: _parseDateTime(map['weekEnd']) ?? DateTime.now(),
      weeklyTheme: map['weeklyTheme'] as String? ?? 'Building momentum',
      actionsCompleted: map['actionsCompleted'] as int? ?? 0,
      boldMoments: map['boldMoments'] as int? ?? 0,
      joyCaptured: map['joyCaptured'] as int? ?? 0,
      streakDays: map['streakDays'] as int? ?? 0,
      maxStreakThisWeek: map['maxStreakThisWeek'] as int? ?? 0,
      aiSummary: map['aiSummary'] as String?,
      summaryGeneratedAt: _parseDateTime(map['summaryGeneratedAt']),
      momentumLevel: MomentumLevel.fromString(map['momentumLevel'] as String?),
    );

  Map<String, dynamic> toMap() => {
      'userId': userId,
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'weeklyTheme': weeklyTheme,
      'actionsCompleted': actionsCompleted,
      'boldMoments': boldMoments,
      'joyCaptured': joyCaptured,
      'streakDays': streakDays,
      'maxStreakThisWeek': maxStreakThisWeek,
      'aiSummary': aiSummary,
      'summaryGeneratedAt': summaryGeneratedAt?.toIso8601String(),
      'momentumLevel': momentumLevel.key,
    };

  WeeklyMomentum copyWith({
    String? id,
    String? userId,
    DateTime? weekStart,
    DateTime? weekEnd,
    String? weeklyTheme,
    int? actionsCompleted,
    int? boldMoments,
    int? joyCaptured,
    int? streakDays,
    int? maxStreakThisWeek,
    String? aiSummary,
    DateTime? summaryGeneratedAt,
    MomentumLevel? momentumLevel,
  }) => WeeklyMomentum(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      weeklyTheme: weeklyTheme ?? this.weeklyTheme,
      actionsCompleted: actionsCompleted ?? this.actionsCompleted,
      boldMoments: boldMoments ?? this.boldMoments,
      joyCaptured: joyCaptured ?? this.joyCaptured,
      streakDays: streakDays ?? this.streakDays,
      maxStreakThisWeek: maxStreakThisWeek ?? this.maxStreakThisWeek,
      aiSummary: aiSummary ?? this.aiSummary,
      summaryGeneratedAt: summaryGeneratedAt ?? this.summaryGeneratedAt,
      momentumLevel: momentumLevel ?? this.momentumLevel,
    );

  /// Total activities this week
  int get totalActivities => actionsCompleted + boldMoments + joyCaptured;

  /// Calculate momentum score (0-5 fire emojis)
  int get momentumScore {
    if (streakDays >= 5 && totalActivities >= 10) return 5;
    if (streakDays >= 4 && totalActivities >= 7) return 4;
    if (streakDays >= 3 && totalActivities >= 5) return 3;
    if (streakDays >= 2 && totalActivities >= 3) return 2;
    if (streakDays >= 1 || totalActivities >= 1) return 1;
    return 0;
  }

  /// Get momentum emoji display
  String get momentumEmoji => List.filled(momentumScore, '🔥').join();
}

/// Momentum levels for visual feedback
enum MomentumLevel {
  starting('starting', 'Getting Started', 'You\'re beginning your journey'),
  building('building', 'Building', 'You\'re developing momentum'),
  growing('growing', 'Growing', 'You\'re in your groove'),
  thriving('thriving', 'Thriving', 'You\'re on fire!'),
  unstoppable('unstoppable', 'Unstoppable', 'Nothing can stop you now');

  final String key;
  final String label;
  final String description;
  const MomentumLevel(this.key, this.label, this.description);

  static MomentumLevel fromString(String? value) {
    if (value == null) return MomentumLevel.building;
    try {
      return MomentumLevel.values.firstWhere((e) => e.key == value);
    } catch (_) {
      return MomentumLevel.building;
    }
  }

  static MomentumLevel fromScore(int score) {
    if (score >= 5) return MomentumLevel.unstoppable;
    if (score >= 4) return MomentumLevel.thriving;
    if (score >= 3) return MomentumLevel.growing;
    if (score >= 2) return MomentumLevel.building;
    return MomentumLevel.starting;
  }
}

/// Weekly theme suggestions based on focus areas
class WeeklyThemes {
  static const Map<String, List<String>> themesByFocusArea = {
    'speak_up': [
      'Speaking your truth',
      'Finding your voice',
      'Asking boldly',
      'Expressing yourself',
    ],
    'take_action': [
      'Moving forward',
      'Taking the leap',
      'Doing, not thinking',
      'Progress over perfection',
    ],
    'find_joy': [
      'Finding magic in the mundane',
      'Everyday celebrations',
      'Savoring moments',
      'Joy hunting',
    ],
    'create_regularly': [
      'Creating without judgment',
      'Showing up to create',
      'Building your craft',
      'Expressing freely',
    ],
    'move_body': [
      'Moving with intention',
      'Honoring your body',
      'Energizing movement',
      'Physical freedom',
    ],
    'manage_time': [
      'Flowing with time',
      'Peaceful productivity',
      'Mindful moments',
      'Calm efficiency',
    ],
  };

  /// Get a theme based on user's focus areas and week number
  static String getThemeForWeek(List<String> focusAreas, int weekOfYear) {
    if (focusAreas.isEmpty) return 'Building momentum';
    
    // Rotate through focus areas week by week
    final focusIndex = weekOfYear % focusAreas.length;
    final primaryFocus = focusAreas[focusIndex];
    
    final themes = themesByFocusArea[primaryFocus] ?? ['Building momentum'];
    final themeIndex = (weekOfYear ~/ focusAreas.length) % themes.length;
    
    return themes[themeIndex];
  }
}
