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

  /// Get a smart task recommendation based on user behavior patterns
  Future<SmartRecommendationResponse> getSmartRecommendation({
    String? preferredType,
  }) async {
    try {
      final callable = _functions.httpsCallable('getSmartRecommendation');

      final Map<String, dynamic> data = {};
      if (preferredType != null) {
        data['preferredType'] = preferredType;
      }

      final result = await callable.call<Map<String, dynamic>>(data);

      return SmartRecommendationResponse.fromMap(
        Map<String, dynamic>.from(result.data),
      );
    } catch (e) {
      return SmartRecommendationResponse(
        success: false,
        error: e.toString(),
      );
    }
  }
}

/// Reasoning behind a smart recommendation
class RecommendationReasoning {
  final String whyThisTask;
  final String expectedImpact;
  final String personalizedTip;

  RecommendationReasoning({
    required this.whyThisTask,
    required this.expectedImpact,
    required this.personalizedTip,
  });

  factory RecommendationReasoning.fromMap(Map<String, dynamic> map) =>
      RecommendationReasoning(
        whyThisTask: map['whyThisTask'] as String? ?? '',
        expectedImpact: map['expectedImpact'] as String? ?? '',
        personalizedTip: map['personalizedTip'] as String? ?? '',
      );
}

/// Behavior insights from user history
class BehaviorInsights {
  final int totalTasksCompleted;
  final String strongestType;
  final int peakHour;

  BehaviorInsights({
    required this.totalTasksCompleted,
    required this.strongestType,
    required this.peakHour,
  });

  factory BehaviorInsights.fromMap(Map<String, dynamic> map) => BehaviorInsights(
        totalTasksCompleted: map['totalTasksCompleted'] as int? ?? 0,
        strongestType: map['strongestType'] as String? ?? 'action',
        peakHour: map['peakHour'] as int? ?? 9,
      );
}

/// Response from smart task recommendation
class SmartRecommendationResponse {
  final bool success;
  final TaskModel? task;
  final RecommendationReasoning? reasoning;
  final BehaviorInsights? behaviorInsights;
  final String? error;

  SmartRecommendationResponse({
    required this.success,
    this.task,
    this.reasoning,
    this.behaviorInsights,
    this.error,
  });

  factory SmartRecommendationResponse.fromMap(Map<String, dynamic> map) {
    final recommendation = map['recommendation'] as Map<String, dynamic>?;

    TaskModel? task;
    RecommendationReasoning? reasoning;
    BehaviorInsights? insights;

    if (recommendation != null) {
      final taskMap = recommendation['task'] as Map<String, dynamic>?;
      if (taskMap != null) {
        task = TaskModel.fromMap(taskMap, taskMap['id'] as String? ?? '');
      }

      final reasoningMap = recommendation['reasoning'] as Map<String, dynamic>?;
      if (reasoningMap != null) {
        reasoning = RecommendationReasoning.fromMap(reasoningMap);
      }

      final insightsMap =
          recommendation['behaviorInsights'] as Map<String, dynamic>?;
      if (insightsMap != null) {
        insights = BehaviorInsights.fromMap(insightsMap);
      }
    }

    return SmartRecommendationResponse(
      success: map['success'] as bool? ?? false,
      task: task,
      reasoning: reasoning,
      behaviorInsights: insights,
      error: map['error'] as String?,
    );
  }
}

