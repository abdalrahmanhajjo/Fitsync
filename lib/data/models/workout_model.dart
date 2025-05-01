import 'package:flutter/material.dart';

class Workout {
  final String id;
  final String title;
  final String description;
  final WorkoutDifficulty difficulty;
  final int duration; // in minutes
  final List<MuscleGroup> primaryMuscleGroups;
  final List<MuscleGroup> secondaryMuscleGroups;
  final WorkoutType type;
  final int calories; // estimated calories burned
  final String? imageUrl;
  final List<WorkoutExercise> exercises;
  final DateTime? createdAt;
  final DateTime? updatedAt;




  const Workout({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.duration,
    required this.primaryMuscleGroups,
    this.secondaryMuscleGroups = const [],
    required this.type,
    required this.calories,
    this.imageUrl,
    required this.exercises,
    this.createdAt,
    this.updatedAt,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      difficulty: WorkoutDifficulty.values.firstWhere(
            (e) => e.toString().split('.').last == json['difficulty'],
        orElse: () => WorkoutDifficulty.intermediate,
      ),
      duration: json['duration'],
      primaryMuscleGroups: (json['primaryMuscleGroups'] as List)
          .map((e) => MuscleGroup.values.firstWhere(
            (m) => m.toString().split('.').last == e,
        orElse: () => MuscleGroup.fullBody,
      ))
          .toList(),
      secondaryMuscleGroups: (json['secondaryMuscleGroups'] as List?)
          ?.map((e) => MuscleGroup.values.firstWhere(
            (m) => m.toString().split('.').last == e,
        orElse: () => MuscleGroup.fullBody,
      ))
          .toList() ??
          [],
      type: WorkoutType.values.firstWhere(
            (e) => e.toString().split('.').last == json['type'],
        orElse: () => WorkoutType.strength,
      ),
      calories: json['calories'],
      imageUrl: json['imageUrl'],
      exercises: (json['exercises'] as List)
          .map((e) => WorkoutExercise.fromJson(e))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty.toString().split('.').last,
      'duration': duration,
      'primaryMuscleGroups':
      primaryMuscleGroups.map((e) => e.toString().split('.').last).toList(),
      'secondaryMuscleGroups': secondaryMuscleGroups
          .map((e) => e.toString().split('.').last)
          .toList(),
      'type': type.toString().split('.').last,
      'calories': calories,
      'imageUrl': imageUrl,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get formattedDuration {
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  bool targetsMuscleGroup(MuscleGroup muscleGroup) {
    return primaryMuscleGroups.contains(muscleGroup) ||
        secondaryMuscleGroups.contains(muscleGroup);
  }

  bool matchesDifficulty(WorkoutDifficulty userLevel) {
    switch (userLevel) {
      case WorkoutDifficulty.beginner:
        return difficulty == WorkoutDifficulty.beginner;
      case WorkoutDifficulty.intermediate:
        return difficulty.index <= WorkoutDifficulty.intermediate.index;
      case WorkoutDifficulty.advanced:
        return true;
    }
  }
}

class WorkoutExercise {
  final String id;
  final String name;
  final String description;
  final List<MuscleGroup> targetedMuscles;
  final String? imageUrl;
  final String? videoUrl;
  final int sets;
  final int reps;
  final int? duration; // in seconds (for timed exercises)
  final int restPeriod; // in seconds between sets
  final String? equipment;
  final String? notes;

  const WorkoutExercise({
    required this.id,
    required this.name,
    required this.description,
    required this.targetedMuscles,
    this.imageUrl,
    this.videoUrl,
    required this.sets,
    required this.reps,
    this.duration,
    required this.restPeriod,
    this.equipment,
    this.notes,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      targetedMuscles: (json['targetedMuscles'] as List)
          .map((e) => MuscleGroup.values.firstWhere(
            (m) => m.toString().split('.').last == e,
        orElse: () => MuscleGroup.fullBody,
      ))
          .toList(),
      imageUrl: json['imageUrl'],
      videoUrl: json['videoUrl'],
      sets: json['sets'],
      reps: json['reps'],
      duration: json['duration'],
      restPeriod: json['restPeriod'] ?? 30,
      equipment: json['equipment'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'targetedMuscles': targetedMuscles.map((e) => e.toString().split('.').last).toList(),
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'sets': sets,
      'reps': reps,
      'duration': duration,
      'restPeriod': restPeriod,
      'equipment': equipment,
      'notes': notes,
    };
  }

  String get formattedReps {
    if (duration != null) {
      return '${duration}s';
    }
    return '$reps reps';
  }
}

enum WorkoutDifficulty {
  beginner,
  intermediate,
  advanced,
}

enum MuscleGroup {
  chest,
  back,
  legs,
  arms,
  shoulders,
  abs,
  glutes,
  calves,
  biceps,
  triceps,
  forearms,
  hamstrings,
  quadriceps,
  fullBody,
  cardio,
}

enum WorkoutType {
  strength,
  cardio,
  hiit,
  yoga,
  pilates,
  stretching,
  crossfit,
  calisthenics,
  mobility,
  recovery,
}

extension WorkoutDifficultyExtension on WorkoutDifficulty {
  String get displayName {
    switch (this) {
      case WorkoutDifficulty.beginner:
        return 'Beginner';
      case WorkoutDifficulty.intermediate:
        return 'Intermediate';
      case WorkoutDifficulty.advanced:
        return 'Advanced';
    }
  }
}

extension MuscleGroupExtension on MuscleGroup {
  String get displayName {
    switch (this) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.legs:
        return 'Legs';
      case MuscleGroup.arms:
        return 'Arms';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.abs:
        return 'Abs';
      case MuscleGroup.glutes:
        return 'Glutes';
      case MuscleGroup.calves:
        return 'Calves';
      case MuscleGroup.biceps:
        return 'Biceps';
      case MuscleGroup.triceps:
        return 'Triceps';
      case MuscleGroup.forearms:
        return 'Forearms';
      case MuscleGroup.hamstrings:
        return 'Hamstrings';
      case MuscleGroup.quadriceps:
        return 'Quadriceps';
      case MuscleGroup.fullBody:
        return 'Full Body';
      case MuscleGroup.cardio:
        return 'Cardio';
    }
  }
}

extension WorkoutTypeExtension on WorkoutType {
  String get displayName {
    switch (this) {
      case WorkoutType.strength:
        return 'Strength';
      case WorkoutType.cardio:
        return 'Cardio';
      case WorkoutType.hiit:
        return 'HIIT';
      case WorkoutType.yoga:
        return 'Yoga';
      case WorkoutType.pilates:
        return 'Pilates';
      case WorkoutType.stretching:
        return 'Stretching';
      case WorkoutType.crossfit:
        return 'CrossFit';
      case WorkoutType.calisthenics:
        return 'Calisthenics';
      case WorkoutType.mobility:
        return 'Mobility';
      case WorkoutType.recovery:
        return 'Recovery';
    }
  }

  IconData get icon {
    switch (this) {
      case WorkoutType.strength:
        return Icons.fitness_center;
      case WorkoutType.cardio:
        return Icons.directions_run;
      case WorkoutType.hiit:
        return Icons.bolt;
      case WorkoutType.yoga:
        return Icons.self_improvement;
      case WorkoutType.pilates:
        return Icons.accessibility_new;
      case WorkoutType.stretching:
        return Icons.open_in_full;
      case WorkoutType.crossfit:
        return Icons.sports_gymnastics;
      case WorkoutType.calisthenics:
        return Icons.sports_kabaddi;
      case WorkoutType.mobility:
        return Icons.directions_walk;
      case WorkoutType.recovery:
        return Icons.health_and_safety;
    }
  }
}
