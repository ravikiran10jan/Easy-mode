/// App-wide constants for Easy Mode
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Easy Mode';
  static const String appTagline = 'Your AI Life Coach';

  // XP Values
  static const int xpTaskComplete = 100;
  static const int xpAudacityAttempt = 200;
  static const int xpAudacitySuccess = 100; // bonus
  static const double streakMultiplier = 0.10; // 10% per streak day starting day 3
  static const int streakBonusStartDay = 3;

  // Levels
  static const int xpPerLevel = 500;
  static const int maxLevel = 50;

  // Task Types
  static const String taskTypeAction = 'action';
  static const String taskTypeAudacity = 'audacity';
  static const String taskTypeEnjoy = 'enjoy';

  // Risk Levels
  static const String riskLow = 'low';
  static const String riskMedium = 'medium';
  static const String riskHigh = 'high';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String tasksCollection = 'tasks';
  static const String userTasksCollection = 'userTasks';
  static const String scriptsCollection = 'scripts';
  static const String userScriptsCollection = 'userScripts';
  static const String ritualsCollection = 'rituals';
  static const String userRitualsCollection = 'userRituals';
  static const String actionsCollection = 'actions';
  static const String userActionsCollection = 'userActions';
  static const String badgesCollection = 'badges';
  static const String analyticsCollection = 'analytics';
  static const String momentumCollection = 'momentum';

  // Shared Preferences Keys
  static const String prefOnboardingComplete = 'onboarding_complete';
  static const String prefNotificationTime = 'notification_time';
  static const String prefUserId = 'user_id';

  // Feature Flags
  static const String featureLlmEnabled = 'llm_enabled';
}
