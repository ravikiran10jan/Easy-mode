import 'package:cloud_functions/cloud_functions.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../models/momentum_model.dart';

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

  /// Generate a personalized weekly plan using the Planner Agent
  /// Uses multi-step reasoning with tool calls
  Future<WeeklyPlanResponse> generateWeeklyPlan({
    String? userGoal,
    int weekNumber = 1,
    bool forceRegenerate = false,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'generateWeeklyPlan',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );

      final result = await callable.call<Map<String, dynamic>>({
        'userGoal': userGoal,
        'weekNumber': weekNumber,
        'forceRegenerate': forceRegenerate,
      });

      return WeeklyPlanResponse.fromMap(
        Map<String, dynamic>.from(result.data),
      );
    } catch (e) {
      return WeeklyPlanResponse(
        success: false,
        source: 'error',
        message: 'Failed to generate weekly plan',
        error: e.toString(),
      );
    }
  }

  /// Let the Coach decide what task to do right now
  /// Shows detailed reasoning to the user
  Future<CoachDecidesResponse> coachDecides() async {
    try {
      final callable = _functions.httpsCallable(
        'coachDecides',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      final result = await callable.call<Map<String, dynamic>>({});

      return CoachDecidesResponse.fromMap(
        Map<String, dynamic>.from(result.data),
      );
    } catch (e) {
      // Return a fallback response with a default task when cloud function is unavailable
      return _generateFallbackCoachDecision();
    }
  }

  /// Generate a fallback coach decision when cloud function is unavailable
  CoachDecidesResponse _generateFallbackCoachDecision() {
    final hour = DateTime.now().hour;
    final timeOfDay = hour < 12 ? 'morning' : (hour < 17 ? 'afternoon' : 'evening');
    
    // Select task based on time of day
    final TaskModel task;
    final String whyNow;
    final String expectedOutcome;
    
    if (hour < 10) {
      task = TaskModel(
        id: 'fallback_morning',
        title: 'Start with a mindful moment',
        description: 'Take 5 minutes to breathe deeply and set your intention for the day. What one thing do you want to accomplish?',
        type: 'action',
        estimatedMinutes: 5,
        xpReward: 50,
        category: 'mindfulness',
      );
      whyNow = 'Morning is the perfect time to set your intention before the day gets busy.';
      expectedOutcome = 'You\'ll feel centered and focused for the day ahead.';
    } else if (hour < 14) {
      task = TaskModel(
        id: 'fallback_midday',
        title: 'Take one bold step',
        description: 'Identify one thing you\'ve been putting off and take the first small action toward it right now.',
        type: 'audacity',
        estimatedMinutes: 10,
        xpReward: 100,
        category: 'productivity',
        riskLevel: 'low',
      );
      whyNow = 'Your energy is high right now - perfect for tackling something you\'ve been avoiding.';
      expectedOutcome = 'You\'ll break through procrastination and build momentum.';
    } else if (hour < 18) {
      task = TaskModel(
        id: 'fallback_afternoon',
        title: 'Celebrate a small win',
        description: 'Think of one thing you accomplished today, no matter how small. Acknowledge it and give yourself credit.',
        type: 'enjoy',
        estimatedMinutes: 5,
        xpReward: 50,
        category: 'reflection',
      );
      whyNow = 'Afternoon is a great time to recognize progress and recharge your motivation.';
      expectedOutcome = 'You\'ll feel more positive and motivated to continue.';
    } else {
      task = TaskModel(
        id: 'fallback_evening',
        title: 'Reflect on today\'s growth',
        description: 'Take a moment to write down one thing you learned or one way you grew today.',
        type: 'action',
        estimatedMinutes: 5,
        xpReward: 50,
        category: 'reflection',
      );
      whyNow = 'Evening reflection helps consolidate your growth and prepares you for tomorrow.';
      expectedOutcome = 'You\'ll sleep better knowing you made progress today.';
    }

    return CoachDecidesResponse(
      success: true,
      task: task,
      reasoning: CoachDecisionReasoning(
        headline: 'Here\'s what I recommend right now',
        whyNow: whyNow,
        expectedOutcome: expectedOutcome,
        confidenceLevel: 'HIGH',
        alternativeConsidered: 'This recommendation is based on the time of day and general best practices.',
      ),
      coachMessage: 'I\'ve picked something perfect for this $timeOfDay. Trust the process!',
      context: CoachDecisionContext(
        streak: 0,
        completedToday: 0,
        timeOfDay: timeOfDay,
        energyAlignment: 'balanced',
      ),
    );
  }

  /// Generate AI weekly summary for momentum journal
  /// Called on Sunday to reflect on the week's progress
  Future<WeeklySummaryResponse> generateWeeklySummary({
    required WeeklyMomentum momentum,
    UserModel? user,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'generateWeeklySummary',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      final result = await callable.call<Map<String, dynamic>>({
        'momentum': {
          'weeklyTheme': momentum.weeklyTheme,
          'actionsCompleted': momentum.actionsCompleted,
          'boldMoments': momentum.boldMoments,
          'joyCaptured': momentum.joyCaptured,
          'streakDays': momentum.streakDays,
          'momentumScore': momentum.momentumScore,
        },
        'userContext': user != null
            ? {
                'name': user.name,
                'focusAreas': user.profile?.focusAreas,
                'streak': user.streak,
                'level': user.level,
              }
            : null,
      });

      return WeeklySummaryResponse.fromMap(
        Map<String, dynamic>.from(result.data),
      );
    } catch (e) {
      // Generate a fallback summary locally
      return _generateFallbackSummary(momentum, user);
    }
  }

  /// Generate a fallback summary when cloud function is unavailable
  WeeklySummaryResponse _generateFallbackSummary(
    WeeklyMomentum momentum,
    UserModel? user,
  ) {
    final name = user?.name ?? 'there';
    final total = momentum.totalActivities;
    final streak = momentum.streakDays;

    String summary;
    if (total >= 10 && streak >= 5) {
      summary = "You're on fire, $name! You showed up $streak days this week and completed $total activities. That's Easy Mode in action. Keep this momentum going!";
    } else if (total >= 5) {
      summary = "Great week, $name! You completed $total activities and made real progress. Remember, it's about consistency, not perfection. You're building something great.";
    } else if (total >= 1) {
      summary = "You showed up this week, $name! Every action counts. You completed $total activities. Next week, let's build on this foundation together.";
    } else {
      summary = "Hey $name, this week was quiet - and that's okay. Life happens. The important thing is you're here now. Let's make next week count!";
    }

    return WeeklySummaryResponse(
      success: true,
      summary: summary,
      encouragement: 'Every small step forward matters.',
      nextWeekFocus: momentum.weeklyTheme,
    );
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

// ============ AGENTIC PLANNING MODELS ============

/// Daily task in a weekly plan
class DailyPlanTask {
  final String dayOfWeek;
  final String title;
  final String type;
  final int estimatedMinutes;
  final int difficulty;
  final String whyToday;
  final bool completed;

  DailyPlanTask({
    required this.dayOfWeek,
    required this.title,
    required this.type,
    required this.estimatedMinutes,
    required this.difficulty,
    required this.whyToday,
    this.completed = false,
  });

  factory DailyPlanTask.fromMap(Map<String, dynamic> map) => DailyPlanTask(
        dayOfWeek: map['dayOfWeek'] as String? ?? '',
        title: map['title'] as String? ?? '',
        type: map['type'] as String? ?? 'action',
        estimatedMinutes: map['estimatedMinutes'] as int? ?? 5,
        difficulty: map['difficulty'] as int? ?? 3,
        whyToday: map['whyToday'] as String? ?? '',
        completed: map['completed'] as bool? ?? false,
      );
}

/// Weekly milestone in a plan
class WeeklyMilestone {
  final int weekNumber;
  final String title;
  final String description;
  final String focusArea;
  final int difficultyLevel;
  final List<DailyPlanTask> dailyTasks;

  WeeklyMilestone({
    required this.weekNumber,
    required this.title,
    required this.description,
    required this.focusArea,
    required this.difficultyLevel,
    required this.dailyTasks,
  });

  factory WeeklyMilestone.fromMap(Map<String, dynamic> map) => WeeklyMilestone(
        weekNumber: map['weekNumber'] as int? ?? 1,
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        focusArea: map['focusArea'] as String? ?? 'action',
        difficultyLevel: map['difficultyLevel'] as int? ?? 3,
        dailyTasks: (map['dailyTasks'] as List<dynamic>?)
                ?.map((t) => DailyPlanTask.fromMap(t as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

/// Weekly plan generated by the Planner Agent
class WeeklyPlan {
  final String id;
  final int weekNumber;
  final String startDate;
  final String endDate;
  final String userGoal;
  final List<WeeklyMilestone> milestones;
  final int currentMilestone;
  final int difficultyLevel;
  final double completionRate;
  final String agentReasoning;

  WeeklyPlan({
    required this.id,
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.userGoal,
    required this.milestones,
    required this.currentMilestone,
    required this.difficultyLevel,
    required this.completionRate,
    required this.agentReasoning,
  });

  factory WeeklyPlan.fromMap(Map<String, dynamic> map) => WeeklyPlan(
        id: map['id'] as String? ?? '',
        weekNumber: map['weekNumber'] as int? ?? 1,
        startDate: map['startDate'] as String? ?? '',
        endDate: map['endDate'] as String? ?? '',
        userGoal: map['userGoal'] as String? ?? '',
        milestones: (map['milestones'] as List<dynamic>?)
                ?.map((m) => WeeklyMilestone.fromMap(m as Map<String, dynamic>))
                .toList() ??
            [],
        currentMilestone: map['currentMilestone'] as int? ?? 1,
        difficultyLevel: map['difficultyLevel'] as int? ?? 3,
        completionRate: (map['completionRate'] as num?)?.toDouble() ?? 0.0,
        agentReasoning: map['agentReasoning'] as String? ?? '',
      );

  /// Get today's planned task from this week's milestone
  DailyPlanTask? getTodaysTask() {
    final dayOfWeek = [
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday'
    ][DateTime.now().weekday % 7];

    final currentMilestoneData =
        milestones.where((m) => m.weekNumber == currentMilestone).firstOrNull;
    if (currentMilestoneData == null) return null;

    return currentMilestoneData.dailyTasks
        .where((t) => t.dayOfWeek.toLowerCase() == dayOfWeek)
        .firstOrNull;
  }
}

/// Response from generateWeeklyPlan Cloud Function
class WeeklyPlanResponse {
  final bool success;
  final WeeklyPlan? plan;
  final String source;
  final AgentSteps? agentSteps;
  final String message;
  final String? error;

  WeeklyPlanResponse({
    required this.success,
    this.plan,
    required this.source,
    this.agentSteps,
    required this.message,
    this.error,
  });

  factory WeeklyPlanResponse.fromMap(Map<String, dynamic> map) =>
      WeeklyPlanResponse(
        success: map['success'] as bool? ?? false,
        plan: map['plan'] != null
            ? WeeklyPlan.fromMap(map['plan'] as Map<String, dynamic>)
            : null,
        source: map['source'] as String? ?? 'unknown',
        agentSteps: map['agentSteps'] != null
            ? AgentSteps.fromMap(map['agentSteps'] as Map<String, dynamic>)
            : null,
        message: map['message'] as String? ?? '',
        error: map['error'] as String?,
      );
}

/// Agent execution steps for transparency
class AgentSteps {
  final int milestonesCreated;
  final int dailyTasksPlanned;
  final bool difficultyAdjusted;
  final int iterations;

  AgentSteps({
    required this.milestonesCreated,
    required this.dailyTasksPlanned,
    required this.difficultyAdjusted,
    required this.iterations,
  });

  factory AgentSteps.fromMap(Map<String, dynamic> map) => AgentSteps(
        milestonesCreated: map['milestonesCreated'] as int? ?? 0,
        dailyTasksPlanned: map['dailyTasksPlanned'] as int? ?? 0,
        difficultyAdjusted: map['difficultyAdjusted'] as bool? ?? false,
        iterations: map['iterations'] as int? ?? 0,
      );
}

// ============ COACH DECIDES MODELS ============

/// Reasoning from the Coach Decides agent
class CoachDecisionReasoning {
  final String headline;
  final String whyNow;
  final String expectedOutcome;
  final String confidenceLevel;
  final String? alternativeConsidered;

  CoachDecisionReasoning({
    required this.headline,
    required this.whyNow,
    required this.expectedOutcome,
    required this.confidenceLevel,
    this.alternativeConsidered,
  });

  factory CoachDecisionReasoning.fromMap(Map<String, dynamic> map) =>
      CoachDecisionReasoning(
        headline: map['headline'] as String? ?? '',
        whyNow: map['whyNow'] as String? ?? '',
        expectedOutcome: map['expectedOutcome'] as String? ?? '',
        confidenceLevel: map['confidenceLevel'] as String? ?? 'MEDIUM',
        alternativeConsidered: map['alternativeConsidered'] as String?,
      );
}

/// Context information from Coach Decides
class CoachDecisionContext {
  final int streak;
  final int completedToday;
  final String timeOfDay;
  final String energyAlignment;

  CoachDecisionContext({
    required this.streak,
    required this.completedToday,
    required this.timeOfDay,
    required this.energyAlignment,
  });

  factory CoachDecisionContext.fromMap(Map<String, dynamic> map) =>
      CoachDecisionContext(
        streak: map['streak'] as int? ?? 0,
        completedToday: map['completedToday'] as int? ?? 0,
        timeOfDay: map['timeOfDay'] as String? ?? 'morning',
        energyAlignment: map['energyAlignment'] as String? ?? 'normal',
      );
}

/// Response from Coach Decides Cloud Function
class CoachDecidesResponse {
  final bool success;
  final TaskModel? task;
  final CoachDecisionReasoning? reasoning;
  final String? coachMessage;
  final CoachDecisionContext? context;
  final String? error;

  CoachDecidesResponse({
    required this.success,
    this.task,
    this.reasoning,
    this.coachMessage,
    this.context,
    this.error,
  });

  factory CoachDecidesResponse.fromMap(Map<String, dynamic> map) {
    final decision = map['decision'] as Map<String, dynamic>?;

    TaskModel? task;
    CoachDecisionReasoning? reasoning;
    String? coachMessage;

    if (decision != null) {
      final taskMap = decision['task'] as Map<String, dynamic>?;
      if (taskMap != null) {
        task = TaskModel.fromMap(taskMap, taskMap['id'] as String? ?? '');
      }

      final reasoningMap = decision['reasoning'] as Map<String, dynamic>?;
      if (reasoningMap != null) {
        reasoning = CoachDecisionReasoning.fromMap(reasoningMap);
      }

      coachMessage = decision['coachMessage'] as String?;
    }

    return CoachDecidesResponse(
      success: map['success'] as bool? ?? false,
      task: task,
      reasoning: reasoning,
      coachMessage: coachMessage,
      context: map['context'] != null
          ? CoachDecisionContext.fromMap(map['context'] as Map<String, dynamic>)
          : null,
      error: map['error'] as String?,
    );
  }
}

// ============ WEEKLY SUMMARY MODELS ============

/// Response from AI weekly summary generation
class WeeklySummaryResponse {
  final bool success;
  final String summary;
  final String? encouragement;
  final String? nextWeekFocus;
  final String? error;

  WeeklySummaryResponse({
    required this.success,
    required this.summary,
    this.encouragement,
    this.nextWeekFocus,
    this.error,
  });

  factory WeeklySummaryResponse.fromMap(Map<String, dynamic> map) =>
      WeeklySummaryResponse(
        success: map['success'] as bool? ?? false,
        summary: map['summary'] as String? ?? '',
        encouragement: map['encouragement'] as String?,
        nextWeekFocus: map['nextWeekFocus'] as String?,
        error: map['error'] as String?,
      );
}

// ============ AI CHAT COACH MODELS ============

/// Chat message for conversation history
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        role: map['role'] as String? ?? 'user',
        content: map['content'] as String? ?? '',
        timestamp: map['timestamp'] != null
            ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Metadata from chat response
class ChatMetadata {
  final int memoriesUsed;
  final bool wasImproved;
  final int confidenceScore;

  ChatMetadata({
    required this.memoriesUsed,
    required this.wasImproved,
    required this.confidenceScore,
  });

  factory ChatMetadata.fromMap(Map<String, dynamic> map) {
    final selfReflection = map['selfReflection'] as Map<String, dynamic>?;
    return ChatMetadata(
      memoriesUsed: map['memoriesUsed'] as int? ?? 0,
      wasImproved: selfReflection?['wasImproved'] as bool? ?? false,
      confidenceScore: selfReflection?['confidenceScore'] as int? ?? 4,
    );
  }
}

/// Response from AI chat coach
class ChatWithCoachResponse {
  final bool success;
  final String message;
  final ChatMetadata? metadata;
  final String? error;

  ChatWithCoachResponse({
    required this.success,
    required this.message,
    this.metadata,
    this.error,
  });

  factory ChatWithCoachResponse.fromMap(Map<String, dynamic> map) =>
      ChatWithCoachResponse(
        success: map['success'] as bool? ?? false,
        message: map['message'] as String? ?? '',
        metadata: map['metadata'] != null
            ? ChatMetadata.fromMap(map['metadata'] as Map<String, dynamic>)
            : null,
        error: map['error'] as String?,
      );
}

// ============ RESILIENCE SUPPORT MODELS ============

/// Micro action from resilience support
class ResilienceMicroAction {
  final String title;
  final String description;
  final int timeMinutes;

  ResilienceMicroAction({
    required this.title,
    required this.description,
    required this.timeMinutes,
  });

  factory ResilienceMicroAction.fromMap(Map<String, dynamic> map) =>
      ResilienceMicroAction(
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        timeMinutes: map['timeMinutes'] as int? ?? 5,
      );
}

/// Support content from resilience agent
class ResilienceSupport {
  final String validation;
  final String reframe;
  final String reminder;
  final ResilienceMicroAction microAction;
  final String closingMessage;

  ResilienceSupport({
    required this.validation,
    required this.reframe,
    required this.reminder,
    required this.microAction,
    required this.closingMessage,
  });

  factory ResilienceSupport.fromMap(Map<String, dynamic> map) =>
      ResilienceSupport(
        validation: map['validation'] as String? ?? '',
        reframe: map['reframe'] as String? ?? '',
        reminder: map['reminder'] as String? ?? '',
        microAction: ResilienceMicroAction.fromMap(
          map['microAction'] as Map<String, dynamic>? ?? {},
        ),
        closingMessage: map['closingMessage'] as String? ?? '',
      );
}

/// Response from resilience support
class ResilienceSupportResponse {
  final bool success;
  final ResilienceSupport? support;
  final int totalSuccesses;
  final int streak;
  final String? error;

  ResilienceSupportResponse({
    required this.success,
    this.support,
    this.totalSuccesses = 0,
    this.streak = 0,
    this.error,
  });

  factory ResilienceSupportResponse.fromMap(Map<String, dynamic> map) {
    final context = map['context'] as Map<String, dynamic>?;
    return ResilienceSupportResponse(
      success: map['success'] as bool? ?? false,
      support: map['support'] != null
          ? ResilienceSupport.fromMap(map['support'] as Map<String, dynamic>)
          : null,
      totalSuccesses: context?['totalSuccesses'] as int? ?? 0,
      streak: context?['streak'] as int? ?? 0,
      error: map['error'] as String?,
    );
  }
}

// ============ PROACTIVE NUDGE MODELS ============

/// AI-generated notification content
class ProactiveNudge {
  final String title;
  final String body;
  final String actionText;

  ProactiveNudge({
    required this.title,
    required this.body,
    required this.actionText,
  });

  factory ProactiveNudge.fromMap(Map<String, dynamic> map) => ProactiveNudge(
        title: map['title'] as String? ?? 'Easy Mode',
        body: map['body'] as String? ?? '',
        actionText: map['actionText'] as String? ?? 'Start',
      );
}

/// Response from proactive nudge generation
class ProactiveNudgeResponse {
  final bool success;
  final ProactiveNudge? notification;
  final String nudgeType;
  final int daysSinceActivity;
  final String? error;

  ProactiveNudgeResponse({
    required this.success,
    this.notification,
    this.nudgeType = 'daily',
    this.daysSinceActivity = 0,
    this.error,
  });

  factory ProactiveNudgeResponse.fromMap(Map<String, dynamic> map) {
    final context = map['context'] as Map<String, dynamic>?;
    return ProactiveNudgeResponse(
      success: map['success'] as bool? ?? false,
      notification: map['notification'] != null
          ? ProactiveNudge.fromMap(map['notification'] as Map<String, dynamic>)
          : null,
      nudgeType: context?['nudgeType'] as String? ?? 'daily',
      daysSinceActivity: context?['daysSinceActivity'] as int? ?? 0,
      error: map['error'] as String?,
    );
  }
}

// ============ AI SERVICE EXTENSION ============

/// Extension methods for new agentic AI features
extension AiServiceAgenticFeatures on AiService {
  /// Chat with the AI coach (conversational interface with memory)
  /// 
  /// Features:
  /// - Retrieval-augmented generation (RAG) using past conversations
  /// - Self-reflection loop for quality improvement
  /// - Multi-turn conversation support
  Future<ChatWithCoachResponse> chatWithCoach({
    required String message,
    List<ChatMessage> conversationHistory = const [],
    bool enableSelfReflection = true,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'chatWithCoach',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      final result = await callable.call<Map<String, dynamic>>({
        'message': message,
        'conversationHistory': conversationHistory.map((m) => m.toMap()).toList(),
        'enableSelfReflection': enableSelfReflection,
      });

      return ChatWithCoachResponse.fromMap(
        Map<String, dynamic>.from(result.data),
      );
    } catch (e) {
      return ChatWithCoachResponse(
        success: false,
        message: "I'm having trouble right now. Take a breath - small steps forward are still progress.",
        error: e.toString(),
      );
    }
  }

  /// Trigger resilience support when user is struggling
  /// 
  /// Call this when:
  /// - User reports a setback
  /// - Streak is broken
  /// - User hasn't been active for a while
  Future<ResilienceSupportResponse> triggerResilienceSupport({
    required String triggerType, // 'task_failed', 'streak_broken', 'user_reported', 'inactivity'
    String? setbackDetails,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'triggerResilienceSupport',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      final result = await callable.call<Map<String, dynamic>>({
        'triggerType': triggerType,
        'setbackDetails': setbackDetails,
      });

      return ResilienceSupportResponse.fromMap(
        Map<String, dynamic>.from(result.data),
      );
    } catch (e) {
      // Return fallback support
      return ResilienceSupportResponse(
        success: false,
        support: ResilienceSupport(
          validation: "It's okay to have hard moments. This is part of the journey.",
          reframe: "Every setback is actually data about what works for you.",
          reminder: "You've shown up before, and that counts.",
          microAction: ResilienceMicroAction(
            title: 'Take 3 deep breaths',
            description: 'This helps reset your nervous system.',
            timeMinutes: 1,
          ),
          closingMessage: "You're still here. That matters.",
        ),
        error: e.toString(),
      );
    }
  }

  /// Generate a proactive AI nudge notification
  Future<ProactiveNudgeResponse> generateProactiveNudge({
    String nudgeType = 'daily', // 'daily', 'streak_at_risk', 'comeback', 'celebration'
  }) async {
    try {
      final callable = _functions.httpsCallable('generateProactiveNudge');

      final result = await callable.call<Map<String, dynamic>>({
        'nudgeType': nudgeType,
      });

      return ProactiveNudgeResponse.fromMap(
        Map<String, dynamic>.from(result.data),
      );
    } catch (e) {
      return ProactiveNudgeResponse(
        success: false,
        notification: ProactiveNudge(
          title: 'Your Easy Mode moment',
          body: 'A small step forward is all it takes.',
          actionText: 'Start',
        ),
        error: e.toString(),
      );
    }
  }
}

