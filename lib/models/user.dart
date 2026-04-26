// lib/models/user.dart
// ─────────────────────────────────────────────
// User model and role enum.
// ─────────────────────────────────────────────

enum UserRole { student, admin }

class AppUser {
  final String id;
  final String? studentId;
  final String name;
  final String? email;
  final UserRole role;

  const AppUser({
    required this.id,
    this.studentId,
    required this.name,
    this.email,
    required this.role,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String docId) {
    return AppUser(
      id: docId,
      studentId: map['id'],
      name: map['name'] ?? '',
      email: map['email'],
      role: _parseUserRole(map['role']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': studentId ?? id,
      'name': name,
      if (email != null) 'email': email,
      'role': role.name,
    };
  }

  bool get isAdmin   => role == UserRole.admin;
  bool get isStudent => role == UserRole.student;

  static UserRole _parseUserRole(String? roleStr) {
    switch (roleStr) {
      case 'student':
        return UserRole.student;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.student; // default fallback
    }
  }
}
