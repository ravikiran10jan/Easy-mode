import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

/// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Firestore service provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});

/// Auth state stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

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
