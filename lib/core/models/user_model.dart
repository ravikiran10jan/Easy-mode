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
    this.name,
    this.email,
    this.photoUrl,
    this.profile,
    this.xpTotal = 0,
    this.level = 1,
    this.streak = 0,
    this.lastActivity,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
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
      lastActivity: map['lastActivity'] != null
          ? DateTime.parse(map['lastActivity'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
  }

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
  }) {
    return UserModel(
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
  }

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

/// User profile from onboarding
class UserProfile {
  final String pain;
  final String goal;
  final int dailyTimeMinutes;
  final DateTime createdAt;

  UserProfile({
    required this.pain,
    required this.goal,
    required this.dailyTimeMinutes,
    required this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      pain: map['pain'] as String? ?? '',
      goal: map['goal'] as String? ?? '',
      dailyTimeMinutes: map['dailyTimeMinutes'] as int? ?? 10,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pain': pain,
      'goal': goal,
      'dailyTimeMinutes': dailyTimeMinutes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
