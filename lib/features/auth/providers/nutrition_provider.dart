import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NutritionProvider with ChangeNotifier {
  final Map<DateTime, List<Map<String, dynamic>>> _dailyMeals = {};
  Map<String, dynamic> _nutrition = {};
  User? _user;

  List<Map<String, dynamic>> get meals {
    return _dailyMeals.values.expand((meals) => meals).toList();
  }

  Map<String, dynamic> get nutrition => _nutrition;
  User? get user => _user;

  List<Map<String, dynamic>> getDailyNutrition(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _dailyMeals[normalizedDate] ?? [];
  }

  bool hasNutritionData(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _dailyMeals.containsKey(normalizedDate) &&
        _dailyMeals[normalizedDate]!.isNotEmpty;
  }

  List<Map<String, dynamic>> get todayMeals {
    final today = DateTime.now();
    return getDailyNutrition(today);
  }

  int getTodayCalories() {
    return calculateDailyTotals(DateTime.now())['calories'] ?? 0;
  }

  Map<String, int> getTodayNutrition() {
    return calculateDailyTotals(DateTime.now());
  }



  void updateUserProfile({
    double? weight,
    double? height,
    String? fitnessLevel,
    List<String>? fitnessGoals,
  }) {
    if (_user == null) return;

    _user = _user!.copyWith(
      weight: weight ?? _user!.weight,
      height: height ?? _user!.height,
      fitnessLevel: fitnessLevel ?? _user!.fitnessLevel,
      fitnessGoals: fitnessGoals ?? _user!.fitnessGoals,
    );

    _nutrition = _calculateRecommendedNutrition(_user!);
    saveUser();
    notifyListeners();
  }

  void addMeal(Map<String, dynamic> meal, DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    meal['date'] = normalizedDate;

    if (!_dailyMeals.containsKey(normalizedDate)) {
      _dailyMeals[normalizedDate] = [];
    }
    _dailyMeals[normalizedDate]!.add(meal);
    notifyListeners();
  }

  void removeMeal(Map<String, dynamic> meal, DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    if (_dailyMeals.containsKey(normalizedDate)) {
      _dailyMeals[normalizedDate]!.remove(meal);
      if (_dailyMeals[normalizedDate]!.isEmpty) {
        _dailyMeals.remove(normalizedDate);
      }
      notifyListeners();
    }
  }

  void setUser(User user) {
    _user = user;
    _nutrition = _calculateRecommendedNutrition(user);
    notifyListeners();
    saveUser(); // If you want to persist changes immediately
  }
  // In your NutritionProvider class
  Future<void> saveUser() async {
    if (_user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_user!.toJson()));
    } catch (e) {
      debugPrint('Error saving user: $e');
      // Optionally rethrow or handle the error
      throw Exception('Failed to save user data');
    }
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('user');
    if (raw == null) return;
    _user = User.fromJson(jsonDecode(raw));
    _nutrition = _calculateRecommendedNutrition(_user!);
    notifyListeners();
  }

  Future<void> saveMealsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _dailyMeals.map((date, meals) => MapEntry(
      date.toIso8601String(),
      meals.map((meal) => jsonEncode(meal)).toList(),
    ));
    await prefs.setString('meals', jsonEncode(encoded));
  }

  Future<void> loadMealsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('meals');
    if (raw == null) return;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _dailyMeals.clear();
    decoded.forEach((dateStr, mealList) {
      final date = DateTime.parse(dateStr);
      final meals = (mealList as List).map((m) => jsonDecode(m)).toList();
      _dailyMeals[date] = List<Map<String, dynamic>>.from(meals);
    });
    notifyListeners();
  }

  Map<String, int> calculateDailyTotals(DateTime date) {
    final dailyMeals = getDailyNutrition(date);
    int totalProtein = 0, totalCarbs = 0, totalFat = 0, totalCalories = 0;

    for (var meal in dailyMeals) {
      totalProtein += (meal['protein'] as num).toInt();
      totalCarbs += (meal['carbs'] as num).toInt();
      totalFat += (meal['fat'] as num).toInt();
      totalCalories += (meal['calories'] as num).toInt();
    }

    return {
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
      'calories': totalCalories,
    };
  }

  Map<String, dynamic> _calculateRecommendedNutrition(User user) {
    final weight = user.weight ?? 70.0;
    final height = (user.height ?? 1.70) * 100;
    final age = 25;

    final fitnessLevel = user.fitnessLevel?.toLowerCase() ?? 'intermediate';
    final goal = (user.fitnessGoals?.isNotEmpty ?? false)
        ? user.fitnessGoals!.first.toLowerCase()
        : 'maintain';

    final bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;

    double activityFactor;
    switch (fitnessLevel) {
      case 'beginner':
        activityFactor = 1.375;
        break;
      case 'advanced':
        activityFactor = 1.725;
        break;
      default:
        activityFactor = 1.55;
    }

    double tdee = bmr * activityFactor;

    if (goal.contains('weight loss') || goal.contains('lose')) {
      tdee -= 500;
    } else if (goal.contains('muscle gain') || goal.contains('gain')) {
      tdee += 300;
      if (fitnessLevel == 'advanced') tdee += 200;
    } else if (goal.contains('endurance')) {
      tdee += 100;
    }

    final protein = _calculateProtein(weight, goal, fitnessLevel);
    final fat = _calculateFat(tdee);
    final carbs = _calculateCarbs(tdee, protein, fat);

    return {
      'calories': tdee.round(),
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'goal': goal,
      'fitnessLevel': fitnessLevel,
    };
  }

  int _calculateProtein(double weight, String goal, String fitnessLevel) {
    double proteinPerKg;
    if (goal.contains('muscle gain')) {
      proteinPerKg = fitnessLevel == 'advanced' ? 2.2 : 2.0;
    } else if (goal.contains('weight loss')) {
      proteinPerKg = 2.0;
    } else if (goal.contains('endurance')) {
      proteinPerKg = 1.6;
    } else {
      proteinPerKg = 1.6;
    }
    return (weight * proteinPerKg).round();
  }

  int _calculateFat(double tdee) => ((tdee * 0.25) / 9).round();
  int _calculateCarbs(double tdee, int protein, int fat) =>
      ((tdee - (protein * 4 + fat * 9)) / 4).round();

  Map<String, int> calculateMealTotals([List<Map<String, dynamic>>? meals]) {
    final targetMeals = meals ?? this.meals;
    int totalProtein = 0, totalCarbs = 0, totalFat = 0, totalCalories = 0;
    for (var meal in targetMeals) {
      totalProtein += (meal['protein'] as num).toInt();
      totalCarbs += (meal['carbs'] as num).toInt();
      totalFat += (meal['fat'] as num).toInt();
      totalCalories += (meal['calories'] as num).toInt();
    }
    return {
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
      'calories': totalCalories,
    };
  }
}
