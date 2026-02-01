import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';
import '../services/analytics_service.dart';
import '../models/user_model.dart';

/// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

/// Firestore service provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

/// AI service provider
final aiServiceProvider = Provider<AiService>((ref) => AiService());

/// Analytics service provider (singleton)
final analyticsServiceProvider = Provider<AnalyticsService>((ref) => AnalyticsService());

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService(
    firestoreService: ref.watch(firestoreServiceProvider),
  ));

/// Auth state stream provider
final authStateProvider = StreamProvider<User?>((ref) => ref.watch(authServiceProvider).authStateChanges);

/// Current user provider
final currentUserProvider = Provider<User?>((ref) => ref.watch(authStateProvider).value);

/// User data stream provider
final userDataProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamUser(uid);
});

/// Current user data provider (convenience)
final currentUserDataProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamUser(user.uid);
});
