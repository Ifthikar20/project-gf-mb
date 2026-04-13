import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Local burn goal — food-linked workout target stored in Hive.
/// Stacks: each food scan can create multiple burn goals.
/// Will migrate to backend BurnGoal API when available.
class BurnGoal {
  final String id;
  final String activity;       // "Walking", "Running", "Cycling"
  final String icon;           // "walking", "running", "cycling"
  final int targetCalories;
  final int targetMinutes;
  final int? targetSteps;
  final String mealName;       // "Fries", "Burger"
  final int mealCalories;      // 220
  int completedCalories;
  int completedMinutes;
  bool isComplete;
  final DateTime createdAt;
  DateTime? completedAt;

  BurnGoal({
    required this.id,
    required this.activity,
    required this.icon,
    required this.targetCalories,
    required this.targetMinutes,
    this.targetSteps,
    required this.mealName,
    required this.mealCalories,
    this.completedCalories = 0,
    this.completedMinutes = 0,
    this.isComplete = false,
    required this.createdAt,
    this.completedAt,
  });

  double get progress => targetCalories > 0
      ? (completedCalories / targetCalories).clamp(0.0, 1.0)
      : 0.0;

  int get progressPercent => (progress * 100).round();

  int get remainingCalories => (targetCalories - completedCalories).clamp(0, targetCalories);
  int get remainingMinutes => (targetMinutes - completedMinutes).clamp(0, targetMinutes);

  Map<String, dynamic> toJson() => {
    'id': id,
    'activity': activity,
    'icon': icon,
    'targetCalories': targetCalories,
    'targetMinutes': targetMinutes,
    'targetSteps': targetSteps,
    'mealName': mealName,
    'mealCalories': mealCalories,
    'completedCalories': completedCalories,
    'completedMinutes': completedMinutes,
    'isComplete': isComplete,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory BurnGoal.fromJson(Map<String, dynamic> json) => BurnGoal(
    id: json['id'] ?? '',
    activity: json['activity'] ?? '',
    icon: json['icon'] ?? '',
    targetCalories: json['targetCalories'] ?? 0,
    targetMinutes: json['targetMinutes'] ?? 0,
    targetSteps: json['targetSteps'],
    mealName: json['mealName'] ?? '',
    mealCalories: json['mealCalories'] ?? 0,
    completedCalories: json['completedCalories'] ?? 0,
    completedMinutes: json['completedMinutes'] ?? 0,
    isComplete: json['isComplete'] ?? false,
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null,
  );
}

/// Local storage for burn goals using Hive
class BurnGoalStorage {
  static const _boxName = 'burn_goals';
  static BurnGoalStorage? _instance;
  static BurnGoalStorage get instance {
    _instance ??= BurnGoalStorage._();
    return _instance!;
  }
  BurnGoalStorage._();

  Future<Box> get _box async => Hive.openBox(_boxName);

  /// Add a new burn goal
  Future<void> addGoal(BurnGoal goal) async {
    final box = await _box;
    await box.put(goal.id, jsonEncode(goal.toJson()));
    debugPrint('BurnGoal added: ${goal.activity} ${goal.targetMinutes}min for ${goal.mealName}');
  }

  /// Get all active (not completed, not expired) burn goals
  Future<List<BurnGoal>> getActiveGoals() async {
    final box = await _box;
    final goals = <BurnGoal>[];
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    for (final key in box.keys) {
      try {
        final raw = box.get(key) as String?;
        if (raw == null) continue;
        final goal = BurnGoal.fromJson(jsonDecode(raw));
        // Only show goals from last 7 days that aren't complete
        if (goal.createdAt.isAfter(weekAgo)) {
          goals.add(goal);
        }
      } catch (_) {}
    }

    goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return goals;
  }

  /// Update a goal's progress
  Future<void> updateProgress(String id, int addCalories, int addMinutes) async {
    final box = await _box;
    final raw = box.get(id) as String?;
    if (raw == null) return;

    final goal = BurnGoal.fromJson(jsonDecode(raw));
    goal.completedCalories = (goal.completedCalories + addCalories).clamp(0, goal.targetCalories);
    goal.completedMinutes = (goal.completedMinutes + addMinutes).clamp(0, goal.targetMinutes);

    if (goal.completedCalories >= goal.targetCalories) {
      goal.isComplete = true;
      goal.completedAt = DateTime.now();
    }

    await box.put(id, jsonEncode(goal.toJson()));
  }

  /// Mark goal as complete
  Future<void> markComplete(String id) async {
    final box = await _box;
    final raw = box.get(id) as String?;
    if (raw == null) return;

    final goal = BurnGoal.fromJson(jsonDecode(raw));
    goal.isComplete = true;
    goal.completedCalories = goal.targetCalories;
    goal.completedMinutes = goal.targetMinutes;
    goal.completedAt = DateTime.now();
    await box.put(id, jsonEncode(goal.toJson()));
  }

  /// Delete a goal
  Future<void> deleteGoal(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  /// Get daily summary
  Future<({int totalTarget, int totalCompleted, int activeCount, int completedCount})> getDailySummary() async {
    final goals = await getActiveGoals();
    final today = DateTime.now();
    final todayGoals = goals.where((g) =>
        g.createdAt.year == today.year &&
        g.createdAt.month == today.month &&
        g.createdAt.day == today.day).toList();

    return (
      totalTarget: todayGoals.fold(0, (s, g) => s + g.targetCalories),
      totalCompleted: todayGoals.fold(0, (s, g) => s + g.completedCalories),
      activeCount: todayGoals.where((g) => !g.isComplete).length,
      completedCount: todayGoals.where((g) => g.isComplete).length,
    );
  }
}
