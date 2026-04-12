import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/config/secure_config.dart';
import '../../../features/wellness_goals/data/models/wellness_checkin_model.dart';
import '../domain/entities/sleep_data.dart';

/// Computes sleep insights entirely on-device from Hive check-in data.
///
/// Uses `WellnessCheckInModel.sleepQuality` (1-5) — no HealthKit sleep
/// stages needed, keeping it simple and HIPAA-free.
class SleepDataService {
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Compute current sleep score and weekly data.
  Future<SleepScore> computeSleepScore() async {
    try {
      final keyList = await SecureConfig.instance.getEncryptionKey();
      final cipher = HiveAesCipher(Uint8List.fromList(keyList));

      final box = await Hive.openBox<WellnessCheckInModel>(
        'wellness_checkins',
        encryptionCipher: cipher,
      );

      if (box.isEmpty) return SleepScore.empty();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 7));
      final twoWeeksAgo = today.subtract(const Duration(days: 14));

      // Get all entries with sleep data
      final allEntries = box.values
          .where((e) => e.sleepQuality != null)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      if (allEntries.isEmpty) return SleepScore.empty();

      // ── Weekly data (last 7 days) ──
      final weeklyData = <DailySleepQuality>[];
      for (int i = 6; i >= 0; i--) {
        final day = today.subtract(Duration(days: i));
        final entry = allEntries.where((e) =>
            e.date.year == day.year &&
            e.date.month == day.month &&
            e.date.day == day.day).toList();

        if (entry.isNotEmpty && entry.first.sleepQuality != null) {
          weeklyData.add(DailySleepQuality(
            date: day,
            quality: entry.first.sleepQuality!,
            dayLabel: _dayNames[day.weekday - 1],
          ));
        }
      }

      // ── Average quality (this week) ──
      double avgQuality = 0;
      if (weeklyData.isNotEmpty) {
        avgQuality = weeklyData.map((d) => d.quality).reduce((a, b) => a + b) /
            weeklyData.length;
      }

      // ── Consistency (standard deviation approach) ──
      double consistency = 0;
      if (weeklyData.length >= 3) {
        final mean = avgQuality;
        final variance = weeklyData
            .map((d) => (d.quality - mean) * (d.quality - mean))
            .reduce((a, b) => a + b) / weeklyData.length;
        // Low variance = high consistency. Max variance for 1-5 scale is ~4.
        consistency = (1.0 - (variance / 4.0)).clamp(0.0, 1.0);
      }

      // ── Trend (this week vs last week) ──
      final lastWeekEntries = allEntries.where((e) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        return d.isAfter(twoWeeksAgo) && d.isBefore(weekAgo);
      }).toList();

      SleepTrend trend = SleepTrend.stable;
      if (lastWeekEntries.isNotEmpty && weeklyData.isNotEmpty) {
        final lastWeekAvg = lastWeekEntries
            .map((e) => e.sleepQuality!)
            .reduce((a, b) => a + b) / lastWeekEntries.length;
        if (avgQuality > lastWeekAvg + 0.3) {
          trend = SleepTrend.improving;
        } else if (avgQuality < lastWeekAvg - 0.3) {
          trend = SleepTrend.declining;
        }
      }

      // ── Sleep score (0-100) ──
      // Weighted: 60% quality + 20% consistency + 20% frequency
      final qualityScore = ((avgQuality - 1) / 4 * 100).clamp(0.0, 100.0);
      final consistencyScore = consistency * 100;
      final frequencyScore = (weeklyData.length / 7 * 100).clamp(0.0, 100.0);
      final totalScore = (qualityScore * 0.6 + consistencyScore * 0.2 + frequencyScore * 0.2).round();

      // Label
      String label;
      if (totalScore >= 80) {
        label = 'Great Sleep';
      } else if (totalScore >= 60) {
        label = 'Good Sleep';
      } else if (totalScore >= 40) {
        label = 'Fair Sleep';
      } else {
        label = 'Needs Improvement';
      }

      return SleepScore(
        score: totalScore,
        label: label,
        weeklyData: weeklyData,
        avgQuality: avgQuality,
        consistency: consistency,
        trend: trend,
      );
    } catch (e) {
      debugPrint('SleepDataService: compute failed: $e');
      return SleepScore.empty();
    }
  }

  /// Generate local sleep insights based on patterns (no AI call).
  Future<List<SleepInsight>> generateInsights(SleepScore score) async {
    final insights = <SleepInsight>[];

    if (!score.hasData) {
      insights.add(const SleepInsight(
        title: 'Start tracking your sleep',
        body: 'Log your sleep quality in your daily check-in to see trends and get personalized insights.',
        emoji: '🌙',
        category: 'tip',
      ));
      return insights;
    }

    // Celebrate good sleep
    if (score.score >= 80) {
      insights.add(const SleepInsight(
        title: 'Your sleep is excellent!',
        body: 'You\'re consistently reporting great sleep quality. Keep up your current routine — it\'s working well.',
        emoji: '🌟',
        category: 'celebration',
      ));
    }

    // Consistency warning
    if (score.consistency < 0.5 && score.weeklyData.length >= 3) {
      insights.add(const SleepInsight(
        title: 'Inconsistent sleep quality',
        body: 'Your sleep quality varies a lot day to day. Try setting a consistent bedtime and wake time — even on weekends.',
        emoji: '⚡',
        category: 'warning',
      ));
    }

    // Low quality
    if (score.avgQuality < 3 && score.weeklyData.length >= 3) {
      insights.add(const SleepInsight(
        title: 'Room for improvement',
        body: 'Your average sleep quality is below target. Try limiting screen time 1 hour before bed and keeping your room cool (65-68°F).',
        emoji: '💡',
        category: 'tip',
      ));
    }

    // Improving trend
    if (score.trend == SleepTrend.improving) {
      insights.add(const SleepInsight(
        title: 'Sleep is improving!',
        body: 'Your sleep quality has been trending upward this week. Whatever changes you\'ve made are paying off.',
        emoji: '📈',
        category: 'celebration',
      ));
    }

    // Declining trend
    if (score.trend == SleepTrend.declining) {
      insights.add(const SleepInsight(
        title: 'Sleep quality declining',
        body: 'Your sleep has dipped this week compared to last. Consider whether stress, caffeine, or a schedule change might be the cause.',
        emoji: '📉',
        category: 'warning',
      ));
    }

    // General tips
    if (insights.length < 2) {
      insights.add(const SleepInsight(
        title: '4-7-8 Breathing Technique',
        body: 'Inhale for 4 seconds, hold for 7, exhale for 8. This activates your parasympathetic nervous system and can help you fall asleep faster.',
        emoji: '🫁',
        category: 'tip',
      ));
    }

    return insights;
  }
}
