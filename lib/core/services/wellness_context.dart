import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/secure_config.dart';
import '../../features/wellness_goals/data/models/wellness_checkin_model.dart';
import '../../features/wellness_goals/data/models/fitness_profile_model.dart';
import '../../features/diet/data/models/diet_models.dart';
import '../../features/meditation/data/models/journal_models.dart';
import '../config/secure_config.dart';

/// Snapshot of the user's current wellness state — built from local Hive data.
/// Sent to the AI advisor endpoint or consumed by the local rule engine.
class WellnessContext {
  // ── Check-in signals ──
  final int? mood;          // 1-5
  final int? energy;        // 1-5
  final int? sleepQuality;  // 1-5

  // ── Fitness profile ──
  final String? bodyType;       // lean, athletic, stocky
  final String? fitnessGoal;    // loseWeight, buildMuscle, stayActive, improveFlexibility
  final String? intensityPref;  // calm, moderate, aggressive

  // ── Workout signals ──
  final String? lastWorkoutName;
  final String? lastWorkoutCategory;
  final int? lastWorkoutDurationMinutes;
  final int? lastWorkoutHoursAgo;
  final int? workoutsThisWeek;

  // ── Nutrition signals ──
  final int? todayCalories;
  final int? todayProtein;
  final int? todayMealCount;

  // ── Meditation signals ──
  final bool meditatedToday;
  final int? lastMeditationMoodAfter; // 1-5

  // ── Streaks & goals ──
  final int? currentStreak;
  final int? activeGoalCount;

  // ── Time context ──
  final int currentHour;    // 0-23
  final String dayOfWeek;   // Monday, Tuesday, etc.
  final DateTime timestamp;

  const WellnessContext({
    this.mood,
    this.energy,
    this.sleepQuality,
    this.bodyType,
    this.fitnessGoal,
    this.intensityPref,
    this.lastWorkoutName,
    this.lastWorkoutCategory,
    this.lastWorkoutDurationMinutes,
    this.lastWorkoutHoursAgo,
    this.workoutsThisWeek,
    this.todayCalories,
    this.todayProtein,
    this.todayMealCount,
    this.meditatedToday = false,
    this.lastMeditationMoodAfter,
    this.currentStreak,
    this.activeGoalCount,
    required this.currentHour,
    required this.dayOfWeek,
    required this.timestamp,
  });

  /// Serialize for the AI endpoint
  Map<String, dynamic> toJson() => {
        'mood': mood,
        'energy': energy,
        'sleep_quality': sleepQuality,
        'body_type': bodyType,
        'fitness_goal': fitnessGoal,
        'intensity_pref': intensityPref,
        'last_workout_name': lastWorkoutName,
        'last_workout_category': lastWorkoutCategory,
        'last_workout_duration_minutes': lastWorkoutDurationMinutes,
        'last_workout_hours_ago': lastWorkoutHoursAgo,
        'workouts_this_week': workoutsThisWeek,
        'today_calories': todayCalories,
        'today_protein': todayProtein,
        'today_meal_count': todayMealCount,
        'meditated_today': meditatedToday,
        'last_meditation_mood_after': lastMeditationMoodAfter,
        'current_streak': currentStreak,
        'active_goal_count': activeGoalCount,
        'current_hour': currentHour,
        'day_of_week': dayOfWeek,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Builds a [WellnessContext] by reading all local Hive boxes.
class WellnessContextCollector {
  WellnessContextCollector._();

  static Future<WellnessContext> collect() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];

    // Obtain the shared encryption key for sensitive Hive boxes (FIX 9)
    final keyList = await SecureConfig.instance.getEncryptionKey();
    final cipher = HiveAesCipher(Uint8List.fromList(keyList));

    // ── Check-in ──
    int? mood, energy, sleepQuality;
    try {
      final box = await Hive.openBox<WellnessCheckInModel>('wellness_checkins',
          encryptionCipher: cipher);
      if (box.isNotEmpty) {
        // Get latest check-in
        final entries = box.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        final latest = entries.first;
        mood = latest.mood;
        energy = latest.energyLevel;
        sleepQuality = latest.sleepQuality;
      }
    } catch (e) {
      debugPrint('⚠ WellnessContext: check-in read failed: $e');
    }

    // ── Fitness profile ──
    String? bodyType, fitnessGoal, intensityPref;
    try {
      final box = await Hive.openBox(
        'fitness_profile',
        encryptionCipher: HiveAesCipher(await SecureConfig.getHiveEncryptionKey()),
      );
      final profile = box.get('profile') as FitnessProfileModel?;
      if (profile != null && profile.isSetUp) {
        bodyType = profile.bodyTypeLabel.toLowerCase();
        fitnessGoal = profile.fitnessGoal.name;
        intensityPref = profile.intensity.name;
      }
    } catch (e) {
      debugPrint('⚠ WellnessContext: fitness profile read failed: $e');
    }

    // ── Diet ──
    int todayCalories = 0, todayProtein = 0, todayMealCount = 0;
    try {
      final box = await Hive.openBox<MealLog>('diet_logs',
          encryptionCipher: cipher);
      final todayMeals = box.values.where((m) =>
          m.timestamp.year == today.year &&
          m.timestamp.month == today.month &&
          m.timestamp.day == today.day);
      for (final m in todayMeals) {
        todayCalories += m.calories;
        todayProtein += m.proteinGrams;
        todayMealCount++;
      }
    } catch (e) {
      debugPrint('⚠ WellnessContext: diet read failed: $e');
    }

    // ── Meditation journal ──
    bool meditatedToday = false;
    int? lastMeditationMood;
    try {
      final box = await Hive.openBox<MeditationJournalEntry>('meditation_journal',
          encryptionCipher: cipher);
      if (box.isNotEmpty) {
        final entries = box.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        final latest = entries.first;
        lastMeditationMood = latest.moodAfter;
        meditatedToday = latest.date.year == today.year &&
            latest.date.month == today.month &&
            latest.date.day == today.day;
      }
    } catch (e) {
      debugPrint('⚠ WellnessContext: meditation journal read failed: $e');
    }

    return WellnessContext(
      mood: mood,
      energy: energy,
      sleepQuality: sleepQuality,
      bodyType: bodyType,
      fitnessGoal: fitnessGoal,
      intensityPref: intensityPref,
      todayCalories: todayCalories > 0 ? todayCalories : null,
      todayProtein: todayProtein > 0 ? todayProtein : null,
      todayMealCount: todayMealCount > 0 ? todayMealCount : null,
      meditatedToday: meditatedToday,
      lastMeditationMoodAfter: lastMeditationMood,
      currentHour: now.hour,
      dayOfWeek: weekdays[now.weekday - 1],
      timestamp: now,
    );
  }
}
