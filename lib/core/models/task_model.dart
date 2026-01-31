/// Task model for daily tasks
class TaskModel {
  final String id;
  final String title;
  final String description;
  final String type; // action, audacity, enjoy
  final int estimatedMinutes;
  final int xpReward;
  final String? category;
  final String? riskLevel;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.estimatedMinutes,
    required this.xpReward,
    this.category,
    this.riskLevel,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      type: map['type'] as String? ?? 'action',
      estimatedMinutes: map['estimatedMinutes'] as int? ?? 5,
      xpReward: map['xpReward'] as int? ?? 100,
      category: map['category'] as String?,
      riskLevel: map['riskLevel'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'estimatedMinutes': estimatedMinutes,
      'xpReward': xpReward,
      'category': category,
      'riskLevel': riskLevel,
    };
  }
}

/// User's completed task record
class UserTaskModel {
  final String id;
  final String taskId;
  final String type;
  final DateTime date;
  final bool completed;
  final int xpEarned;
  final String? notes;
  final String? outcome;
  final DateTime? completedAt;

  UserTaskModel({
    required this.id,
    required this.taskId,
    required this.type,
    required this.date,
    required this.completed,
    required this.xpEarned,
    this.notes,
    this.outcome,
    this.completedAt,
  });

  factory UserTaskModel.fromMap(Map<String, dynamic> map, String id) {
    return UserTaskModel(
      id: id,
      taskId: map['taskId'] as String? ?? '',
      type: map['type'] as String? ?? 'action',
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      completed: map['completed'] as bool? ?? false,
      xpEarned: map['xpEarned'] as int? ?? 0,
      notes: map['notes'] as String?,
      outcome: map['outcome'] as String?,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'type': type,
      'date': date.toIso8601String(),
      'completed': completed,
      'xpEarned': xpEarned,
      'notes': notes,
      'outcome': outcome,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
