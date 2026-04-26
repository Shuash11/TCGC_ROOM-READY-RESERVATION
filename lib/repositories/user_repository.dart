import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../data/app_data.dart';

class UserRepository {
  UserRepository._internal();
  static final UserRepository instance = UserRepository._internal();

  final FirestoreService _fs = FirestoreService.instance;

  // Helper to hash password with SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // 1. Fetch user by ID
  Future<AppUser?> fetchUserById(String uid) async {
    try {
      final doc = await _fs.users.doc(uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 2. Login student
  Future<AppUser?> loginStudent(String email, String password) async {
    try {
      final userCredential = await AuthService.instance.signIn(email, password);
      final uid = userCredential.user?.uid;
      if (uid == null) return null;
      
      final userDoc = await _fs.users.doc(uid).get();
      if (!userDoc.exists) return null;
      
      final user = AppUser.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);
      // Verify role is student
      if (user.role != UserRole.student) return null;
      
      return user;
    } catch (e) {
      return null;
    }
  }

  // 3. Login admin
  Future<AppUser?> loginAdmin(String username, String password, String email) async {
    print('loginAdmin called - username: $username, password: $password, email: $email');

    // Static admin username gate (UI-facing) - just validate the username "admin"
    if (username != AppData.adminId) {
      throw Exception('Invalid admin username.');
    }

    // Use the provided credentials to sign in to Firebase
    print('Attempting Firebase sign-in with: $email');
    final userCredential = await AuthService.instance.signIn(email, password);
    final uid = userCredential.user?.uid;
    print('Firebase sign-in success, uid: $uid');

    if (uid == null) {
      throw Exception('Admin sign-in failed. Try again.');
    }

    final userDoc = await _fs.users.doc(uid).get();
    if (!userDoc.exists) {
      throw Exception(
          'Admin Firestore user doc missing. Create users/{adminUid} with role="admin".');
    }

    final user =
        AppUser.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);
    if (user.role != UserRole.admin) {
      throw Exception('This Firebase account is not an admin (role != "admin").');
    }

    return user;
  }

  // 4. Register student
  Future<AppUser?> registerStudent({
    required String name,
    required String id,
    required String email,
    required String password,
  }) async {
    // NOTE:
    // With your current Firestore rules, a student cannot query/search other user
    // documents (only their own). So we must NOT do "duplicate ID/email" Firestore
    // queries here. Duplicate emails are enforced by Firebase Auth.
    //
    // If you need guaranteed unique Student IDs, you must enforce it server-side
    // (Cloud Function) or redesign the users collection keying strategy.

    // Create Firebase Auth user (enforces unique email)
    final userCredential = await AuthService.instance.signUp(email, password);
    final uid = userCredential.user?.uid;
    if (uid == null) {
      throw Exception('Account creation failed. Please try again.');
    }

    final hashedPassword = _hashPassword(password);

    final user = AppUser(
      id: uid,
      studentId: id,
      name: name,
      email: email,
      role: UserRole.student,
    );

    await _fs.users.doc(uid).set({
      ...user.toMap(),
      'passwordHash': hashedPassword,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return user;
  }

  // 5. Logout
  void logout() {
    AuthService.instance.signOut();
  }
}