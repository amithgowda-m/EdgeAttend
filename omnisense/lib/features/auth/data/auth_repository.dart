// lib/features/auth/data/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';

/// Repository encapsulating all Firebase Auth operations.
class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Stream of the current auth state — emits null when signed out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently authenticated user, or null.
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email:    email.trim(),
      password: password.trim(),
    );
  }

  /// Sign out the current user.
  Future<void> signOut() => _auth.signOut();

  /// Human-readable error message from a FirebaseAuthException.
  static String errorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No admin account found for this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid credentials. Check your email and password.';
      case 'invalid-email':
        return 'That email address is malformed.';
      case 'user-disabled':
        return 'This admin account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
