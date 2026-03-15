import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../features/diet/data/models/food_scan_result.dart';

/// Sends food images to Gemini 2.0 Flash Vision and returns
/// calorie + macro estimates as structured JSON.
class FoodScannerService {
  FoodScannerService._();
  static final FoodScannerService instance = FoodScannerService._();

  GenerativeModel? _model;

  GenerativeModel get _gemini {
    if (_model != null) return _model!;
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception(
          'GEMINI_API_KEY not found in .env file. '
          'Get one free at https://aistudio.google.com');
    }
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
    );
    return _model!;
  }

  /// Analyze a food image and return detected items with calories & macros.
  Future<FoodScanResult> analyzeImage(Uint8List imageBytes) async {
    try {
      debugPrint('🍽 Sending food image to Gemini Vision...');

      final prompt = TextPart('''
You are a professional nutritionist AI. Analyze this food image and identify every food item visible.

Return ONLY valid JSON (no markdown, no backticks) in this exact format:
{
  "items": [
    {
      "name": "Food Name",
      "calories": 250,
      "protein_g": 12.5,
      "carbs_g": 30.0,
      "fat_g": 8.0,
      "serving_size": "1 cup (240g)",
      "confidence": 0.9
    }
  ],
  "meal_type": "lunch"
}

Rules:
- Estimate calories and macros as accurately as possible based on visual portion size.
- Use standard USDA nutrition data as reference.
- meal_type should be one of: breakfast, lunch, dinner, snack.
- confidence is 0.0 to 1.0, reflecting how sure you are about the identification.
- If you see multiple food items, list each separately.
- If you cannot identify the food, return an item with name "Unknown food" and your best calorie estimate.
''');

      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await _gemini.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      final text = response.text ?? '';
      debugPrint('🍽 Gemini response: ${text.substring(0, text.length.clamp(0, 200))}');

      // Parse JSON from response (handle possible markdown wrapping)
      String jsonStr = text.trim();
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.replaceAll(RegExp(r'^```\w*\n?'), '').replaceAll(RegExp(r'\n?```$'), '');
      }

      final Map<String, dynamic> parsed = json.decode(jsonStr);
      return FoodScanResult.fromJson(parsed);
    } catch (e) {
      debugPrint('🍽 Gemini analysis failed: $e');
      // Return a fallback result
      return const FoodScanResult(
        items: [
          DetectedFoodItem(
            name: 'Could not analyze',
            calories: 0,
            proteinG: 0,
            carbsG: 0,
            fatG: 0,
            servingSize: 'N/A',
            confidence: 0,
          ),
        ],
        totalCalories: 0,
      );
    }
  }
}
