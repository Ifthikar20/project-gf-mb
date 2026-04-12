import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/config/secure_config.dart';
import '../../../core/services/healthkit_service.dart';
import '../../../features/wellness_goals/data/models/wellness_checkin_model.dart';
import '../../../features/diet/data/models/diet_models.dart';
import '../domain/entities/wellness_score.dart';

/// Computes the daily Wellness Score entirely on-device.
///
/// Reads from:
/// - Hive: check-ins (mood + sleep), diet logs, goal streaks
/// - HealthKit: steps, workout minutes
///
/// Caches daily snapshots in Hive for trend charts.
class WellnessScoreService {
  static const String _scoreBoxName = 'wellness_scores';
  static const int _maxHistoryDays = 90;

  /// Compute today's wellness score from all local sources.
  Future<WellnessScore> computeTodayScore() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get encryption key for Hive boxes
    final keyList = await SecureConfig.instance.getEncryptionKey();
    final cipher = HiveAesCipher(Uint8List.fromList(keyList));

    // ── 1. Sleep score (from latest check-in) ──
    int sleepScore = 0;
    try {
      final box = await Hive.openBox<WellnessCheckInModel>(
        'wellness_checkins',
        encryptionCipher: cipher,
      );
      if (box.isNotEmpty) {
        final entries = box.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        final latest = entries.first;
        if (latest.sleepQuality != null) {
          // 1-5 → 0-100
          sleepScore = ((latest.sleepQuality! - 1) * 25).clamp(0, 100);
        }
      }
    } catch (e) {
      debugPrint('WellnessScoreService: sleep read failed: $e');
    }

    // ── 2. Activity score (steps from HealthKit) ──
    int activityScore = 0;
    try {
      final hk = HealthKitService.instance;
      if (hk.isAuthorized) {
        final steps = await hk.getStepCount(days: 1);
        // 10,000 steps = 100
        activityScore = ((steps / 10000) * 100).round().clamp(0, 100);
      }
    } catch (e) {
      debugPrint('WellnessScoreService: steps read failed: $e');
    }

    // ── 3. Nutrition score (meals logged today) ──
    int nutritionScore = 0;
    try {
      final box = await Hive.openBox<MealLog>(
        'diet_logs',
        encryptionCipher: cipher,
      );
      final todayMeals = box.values.where((m) =>
          m.timestamp.year == today.year &&
          m.timestamp.month == today.month &&
          m.timestamp.day == today.day);
      final mealCount = todayMeals.length;
      // 3 meals = 100 (encourage regular eating)
      nutritionScore = ((mealCount / 3) * 100).round().clamp(0, 100);
    } catch (e) {
      debugPrint('WellnessScoreService: nutrition read failed: $e');
    }

    // ── 4. Workout score (minutes from HealthKit) ──
    int workoutScore = 0;
    try {
      final hk = HealthKitService.instance;
      if (hk.isAuthorized) {
        final summaries = await hk.getWorkoutSummaries(days: 1);
        final todayMinutes = summaries.isEmpty ? 0 : summaries.last.totalMinutes;
        // 30 min = 100
        workoutScore = ((todayMinutes / 30) * 100).round().clamp(0, 100);
      }
    } catch (e) {
      debugPrint('WellnessScoreService: workout read failed: $e');
    }

    // ── 5. Mood score (from latest check-in) ──
    int moodScore = 0;
    try {
      final box = await Hive.openBox<WellnessCheckInModel>(
        'wellness_checkins',
        encryptionCipher: cipher,
      );
      if (box.isNotEmpty) {
        final entries = box.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        final latest = entries.first;
        // 1-5 → 0-100
        moodScore = ((latest.mood - 1) * 25).clamp(0, 100);
      }
    } catch (e) {
      debugPrint('WellnessScoreService: mood read failed: $e');
    }

