import 'package:flutter/material.dart';

/// Workout type from the API reference data
class WorkoutTypeModel {
  final String id;
  final String name;
  final String slug;
  final double metValue;
  final String iconName; // Material Icons name string
  final String category; // cardio, strength, flexibility, mindfulness

  const WorkoutTypeModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.metValue,
    required this.iconName,
    required this.category,
  });

  factory WorkoutTypeModel.fromJson(Map<String, dynamic> json) {
    return WorkoutTypeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      metValue: (json['met_value'] as num?)?.toDouble() ?? 0.0,
      iconName: json['icon'] ?? 'fitness_center',
      category: json['category'] ?? 'cardio',
    );
  }

  /// Get the Material Icon for this workout type
  IconData get icon {
    switch (iconName) {
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'directions_run':
        return Icons.directions_run;
      case 'directions_bike':
        return Icons.directions_bike;
      case 'pool':
        return Icons.pool;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'sports_martial_arts':
        return Icons.sports_martial_arts;
      case 'hiking':
        return Icons.hiking;
      case 'sports':
        return Icons.sports;
      case 'spa':
        return Icons.spa;
      case 'air':
        return Icons.air;
      default:
        return Icons.fitness_center;
    }
  }

  /// Category color
  Color get categoryColor {
    switch (category) {
      case 'cardio':
        return const Color(0xFFFF6B6B);
      case 'strength':
        return const Color(0xFF4ECDC4);
      case 'flexibility':
        return const Color(0xFFA78BFA);
      case 'mindfulness':
        return const Color(0xFF60A5FA);
      default:
        return const Color(0xFF8B5CF6);
    }
  }
}

/// User's body profile for calorie calculations
class BodyProfile {
  final double weightKg;
  final double? heightCm;
  final String? updatedAt;

  const BodyProfile({
    required this.weightKg,
    this.heightCm,
    this.updatedAt,
  });

  factory BodyProfile.fromJson(Map<String, dynamic> json) {
    return BodyProfile(
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      updatedAt: json['updated_at'],
    );
  }

  /// Convert kg to lbs for display
  double get weightLbs => weightKg * 2.205;
}

/// A logged workout entry
class WorkoutLogModel {
  final String id;
  final String workoutName;
  final WorkoutTypeModel? workoutType;
  final int durationMinutes;
  final int caloriesBurned;
  final String source;
  final DateTime startedAt;
  final String? note;
  final String? mood;
  final String? createdAt;

  const WorkoutLogModel({
    required this.id,
    required this.workoutName,
    this.workoutType,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.source,
    required this.startedAt,
    this.note,
    this.mood,
    this.createdAt,
  });

  factory WorkoutLogModel.fromJson(Map<String, dynamic> json) {
    return WorkoutLogModel(
      id: json['id'] ?? '',
      workoutName: json['workout_name'] ?? 'Workout',
      workoutType: json['workout_type'] != null
          ? WorkoutTypeModel.fromJson(json['workout_type'])
          : null,
      durationMinutes: json['duration_minutes'] ?? 0,
      caloriesBurned: json['calories_burned'] ?? 0,
      source: json['source'] ?? 'manual',
      startedAt: DateTime.parse(
          json['started_at'] ?? DateTime.now().toIso8601String()),
      note: json['note'],
      mood: json['mood'],
      createdAt: json['created_at'],
    );
  }

  bool get isManual => source == 'manual';
  bool get hasMood => mood != null && mood!.isNotEmpty;

  /// Mood label for display
  String get moodLabel {
    switch (mood) {
      case 'great':
        return 'Great';
      case 'good':
        return 'Good';
      case 'okay':
        return 'Okay';
      case 'tired':
        return 'Tired';
      case 'exhausted':
        return 'Exhausted';
      default:
        return '';
    }
  }
}

/// Weekly goal progress
class GoalProgress {
  final String id;
  final String goalType; // calories_burned, active_minutes, workout_count
  final int targetValue;
  final int currentValue;
  final int progressPercent;
  final bool isComplete;

  const GoalProgress({
    required this.id,
    required this.goalType,
    required this.targetValue,
    required this.currentValue,
    required this.progressPercent,
    required this.isComplete,
  });

  factory GoalProgress.fromJson(Map<String, dynamic> json) {
    return GoalProgress(
      id: json['id'] ?? '',
      goalType: json['goal_type'] ?? '',
      targetValue: json['target_value'] ?? 0,
      currentValue: json['current_value'] ?? 0,
      progressPercent: json['progress_percent'] ?? 0,
      isComplete: json['is_complete'] ?? false,
    );
  }

