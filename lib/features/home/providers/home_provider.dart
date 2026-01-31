import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/models/task_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/ai_service.dart';

/// State for daily task with AI reasoning
class DailyTaskState {
  final TaskModel? task;
  final bool isTimerRunning;
  final Duration elapsedTime;
  final bool isCompleted;
  final bool isLoading;
  final RecommendationReasoning? aiReasoning;
  final BehaviorInsights? behaviorInsights;

  DailyTaskState({
    this.task,
    this.isTimerRunning = false,
    this.elapsedTime = Duration.zero,
    this.isCompleted = false,
    this.isLoading = false,
    this.aiReasoning,
    this.behaviorInsights,
  });

  DailyTaskState copyWith({
    TaskModel? task,
    bool? isTimerRunning,
    Duration? elapsedTime,
    bool? isCompleted,
    bool? isLoading,
    RecommendationReasoning? aiReasoning,
    BehaviorInsights? behaviorInsights,
  }) => DailyTaskState(
      task: task ?? this.task,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      aiReasoning: aiReasoning ?? this.aiReasoning,
      behaviorInsights: behaviorInsights ?? this.behaviorInsights,
    );
}

/// Smart recommendation response with task and reasoning
class SmartTaskRecommendation {
  final TaskModel task;
  final RecommendationReasoning? reasoning;
  final BehaviorInsights? insights;

  SmartTaskRecommendation({
    required this.task,
    this.reasoning,
    this.insights,
  });
}

/// Smart daily task provider using AI recommendations
final dailyTaskProvider = FutureProvider<SmartTaskRecommendation>((ref) async {
  final aiService = ref.watch(aiServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  // Try smart recommendation first
  final recommendation = await aiService.getSmartRecommendation();
  
  if (recommendation.success && recommendation.task != null) {
    return SmartTaskRecommendation(
      task: recommendation.task!,
      reasoning: recommendation.reasoning,
      insights: recommendation.behaviorInsights,
    );
  }
  
  // Fallback to simple rotation if AI fails
  final dayOfWeek = DateTime.now().weekday;
  String taskType;
  
  if (dayOfWeek % 3 == 1) {
    taskType = AppConstants.taskTypeAction;
  } else if (dayOfWeek % 3 == 2) {
    taskType = AppConstants.taskTypeAudacity;
  } else {
    taskType = AppConstants.taskTypeEnjoy;
  }
  
  final taskData = await firestoreService.getRandomTaskByType(taskType);
  
  if (taskData != null) {
    return SmartTaskRecommendation(
      task: TaskModel.fromMap(taskData, taskData['id'] as String),
    );
  }
  
  // Ultimate fallback
  return SmartTaskRecommendation(
    task: TaskModel(
      id: 'default',
      title: 'Take One Small Action',
      description: 'Pick one small task that\'s been on your mind and complete it in the next 5 minutes.',
      type: AppConstants.taskTypeAction,
      estimatedMinutes: 5,
      xpReward: AppConstants.xpTaskComplete,
    ),
  );
});

/// Task timer state provider
final taskTimerProvider = StateNotifierProvider<TaskTimerNotifier, DailyTaskState>((ref) => TaskTimerNotifier());

class TaskTimerNotifier extends StateNotifier<DailyTaskState> {
  TaskTimerNotifier() : super(DailyTaskState());

  void setTask(TaskModel task) {
    state = state.copyWith(task: task);
  }

  void startTimer() {
    state = state.copyWith(isTimerRunning: true);
  }

  void stopTimer() {
    state = state.copyWith(isTimerRunning: false);
  }

  void updateElapsedTime(Duration elapsed) {
    state = state.copyWith(elapsedTime: elapsed);
  }

  void completeTask() {
    state = state.copyWith(
      isCompleted: true,
      isTimerRunning: false,
    );
  }

  void reset() {
    state = DailyTaskState();
  }
}

/// Provider to track if today's task is completed
final todayTaskCompletedProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  
  final tasks = await firestoreService.getUserTasks(
    user.uid,
    startDate: startOfDay,
    endDate: endOfDay,
  );
  
  return tasks.any((t) => t['completed'] == true);
});
