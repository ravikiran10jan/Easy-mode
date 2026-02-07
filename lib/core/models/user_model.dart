import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper to parse DateTime from Firestore (handles both Timestamp and String)
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// User model for Easy Mode
class UserModel {
  final String uid;
  final String? name;
  final String? email;
  final String? photoUrl;
  final UserProfile? profile;
  final int xpTotal;
  final int level;
  final int streak;
  final DateTime? lastActivity;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.createdAt, this.name,
    this.email,
    this.photoUrl,
    this.profile,
    this.xpTotal = 0,
    this.level = 1,
    this.streak = 0,
    this.lastActivity,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) => UserModel(
      uid: uid,
      name: map['name'] as String?,
      email: map['email'] as String?,
      photoUrl: map['photoUrl'] as String?,
      profile: map['profile'] != null
          ? UserProfile.fromMap(map['profile'] as Map<String, dynamic>)
          : null,
      xpTotal: map['xpTotal'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      streak: map['streak'] as int? ?? 0,
      lastActivity: _parseDateTime(map['lastActivity']),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
    );

  Map<String, dynamic> toMap() => {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'profile': profile?.toMap(),
      'xpTotal': xpTotal,
      'level': level,
      'streak': streak,
      'lastActivity': lastActivity?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    UserProfile? profile,
    int? xpTotal,
    int? level,
    int? streak,
    DateTime? lastActivity,
    DateTime? createdAt,
  }) => UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      profile: profile ?? this.profile,
      xpTotal: xpTotal ?? this.xpTotal,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      lastActivity: lastActivity ?? this.lastActivity,
      createdAt: createdAt ?? this.createdAt,
    );

  /// Check if user has completed onboarding
  bool get hasCompletedOnboarding => profile != null;

  /// Calculate XP needed for next level
  int get xpForNextLevel => level * 500;

  /// Calculate current progress to next level (0.0 to 1.0)
  double get levelProgress {
    final xpInCurrentLevel = xpTotal - ((level - 1) * 500);
    return xpInCurrentLevel / xpForNextLevel;
  }
}

/// Aspiration types for "What does Easy Mode feel like?"
enum EasyModeAspiration {
  speakUp('speak_up', 'I speak up for what I want'),
  takeAction('take_action', 'I take action without overthinking'),
  findJoy('find_joy', 'I find joy in ordinary moments'),
  createRegularly('create_regularly', 'I write/create regularly'),
  moveBody('move_body', 'I move my body with ease'),
  manageTime('manage_time', 'I manage my time without stress');

  final String key;
  final String label;
  const EasyModeAspiration(this.key, this.label);

  static EasyModeAspiration? fromKey(String key) {
    try {
      return EasyModeAspiration.values.firstWhere((e) => e.key == key);
    } catch (_) {
      return null;
    }
  }
}

/// User profile from onboarding
class UserProfile {
  // Legacy fields (for backward compatibility)
  final String pain;
  final String goal;
  
  // New aspiration-based fields
  final List<String> focusAreas; // Keys from EasyModeAspiration
  final String? intent; // Optional resolution text
  final bool hasResolution; // Whether user entered via resolution path
  
  final int dailyTimeMinutes;
  final DateTime createdAt;

  UserProfile({
    this.pain = '',
    this.goal = '',
    this.focusAreas = const [],
    this.intent,
    this.hasResolution = false,
    required this.dailyTimeMinutes,
    required this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
      pain: map['pain'] as String? ?? '',
      goal: map['goal'] as String? ?? '',
      focusAreas: (map['focusAreas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      intent: map['intent'] as String?,
      hasResolution: map['hasResolution'] as bool? ?? false,
      dailyTimeMinutes: map['dailyTimeMinutes'] as int? ?? 10,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
    );

  Map<String, dynamic> toMap() => {
      'pain': pain,
      'goal': goal,
      'focusAreas': focusAreas,
      'intent': intent,
      'hasResolution': hasResolution,
      'dailyTimeMinutes': dailyTimeMinutes,
      'createdAt': createdAt.toIso8601String(),
    };

  /// Get the primary focus area for AI recommendations
  String? get primaryFocusArea => focusAreas.isNotEmpty ? focusAreas.first : null;

  /// Map focus areas to internal tracks for backend/judges
  List<String> get mappedTracks {
    final tracks = <String>{};
    for (final area in focusAreas) {
      switch (area) {
        case 'speak_up':
        case 'take_action':
          tracks.add('personal_growth');
          break;
        case 'find_joy':
        case 'move_body':
          tracks.add('wellness');
          break;
        case 'create_regularly':
          tracks.add('creative_expression');
          break;
        case 'manage_time':
          tracks.add('productivity');
          break;
      }
    }
    return tracks.toList();
  }
}