  String get label {
    switch (goalType) {
      case 'calories_burned':
        return 'Calories';
      case 'active_minutes':
        return 'Minutes';
      case 'workout_count':
        return 'Workouts';
      default:
        return goalType;
    }
  }

  String get unit {
    switch (goalType) {
      case 'calories_burned':
        return 'cal';
      case 'active_minutes':
        return 'min';
      case 'workout_count':
        return '';
      default:
        return '';
    }
  }

  IconData get icon {
    switch (goalType) {
      case 'calories_burned':
        return Icons.local_fire_department;
      case 'active_minutes':
        return Icons.timer;
      case 'workout_count':
        return Icons.fitness_center;
      default:
        return Icons.flag;
    }
  }

  Color get color {
    switch (goalType) {
      case 'calories_burned':
        return const Color(0xFFFF6B6B);
      case 'active_minutes':
        return const Color(0xFF4ECDC4);
      case 'workout_count':
        return const Color(0xFFA78BFA);
      default:
        return const Color(0xFF8B5CF6);
    }
  }
}

/// Daily breakdown for the bar chart
class DailyBreakdown {
  final String date;
  final String dayName;
  final int calories;
  final int minutes;
  final int workoutCount;

  const DailyBreakdown({
    required this.date,
    required this.dayName,
    required this.calories,
    required this.minutes,
    required this.workoutCount,
  });

  factory DailyBreakdown.fromJson(Map<String, dynamic> json) {
    return DailyBreakdown(
      date: json['date'] ?? '',
      dayName: json['day_name'] ?? '',
      calories: json['calories'] ?? 0,
      minutes: json['minutes'] ?? 0,
      workoutCount: json['workout_count'] ?? 0,
    );
  }
}

/// Weekly stats aggregate
class WorkoutStats {
  final int thisWeekCalories;
  final int thisWeekMinutes;
  final int thisWeekCount;
  final String weekStart;
  final int allTimeCalories;
  final int allTimeMinutes;
  final int allTimeCount;
  final String? mostFrequentWorkout;
  final List<DailyBreakdown> dailyBreakdown;

  const WorkoutStats({
    required this.thisWeekCalories,
    required this.thisWeekMinutes,
    required this.thisWeekCount,
    required this.weekStart,
    required this.allTimeCalories,
    required this.allTimeMinutes,
    required this.allTimeCount,
    this.mostFrequentWorkout,
    required this.dailyBreakdown,
  });

  factory WorkoutStats.fromJson(Map<String, dynamic> json) {
    final thisWeek = json['this_week'] as Map<String, dynamic>? ?? {};
    final allTime = json['all_time'] as Map<String, dynamic>? ?? {};
    final daily = json['daily_breakdown'] as List? ?? [];

    return WorkoutStats(
      thisWeekCalories: thisWeek['total_calories'] ?? 0,
      thisWeekMinutes: thisWeek['total_minutes'] ?? 0,
      thisWeekCount: thisWeek['workout_count'] ?? 0,
      weekStart: thisWeek['week_start'] ?? '',
      allTimeCalories: allTime['total_calories'] ?? 0,
      allTimeMinutes: allTime['total_minutes'] ?? 0,
      allTimeCount: allTime['workout_count'] ?? 0,
      mostFrequentWorkout: allTime['most_frequent_workout'],
      dailyBreakdown:
          daily.map((d) => DailyBreakdown.fromJson(d)).toList(),
    );
  }

  /// Max calories in a day this week — used for bar chart scaling
  int get maxDailyCalories {
    if (dailyBreakdown.isEmpty) return 1;
    final max = dailyBreakdown
        .map((d) => d.calories)
        .reduce((a, b) => a > b ? a : b);
    return max == 0 ? 1 : max;
  }
}

/// Calorie estimate preview
class CalorieEstimate {
  final String workoutName;
  final double metValue;
  final double weightKg;
  final int durationMinutes;
  final int caloriesBurned;

  const CalorieEstimate({
    required this.workoutName,
    required this.metValue,
    required this.weightKg,
    required this.durationMinutes,
    required this.caloriesBurned,
  });

  factory CalorieEstimate.fromJson(Map<String, dynamic> json) {
    final estimate = json['estimate'] as Map<String, dynamic>? ?? json;
    return CalorieEstimate(
      workoutName: estimate['workout_name'] ?? '',
      metValue: (estimate['met_value'] as num?)?.toDouble() ?? 0.0,
      weightKg: (estimate['weight_kg'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: estimate['duration_minutes'] ?? 0,
      caloriesBurned: estimate['calories_burned'] ?? 0,
    );
  }
}
