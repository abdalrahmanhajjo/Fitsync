import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum ProgressTimeRange { week, month, year, all }

class ProgressData {
  final DateTime date;
  final int workoutCount;
  final int caloriesBurned;

  ProgressData({
    required this.date,
    required this.workoutCount,
    required this.caloriesBurned,
  });
}

class CompletedWorkout {
  final String workoutId;
  final String workoutName;
  final DateTime completedAt;
  final int duration;
  final int calories;

  CompletedWorkout({
    required this.workoutId,
    required this.workoutName,
    required this.completedAt,
    required this.duration,
    required this.calories,
  });

  Map<String, dynamic> toJson() {
    return {
      'workoutId': workoutId,
      'workoutName': workoutName,
      'completedAt': completedAt.toIso8601String(),
      'duration': duration,
      'calories': calories,
    };
  }

  factory CompletedWorkout.fromJson(Map<String, dynamic> json) {
    return CompletedWorkout(
      workoutId: json['workoutId'] as String,
      workoutName: json['workoutName'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      duration: json['duration'] as int,
      calories: json['calories'] as int,
    );
  }
}

class BodyMetricData {
  final DateTime date;
  final double value;

  BodyMetricData({
    required this.date,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
    };
  }

  factory BodyMetricData.fromJson(Map<String, dynamic> json) {
    return BodyMetricData(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
    );
  }
}

class WorkoutStatistics {
  final int totalWorkouts;
  final double workoutsPerWeek;
  final double avgDuration;
  final double totalHours;

  WorkoutStatistics({
    required this.totalWorkouts,
    required this.workoutsPerWeek,
    required this.avgDuration,
    required this.totalHours,
  });
}

class BodyStatistics {
  final List<BodyMetricData> weightData;
  final List<BodyMetricData> bodyFatData;
  final double? weightChange;

  BodyStatistics({
    required this.weightData,
    required this.bodyFatData,
    this.weightChange,
  });
}

class ProgressProvider with ChangeNotifier {
  List<ProgressData> _progressData = [];
  List<CompletedWorkout> _completedWorkouts = [];
  List<BodyMetricData> _weightData = [];
  List<BodyMetricData> _bodyFatData = [];
  ProgressTimeRange _currentTimeRange = ProgressTimeRange.week;
  bool _isLoading = false;

  List<ProgressData> get progressData => _progressData;
  List<CompletedWorkout> get completedWorkouts => _completedWorkouts;
  List<BodyMetricData> get weightData => _weightData;
  List<BodyMetricData> get bodyFatData => _bodyFatData;
  bool get isLoading => _isLoading;

  Future<void> loadProgressData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load completed workouts
      final workoutsJson = prefs.getString('completedWorkouts');
      if (workoutsJson != null) {
        final List<dynamic> workoutsList = json.decode(workoutsJson);
        _completedWorkouts = workoutsList.map((item) =>
            CompletedWorkout.fromJson(item as Map<String, dynamic>)).toList();
      }

      // Load weight data
      final weightJson = prefs.getString('weightData');
      if (weightJson != null) {
        final List<dynamic> weightList = json.decode(weightJson);
        _weightData = weightList.map((item) =>
            BodyMetricData.fromJson(item as Map<String, dynamic>)).toList();
      }

      // Load body fat data
      final bodyFatJson = prefs.getString('bodyFatData');
      if (bodyFatJson != null) {
        final List<dynamic> bodyFatList = json.decode(bodyFatJson);
        _bodyFatData = bodyFatList.map((item) =>
            BodyMetricData.fromJson(item as Map<String, dynamic>)).toList();
      }

      _processProgressData();
    } catch (e) {
      debugPrint('Error loading progress data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveDataToPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('completedWorkouts',
        json.encode(_completedWorkouts.map((e) => e.toJson()).toList()));

    await prefs.setString('weightData',
        json.encode(_weightData.map((e) => e.toJson()).toList()));

    await prefs.setString('bodyFatData',
        json.encode(_bodyFatData.map((e) => e.toJson()).toList()));
  }

