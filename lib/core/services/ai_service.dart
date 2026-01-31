import 'package:cloud_functions/cloud_functions.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';

/// Response from AI task personalization
class PersonalizedTaskResponse {
  final bool success;
  final String personalizedDescription;
  final String coachTip;
  final String motivationalNote;
  final String? error;

  PersonalizedTaskResponse({
    required this.success,
    required this.personalizedDescription,
    required this.coachTip,
    required this.motivationalNote,
    this.error,
  });

  factory PersonalizedTaskResponse.fromMap(Map<String, dynamic> map) =>
      PersonalizedTaskResponse(
        success: map['success'] as bool? ?? false,
        personalizedDescription:
            map['personalizedDescription'] as String? ?? '',
        coachTip: map['coachTip'] as String? ?? '',
        motivationalNote: map['motivationalNote'] as String? ?? '',
        error: map['error'] as String?,
      );
}

/// Response from AI daily insight generation
class DailyInsightResponse {
  final bool success;
  final String greeting;
  final String insight;
  final String todayFocus;
  final String encouragement;
  final DateTime? generatedAt;
  final String? error;

  DailyInsightResponse({
    required this.success,
    required this.greeting,
    required this.insight,
    required this.todayFocus,
    required this.encouragement,
    this.generatedAt,
    this.error,
  });

  factory DailyInsightResponse.fromMap(Map<String, dynamic> map) =>
      DailyInsightResponse(
        success: map['success'] as bool? ?? false,
        greeting: map['greeting'] as String? ?? 'Hello!',
        insight: map['insight'] as String? ?? '',
        todayFocus: map['todayFocus'] as String? ?? '',
        encouragement: map['encouragement'] as String? ?? '',
        generatedAt: map['generatedAt'] != null
            ? DateTime.tryParse(map['generatedAt'] as String)
            : null,
        error: map['error'] as String?,
      );
}

/// Service for AI-powered features via Firebase Cloud Functions
class AiService {
  final FirebaseFunctions _functions;

  AiService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// Personalize a task based on user context
  Future<PersonalizedTaskResponse> personalizeTask({
    required TaskModel task,
    required UserModel user,
  }) async {
    try {
      final callable = _functions.httpsCallable('personalizeTask');

      final result = await callable.call<Map<String, dynamic>>({
        'task': {
          'id': task.id,
          'title': task.title,
          'description': task.description,
          'type': task.type,
          'estimatedMinutes': task.estimatedMinutes,
        },
        'userContext': {
          'name': user.name,
          'streak': user.streak,
          'level': user.level,
          'goal': user.profile?.goal,
          'pain': user.profile?.pain,
          'dailyTimeMinutes': user.profile?.dailyTimeMinutes,
        },
      });

      return PersonalizedTaskResponse.fromMap(
        Map<String, dynamic>.from(result.data),
      );
    } catch (e) {
      return PersonalizedTaskResponse(
        success: false,
        personalizedDescription: task.description,
        coachTip: 'Take it one step at a time. You\'ve got this.',
        motivationalNote: 'Every small action builds momentum.',
        error: e.toString(),
      );
    }
  }

  /// Generate daily AI insight for the user
  Future<DailyInsightResponse> generateDailyInsight({
    UserModel? user,
    int? tasksCompletedLast7Days,
    List<String>? recentTaskTypes,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateDailyInsight');

      final Map<String, dynamic> data = {};

      if (user != null) {
        data['userStats'] = {
          'name': user.name,
          'xpTotal': user.xpTotal,
          'level': user.level,
          'streak': user.streak,
          'goal': user.profile?.goal,
          'pain': user.profile?.pain,
        };
      }

      if (tasksCompletedLast7Days != null || recentTaskTypes != null) {
        data['recentActivity'] = {
          'tasksCompleted': tasksCompletedLast7Days,
          'taskTypes': recentTaskTypes,
        };
      }

      final result = await callable.call<Map<String, dynamic>>(data);

      return DailyInsightResponse.fromMap(
        Map<String, dynamic>.from(result.data),
      );
    } catch (e) {
      return DailyInsightResponse(
        success: false,
        greeting: 'Good morning${user?.name != null ? ', ${user!.name}' : ''}!',
        insight:
            'Every day is a fresh opportunity to take action toward your goals.',
        todayFocus: 'Pick one small task and give it your full attention.',
        encouragement: 'You\'re building something great, one step at a time.',
        error: e.toString(),
      );
    }
  }
}
