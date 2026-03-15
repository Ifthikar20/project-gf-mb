/// Data model for food scan results from Gemini Vision API.

class FoodScanResult {
  final List<DetectedFoodItem> items;
  final int totalCalories;
  final String? mealType; // breakfast, lunch, dinner, snack

  const FoodScanResult({
    required this.items,
    required this.totalCalories,
    this.mealType,
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
          items.fold(0, (sum, item) => sum + item.calories),
      mealType: json['meal_type'] as String?,
    );
  }
}

class DetectedFoodItem {
  final String name;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String servingSize;
  final double confidence; // 0.0 – 1.0

  const DetectedFoodItem({
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.servingSize,
    this.confidence = 0.8,
  });

  factory DetectedFoodItem.fromJson(Map<String, dynamic> json) {
    return DetectedFoodItem(
      name: json['name'] as String? ?? 'Unknown',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      servingSize: json['serving_size'] as String? ?? '1 serving',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
    );
  }
}
