// lib/screens/login_screen.dart
// ─────────────────────────────────────────────
// Login screen — Student or Admin.
// Admin: admin / admin123
// Student: any non-empty credentials
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:kaye/data/app_data.dart';
import 'package:kaye/models/user.dart';
import 'package:kaye/theme/app_theme.dart';
import 'package:kaye/screens/signup_screen.dart';
import 'student/student_home_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ── State ─────────────────────────────────
  final _idController       = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey            = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading       = false;
  String? _errorMessage;
  UserRole _selectedRole = UserRole.student;

  // ── Helpers ───────────────────────────────

  void _toggleRole(UserRole role) {
    setState(() {
      _selectedRole  = role;
      _errorMessage  = null;
      _idController.clear();
      _passwordController.clear();
    });
  }

    Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    final id       = _idController.text.trim();
    final password = _passwordController.text.trim();

    try {
      AppUser? user;
      // Admin role: use Firebase authentication
      if (_selectedRole == UserRole.admin) {
        // Construct email from admin ID (admin -> admin@roomready.app)
        final adminEmail = '$id@roomready.app';
        user = await AppData.loginAdmin(id, password, adminEmail);
      } else {
        // Student role: use Firebase authentication
        user = await AppData.loginStudent(id, password);
      }

      setState(() => _isLoading = false);

      if (user == null) {
        setState(() => _errorMessage = 'Login failed. Please try again.');
        return;
      }

      // Navigate based on role
      if (!mounted) return;
      if (user.isAdmin) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const StudentHomeScreen()));
      }
    } catch (e) {
      setState(() {
        _isLoading    = false;
        _errorMessage = 'Login failed: $e';
      });
    }
  }

  // ── Build ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildRoleToggle(),
                const SizedBox(height: 28),
                _buildIdField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 8),
                _buildHint(),
                const SizedBox(height: 24),
                if (_errorMessage != null) _buildError(),
                _buildLoginButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo dot + name
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          const  Text(
              'RoomReady',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
    const Text(
          'Welcome back 👋',
          style:  TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sign in to check classroom availability.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _roleTab('Student', UserRole.student),
          _roleTab('Admin',   UserRole.admin),
        ],
      ),
    );
  }

  Widget _roleTab(String label, UserRole role) {
    final isActive = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => _toggleRole(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdField() {
    return TextFormField(
      controller: _idController,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: _selectedRole == UserRole.admin ? 'Admin ID' : 'Student ID / Email',
        hintText: _selectedRole == UserRole.admin ? 'admin' : 'e.g. 2023-00123',
        prefixIcon: const Icon(Icons.person_outline, size: 20),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your ID' : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleLogin(),
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: '••••••••',
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your password' : null,
    );
  }

  Widget _buildHint() {
    final hint = _selectedRole == UserRole.admin
        ? 'Admin login: ID = admin  •  Password = admin123'
        : 'Use your registered Student ID or email + password.';
    return Text(
      hint,
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.occupied.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.occupied.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.occupied, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.occupied,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Log In'),
        ),

        // Show sign-up link only for student role
        if (_selectedRole == UserRole.student) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}