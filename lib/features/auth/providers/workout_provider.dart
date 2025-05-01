import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../data/models/workout_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class WorkoutProvider with ChangeNotifier {
  final List<Workout> _workouts = [];
  final List<String> _favoriteWorkoutIds = [];
  final Map<String, DateTime> _workoutCompletions = {}; // Renamed from _workoutHistory for clarity

  WorkoutDifficulty? _selectedDifficulty;
  MuscleGroup? _selectedMuscleGroup;
  WorkoutType? _selectedWorkoutType;

  bool _showFavoritesOnly = false;
  bool _showRecommendedOnly = false;

  // Getters
  List<Workout> get workouts => _workouts;
  List<String> get favoriteWorkoutIds => _favoriteWorkoutIds;
  Map<String, DateTime> get workoutCompletions => _workoutCompletions;
  WorkoutDifficulty? get selectedDifficulty => _selectedDifficulty;
  MuscleGroup? get selectedMuscleGroup => _selectedMuscleGroup;
  WorkoutType? get selectedWorkoutType => _selectedWorkoutType;
  bool get showFavoritesOnly => _showFavoritesOnly;
  bool get showRecommendedOnly => _showRecommendedOnly;

  // Completion tracking methods
  List<Workout> getCompletedWorkouts() {
    return _workouts.where((workout) => _workoutCompletions.containsKey(workout.id)).toList();
  }

  List<Workout> getTodayCompletedWorkouts() {
    final today = DateTime.now();
    return _workouts.where((workout) {
      final completionDate = _workoutCompletions[workout.id];
      return completionDate != null &&
          completionDate.year == today.year &&
          completionDate.month == today.month &&
          completionDate.day == today.day;
    }).toList();
  }

  bool isWorkoutCompletedToday(String workoutId) {
    final completionDate = _workoutCompletions[workoutId];
    if (completionDate == null) return false;

    final today = DateTime.now();
    return completionDate.year == today.year &&
        completionDate.month == today.month &&
        completionDate.day == today.day;
  }

  Workout? getTodaysWorkout() {
    if (_workouts.isEmpty) return null;
    // Simple logic - return first workout for demo
    // In real app, you might have a schedule system
    return _workouts.first;
  }

  int getActiveDaysCount() {
    // Count unique days with workouts in the last 7 days
    final now = DateTime.now();
    final activeDays = _workoutCompletions.values
        .where((date) => now.difference(date) < const Duration(days: 7))
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet();
    return activeDays.length;
  }

  List<Map<String, dynamic>> getRecentActivities({int limit = 2}) {
    final sortedCompletions = _workoutCompletions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCompletions.take(limit).map((entry) {
      final workout = _workouts.firstWhere((w) => w.id == entry.key);
      return {
        'type': 'workout',
        'title': 'Completed ${workout.title}',
        'subtitle': '${workout.duration} mins • ${workout.calories} cal',
        'timestamp': entry.value,
      };
    }).toList();
  }

  // Workout management methods
  void addWorkout(Workout workout) {
    _workouts.add(workout);
    notifyListeners();
  }

  // In WorkoutProvider class
  Future<void> completeWorkout(String workoutId) async {
    if (!_workoutCompletions.containsKey(workoutId)) {
      _workoutCompletions[workoutId] = DateTime.now();
      notifyListeners();
      await _saveCompletionData();
    }
  }

// Add this method to count unique workout completions
  int get uniqueCompletedWorkoutCount {
    return _workoutCompletions.length;
  }

  void addToHistory(String workoutId) {
    completeWorkout(workoutId); // Alias for backward compatibility
  }

  // Favorite management
  void toggleFavorite(String workoutId) {
    if (_favoriteWorkoutIds.contains(workoutId)) {
      _favoriteWorkoutIds.remove(workoutId);
    } else {
      _favoriteWorkoutIds.add(workoutId);
    }
    notifyListeners();
  }

  bool isFavorite(String workoutId) => _favoriteWorkoutIds.contains(workoutId);

  bool wasRecentlyCompleted(String workoutId) {
    final completionDate = _workoutCompletions[workoutId];
    if (completionDate == null) return false;
    return DateTime.now().difference(completionDate) < const Duration(days: 3);
  }

  // Filter management
  void setFilters({
    WorkoutDifficulty? difficulty,
    MuscleGroup? muscleGroup,
    WorkoutType? workoutType,
  }) {
    _selectedDifficulty = difficulty;
    _selectedMuscleGroup = muscleGroup;
    _selectedWorkoutType = workoutType;
    notifyListeners();
  }

  void toggleShowFavoritesOnly() {
    _showFavoritesOnly = !_showFavoritesOnly;
    if (_showFavoritesOnly) _showRecommendedOnly = false;
    notifyListeners();
  }

  void toggleShowRecommendedOnly() {
    _showRecommendedOnly = !_showRecommendedOnly;
    if (_showRecommendedOnly) _showFavoritesOnly = false;
    notifyListeners();
  }

  void clearFilters() {
    _selectedDifficulty = null;
    _selectedMuscleGroup = null;
    _selectedWorkoutType = null;
    notifyListeners();
  }

  // Stats methods
  List<Workout> get completedWorkouts {
    return _workouts.where((workout) => _workoutCompletions.containsKey(workout.id)).toList();
  }

  int get totalWorkouts => _workouts.length;

  double get averageDuration {
    if (_workouts.isEmpty) return 0.0;
    int totalMinutes = _workouts.fold(0, (sum, workout) => sum + workout.duration);
    return totalMinutes / _workouts.length;
  }

  int get totalCalories {
    return _workouts.fold(0, (sum, workout) => sum + workout.calories);
  }

  Map<String, dynamic> get workoutStats {
    final completed = completedWorkouts;
    final totalWorkouts = completed.length;
    final totalDuration = completed.fold<int>(0, (sum, workout) => sum + workout.duration);
    final totalCalories = completed.fold<int>(0, (sum, workout) => sum + workout.calories);

    return {
      'totalWorkouts': totalWorkouts,
      'totalDuration': totalDuration,
      'totalCalories': totalCalories,
    };
  }

  void updateWorkoutStats() {
    final stats = workoutStats;
    if (kDebugMode) {
      print("Workout Stats: $stats");
    }
  }

  // Initialization methods
  void loadFavorites(List<String> favorites) {
    _favoriteWorkoutIds.addAll(favorites);
    notifyListeners();
  }
  Future<void> _saveCompletionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert the completions map to JSON
      final completionsJson = jsonEncode(
          _workoutCompletions.map((k, v) => MapEntry(k, v.toIso8601String()))
      );

      await prefs.setString('workout_completions', completionsJson);

      if (kDebugMode) {
        print('Workout completions saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving workout completions: $e');
      }
    }
  }

  Future<void> _loadCompletionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completionsJson = prefs.getString('workout_completions');

      if (completionsJson != null) {
        final decoded = jsonDecode(completionsJson) as Map<String, dynamic>;
        _workoutCompletions.clear(); // Clear existing data
        _workoutCompletions.addAll( // Add new data
            decoded.map((k, v) => MapEntry(k, DateTime.parse(v as String)))
        );
        notifyListeners();

        if (kDebugMode) {
          print('Workout completions loaded successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading workout completions: $e');
      }
    }
  }

}