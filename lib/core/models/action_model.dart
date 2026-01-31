/// Action template model for quick wins and micro-tasks
class ActionModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty; // easy, medium, challenging
  final int estimatedMinutes;
  final int xpReward;
  final String? iconName;
  final List<String> tips;

  ActionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.xpReward,
    this.iconName,
    required this.tips,
  });

  factory ActionModel.fromMap(Map<String, dynamic> map, String id) => ActionModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      difficulty: map['difficulty'] as String? ?? 'easy',
      estimatedMinutes: map['estimatedMinutes'] as int? ?? 5,
      xpReward: map['xpReward'] as int? ?? 100,
      iconName: map['iconName'] as String?,
      tips: (map['tips'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

  Map<String, dynamic> toMap() => {
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'estimatedMinutes': estimatedMinutes,
      'xpReward': xpReward,
      'iconName': iconName,
      'tips': tips,
    };
}

/// User's action completion record
class UserActionModel {
  final String id;
  final String actionId;
  final DateTime completedDate;
  final bool completed;
  final String? notes;
  final int xpEarned;

  UserActionModel({
    required this.id,
    required this.actionId,
    required this.completedDate,
    required this.completed,
    required this.xpEarned,
    this.notes,
  });

  factory UserActionModel.fromMap(Map<String, dynamic> map, String id) => UserActionModel(
      id: id,
      actionId: map['actionId'] as String? ?? '',
      completedDate: map['completedDate'] != null
          ? DateTime.parse(map['completedDate'] as String)
          : DateTime.now(),
      completed: map['completed'] as bool? ?? false,
      notes: map['notes'] as String?,
      xpEarned: map['xpEarned'] as int? ?? 0,
    );

  Map<String, dynamic> toMap() => {
      'actionId': actionId,
      'completedDate': completedDate.toIso8601String(),
      'completed': completed,
      'notes': notes,
      'xpEarned': xpEarned,
    };
}
