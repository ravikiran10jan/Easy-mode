/// Badge model for achievements
class BadgeModel {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final String requirement;
  final int requiredCount;
  final String? category;

  BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.requirement,
    required this.requiredCount,
    this.category,
  });

  factory BadgeModel.fromMap(Map<String, dynamic> map, String id) {
    return BadgeModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      iconName: map['iconName'] as String? ?? 'star',
      requirement: map['requirement'] as String? ?? '',
      requiredCount: map['requiredCount'] as int? ?? 1,
      category: map['category'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'iconName': iconName,
      'requirement': requirement,
      'requiredCount': requiredCount,
      'category': category,
    };
  }
}

/// User's earned badge
class UserBadgeModel {
  final String badgeId;
  final DateTime earnedAt;

  UserBadgeModel({
    required this.badgeId,
    required this.earnedAt,
  });

  factory UserBadgeModel.fromMap(Map<String, dynamic> map) {
    return UserBadgeModel(
      badgeId: map['badgeId'] as String? ?? '',
      earnedAt: map['earnedAt'] != null
          ? DateTime.parse(map['earnedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'badgeId': badgeId,
      'earnedAt': earnedAt.toIso8601String(),
    };
  }
}
