import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../features/diet/data/models/food_scan_result.dart';

/// Looks up product nutrition info from a barcode using OpenFoodFacts API.
/// Free, no API key required.
class BarcodeLookupService {
  BarcodeLookupService._();
  static final BarcodeLookupService instance = BarcodeLookupService._();

  /// Look up a product by its barcode and return nutrition info.
  Future<FoodScanResult?> lookupBarcode(String barcode) async {
    try {
      debugPrint('🔍 Looking up barcode: $barcode');

      final url = Uri.parse(
          'https://world.openfoodfacts.org/api/v2/product/$barcode.json');
      final response = await http.get(url, headers: {
        'User-Agent': 'BetterBliss Wellness App/1.0',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('🔍 OpenFoodFacts API returned ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);

      if (data['status'] != 1 || data['product'] == null) {
        debugPrint('🔍 Product not found for barcode: $barcode');
        return null;
      }

      final product = data['product'];
      final name = product['product_name'] ??
          product['product_name_en'] ??
          'Unknown Product';
      final nutriments = product['nutriments'] ?? {};
      final servingSize = product['serving_size'] ?? '100g';

      // Per serving or per 100g
      final calories =
          (nutriments['energy-kcal_serving'] ?? nutriments['energy-kcal_100g'] ?? 0)
              .toDouble();
      final protein =
          (nutriments['proteins_serving'] ?? nutriments['proteins_100g'] ?? 0)
              .toDouble();
      final carbs = (nutriments['carbohydrates_serving'] ??
                  nutriments['carbohydrates_100g'] ??
                  0)
              .toDouble();
      final fat =
          (nutriments['fat_serving'] ?? nutriments['fat_100g'] ?? 0)
              .toDouble();

      debugPrint('🔍 Found: $name — ${calories.round()} cal');

      final item = DetectedFoodItem(
        name: name,
        calories: calories.round(),
        proteinG: protein,
        carbsG: carbs,
        fatG: fat,
        servingSize: servingSize,
        confidence: 1.0,
      );

      return FoodScanResult(
        items: [item],
        totalCalories: calories.round(),
        mealType: _guessMealType(),
      );
    } on TimeoutException {
      debugPrint('[Barcode] Lookup timed out');
      return null;
    } catch (e) {
      debugPrint('🔍 Barcode lookup failed: $e');
      return null;
    }
  }

  /// Simple time-based meal type guess
  String _guessMealType() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'breakfast';
    if (hour < 15) return 'lunch';
    if (hour < 20) return 'dinner';
    return 'snack';
  }
}
