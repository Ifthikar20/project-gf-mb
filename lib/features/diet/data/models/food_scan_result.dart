/// Data model for food scan results from the backend API.
/// The backend calls Gemini 2.5 Flash Vision server-side.

class FoodScanResult {
  final List<DetectedFoodItem> items;
  final int totalCalories;
  final String? mealType; // breakfast, lunch, dinner, snack
  final String? scanId; // UUID from backend (for audit trail)
  final String? mealName; // Display name: "Burger", "Chicken Salad", etc.

  const FoodScanResult({
    required this.items,
    required this.totalCalories,
    this.mealType,
    this.scanId,
    this.mealName,
  });

  double get totalProtein =>
      items.fold(0.0, (sum, item) => sum + item.proteinG);
  double get totalCarbs =>
      items.fold(0.0, (sum, item) => sum + item.carbsG);
  double get totalFat =>
      items.fold(0.0, (sum, item) => sum + item.fatG);

  factory FoodScanResult.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>?)
            ?.map((e) => DetectedFoodItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return FoodScanResult(
      items: items,
      totalCalories:
          json['total_calories'] as int? ??
          items.fold(0, (sum, item) => sum + item.calories),
      mealType: json['meal_type'] as String?,
      scanId: json['scan_id'] as String?,
      mealName: json['meal_name'] as String?,
    );
  }
}

class DetectedFoodItem {
  final String name;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double sugarG;
  final double fiberG;
  final int sodiumMg;
  final int caffeineMg;
  final String servingSize;
  final double confidence; // 0.0 – 1.0
  final String type; // 'solid', 'liquid', 'beverage'
  final int? liquidVolumeMl; // estimated ml for liquids/beverages
  final List<FoodWarning> warnings;

  const DetectedFoodItem({
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.servingSize,
    this.sugarG = 0,
    this.fiberG = 0,
    this.sodiumMg = 0,
    this.caffeineMg = 0,
    this.confidence = 0.8,
    this.type = 'solid',
    this.liquidVolumeMl,
    this.warnings = const [],
  });

  bool get isLiquid => type == 'liquid';
  bool get isBeverage => type == 'beverage';
  bool get isLiquidOrBeverage => type == 'liquid' || type == 'beverage';
  bool get hasCaffeine => caffeineMg > 0;
  bool get hasWarnings => warnings.isNotEmpty;

  /// Display string for volume: "350 ml" or null for solids
  String? get volumeDisplay =>
      liquidVolumeMl != null ? '$liquidVolumeMl ml' : null;

  factory DetectedFoodItem.fromJson(Map<String, dynamic> json) {
    return DetectedFoodItem(
      name: json['name'] as String? ?? 'Unknown',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      sugarG: (json['sugar_g'] as num?)?.toDouble() ?? 0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0,
      sodiumMg: (json['sodium_mg'] as num?)?.toInt() ?? 0,
      caffeineMg: (json['caffeine_mg'] as num?)?.toInt() ?? 0,
      servingSize: json['serving_size'] as String? ?? '1 serving',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
      type: json['type'] as String? ?? 'solid',
      liquidVolumeMl: (json['liquid_volume_ml'] as num?)?.toInt(),
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((w) => FoodWarning.fromJson(w as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// Health warning returned by the food scanner API.
class FoodWarning {
  final String type; // allergen, high_caffeine, high_sugar, etc.
  final String severity; // low, medium, high
  final String label; // Short: "Contains Nuts"
  final String detail; // Explanation sentence

  const FoodWarning({
    required this.type,
    required this.severity,
    required this.label,
    required this.detail,
  });

  bool get isHigh => severity == 'high';
  bool get isMedium => severity == 'medium';
  bool get isLow => severity == 'low';

  factory FoodWarning.fromJson(Map<String, dynamic> json) {
    return FoodWarning(
      type: json['type'] as String? ?? 'unknown',
      severity: json['severity'] as String? ?? 'low',
      label: json['label'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
    );
  }
}
