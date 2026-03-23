/// Data model for food scan results from the backend API.
/// The backend calls Gemini 2.5 Flash Vision server-side.

class FoodScanResult {
  final List<DetectedFoodItem> items;
  final int totalCalories;
  final String? mealType; // breakfast, lunch, dinner, snack
  final String? scanId; // UUID from backend (for audit trail)
  final String? mealName; // Display name: "Burger", "Chicken Salad", etc.
  final String? imageUrl; // S3 pre-signed URL of the captured food image
  final MealWellness? mealWellness; // Wellness scoring from backend

  const FoodScanResult({
    required this.items,
    required this.totalCalories,
    this.mealType,
    this.scanId,
    this.mealName,
    this.imageUrl,
    this.mealWellness,
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
      imageUrl: json['image_url'] as String?,
      mealWellness: json['meal_wellness'] != null
          ? MealWellness.fromJson(json['meal_wellness'] as Map<String, dynamic>)
          : null,
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
  final List<FoodBenefit> benefits;
  final List<CalorieBurn> calorieBurn;

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
    this.benefits = const [],
    this.calorieBurn = const [],
  });

  bool get isLiquid => type == 'liquid';
  bool get isBeverage => type == 'beverage';
  bool get isLiquidOrBeverage => type == 'liquid' || type == 'beverage';
  bool get hasCaffeine => caffeineMg > 0;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasBenefits => benefits.isNotEmpty;
  bool get hasCalorieBurn => calorieBurn.isNotEmpty;

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
      benefits: (json['benefits'] as List<dynamic>?)
              ?.map((b) => FoodBenefit.fromJson(b as Map<String, dynamic>))
              .toList() ??
          const [],
      calorieBurn: (json['calorie_burn'] as List<dynamic>?)
              ?.map((c) => CalorieBurn.fromJson(c as Map<String, dynamic>))
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

/// Nutritional benefit of a food item.
class FoodBenefit {
  final String icon; // protein, fiber, vitamins, antioxidants, etc.
  final String title; // "Rich in Calcium"
  final String detail; // Explanation

  const FoodBenefit({
    required this.icon,
    required this.title,
    required this.detail,
  });

  factory FoodBenefit.fromJson(Map<String, dynamic> json) {
    return FoodBenefit(
      icon: json['icon'] as String? ?? 'vitamins',
      title: json['title'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
    );
  }
}

/// Calorie burn suggestion for a food item.
class CalorieBurn {
  final String activity; // "Walking", "Running", "Cycling"
  final String duration; // "90 minutes"
  final String icon; // walking, running, cycling, etc.
  final int? steps; // step count for walking/running
  final String detail; // How this exercise burns calories

  const CalorieBurn({
    required this.activity,
    required this.duration,
    required this.icon,
    this.steps,
    required this.detail,
  });

  factory CalorieBurn.fromJson(Map<String, dynamic> json) {
    return CalorieBurn(
      activity: json['activity'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      icon: json['icon'] as String? ?? 'walking',
      steps: (json['steps'] as num?)?.toInt(),
      detail: json['detail'] as String? ?? '',
    );
  }
}

/// Wellness scoring for an entire meal.
class MealWellness {
  final int overallScore; // -100 to +100
  final String label; // 'Excellent', 'Good', 'Okay', 'Poor'
  final List<ItemWellnessScore> perItem; // Per-item scores
  final List<WellnessFactor> positiveFactors; // What helped
  final List<WellnessFactor> negativeFactors; // What hurt

  const MealWellness({
    required this.overallScore,
    required this.label,
    this.perItem = const [],
    this.positiveFactors = const [],
    this.negativeFactors = const [],
  });

  bool get isPositive => overallScore > 0;
  bool get isNegative => overallScore < 0;
  bool get isNeutral => overallScore == 0;

  factory MealWellness.fromJson(Map<String, dynamic> json) {
    return MealWellness(
      overallScore: (json['overall_score'] as num?)?.toInt() ?? 0,
      label: json['label'] as String? ?? 'Unknown',
      perItem: (json['per_item'] as List<dynamic>?)
              ?.map((e) => ItemWellnessScore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      positiveFactors: (json['positive_factors'] as List<dynamic>?)
              ?.map((e) => WellnessFactor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      negativeFactors: (json['negative_factors'] as List<dynamic>?)
              ?.map((e) => WellnessFactor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// Per-item wellness score.
class ItemWellnessScore {
  final String name;
  final int score;

  const ItemWellnessScore({required this.name, required this.score});

  factory ItemWellnessScore.fromJson(Map<String, dynamic> json) {
    return ItemWellnessScore(
      name: json['name'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A single factor that influenced the wellness score.
class WellnessFactor {
  final String label; // "High Protein", "Excess Sugar"
  final int points; // +12 or -20
  final String reason; // "Supports muscle recovery"

  const WellnessFactor({
    required this.label,
    required this.points,
    required this.reason,
  });

  factory WellnessFactor.fromJson(Map<String, dynamic> json) {
    return WellnessFactor(
      label: json['label'] as String? ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String? ?? '',
    );
  }
}
