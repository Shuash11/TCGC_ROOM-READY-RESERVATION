import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Returns the Firebase User on success, throws on failure
  Future<UserCredential> signIn(String email, String password) async {
    print('Attempting to sign in with email: $email');
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Sign in successful, uid: ${result.user?.uid}');
      return result;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: code=${e.code}, message=${e.message}');
      switch (e.code) {
        case 'user-not-found':
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No user found for this email.',
          );
        case 'wrong-password':
          throw FirebaseAuthException(
            code: 'wrong-password',
            message: 'Wrong password provided for this user.',
          );
        case 'invalid-credential':
          throw FirebaseAuthException(
            code: 'invalid-credential',
            message: 'The supplied credential is incorrect, malformed, or has expired.',
          );
        default:
          rethrow;
      }
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Creates the Firebase Auth account
  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Rethrow with meaningful messages
      switch (e.code) {
        case 'email-already-in-use':
          throw FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'The account already exists for that email.',
          );
        case 'weak-password':
          throw FirebaseAuthException(
            code: 'weak-password',
            message: 'The password provided is too weak.',
          );
        default:
          rethrow;
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentFirebaseUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}