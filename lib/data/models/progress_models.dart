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

