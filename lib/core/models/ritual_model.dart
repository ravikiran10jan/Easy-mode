/// Ritual model for enjoyment rituals
class RitualModel {
  final String id;
  final String title;
  final String description;
  final List<String> steps;
  final int estimatedMinutes;
  final String? category;
  final String? iconName;

  RitualModel({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
    required this.estimatedMinutes,
    this.category,
    this.iconName,
  });

  factory RitualModel.fromMap(Map<String, dynamic> map, String id) {
    return RitualModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      steps: (map['steps'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      estimatedMinutes: map['estimatedMinutes'] as int? ?? 5,
      category: map['category'] as String?,
      iconName: map['iconName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'steps': steps,
      'estimatedMinutes': estimatedMinutes,
      'category': category,
      'iconName': iconName,
    };
  }
}

/// User's ritual completion record
class UserRitualModel {
  final String id;
  final String ritualId;
  final DateTime date;
  final bool completed;
  final String? notes;
  final int? moodBefore;
  final int? moodAfter;

  UserRitualModel({
    required this.id,
    required this.ritualId,
    required this.date,
    required this.completed,
    this.notes,
    this.moodBefore,
    this.moodAfter,
  });

  factory UserRitualModel.fromMap(Map<String, dynamic> map, String id) {
    return UserRitualModel(
      id: id,
      ritualId: map['ritualId'] as String? ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      completed: map['completed'] as bool? ?? false,
      notes: map['notes'] as String?,
      moodBefore: map['moodBefore'] as int?,
      moodAfter: map['moodAfter'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ritualId': ritualId,
      'date': date.toIso8601String(),
      'completed': completed,
      'notes': notes,
      'moodBefore': moodBefore,
      'moodAfter': moodAfter,
    };
  }
}