    // ── 6. Streak score (from goals) ──
    int streakScore = 0;
    try {
      final box = await Hive.openBox(
        'goals_box',
        encryptionCipher: HiveAesCipher(await SecureConfig.getHiveEncryptionKey()),
      );
      if (box.isNotEmpty) {
        // Find the highest streak among all goals
        int maxStreak = 0;
        for (final goal in box.values) {
          try {
            final current = goal.currentStreak as int? ?? 0;
            if (current > maxStreak) maxStreak = current;
          } catch (_) {}
        }
        // 7-day streak = 100
        streakScore = ((maxStreak / 7) * 100).round().clamp(0, 100);
      }
    } catch (e) {
      debugPrint('WellnessScoreService: streak read failed: $e');
    }

    // ── Compute weighted total ──
    final totalScore = (
      sleepScore * ScoreCategory.sleep.weight +
      activityScore * ScoreCategory.activity.weight +
      nutritionScore * ScoreCategory.nutrition.weight +
      workoutScore * ScoreCategory.workout.weight +
      moodScore * ScoreCategory.mood.weight +
      streakScore * ScoreCategory.streak.weight
    ).round().clamp(0, 100);

    // ── Determine trend vs yesterday ──
    final history = await getScoreHistory(days: 2);
    ScoreTrend trend = ScoreTrend.flat;
    if (history.length >= 2) {
      final yesterday = history[history.length - 2].score;
      if (totalScore > yesterday + 5) {
        trend = ScoreTrend.up;
      } else if (totalScore < yesterday - 5) {
        trend = ScoreTrend.down;
      }
    }

    final score = WellnessScore(
      totalScore: totalScore,
      sleep: SubScore(category: ScoreCategory.sleep, score: sleepScore),
      activity: SubScore(category: ScoreCategory.activity, score: activityScore),
      nutrition: SubScore(category: ScoreCategory.nutrition, score: nutritionScore),
      workout: SubScore(category: ScoreCategory.workout, score: workoutScore),
      mood: SubScore(category: ScoreCategory.mood, score: moodScore),
      streak: SubScore(category: ScoreCategory.streak, score: streakScore),
      date: today,
      trend: trend,
    );

    // Cache today's score for history
    await _saveSnapshot(DailyScoreSnapshot(date: today, score: totalScore));

    return score;
  }

  /// Get score history for trend charts.
  Future<List<DailyScoreSnapshot>> getScoreHistory({int days = 30}) async {
    try {
      final box = await Hive.openBox(_scoreBoxName);
      final raw = box.get('history', defaultValue: '[]') as String;
      final list = (jsonDecode(raw) as List)
          .map((e) => DailyScoreSnapshot.fromJson(e))
          .toList();

      // Filter to requested range
      final cutoff = DateTime.now().subtract(Duration(days: days));
      return list.where((s) => s.date.isAfter(cutoff)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      debugPrint('WellnessScoreService: history read failed: $e');
      return [];
    }
  }

  /// Save a daily score snapshot to Hive.
  Future<void> _saveSnapshot(DailyScoreSnapshot snapshot) async {
    try {
      final box = await Hive.openBox(_scoreBoxName);
      final raw = box.get('history', defaultValue: '[]') as String;
      final list = (jsonDecode(raw) as List)
          .map((e) => DailyScoreSnapshot.fromJson(e))
          .toList();

      // Remove existing entry for same date
      list.removeWhere((s) =>
          s.date.year == snapshot.date.year &&
          s.date.month == snapshot.date.month &&
          s.date.day == snapshot.date.day);

      list.add(snapshot);

      // Trim to max history
      if (list.length > _maxHistoryDays) {
        list.sort((a, b) => a.date.compareTo(b.date));
        list.removeRange(0, list.length - _maxHistoryDays);
      }

      await box.put('history', jsonEncode(list.map((s) => s.toJson()).toList()));
    } catch (e) {
      debugPrint('WellnessScoreService: snapshot save failed: $e');
    }
  }
}
