import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/momentum_model.dart';
import '../constants/app_constants.dart';

/// Service for Firestore database operations
class FirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // ============ USER OPERATIONS ============

  /// Create or update user document
  Future<void> createUser(UserModel user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  /// Get user by ID
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  /// Stream user data
  Stream<UserModel?> streamUser(String uid) => _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, uid);
    });

  /// Update user profile after onboarding
  Future<void> updateUserProfile(String uid, UserProfile profile) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'profile': profile.toMap(),
    });
  }

  /// Update user XP and level
  Future<void> updateUserXp(String uid, int xpToAdd) async {
    final userDoc = await getUser(uid);
    if (userDoc == null) return;

    final newXpTotal = userDoc.xpTotal + xpToAdd;
    final newLevel = (newXpTotal ~/ AppConstants.xpPerLevel) + 1;

    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'xpTotal': newXpTotal,
      'level': newLevel,
      'lastActivity': DateTime.now().toIso8601String(),
    });
  }

  /// Update streak
  Future<void> updateStreak(String uid, int streak) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'streak': streak,
      'lastActivity': DateTime.now().toIso8601String(),
    });
  }

  // ============ TASK OPERATIONS ============

  /// Get all task templates
  Future<List<Map<String, dynamic>>> getTasks() async {
    final snapshot = await _firestore
        .collection(AppConstants.tasksCollection)
        .get();
    
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  /// Get random task by type
  Future<Map<String, dynamic>?> getRandomTaskByType(String type) async {
    final snapshot = await _firestore
        .collection(AppConstants.tasksCollection)
        .where('type', isEqualTo: type)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    
    final randomIndex = DateTime.now().millisecondsSinceEpoch % snapshot.docs.length;
    final doc = snapshot.docs[randomIndex];
    return {...doc.data(), 'id': doc.id};
  }

  /// Log user task completion
  Future<void> logUserTask(String uid, Map<String, dynamic> taskData) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.userTasksCollection)
        .add(taskData);
  }

  /// Get user tasks for date range
  Future<List<Map<String, dynamic>>> getUserTasks(
    String uid, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.userTasksCollection);
    
    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: endDate.toIso8601String());
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList();
  }

  // ============ SCRIPT OPERATIONS ============

  /// Get all scripts
  Future<List<Map<String, dynamic>>> getScripts() async {
    final snapshot = await _firestore
        .collection(AppConstants.scriptsCollection)
        .get();
    
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  /// Get scripts by category
  Future<List<Map<String, dynamic>>> getScriptsByCategory(String category) async {
    final snapshot = await _firestore
        .collection(AppConstants.scriptsCollection)
        .where('category', isEqualTo: category)
        .get();
    
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  /// Log user script attempt
  Future<void> logUserScript(String uid, Map<String, dynamic> scriptData) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.userScriptsCollection)
        .add(scriptData);
  }

  // ============ RITUAL OPERATIONS ============

  /// Get all rituals
  Future<List<Map<String, dynamic>>> getRituals() async {
    final snapshot = await _firestore
        .collection(AppConstants.ritualsCollection)
        .get();
    
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  /// Log user ritual completion
  Future<void> logUserRitual(String uid, Map<String, dynamic> ritualData) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.userRitualsCollection)
        .add(ritualData);
  }

  // ============ ACTION OPERATIONS ============

  /// Get all actions
  Future<List<Map<String, dynamic>>> getActions() async {
    final snapshot = await _firestore
        .collection(AppConstants.actionsCollection)
        .get();
    
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  /// Get actions by category
  Future<List<Map<String, dynamic>>> getActionsByCategory(String category) async {
    final snapshot = await _firestore
        .collection(AppConstants.actionsCollection)
        .where('category', isEqualTo: category)
        .get();
    
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  /// Log user action completion
  Future<void> logUserAction(String uid, Map<String, dynamic> actionData) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.userActionsCollection)
        .add(actionData);
  }

  // ============ BADGE OPERATIONS ============

  /// Get all badges
  Future<List<Map<String, dynamic>>> getBadges() async {
    final snapshot = await _firestore
        .collection(AppConstants.badgesCollection)
        .get();
    
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  /// Add badge to user
  Future<void> addUserBadge(String uid, String badgeId) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'badges': FieldValue.arrayUnion([
        {
          'badgeId': badgeId,
          'earnedAt': DateTime.now().toIso8601String(),
        }
      ]),
    });
  }

  // ============ ANALYTICS OPERATIONS ============

  /// Log analytics event
  Future<void> logAnalyticsEvent(String eventName, Map<String, dynamic> data) async {
    await _firestore.collection(AppConstants.analyticsCollection).add({
      'event': eventName,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'userId': currentUserId,
    });
  }

  // ============ MOMENTUM OPERATIONS ============

  /// Get current week's momentum data
  Future<WeeklyMomentum?> getCurrentWeekMomentum(String uid) async {
    final weekStart = _getWeekStart(DateTime.now());
    final weekEnd = _getWeekEnd(DateTime.now());

    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.momentumCollection)
        .where('weekStart', isEqualTo: weekStart.toIso8601String())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      // Create new momentum record for this week
      return _createWeekMomentum(uid, weekStart, weekEnd);
    }

    final doc = snapshot.docs.first;
    return WeeklyMomentum.fromMap(doc.data(), doc.id);
  }

  /// Create a new weekly momentum record
  Future<WeeklyMomentum> _createWeekMomentum(
    String uid,
    DateTime weekStart,
    DateTime weekEnd,
  ) async {
    // Get user's focus areas for theme generation
    final user = await getUser(uid);
    final focusAreas = user?.profile?.focusAreas ?? [];
    final weekOfYear = _getWeekOfYear(weekStart);
    final theme = WeeklyThemes.getThemeForWeek(focusAreas, weekOfYear);

    final momentum = WeeklyMomentum(
      id: '',
      userId: uid,
      weekStart: weekStart,
      weekEnd: weekEnd,
      weeklyTheme: theme,
      streakDays: user?.streak ?? 0,
    );

    final docRef = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.momentumCollection)
        .add(momentum.toMap());

    return momentum.copyWith(id: docRef.id);
  }

  /// Update momentum data
  Future<void> updateMomentum(WeeklyMomentum momentum) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(momentum.userId)
        .collection(AppConstants.momentumCollection)
        .doc(momentum.id)
        .update(momentum.toMap());
  }

  /// Get momentum history for the last N weeks
  Future<List<WeeklyMomentum>> getMomentumHistory(String uid, {int weeks = 4}) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: weeks * 7));

    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.momentumCollection)
        .where('weekStart', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .orderBy('weekStart', descending: true)
        .limit(weeks)
        .get();

    return snapshot.docs
        .map((doc) => WeeklyMomentum.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Save AI weekly summary to momentum record
  Future<void> saveMomentumSummary(String uid, String momentumId, String summary) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.momentumCollection)
        .doc(momentumId)
        .update({
      'aiSummary': summary,
      'summaryGeneratedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Helper to get the start of the week (Monday)
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - weekday + 1);
  }

  /// Helper to get the end of the week (Sunday)
  DateTime _getWeekEnd(DateTime date) {
    final weekStart = _getWeekStart(date);
    return weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }

  /// Helper to get week of year
  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(firstDayOfYear).inDays;
    return (daysDifference / 7).ceil() + 1;
  }
}