  void _processProgressData() {
    final now = DateTime.now();
    DateTime startDate;

    switch (_currentTimeRange) {
      case ProgressTimeRange.week:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case ProgressTimeRange.month:
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case ProgressTimeRange.year:
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case ProgressTimeRange.all:
        startDate = _completedWorkouts.isNotEmpty
            ? _completedWorkouts.last.completedAt
            : now.subtract(const Duration(days: 7));
        break;
    }

    // Group workouts by day
    final dailyWorkouts = <DateTime, List<CompletedWorkout>>{};
    for (var workout in _completedWorkouts) {
      if (workout.completedAt.isBefore(startDate)) continue;

      final day = DateTime(
        workout.completedAt.year,
        workout.completedAt.month,
        workout.completedAt.day,
      );

      dailyWorkouts.putIfAbsent(day, () => []).add(workout);
    }

    // Create progress data points
    _progressData = dailyWorkouts.entries.map((entry) {
      final totalCalories = entry.value.fold(
          0, (sum, workout) => sum + workout.calories);
      return ProgressData(
        date: entry.key,
        workoutCount: entry.value.length,
        caloriesBurned: totalCalories,
      );
    }).toList();

    // Fill in missing days with zero values
    if (_currentTimeRange != ProgressTimeRange.all) {
      final filledData = <ProgressData>[];
      var currentDate = startDate;
      final endDate = now;

      while (currentDate.isBefore(endDate)) {
        final existingData = _progressData.firstWhere(
              (data) => _isSameDay(data.date, currentDate),
          orElse: () => ProgressData(
            date: currentDate,
            workoutCount: 0,
            caloriesBurned: 0,
          ),
        );

        filledData.add(existingData);
        currentDate = currentDate.add(const Duration(days: 1));
      }

      _progressData = filledData;
    }

    // Sort by date
    _progressData.sort((a, b) => a.date.compareTo(b.date));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<ProgressData> getFilteredProgress(ProgressTimeRange timeRange) {
    if (timeRange != _currentTimeRange) {
      _currentTimeRange = timeRange;
      _processProgressData();
    }
    return _progressData;
  }

  List<CompletedWorkout> getRecentWorkouts() {
    return _completedWorkouts.take(5).toList();
  }

  WorkoutStatistics getWorkoutStatistics(ProgressTimeRange timeRange) {
    final filteredWorkouts = _completedWorkouts.where((workout) {
      final now = DateTime.now();
      switch (timeRange) {
        case ProgressTimeRange.week:
          return workout.completedAt.isAfter(now.subtract(const Duration(days: 7)));
        case ProgressTimeRange.month:
          return workout.completedAt.isAfter(DateTime(now.year, now.month - 1, now.day));
        case ProgressTimeRange.year:
          return workout.completedAt.isAfter(DateTime(now.year - 1, now.month, now.day));
        case ProgressTimeRange.all:
          return true;
      }
    }).toList();

    final totalWorkouts = filteredWorkouts.length;
    final totalDuration = filteredWorkouts.fold(
        0, (sum, workout) => sum + workout.duration);
    final avgDuration = totalWorkouts > 0 ? totalDuration / totalWorkouts : 0;
    final totalHours = totalDuration / 60;
    final weeksInRange = _getWeeksInTimeRange(timeRange);

    return WorkoutStatistics(
      totalWorkouts: totalWorkouts,
      workoutsPerWeek: weeksInRange > 0 ? totalWorkouts / weeksInRange : 0,
      avgDuration: avgDuration.toDouble(),
      totalHours: totalHours,
    );
  }

  BodyStatistics getBodyStatistics(ProgressTimeRange timeRange) {
    final now = DateTime.now();
    DateTime startDate;

    switch (timeRange) {
      case ProgressTimeRange.week:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case ProgressTimeRange.month:
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case ProgressTimeRange.year:
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case ProgressTimeRange.all:
        startDate = _weightData.isNotEmpty ? _weightData.first.date : now;
        break;
    }

    final filteredWeight = _weightData.where((data) => data.date.isAfter(startDate)).toList();
    final filteredBodyFat = _bodyFatData.where((data) => data.date.isAfter(startDate)).toList();

    double? weightChange;
    if (filteredWeight.length >= 2) {
      weightChange = filteredWeight.last.value - filteredWeight.first.value;
    }

    return BodyStatistics(
      weightData: filteredWeight,
      bodyFatData: filteredBodyFat,
      weightChange: weightChange,
    );
  }

  int _getWeeksInTimeRange(ProgressTimeRange timeRange) {
    final now = DateTime.now();
    switch (timeRange) {
      case ProgressTimeRange.week:
        return 1;
      case ProgressTimeRange.month:
        return 4;
      case ProgressTimeRange.year:
        return 52;
      case ProgressTimeRange.all:
        if (_completedWorkouts.isEmpty) return 1;
        final firstDate = _completedWorkouts.last.completedAt;
        final days = now.difference(firstDate).inDays;
        return (days / 7).ceil();
    }
  }

  Future<void> addBodyMeasurement({
    required double? weight,
    required double? bodyFat,
  }) async {
    try {
      final now = DateTime.now();
      if (weight != null) {
        _weightData.add(BodyMetricData(
          date: now,
          value: weight,
        ));
      }
      if (bodyFat != null) {
        _bodyFatData.add(BodyMetricData(
          date: now,
          value: bodyFat,
        ));
      }

      await _saveDataToPrefs();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding body measurement: $e');
      rethrow;
    }
  }

  Future<void> completeWorkout({
    required String workoutId,
    required String workoutName,
    required int duration,
    required int calories,
  }) async {
    try {
      _completedWorkouts.insert(0, CompletedWorkout(
        workoutId: workoutId,
        workoutName: workoutName,
        completedAt: DateTime.now(),
        duration: duration,
        calories: calories,
      ));

      await _saveDataToPrefs();
      _processProgressData();
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing workout: $e');
      rethrow;
    }
  }
  /// Returns number of unique days with at least one workout
  int getActiveDaysCount(ProgressTimeRange timeRange) {
    final now = DateTime.now();
    DateTime startDate;

    switch (timeRange) {
      case ProgressTimeRange.week:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case ProgressTimeRange.month:
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case ProgressTimeRange.year:
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case ProgressTimeRange.all:
        startDate = _completedWorkouts.isNotEmpty
            ? _completedWorkouts.last.completedAt
            : now.subtract(const Duration(days: 7));
        break;
    }

    final activeDays = _completedWorkouts
        .where((workout) => workout.completedAt.isAfter(startDate))
        .map((workout) => DateTime(
      workout.completedAt.year,
      workout.completedAt.month,
      workout.completedAt.day,
    ))
        .toSet();

    return activeDays.length;
  }

  /// Returns a list of recent completed workouts (activities)
  List<CompletedWorkout> getRecentActivities({int limit = 10}) {
    return _completedWorkouts.take(limit).toList();
  }

  /// Getter to expose progress entries
  List<ProgressData> get progressEntries => _progressData;


  Future<void> clearAllData() async {
    _completedWorkouts.clear();
    _weightData.clear();
    _bodyFatData.clear();
    _progressData.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('completedWorkouts');
    await prefs.remove('weightData');
    await prefs.remove('bodyFatData');

    notifyListeners();
  }
}