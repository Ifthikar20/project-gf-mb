import 'package:hive/hive.dart';

part 'diet_models.g.dart';

/// Meal type enum
@HiveType(typeId: 30)
enum MealType {
  @HiveField(0)
  breakfast,
  @HiveField(1)
  lunch,
  @HiveField(2)
  dinner,
  @HiveField(3)
  snack,
}

/// Extension for display labels / icons
extension MealTypeExtension on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast:
        return '🌅';
      case MealType.lunch:
        return '☀️';
      case MealType.dinner:
        return '🌙';
      case MealType.snack:
        return '🍎';
    }
  }
}

/// A single logged meal entry, stored locally via Hive
@HiveType(typeId: 31)
class MealLog extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int calories;

  @HiveField(2)
  final int proteinGrams;

  @HiveField(3)
  final int carbsGrams;

  @HiveField(4)
  final int fatGrams;

  @HiveField(5)
  final MealType mealType;

  @HiveField(6)
  final DateTime timestamp;

  @HiveField(7)
  final String? notes;

  @HiveField(8)
  final String? imagePath; // Local file path of captured food photo

  @HiveField(9)
  final String? scanId; // Groups items from the same scan

  @HiveField(10)
  final String? mealName; // Display name: "Burger", "Chicken Salad"

  @HiveField(11, defaultValue: 0)
  final int sugarGrams;

  @HiveField(12, defaultValue: 0)
  final int fiberGrams;

  @HiveField(13, defaultValue: 0)
  final int sodiumMg;

  @HiveField(14, defaultValue: 0)
  final int caffeineMg;

  @HiveField(15, defaultValue: 'solid')
  final String? itemType; // 'solid', 'liquid', 'beverage'

  @HiveField(16)
  final String? warningsJson; // JSON-encoded warnings array

  @HiveField(17)
  final String? imageUrl; // S3 pre-signed URL of captured food photo

  @HiveField(18)
  final String? benefitsJson; // JSON-encoded benefits array

  @HiveField(19)
  final String? calorieBurnJson; // JSON-encoded calorie burn array

  @HiveField(20, defaultValue: 0)
  final int? wellnessScore; // -100 to +100

  @HiveField(21)
  final String? wellnessBreakdownJson; // JSON-encoded wellness factors

  MealLog({
    required this.name,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.mealType,
    required this.timestamp,
    this.notes,
    this.imagePath,
    this.scanId,
    this.mealName,
    this.sugarGrams = 0,
    this.fiberGrams = 0,
    this.sodiumMg = 0,
    this.caffeineMg = 0,
    this.itemType = 'solid',
    this.warningsJson,
    this.imageUrl,
    this.benefitsJson,
    this.calorieBurnJson,
    this.wellnessScore = 0,
    this.wellnessBreakdownJson,
  });

  bool get isLiquidOrBeverage => (itemType ?? 'solid') == 'liquid' || (itemType ?? 'solid') == 'beverage';
  bool get isBeverage => (itemType ?? 'solid') == 'beverage';
  bool get hasCaffeine => caffeineMg > 0;
  String get safeItemType => itemType ?? 'solid';
  int get safeWellnessScore => wellnessScore ?? 0;

  /// Check if this meal was logged today
  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }
}

/// Computed daily nutrition summary (not stored — derived from meals)
class DailyNutritionSummary {
  final int totalCalories;
  final int totalProtein;
  final int totalCarbs;
  final int totalFat;
  final int mealCount;
  final int calorieGoal;
  final int proteinGoal;
  final int carbsGoal;
  final int fatGoal;

  const DailyNutritionSummary({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.mealCount,
    this.calorieGoal = 2000,
    this.proteinGoal = 150,
    this.carbsGoal = 250,
    this.fatGoal = 65,
  });

  double get calorieProgress =>
      calorieGoal > 0 ? (totalCalories / calorieGoal).clamp(0.0, 1.5) : 0.0;
  double get proteinProgress =>
      proteinGoal > 0 ? (totalProtein / proteinGoal).clamp(0.0, 1.5) : 0.0;
  double get carbsProgress =>
      carbsGoal > 0 ? (totalCarbs / carbsGoal).clamp(0.0, 1.5) : 0.0;
  double get fatProgress =>
      fatGoal > 0 ? (totalFat / fatGoal).clamp(0.0, 1.5) : 0.0;

  int get caloriesRemaining => (calorieGoal - totalCalories).clamp(0, calorieGoal);

  static DailyNutritionSummary fromMeals(List<MealLog> meals) {
    int cal = 0, pro = 0, carb = 0, fat = 0;
    for (final m in meals) {
      cal += m.calories;
      pro += m.proteinGrams;
      carb += m.carbsGrams;
      fat += m.fatGrams;
    }
    return DailyNutritionSummary(
      totalCalories: cal,
      totalProtein: pro,
      totalCarbs: carb,
      totalFat: fat,
      mealCount: meals.length,
    );
  }
}
