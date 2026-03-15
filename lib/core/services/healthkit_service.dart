import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Data point for heart rate readings
class HeartRatePoint {
  final DateTime time;
  final double bpm;
  const HeartRatePoint({required this.time, required this.bpm});
}

/// Daily workout summary
class DailyWorkoutSummary {
  final DateTime date;
  final int totalMinutes;
  final double caloriesBurned;
  final int workoutCount;
  const DailyWorkoutSummary({
    required this.date,
    this.totalMinutes = 0,
    this.caloriesBurned = 0,
    this.workoutCount = 0,
  });
}

/// HealthKit service — reads Apple Watch data via the `health` package.
/// On-device only (Pattern 1): data is read from HealthKit and cached locally.
/// Falls back to simulated data on simulator or when permissions are denied.
class HealthKitService {
  static HealthKitService? _instance;
  static HealthKitService get instance {
    _instance ??= HealthKitService._();
    return _instance!;
  }

  HealthKitService._();

  final Health _health = Health();
  bool _isAuthorized = false;
  bool _checkedAvailability = false;
  bool _isAvailable = false;

  /// HealthKit data types we need
  static const _readTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WORKOUT,
  ];

  // ──────────────────────────────────
  // Availability & Permissions
  // ──────────────────────────────────

  /// Check if HealthKit is available on this device
  Future<bool> get isAvailable async {
    if (_checkedAvailability) return _isAvailable;
    try {
      _isAvailable = await Health().hasPermissions(_readTypes) ?? false;
      // If hasPermissions returns null, HealthKit may still be available
      // but permissions haven't been requested yet
      _isAvailable = true;
    } catch (e) {
      debugPrint('HealthKit not available: $e');
      _isAvailable = false;
    }
    _checkedAvailability = true;
    return _isAvailable;
  }

  /// Whether the user has granted permissions
  bool get isAuthorized => _isAuthorized;

  /// Request HealthKit permissions
  /// Returns true if all requested permissions were granted
  Future<bool> requestPermissions() async {
    try {
      final granted = await _health.requestAuthorization(
        _readTypes,
        permissions: _readTypes.map((_) => HealthDataAccess.READ).toList(),
      );
      _isAuthorized = granted;
      _isAvailable = true;
      _checkedAvailability = true;

      // Persist auth state
      final box = await Hive.openBox('healthkit_prefs');
      await box.put('authorized', granted);

      debugPrint('HealthKit authorization: $granted');
      return granted;
    } catch (e) {
      debugPrint('HealthKit permission error: $e');
      _isAuthorized = false;
      return false;
    }
  }

  /// Check if we previously had permissions (from cached state)
  Future<bool> checkCachedPermission() async {
    try {
      final box = await Hive.openBox('healthkit_prefs');
      _isAuthorized = box.get('authorized', defaultValue: false) as bool;
      return _isAuthorized;
    } catch (_) {
      return false;
    }
  }

  // ──────────────────────────────────
  // Heart Rate
  // ──────────────────────────────────

  /// Get heart rate data for the last [days] days
  /// Returns empty list if HealthKit is not available or not authorized
  Future<List<HeartRatePoint>> getHeartRateData({int days = 2}) async {
    if (!_isAuthorized) return [];

    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      final dataPoints = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: now,
      );

      // Remove duplicates
      final cleaned = Health().removeDuplicates(dataPoints);

      return cleaned.map((dp) {
        return HeartRatePoint(
          time: dp.dateFrom,
          bpm: (dp.value as NumericHealthValue).numericValue.toDouble(),
        );
      }).toList()
        ..sort((a, b) => a.time.compareTo(b.time));
    } catch (e) {
      debugPrint('HealthKit HR fetch error: $e');
      return [];
    }
  }

  // ──────────────────────────────────
  // Workouts / Activity
  // ──────────────────────────────────

  /// Get daily workout summaries for the last [days] days
  Future<List<DailyWorkoutSummary>> getWorkoutSummaries({int days = 7}) async {
    if (!_isAuthorized) return [];

    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      // Get active energy data
      final energyData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: start,
        endTime: now,
      );

      // Get workout sessions
      final workoutData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: start,
        endTime: now,
      );

      // Clean duplicates
      final cleanedEnergy = Health().removeDuplicates(energyData);
      final cleanedWorkouts = Health().removeDuplicates(workoutData);

      // Group by day
      final Map<String, DailyWorkoutSummary> dailyMap = {};

      for (var i = 0; i < days; i++) {
        final day = now.subtract(Duration(days: i));
        final key = '${day.year}-${day.month}-${day.day}';
        dailyMap[key] = DailyWorkoutSummary(date: day);
      }

      // Add workout minutes
      for (final wp in cleanedWorkouts) {
        final key = '${wp.dateFrom.year}-${wp.dateFrom.month}-${wp.dateFrom.day}';
        if (dailyMap.containsKey(key)) {
          final existing = dailyMap[key]!;
          final minutes = wp.dateTo.difference(wp.dateFrom).inMinutes;
          dailyMap[key] = DailyWorkoutSummary(
            date: existing.date,
            totalMinutes: existing.totalMinutes + minutes,
            caloriesBurned: existing.caloriesBurned,
            workoutCount: existing.workoutCount + 1,
          );
        }
      }

      // Add calories
      for (final ep in cleanedEnergy) {
        final key = '${ep.dateFrom.year}-${ep.dateFrom.month}-${ep.dateFrom.day}';
        if (dailyMap.containsKey(key)) {
          final existing = dailyMap[key]!;
          final cal = (ep.value as NumericHealthValue).numericValue.toDouble();
          dailyMap[key] = DailyWorkoutSummary(
            date: existing.date,
            totalMinutes: existing.totalMinutes,
            caloriesBurned: existing.caloriesBurned + cal,
            workoutCount: existing.workoutCount,
          );
        }
      }

      final result = dailyMap.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      return result;
    } catch (e) {
      debugPrint('HealthKit workout fetch error: $e');
      return [];
    }
  }

  // ──────────────────────────────────
  // Steps
  // ──────────────────────────────────

  /// Get total step count for the last [days] days
  Future<int> getStepCount({int days = 1}) async {
    if (!_isAuthorized) return 0;

    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      final steps = await _health.getTotalStepsInInterval(start, now);
      return steps ?? 0;
    } catch (e) {
      debugPrint('HealthKit steps fetch error: $e');
      return 0;
    }
  }

  // ──────────────────────────────────
  // Effort Score (composite metric)
  // ──────────────────────────────────

  /// Calculate an effort score (0.0–1.0) based on the last [days] days
  /// Combines workout minutes + calories vs a target
  Future<double> getEffortScore({int days = 7}) async {
    final summaries = await getWorkoutSummaries(days: days);
    if (summaries.isEmpty) return 0.0;

    final totalMinutes = summaries.fold<int>(0, (sum, s) => sum + s.totalMinutes);
    final totalCalories = summaries.fold<double>(0, (sum, s) => sum + s.caloriesBurned);

    // Target: 150 min/week recommended + ~2000 cal/week active
    const targetMinutes = 150;
    const targetCalories = 2000.0;

    final minuteScore = (totalMinutes / targetMinutes).clamp(0.0, 1.0);
    final calorieScore = (totalCalories / targetCalories).clamp(0.0, 1.0);

    // Weighted average: 60% minutes, 40% calories
    return (minuteScore * 0.6 + calorieScore * 0.4).clamp(0.0, 1.0);
  }

  // ──────────────────────────────────
  // Simulated data (fallback for simulator)
  // ──────────────────────────────────

  /// Simulated heart rate data for when HealthKit is unavailable
  static List<HeartRatePoint> get simulatedHeartRate {
    final now = DateTime.now();
    const hrValues = [72, 85, 110, 135, 152, 148, 138, 120, 95, 78];
    return List.generate(hrValues.length, (i) {
      return HeartRatePoint(
        time: now.subtract(Duration(minutes: (hrValues.length - i) * 6)),
        bpm: hrValues[i].toDouble(),
      );
    });
  }

  /// Simulated weekly workout data for when HealthKit is unavailable
  static List<DailyWorkoutSummary> get simulatedWeekly {
    final now = DateTime.now();
    const minutes = [45, 0, 30, 60, 20, 90, 0];
    return List.generate(7, (i) {
      return DailyWorkoutSummary(
        date: now.subtract(Duration(days: 6 - i)),
        totalMinutes: minutes[i],
        caloriesBurned: minutes[i] * 8.5,
        workoutCount: minutes[i] > 0 ? 1 : 0,
      );
    });
  }
}
