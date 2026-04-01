import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Data point for heart rate readings
class HeartRatePoint {
  final DateTime time;
  final double bpm;
  const HeartRatePoint({required this.time, required this.bpm});

  Map<String, dynamic> toJson() => {'time': time.toIso8601String(), 'bpm': bpm};
  factory HeartRatePoint.fromJson(Map<String, dynamic> json) => HeartRatePoint(
        time: DateTime.parse(json['time']),
        bpm: (json['bpm'] as num).toDouble(),
      );
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

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'totalMinutes': totalMinutes,
        'caloriesBurned': caloriesBurned,
        'workoutCount': workoutCount,
      };
  factory DailyWorkoutSummary.fromJson(Map<String, dynamic> json) =>
      DailyWorkoutSummary(
        date: DateTime.parse(json['date']),
        totalMinutes: json['totalMinutes'] ?? 0,
        caloriesBurned: (json['caloriesBurned'] as num?)?.toDouble() ?? 0,
        workoutCount: json['workoutCount'] ?? 0,
      );
}

/// HealthKit service — reads Apple Watch data via the `health` package.
/// On-device only: data is read from HealthKit and cached locally in Hive.
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
  bool _configured = false;

  /// Whether the user has opted in to health data collection in profile settings
  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  /// Last error message (for UI feedback)
  String? lastError;

  /// HealthKit data types we need
  static const _readTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WORKOUT,
  ];

  // Hive box name for health data cache
  static const _boxName = 'health_data';

  // ──────────────────────────────────
  // Initialization
  // ──────────────────────────────────

  /// Load saved preferences (call at app startup)
  Future<void> init() async {
    final box = await Hive.openBox('healthkit_prefs');
    _isAuthorized = box.get('authorized', defaultValue: false) as bool;
    _isEnabled = box.get('enabled', defaultValue: false) as bool;
    debugPrint('HealthKit init: enabled=$_isEnabled, authorized=$_isAuthorized');

    // Pre-configure the health plugin
    try {
      await _health.configure();
      _configured = true;
      debugPrint('HealthKit: configure() success');
    } catch (e) {
      debugPrint('HealthKit: configure() failed: $e');
    }
  }

  // ──────────────────────────────────
  // Enable / Disable Toggle
  // ──────────────────────────────────

  /// Enable or disable health data collection.
  /// When enabled: requests HealthKit permissions, reads & caches data.
  /// When disabled: clears cached health data.
  Future<bool> setEnabled(bool enabled) async {
    if (enabled) {
      final granted = await requestPermissions();
      if (!granted) return false;
      _isEnabled = true;
      final box = await Hive.openBox('healthkit_prefs');
      await box.put('enabled', true);
      // Do initial data fetch & cache
      await refreshAndCache();
      return true;
    } else {
      _isEnabled = false;
      final box = await Hive.openBox('healthkit_prefs');
      await box.put('enabled', false);
      // Clear cached health data
      await _clearCachedData();
      return true;
    }
  }

  /// Refresh all health data from HealthKit and save to local cache
  Future<void> refreshAndCache() async {
    if (!_isEnabled || !_isAuthorized) return;
    try {
      final hr = await getHeartRateData(days: 2);
      final workouts = await getWorkoutSummaries(days: 7);
      final steps = await getStepCount(days: 1);
      final effort = await getEffortScore(days: 7);

      final box = await Hive.openBox(_boxName);
      await box.put('heart_rate', jsonEncode(hr.map((e) => e.toJson()).toList()));
      await box.put('workouts', jsonEncode(workouts.map((e) => e.toJson()).toList()));
      await box.put('steps', steps);
      await box.put('effort_score', effort);
      await box.put('last_sync', DateTime.now().toIso8601String());
      debugPrint('Health data cached: ${hr.length} HR points, ${workouts.length} days, $steps steps');
    } catch (e) {
      debugPrint('Failed to cache health data: $e');
    }
  }

  Future<void> _clearCachedData() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.clear();
    } catch (_) {}
  }

  // ──────────────────────────────────
  // Cached Data Getters
  // ──────────────────────────────────

  /// Get cached heart rate data (from Hive, no HealthKit call)
  Future<List<HeartRatePoint>> getCachedHeartRate() async {
    try {
      final box = await Hive.openBox(_boxName);
      final raw = box.get('heart_rate') as String?;
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list.map((e) => HeartRatePoint.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get cached workout summaries
  Future<List<DailyWorkoutSummary>> getCachedWorkouts() async {
    try {
      final box = await Hive.openBox(_boxName);
      final raw = box.get('workouts') as String?;
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list.map((e) => DailyWorkoutSummary.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get cached step count
  Future<int> getCachedSteps() async {
    try {
      final box = await Hive.openBox(_boxName);
      return box.get('steps', defaultValue: 0) as int;
    } catch (_) {
      return 0;
    }
  }

  /// Get cached effort score
  Future<double> getCachedEffortScore() async {
    try {
      final box = await Hive.openBox(_boxName);
      return (box.get('effort_score', defaultValue: 0.0) as num).toDouble();
    } catch (_) {
      return 0.0;
    }
  }

  /// Get latest cached heart rate BPM (for the live card)
  Future<int> getLatestHeartRate() async {
    final data = await getCachedHeartRate();
    if (data.isEmpty) return 0;
    return data.last.bpm.round();
  }

  /// Last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final box = await Hive.openBox(_boxName);
      final raw = box.get('last_sync') as String?;
      return raw != null ? DateTime.parse(raw) : null;
    } catch (_) {
      return null;
    }
  }

  // ──────────────────────────────────
  // Availability & Permissions
  // ──────────────────────────────────

  /// Check if HealthKit is available on this device
  Future<bool> get isAvailable async {
    if (_checkedAvailability) return _isAvailable;
    try {
      // hasPermissions returns null if HealthKit is not available on the device
      final result = await Health().hasPermissions(_readTypes);
      _isAvailable = result != null;
    } catch (e) {
      debugPrint('HealthKit not available: $e');
      _isAvailable = false;
    }
    _checkedAvailability = true;
    return _isAvailable;
  }

  /// Whether the user has granted permissions
  bool get isAuthorized => _isAuthorized;

  /// Ensure Health plugin is configured (required once before any calls)
  Future<void> _ensureConfigured() async {
    if (_configured) return;
    try {
      await _health.configure();
      _configured = true;
      debugPrint('Health plugin configured');
    } catch (e) {
      debugPrint('Health configure error: $e');
    }
  }

  /// Request HealthKit permissions.
  Future<bool> requestPermissions() async {
    try {
      await _ensureConfigured();

      debugPrint('HealthKit: requesting authorization...');
      final granted = await _health.requestAuthorization(
        _readTypes,
        permissions: _readTypes.map((_) => HealthDataAccess.READ).toList(),
      );
      debugPrint('HealthKit: requestAuthorization returned $granted');

      _isAuthorized = granted;
      _isAvailable = true;
      _checkedAvailability = true;
      lastError = null;

      final box = await Hive.openBox('healthkit_prefs');
      await box.put('authorized', granted);

      if (granted) {
        // Verify we can actually read data
        final testSteps = await getStepCount(days: 1);
        debugPrint('HealthKit verification: $testSteps steps today');
      } else {
        debugPrint('HealthKit: authorization denied');
        lastError = 'Permission denied';
      }

      return granted;
    } catch (e) {
      debugPrint('HealthKit permission error: $e');
      lastError = e.toString();
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
  Future<List<HeartRatePoint>> getHeartRateData({int days = 2}) async {
    if (!_isAuthorized) return [];
    await _ensureConfigured();

    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      final dataPoints = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: now,
      );

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
    await _ensureConfigured();

    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      final energyData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: start,
        endTime: now,
      );

      final workoutData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: start,
        endTime: now,
      );

      final cleanedEnergy = Health().removeDuplicates(energyData);
      final cleanedWorkouts = Health().removeDuplicates(workoutData);

      final Map<String, DailyWorkoutSummary> dailyMap = {};

      for (var i = 0; i < days; i++) {
        final day = now.subtract(Duration(days: i));
        final key = '${day.year}-${day.month}-${day.day}';
        dailyMap[key] = DailyWorkoutSummary(date: day);
      }

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

  /// Get total step count for the last [days] days.
  /// Uses getTotalStepsInInterval first, falls back to summing STEPS data points.
  Future<int> getStepCount({int days = 1}) async {
    if (!_isAuthorized) {
      debugPrint('HealthKit steps: not authorized');
      return 0;
    }
    await _ensureConfigured();

    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));

      debugPrint('HealthKit steps: querying $start to $now');

      // Method 1: getTotalStepsInInterval
      final steps = await _health.getTotalStepsInInterval(start, now);
      debugPrint('HealthKit steps (total): $steps');
      if (steps != null && steps > 0) return steps;

      // Method 2: Sum individual STEPS data points
      final dataPoints = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: start,
        endTime: now,
      );
      final cleaned = Health().removeDuplicates(dataPoints);
      int sum = 0;
      for (final dp in cleaned) {
        sum += (dp.value as NumericHealthValue).numericValue.toInt();
      }
      debugPrint('HealthKit steps (summed ${cleaned.length} points): $sum');
      return sum;
    } catch (e) {
      debugPrint('HealthKit steps fetch error: $e');
      return 0;
    }
  }

  // ──────────────────────────────────
  // Effort Score (composite metric)
  // ──────────────────────────────────

  /// Calculate an effort score (0.0–1.0) based on the last [days] days
  Future<double> getEffortScore({int days = 7}) async {
    final summaries = await getWorkoutSummaries(days: days);
    if (summaries.isEmpty) return 0.0;

    final totalMinutes = summaries.fold<int>(0, (sum, s) => sum + s.totalMinutes);
    final totalCalories = summaries.fold<double>(0, (sum, s) => sum + s.caloriesBurned);

    const targetMinutes = 150;
    const targetCalories = 2000.0;

    final minuteScore = (totalMinutes / targetMinutes).clamp(0.0, 1.0);
    final calorieScore = (totalCalories / targetCalories).clamp(0.0, 1.0);

    return (minuteScore * 0.6 + calorieScore * 0.4).clamp(0.0, 1.0);
  }

  // ──────────────────────────────────
  // Simulated data (fallback for simulator)
  // ──────────────────────────────────

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
