import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Comprehensive analytics service for tracking user behavior and engagement
/// 
/// Events are stored in Firestore 'analytics' collection with structure:
/// - event: String (event name)
/// - category: String (event category for filtering)
/// - data: Map (event-specific data)
/// - userId: String (user identifier)
/// - sessionId: String (session identifier)
/// - timestamp: String (ISO8601 timestamp)
/// - platform: String (ios/android/web)
class AnalyticsService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  // Session tracking
  String? _sessionId;
  DateTime? _sessionStart;
  String? _currentScreen;
  
  AnalyticsService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  
  /// Initialize a new session
  void startSession() {
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _sessionStart = DateTime.now();
    logEvent(
      event: 'session_start',
      category: EventCategory.session,
      data: {},
    );
  }
  
  /// End the current session
  void endSession() {
    if (_sessionStart != null) {
      final duration = DateTime.now().difference(_sessionStart!).inSeconds;
      logEvent(
        event: 'session_end',
        category: EventCategory.session,
        data: {
          'duration_seconds': duration,
          'screens_visited': _currentScreen,
        },
      );
    }
    _sessionId = null;
    _sessionStart = null;
  }
  
  /// Core event logging method
  Future<void> logEvent({
    required String event,
    required String category,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(AppConstants.analyticsCollection).add({
        'event': event,
        'category': category,
        'data': data,
        'userId': currentUserId,
        'sessionId': _sessionId,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': defaultTargetPlatform.name,
      });
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }
  
  // ============ SCREEN TRACKING ============
  
  /// Track screen view
  Future<void> trackScreenView(String screenName) async {
    final previousScreen = _currentScreen;
    _currentScreen = screenName;
    
    await logEvent(
      event: 'screen_view',
      category: EventCategory.navigation,
      data: {
        'screen_name': screenName,
        'previous_screen': previousScreen,
      },
    );
  }
  
  // ============ AUTH EVENTS ============
  
  /// Track sign in attempt
  Future<void> trackSignInAttempt(String method) async {
    await logEvent(
      event: 'sign_in_attempt',
      category: EventCategory.auth,
      data: {'method': method},
    );
  }
  
  /// Track sign in success
  Future<void> trackSignInSuccess(String method) async {
    await logEvent(
      event: 'sign_in_success',
      category: EventCategory.auth,
      data: {'method': method},
    );
  }
  
  /// Track sign in failure
  Future<void> trackSignInFailure(String method, String error) async {
    await logEvent(
      event: 'sign_in_failure',
      category: EventCategory.auth,
      data: {
        'method': method,
        'error': error,
      },
    );
  }
  
  /// Track sign up attempt
  Future<void> trackSignUpAttempt(String method) async {
    await logEvent(
      event: 'sign_up_attempt',
      category: EventCategory.auth,
      data: {'method': method},
    );
  }
  
  /// Track sign up success
  Future<void> trackSignUpSuccess(String method) async {
    await logEvent(
      event: 'sign_up_success',
      category: EventCategory.auth,
      data: {'method': method},
    );
  }
  
  /// Track sign up failure
  Future<void> trackSignUpFailure(String method, String error) async {
    await logEvent(
      event: 'sign_up_failure',
      category: EventCategory.auth,
      data: {
        'method': method,
        'error': error,
      },
    );
  }
  
  /// Track sign out
  Future<void> trackSignOut() async {
    await logEvent(
      event: 'sign_out',
      category: EventCategory.auth,
      data: {},
    );
  }
  
  // ============ ONBOARDING EVENTS ============
  
  /// Track onboarding step view
  Future<void> trackOnboardingStepView(int step, String stepName) async {
    await logEvent(
      event: 'onboarding_step_view',
      category: EventCategory.onboarding,
      data: {
        'step': step,
        'step_name': stepName,
      },
    );
  }
  
  /// Track onboarding step complete
  Future<void> trackOnboardingStepComplete(int step, String stepName, Map<String, dynamic>? selection) async {
    await logEvent(
      event: 'onboarding_step_complete',
      category: EventCategory.onboarding,
      data: {
        'step': step,
        'step_name': stepName,
        'selection': selection,
      },
    );
  }
  
  /// Track onboarding skip
  Future<void> trackOnboardingSkip(int atStep) async {
    await logEvent(
      event: 'onboarding_skip',
      category: EventCategory.onboarding,
      data: {'at_step': atStep},
    );
  }
  
  /// Track onboarding complete
  Future<void> trackOnboardingComplete(Map<String, dynamic> selections) async {
    await logEvent(
      event: 'onboarding_complete',
      category: EventCategory.onboarding,
      data: selections,
    );
  }
  
  // ============ FEATURE ENGAGEMENT EVENTS ============
  
  /// Track task view (before starting)
  Future<void> trackTaskView(String taskId, String taskType) async {
    await logEvent(
      event: 'task_view',
      category: EventCategory.engagement,
      data: {
        'task_id': taskId,
        'task_type': taskType,
      },
    );
  }
  
  /// Track task start
  Future<void> trackTaskStart(String taskId, String taskType) async {
    await logEvent(
      event: 'task_start',
      category: EventCategory.engagement,
      data: {
        'task_id': taskId,
        'task_type': taskType,
      },
    );
  }
  
  /// Track task complete
  Future<void> trackTaskComplete(String taskId, String taskType, int xpEarned, int durationSeconds) async {
    await logEvent(
      event: 'task_complete',
      category: EventCategory.engagement,
      data: {
        'task_id': taskId,
        'task_type': taskType,
        'xp_earned': xpEarned,
        'duration_seconds': durationSeconds,
      },
    );
  }
  
  /// Track task abandon (started but not completed)
  Future<void> trackTaskAbandon(String taskId, String taskType, int durationSeconds) async {
    await logEvent(
      event: 'task_abandon',
      category: EventCategory.engagement,
      data: {
        'task_id': taskId,
        'task_type': taskType,
        'duration_seconds': durationSeconds,
      },
    );
  }
  
  /// Track action view
  Future<void> trackActionView(String actionId, String category) async {
    await logEvent(
      event: 'action_view',
      category: EventCategory.engagement,
      data: {
        'action_id': actionId,
        'action_category': category,
      },
    );
  }
  
  /// Track action start
  Future<void> trackActionStart(String actionId, String category) async {
    await logEvent(
      event: 'action_start',
      category: EventCategory.engagement,
      data: {
        'action_id': actionId,
        'action_category': category,
      },
    );
  }
  
  /// Track action complete
  Future<void> trackActionComplete(String actionId, String category, int xpEarned) async {
    await logEvent(
      event: 'action_complete',
      category: EventCategory.engagement,
      data: {
        'action_id': actionId,
        'action_category': category,
        'xp_earned': xpEarned,
      },
    );
  }
  
  /// Track script/audacity view
  Future<void> trackScriptView(String scriptId, String riskLevel) async {
    await logEvent(
      event: 'script_view',
      category: EventCategory.engagement,
      data: {
        'script_id': scriptId,
        'risk_level': riskLevel,
      },
    );
  }
  
  /// Track script start
  Future<void> trackScriptStart(String scriptId, String riskLevel) async {
    await logEvent(
      event: 'script_start',
      category: EventCategory.engagement,
      data: {
        'script_id': scriptId,
        'risk_level': riskLevel,
      },
    );
  }
  
  /// Track script attempt (with outcome)
  Future<void> trackScriptAttempt(String scriptId, String outcome, int xpEarned, String riskLevel) async {
    await logEvent(
      event: 'script_attempt',
      category: EventCategory.engagement,
      data: {
        'script_id': scriptId,
        'outcome': outcome,
        'xp_earned': xpEarned,
        'risk_level': riskLevel,
      },
    );
  }
  
  /// Track ritual view
  Future<void> trackRitualView(String ritualId) async {
    await logEvent(
      event: 'ritual_view',
      category: EventCategory.engagement,
      data: {'ritual_id': ritualId},
    );
  }
  
  /// Track ritual start
  Future<void> trackRitualStart(String ritualId) async {
    await logEvent(
      event: 'ritual_start',
      category: EventCategory.engagement,
      data: {'ritual_id': ritualId},
    );
  }
  
  /// Track ritual complete
  Future<void> trackRitualComplete(String ritualId, int xpEarned) async {
    await logEvent(
      event: 'ritual_complete',
      category: EventCategory.engagement,
      data: {
        'ritual_id': ritualId,
        'xp_earned': xpEarned,
      },
    );
  }
  
  // ============ PROGRESS & ACHIEVEMENT EVENTS ============
  
  /// Track level up
  Future<void> trackLevelUp(int newLevel, int totalXp) async {
    await logEvent(
      event: 'level_up',
      category: EventCategory.progress,
      data: {
        'new_level': newLevel,
        'total_xp': totalXp,
      },
    );
  }
  
  /// Track streak update
  Future<void> trackStreakUpdate(int streak) async {
    await logEvent(
      event: 'streak_update',
      category: EventCategory.progress,
      data: {'streak': streak},
    );
  }
  
  /// Track badge earned
  Future<void> trackBadgeEarned(String badgeId, String badgeName) async {
    await logEvent(
      event: 'badge_earned',
      category: EventCategory.progress,
      data: {
        'badge_id': badgeId,
        'badge_name': badgeName,
      },
    );
  }
  
  // ============ AI FEATURE EVENTS ============
  
  /// Track AI insight viewed
  Future<void> trackAiInsightViewed() async {
    await logEvent(
      event: 'ai_insight_viewed',
      category: EventCategory.ai,
      data: {},
    );
  }
  
  /// Track AI recommendation interaction
  Future<void> trackAiRecommendationInteraction(String action, String taskId) async {
    await logEvent(
      event: 'ai_recommendation_interaction',
      category: EventCategory.ai,
      data: {
        'action': action,
        'task_id': taskId,
      },
    );
  }
  
  // ============ ERROR TRACKING ============
  
  /// Track error
  Future<void> trackError(String errorType, String message, String? stackTrace) async {
    await logEvent(
      event: 'error',
      category: EventCategory.error,
      data: {
        'error_type': errorType,
        'message': message,
        'stack_trace': stackTrace,
        'screen': _currentScreen,
      },
    );
  }
}

/// Event categories for filtering and dashboard organization
class EventCategory {
  static const String session = 'session';
  static const String navigation = 'navigation';
  static const String auth = 'auth';
  static const String onboarding = 'onboarding';
  static const String engagement = 'engagement';
  static const String progress = 'progress';
  static const String ai = 'ai';
  static const String error = 'error';
}
