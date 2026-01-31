/// Audacity Script model
class ScriptModel {
  final String id;
  final String title;
  final String category;
  final String template;
  final String riskLevel; // low, medium, high
  final List<String> exampleOutcomes;
  final int estimatedMinutes;
  final String? tips;

  ScriptModel({
    required this.id,
    required this.title,
    required this.category,
    required this.template,
    required this.riskLevel,
    required this.exampleOutcomes,
    required this.estimatedMinutes,
    this.tips,
  });

  factory ScriptModel.fromMap(Map<String, dynamic> map, String id) {
    return ScriptModel(
      id: id,
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? '',
      template: map['template'] as String? ?? '',
      riskLevel: map['riskLevel'] as String? ?? 'low',
      exampleOutcomes: (map['exampleOutcomes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      estimatedMinutes: map['estimatedMinutes'] as int? ?? 5,
      tips: map['tips'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'template': template,
      'riskLevel': riskLevel,
      'exampleOutcomes': exampleOutcomes,
      'estimatedMinutes': estimatedMinutes,
      'tips': tips,
    };
  }
}

/// User's script attempt record
class UserScriptModel {
  final String id;
  final String scriptId;
  final DateTime attemptDate;
  final String outcome; // success, partial, declined, not_attempted
  final String? customText;
  final String? notes;
  final String? reflection;
  final int xpEarned;

  UserScriptModel({
    required this.id,
    required this.scriptId,
    required this.attemptDate,
    required this.outcome,
    this.customText,
    this.notes,
    this.reflection,
    required this.xpEarned,
  });

  factory UserScriptModel.fromMap(Map<String, dynamic> map, String id) {
    return UserScriptModel(
      id: id,
      scriptId: map['scriptId'] as String? ?? '',
      attemptDate: map['attemptDate'] != null
          ? DateTime.parse(map['attemptDate'] as String)
          : DateTime.now(),
      outcome: map['outcome'] as String? ?? 'not_attempted',
      customText: map['customText'] as String?,
      notes: map['notes'] as String?,
      reflection: map['reflection'] as String?,
      xpEarned: map['xpEarned'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scriptId': scriptId,
      'attemptDate': attemptDate.toIso8601String(),
      'outcome': outcome,
      'customText': customText,
      'notes': notes,
      'reflection': reflection,
      'xpEarned': xpEarned,
    };
  }
}
