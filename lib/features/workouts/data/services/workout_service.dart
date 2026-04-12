import 'package:flutter/foundation.dart';
import '../../../../core/services/api_client.dart';
import '../models/workout_models.dart';

/// Service for all workout & calorie tracking API calls
/// Uses the existing ApiClient singleton (DRF Token auth handled automatically)
class WorkoutService {
  static WorkoutService? _instance;
  final ApiClient _api;

  // Cache workout types since they rarely change
  List<WorkoutTypeModel>? _cachedTypes;

  static WorkoutService get instance {
    _instance ??= WorkoutService._(ApiClient.instance);
    return _instance!;
  }

  WorkoutService._(this._api);

  // ============================================
  // Workout Types (Reference Data)
  // ============================================

  /// Get available workout types — cached after first call
  Future<List<WorkoutTypeModel>> getWorkoutTypes({bool forceRefresh = false}) async {
    if (_cachedTypes != null && !forceRefresh) return _cachedTypes!;

    final response = await _api.get('/api/workouts/types');
    final data = response.data as Map<String, dynamic>;
    final types = (data['workout_types'] as List? ?? [])
        .map((e) => WorkoutTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();

    _cachedTypes = types;
    debugPrint(' Cached ${types.length} workout types');
    return types;
  }

  // ============================================
  // Body Profile
  // ============================================

  /// Get user's body profile — returns null if not set yet or endpoint unavailable
  Future<BodyProfile?> getBodyProfile() async {
    try {
      final response = await _api.get('/api/workouts/body-profile');
      final data = response.data as Map<String, dynamic>;
      final profile = data['body_profile'];
      return profile != null ? BodyProfile.fromJson(profile) : null;
    } catch (_) {
      // Endpoint may not be deployed yet — return null silently
      return null;
    }
  }

  /// Set or update body profile
  Future<BodyProfile> setBodyProfile({
    required double weightKg,
    double? heightCm,
  }) async {
    final response = await _api.put('/api/workouts/body-profile', data: {
      'weight_kg': weightKg,
      if (heightCm != null) 'height_cm': heightCm,
    });
    final data = response.data as Map<String, dynamic>;
    return BodyProfile.fromJson(data['body_profile']);
  }

  // ============================================
  // Calorie Estimate
  // ============================================

  /// Preview calorie burn before confirming workout
  Future<CalorieEstimate> estimateCalories({
    required String workoutTypeId,
    required int durationMinutes,
  }) async {
    final response = await _api.post('/api/workouts/estimate', data: {
      'workout_type_id': workoutTypeId,
      'duration_minutes': durationMinutes,
    });
    return CalorieEstimate.fromJson(response.data);
  }

  // ============================================
  // Log Workouts
  // ============================================

  /// Log a manual workout
  Future<WorkoutLogModel> logManualWorkout({
    required String workoutTypeId,
    required int durationMinutes,
    required DateTime startedAt,
    String? note,
    String? mood,
  }) async {
    final response = await _api.post('/api/workouts/log/manual', data: {
      'workout_type_id': workoutTypeId,
      'duration_minutes': durationMinutes,
      'started_at': startedAt.toUtc().toIso8601String(),
      if (note != null && note.isNotEmpty) 'note': note,
      if (mood != null && mood.isNotEmpty) 'mood': mood,
    });
    final data = response.data as Map<String, dynamic>;
    return WorkoutLogModel.fromJson(data['workout']);
  }

  // ============================================
  // History
  // ============================================

  /// Get workout history with optional filters
  Future<List<WorkoutLogModel>> getHistory({
    int limit = 20,
    int offset = 0,
    String? source,
    int days = 30,
  }) async {
    final response = await _api.get(
      '/api/workouts/history',
      queryParameters: {
        'limit': limit,
        'offset': offset,
        if (source != null) 'source': source,
        'days': days,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return (data['workouts'] as List? ?? [])
        .map((e) => WorkoutLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================
  // Stats
  // ============================================

  /// Get weekly stats with daily breakdown
  Future<WorkoutStats> getStats() async {
    final response = await _api.get('/api/workouts/stats');
    return WorkoutStats.fromJson(response.data);
  }

  // ============================================
  // Goals
  // ============================================

  /// Get weekly goals with current progress
  Future<List<GoalProgress>> getGoals() async {
    final response = await _api.get('/api/workouts/goals');
    final data = response.data as Map<String, dynamic>;
    return (data['goals'] as List? ?? [])
        .map((e) => GoalProgress.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Set a weekly goal (creates or updates)
  Future<void> setGoal({
    required String goalType,
    required int targetValue,
  }) async {
    await _api.post('/api/workouts/goals/set', data: {
      'goal_type': goalType,
      'target_value': targetValue,
    });
  }

  /// Remove a weekly goal
  Future<void> deleteGoal(String goalType) async {
    await _api.delete('/api/workouts/goals/$goalType');
  }
}
