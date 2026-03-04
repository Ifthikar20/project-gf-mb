import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/diet_models.dart';

/// Local data source for diet/meal logging using Hive
class DietLocalDataSource {
  static const String _boxName = 'diet_logs';
  Box<MealLog>? _box;

  Future<Box<MealLog>> get _openBox async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<MealLog>(_boxName);
    return _box!;
  }

  /// Log a new meal
  Future<void> logMeal(MealLog meal) async {
    try {
      final box = await _openBox;
      await box.add(meal);
    } catch (e) {
      debugPrint('⚠ Failed to log meal: $e');
    }
  }

  /// Get all meals for a specific date
  Future<List<MealLog>> getMealsForDate(DateTime date) async {
    try {
      final box = await _openBox;
      return box.values.where((m) {
        return m.timestamp.year == date.year &&
            m.timestamp.month == date.month &&
            m.timestamp.day == date.day;
      }).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (e) {
      debugPrint('⚠ Failed to get meals: $e');
      return [];
    }
  }

  /// Get daily summary for a specific date
  Future<DailyNutritionSummary> getDailySummary(DateTime date) async {
    final meals = await getMealsForDate(date);
    return DailyNutritionSummary.fromMeals(meals);
  }

  /// Delete a meal by its Hive key
  Future<void> deleteMeal(int key) async {
    try {
      final box = await _openBox;
      await box.delete(key);
    } catch (e) {
      debugPrint('⚠ Failed to delete meal: $e');
    }
  }

  /// Get meals for the last N days (for weekly overview)
  Future<Map<DateTime, List<MealLog>>> getMealsForWeek() async {
    final result = <DateTime, List<MealLog>>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      result[day] = await getMealsForDate(day);
    }
    return result;
  }
}
