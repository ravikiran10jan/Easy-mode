import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

/// Authentication service for Firebase Auth
class AuthService {
  final FirebaseAuth _auth;
  final FirestoreService _firestoreService;
  GoogleSignIn? _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    FirestoreService? firestoreService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  /// Lazy initialization of GoogleSignIn to avoid web client ID errors
  GoogleSignIn get googleSignIn {
    _googleSignIn ??= GoogleSignIn(
      // For web, you need to configure OAuth in Google Cloud Console
      // and add client ID here or in index.html meta tag
      scopes: ['email', 'profile'],
    );
    return _googleSignIn!;
  }

  /// Current user
  User? get currentUser => _auth.currentUser;

  /// Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      // Update display name
      if (name != null) {
        await credential.user!.updateDisplayName(name);
      }

      // Create user document in Firestore
      final user = UserModel(
        uid: credential.user!.uid,
        name: name ?? credential.user!.displayName,
        email: email,
        photoUrl: credential.user!.photoURL,
        createdAt: DateTime.now(),
      );
      await _firestoreService.createUser(user);
    }

    return credential;
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async => await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    // Google Sign-In is not fully configured for web without OAuth client ID
    // For MVP, show error message on web
    if (kIsWeb) {
      throw UnsupportedError(
        'Google Sign-In requires OAuth configuration. Use email/password for now.',
      );
    }

    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      return null; // User cancelled the sign-in
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credential
    final userCredential = await _auth.signInWithCredential(credential);

    if (userCredential.user != null) {
      // Check if user exists in Firestore
      final existingUser =
          await _firestoreService.getUser(userCredential.user!.uid);

      if (existingUser == null) {
        // Create new user document
        final user = UserModel(
          uid: userCredential.user!.uid,
          name: userCredential.user!.displayName,
          email: userCredential.user!.email,
          photoUrl: userCredential.user!.photoURL,
          createdAt: DateTime.now(),
        );
        await _firestoreService.createUser(user);
      }
    }

    return userCredential;
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleSignIn != null) {
      await _googleSignIn!.signOut();
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }
}
