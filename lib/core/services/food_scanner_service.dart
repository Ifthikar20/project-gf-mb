import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../../features/diet/data/models/food_scan_result.dart';

/// Sends food images to the Django backend for AI analysis.
/// The backend calls Gemini 2.5 Flash Vision server-side —
/// the API key never leaves the server.
///
/// Rate limit: 5 scans/minute per user (backend-enforced).
class FoodScannerService {
  FoodScannerService._();
  static final FoodScannerService instance = FoodScannerService._();

  final ApiClient _api = ApiClient.instance;

  /// Analyze a food image via the backend.
  ///
  /// Sends the image as multipart to `POST /api/food/analyze`.
  /// Returns [FoodScanResult] with items, calories, macros, and confidence.
  ///
  /// Throws [FoodScanException] on validation, auth, rate-limit, or server errors.
  Future<FoodScanResult> analyzeImage(
    Uint8List imageBytes, {
    String mealType = 'lunch',
  }) async {
    try {
      debugPrint('🍽 Sending food image to backend for analysis...');

      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: 'food_scan.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
        'meal_type': mealType,
      });

      final response = await _api.post(
        '/api/food/analyze',
        data: formData,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        debugPrint('🍽 Analysis complete: ${data['total_calories']} calories, '
            '${(data['items'] as List?)?.length ?? 0} items');
        return FoodScanResult.fromJson(data);
      } else {
        final error = data['error'] as Map<String, dynamic>?;
        throw FoodScanException(
          error?['code'] ?? 'UNKNOWN',
          error?['message'] ?? 'Analysis failed',
        );
      }
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final errorData = responseData is Map<String, dynamic>
          ? responseData['error'] as Map<String, dynamic>?
          : null;
      final code = errorData?['code'] ?? 'NETWORK_ERROR';
      final msg = errorData?['message'] ?? 'Network error';

      if (e.response?.statusCode == 429) {
        throw FoodScanException(
          'RATE_LIMITED',
          'Too many scans. Please wait and try again.',
        );
      }
      if (e.response?.statusCode == 400) {
        throw FoodScanException(
          'INVALID_IMAGE',
          msg,
        );
      }
      if (e.response?.statusCode == 401) {
        throw FoodScanException(
          'AUTHENTICATION_REQUIRED',
          'Please log in to use the food scanner.',
        );
      }

      debugPrint('🍽 Food scan API error: $code — $msg');
      throw FoodScanException(code, msg);
    } on FoodScanException {
      rethrow;
    } catch (e) {
      debugPrint('🍽 Unexpected food scan error: $e');
      throw FoodScanException('UNKNOWN', 'Something went wrong. Please try again.');
    }
  }
}

/// Exception for food scanner errors with a machine-readable code.
class FoodScanException implements Exception {
  final String code;
  final String message;
  FoodScanException(this.code, this.message);

  @override
  String toString() => 'FoodScanException($code): $message';
}
