import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/user_model.dart';

/// Provides authentication and user management functionality
class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  bool _isEditingProfile = false;
  String? _errorMessage;
  bool _isSaving = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isEditingProfile => _isEditingProfile;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  /// Clears any existing error messages
  void _clearError() {
    _errorMessage = null;
  }

  /// Initializes user data from local storage
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await loadUserDataLocally();
      if (user != null) {
        _currentUser = user;
      }
    } catch (e) {
      debugPrint('Failed to initialize user: $e');
      _errorMessage = 'Failed to load user data';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles profile editing mode
  void toggleEditingProfile() {
    _isEditingProfile = !_isEditingProfile;
    notifyListeners();
  }

  // ========== USER UPDATE METHODS ==========

  /// Updates user data with named parameters (recommended)
  Future<void> updateUser({
    String? name,
    String? email,
    double? weight,
    double? height,
    String? fitnessLevel,
    List<String>? fitnessGoals,
  }) async {
    if (_currentUser == null) return;

    try {
      _isSaving = true;
      _clearError();
      notifyListeners();

      _currentUser = _currentUser!.copyWith(
        name: name,
        email: email,
        weight: weight,
        height: height,
        fitnessLevel: fitnessLevel,
        fitnessGoals: fitnessGoals,
      );

      await _persistUserChanges();
    } catch (e) {
      _handleError('Failed to update user', e);
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Updates user with complete User object (legacy support)
  Future<void> updateUserWithObject(User updatedUser) async {
    if (_currentUser == null) return;

    try {
      _isSaving = true;
      _clearError();
      notifyListeners();

      _currentUser = updatedUser;
      await _persistUserChanges();
    } catch (e) {
      _handleError('Failed to update user', e);
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ========== AUTHENTICATION METHODS ==========

  /// Simulates user login
  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      _clearError();
      notifyListeners();

      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

      _currentUser = User(
        id: 'user123',
        name: 'Test User',
        email: email,
        joinDate: DateTime.now(),
        weight: 70.0,
        height: 1.75,
        fitnessLevel: 'Intermediate',
        fitnessGoals: ['Weight Loss', 'Muscle Gain'],
      );

      await _persistUserChanges();
    } catch (e) {
      _handleError('Login failed', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Simulates user registration
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required double weight,
    required double height,
    required String fitnessLevel,
    required List<String> fitnessGoals,
  }) async {
    try {
      _isLoading = true;
      _clearError();
      notifyListeners();

      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

      _currentUser = User(
        id: 'new_user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        joinDate: DateTime.now(),
        weight: weight,
        height: height,
        fitnessLevel: fitnessLevel,
        fitnessGoals: fitnessGoals,
      );

      await _persistUserChanges();
    } catch (e) {
      _handleError('Registration failed', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logs out the current user
  Future<void> logout() async {
    try {
      _isLoading = true;
      _clearError();
      notifyListeners();

      await clearUserDataLocally();
      _currentUser = null;
    } catch (e) {
      _handleError('Logout failed', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== PERSISTENCE METHODS ==========

  /// Saves all user data to local storage
  Future<void> saveUserDataLocally(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString('user_id', user.id),
        prefs.setString('user_name', user.name),
        prefs.setString('user_email', user.email),
        prefs.setDouble('user_weight', user.weight ?? 0.0),
        prefs.setDouble('user_height', user.height ?? 0.0),
        prefs.setString('user_fitness_level', user.fitnessLevel ?? 'Beginner'),
        prefs.setStringList('user_fitness_goals', user.fitnessGoals ?? []),
        prefs.setString('user_join_date', user.joinDate.toIso8601String()),
      ]);
    } catch (e) {
      debugPrint('Failed to save user data locally: $e');
      rethrow;
    }
  }

  /// Loads user data from local storage
  Future<User?> loadUserDataLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) return null;

      final joinDateString = prefs.getString('user_join_date');
      final joinDate = joinDateString != null
          ? DateTime.parse(joinDateString)
          : DateTime.now();

      return User(
        id: userId,
        name: prefs.getString('user_name') ?? '',
        email: prefs.getString('user_email') ?? '',
        weight: prefs.getDouble('user_weight'),
        height: prefs.getDouble('user_height'),
        fitnessLevel: prefs.getString('user_fitness_level') ?? 'Beginner',
        fitnessGoals: prefs.getStringList('user_fitness_goals') ?? [],
        joinDate: joinDate,
      );
    } catch (e) {
      debugPrint('Failed to load user data: $e');
      return null;
    }
  }

  /// Clears all locally stored user data
  Future<void> clearUserDataLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove('user_id'),
        prefs.remove('user_name'),
        prefs.remove('user_email'),
        prefs.remove('user_weight'),
        prefs.remove('user_height'),
        prefs.remove('user_fitness_level'),
        prefs.remove('user_fitness_goals'),
        prefs.remove('user_join_date'),
        prefs.remove('user_nutrition_preferences'),
      ]);
    } catch (e) {
      debugPrint('Failed to clear user data: $e');
      rethrow;
    }
  }

  // ========== PRIVATE HELPERS ==========

  /// Persists user changes to local storage
  Future<void> _persistUserChanges() async {
    if (_currentUser != null) {
      await saveUserDataLocally(_currentUser!);
    }
  }

  /// Handles errors consistently
  void _handleError(String message, dynamic error) {
    _errorMessage = '$message: ${error.toString()}';
    debugPrint(_errorMessage!);
  }


}