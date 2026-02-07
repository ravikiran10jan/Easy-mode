import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/momentum_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_providers.dart';

/// Provider for current week's momentum data
final currentWeekMomentumProvider = FutureProvider<WeeklyMomentum?>((ref) async {
  final userData = await ref.watch(currentUserDataProvider.future);
  if (userData == null) return null;
  
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.getCurrentWeekMomentum(userData.uid);
});

/// Provider for momentum history (last 4 weeks)
final momentumHistoryProvider = FutureProvider<List<WeeklyMomentum>>((ref) async {
  final userData = await ref.watch(currentUserDataProvider.future);
  if (userData == null) return [];
  
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.getMomentumHistory(userData.uid, weeks: 4);
});

/// Provider for weekly theme based on user's focus areas
final weeklyThemeProvider = Provider<String>((ref) {
  final userData = ref.watch(currentUserDataProvider);
  
  return userData.maybeWhen(
    data: (user) {
      if (user?.profile == null) return 'Building momentum';
      
      final focusAreas = user!.profile!.focusAreas;
      final weekOfYear = _getWeekOfYear(DateTime.now());
      
      return WeeklyThemes.getThemeForWeek(focusAreas, weekOfYear);
    },
    orElse: () => 'Building momentum',
  );
});

/// Momentum state notifier for real-time updates
class MomentumNotifier extends StateNotifier<AsyncValue<WeeklyMomentum?>> {
  final Ref _ref;
  
  MomentumNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadMomentum();
  }

  Future<void> _loadMomentum() async {
    state = const AsyncValue.loading();
    try {
      final userData = await _ref.read(currentUserDataProvider.future);
      if (userData == null) {
        state = const AsyncValue.data(null);
        return;
      }
      
      final firestoreService = _ref.read(firestoreServiceProvider);
      final momentum = await firestoreService.getCurrentWeekMomentum(userData.uid);
      state = AsyncValue.data(momentum);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Increment action count
  Future<void> recordAction() async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final updated = current.copyWith(
      actionsCompleted: current.actionsCompleted + 1,
      momentumLevel: MomentumLevel.fromScore(current.momentumScore),
    );
    
    state = AsyncValue.data(updated);
    
    final firestoreService = _ref.read(firestoreServiceProvider);
    await firestoreService.updateMomentum(updated);
  }

  /// Increment bold moment count (audacity)
  Future<void> recordBoldMoment() async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final updated = current.copyWith(
      boldMoments: current.boldMoments + 1,
      momentumLevel: MomentumLevel.fromScore(current.momentumScore),
    );
    
    state = AsyncValue.data(updated);
    
    final firestoreService = _ref.read(firestoreServiceProvider);
    await firestoreService.updateMomentum(updated);
  }

  /// Increment joy captured count (ritual)
  Future<void> recordJoy() async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final updated = current.copyWith(
      joyCaptured: current.joyCaptured + 1,
      momentumLevel: MomentumLevel.fromScore(current.momentumScore),
    );
    
    state = AsyncValue.data(updated);
    
    final firestoreService = _ref.read(firestoreServiceProvider);
    await firestoreService.updateMomentum(updated);
  }

  /// Update streak days
  Future<void> updateStreak(int streak) async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final updated = current.copyWith(
      streakDays: streak,
      maxStreakThisWeek: streak > current.maxStreakThisWeek ? streak : current.maxStreakThisWeek,
      momentumLevel: MomentumLevel.fromScore(current.momentumScore),
    );
    
    state = AsyncValue.data(updated);
    
    final firestoreService = _ref.read(firestoreServiceProvider);
    await firestoreService.updateMomentum(updated);
  }

  /// Refresh momentum data from server
  Future<void> refresh() async => _loadMomentum();
}

/// Provider for momentum state management
final momentumNotifierProvider = StateNotifierProvider<MomentumNotifier, AsyncValue<WeeklyMomentum?>>((ref) => MomentumNotifier(ref));

/// Helper to get week of year
int _getWeekOfYear(DateTime date) {
  final firstDayOfYear = DateTime(date.year, 1, 1);
  final daysDifference = date.difference(firstDayOfYear).inDays;
  return (daysDifference / 7).ceil() + 1;
}

/// Helper to get the start of the current week (Monday)
DateTime getWeekStart(DateTime date) {
  final weekday = date.weekday;
  return DateTime(date.year, date.month, date.day - weekday + 1);
}

/// Helper to get the end of the current week (Sunday)
DateTime getWeekEnd(DateTime date) {
  final weekStart = getWeekStart(date);
  return weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
}
