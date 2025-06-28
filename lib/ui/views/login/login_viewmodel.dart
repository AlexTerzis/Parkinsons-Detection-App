import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../services/authentication_service.dart';

class LoginViewModel extends BaseViewModel {
  final AuthenticationService _authService = locator<AuthenticationService>();
  final NavigationService _navigationService = locator<NavigationService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- UI State ---
  bool _isLoginMode = true;
  UserRole _selectedRole = UserRole.patient;
  String? _errorMessage;
  bool _keepMeLoggedIn = false;

  // Form controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  // UI Toggles
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  // --- Getters ---
  bool get isLoginMode => _isLoginMode;
  UserRole get selectedRole => _selectedRole;
  String? get errorMessage => _errorMessage;
  bool get passwordVisible => _passwordVisible;
  bool get confirmPasswordVisible => _confirmPasswordVisible;
  bool get keepMeLoggedIn => _keepMeLoggedIn;

  // --- Setters / Actions ---
  void toggleMode() {
    _isLoginMode = !_isLoginMode;
    _errorMessage = null;
    notifyListeners();
  }

  void selectRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _passwordVisible = !_passwordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _confirmPasswordVisible = !_confirmPasswordVisible;
    notifyListeners();
  }

  void setKeepMeLoggedIn(bool value) {
    _keepMeLoggedIn = value;
    notifyListeners();
  }

  // --- Authentication Logic ---
  Future<void> authenticate({
    required String email,
    required String password,
    String? confirmPassword,
  }) async {
    if (!_isLoginMode && password != confirmPassword) {
      _setError('Passwords do not match.');
      return;
    }

    _setError(null);
    setBusy(true);

    try {
      if (_isLoginMode) {
        await _authService.signIn(email: email, password: password);
        if (kDebugMode) print('Login successful');
      } else {
        await _authService.signUp(
          email: email,
          password: password,
          userRole: _selectedRole,
          name: nameController.text.trim(),
        );
        if (kDebugMode) print('Sign-up successful');
      }

      if (_keepMeLoggedIn) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('keepMeLoggedIn', true);
      }

      await _navigateBasedOnRole();
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Authentication error');
    } catch (e) {
      _setError('An unexpected error occurred.');
    } finally {
      setBusy(false);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    if (email.isEmpty) {
      _setError('Please enter your email first.');
      return;
    }

    _setError(null);
    setBusy(true);

    try {
      await _authService.sendPasswordReset(email: email);
      if (kDebugMode) print('Password reset email sent.');
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Failed to send reset email.');
    } catch (_) {
      _setError('An unexpected error occurred.');
    } finally {
      setBusy(false);
    }
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // --- Validators ---
  String? validateEmail(String? email) {
    if (email == null || email.isEmpty) return 'Email is required';
    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) return 'Please enter a valid email address';
    return null;
  }

  String? validatePassword(String? password) {
    if (password == null || password.isEmpty) return 'Password is required';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? validateConfirmPassword(String? confirmPassword) {
    if (!_isLoginMode) {
      if (confirmPassword == null || confirmPassword.isEmpty) return 'Please confirm your password';
      if (confirmPassword != passwordController.text) return 'Passwords do not match';
    }
    return null;
  }

  String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Name is required';
    return null;
  }

  // --- Navigation ---
  Future<void> _navigateBasedOnRole() async {
    final User? currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      final doc = await _firestore.collection('users').doc(currentUser.uid).get();
      final role = doc.data()?['role'] ?? 'patient';

      if (role == 'doctor') {
        await _navigationService.navigateToDoctorView();
      } else {
        await _navigationService.navigateToPatienceView();
      }
    } catch (e) {
      if (kDebugMode) print('Error determining role: $e');
      if (_selectedRole == UserRole.doctor) {
        await _navigationService.navigateToDoctorView();
      } else {
        await _navigationService.navigateToPatienceView();
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
