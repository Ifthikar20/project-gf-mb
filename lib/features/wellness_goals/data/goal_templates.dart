import 'package:flutter/material.dart';
import '../domain/entities/goal_entity.dart';

/// Template for creating pre-defined goals
class GoalTemplate {
  final String id;
  final IconData icon;
  final String title;
  final String description;
  final GoalType type;
  final GoalPeriod period;
  final int targetValue;
  final String category;
  final Color color;

  const GoalTemplate({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.type,
    required this.period,
    required this.targetValue,
    required this.category,
    required this.color,
  });

  /// Create a GoalEntity from this template
  GoalEntity toEntity() {
    final now = DateTime.now();
    return GoalEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      category: category,
      targetValue: targetValue,
      currentValue: 0,
      createdAt: now,
      type: type,
      period: period,
      periodStart: _getPeriodStart(now, period),
      iconName: icon.codePoint.toString(),
    );
  }

  DateTime _getPeriodStart(DateTime now, GoalPeriod period) {
    switch (period) {
      case GoalPeriod.daily:
        return DateTime(now.year, now.month, now.day);
      case GoalPeriod.weekly:
        final daysFromMonday = now.weekday - 1;
        return DateTime(now.year, now.month, now.day - daysFromMonday);
      case GoalPeriod.monthly:
        return DateTime(now.year, now.month, 1);
      case GoalPeriod.allTime:
        return now;
    }
  }
}

/// Pre-defined goal templates for users to choose from
class GoalTemplates {
  static List<GoalTemplate> get all => [
    // Content-Based Goals
    ...contentGoals,
    // Streak Goals
    ...streakGoals,
    // Exploration Goals
    ...explorationGoals,
    // Time Goals
    ...timeGoals,
  ];

  static List<GoalTemplate> get contentGoals => [
    GoalTemplate(
      id: 'watch_10_videos_week',
      icon: Icons.play_circle_filled,
      title: 'Watch 10 Videos',
      description: 'Complete 10 wellness videos this week',
      type: GoalType.videoCompletion,
      period: GoalPeriod.weekly,
      targetValue: 10,
      category: 'Wellness',
      color: const Color(0xFF7C3AED),
    ),
    GoalTemplate(
      id: 'watch_5_videos_week',
      icon: Icons.ondemand_video,
      title: 'Watch 5 Videos',
      description: 'Complete 5 wellness videos this week',
      type: GoalType.videoCompletion,
      period: GoalPeriod.weekly,
      targetValue: 5,
      category: 'Wellness',
      color: const Color(0xFF6366F1),
    ),
    GoalTemplate(
      id: 'meditation_master',
      icon: Icons.self_improvement,
      title: 'Meditation Master',
      description: 'Complete 7 meditations this month',
      type: GoalType.audioCompletion,
      period: GoalPeriod.monthly,
      targetValue: 7,
      category: 'Meditation',
      color: const Color(0xFF8B5CF6),
    ),
    GoalTemplate(
      id: 'daily_meditation',
      icon: Icons.spa,
      title: 'Daily Calm',
      description: 'Complete 1 meditation session today',
      type: GoalType.audioCompletion,
      period: GoalPeriod.daily,
      targetValue: 1,
      category: 'Meditation',
      color: const Color(0xFF10B981),
    ),
    GoalTemplate(
      id: 'weekend_wellness',
      icon: Icons.weekend,
      title: 'Weekend Wellness',
      description: 'Watch 3 videos this weekend',
      type: GoalType.videoCompletion,
      period: GoalPeriod.weekly,
      targetValue: 3,
      category: 'Wellness',
      color: const Color(0xFFF59E0B),
    ),
  ];

  static List<GoalTemplate> get streakGoals => [
    GoalTemplate(
      id: 'streak_7_days',
      icon: Icons.local_fire_department,
      title: '7-Day Streak',
      description: 'Meditate for 7 consecutive days',
      type: GoalType.dailyStreak,
      period: GoalPeriod.allTime,
      targetValue: 7,
      category: 'Mindfulness',
      color: const Color(0xFFEF4444),
    ),
    GoalTemplate(
      id: 'streak_14_days',
      icon: Icons.whatshot,
      title: '14-Day Streak',
      description: 'Meditate for 14 consecutive days',
      type: GoalType.dailyStreak,
      period: GoalPeriod.allTime,
      targetValue: 14,
      category: 'Mindfulness',
      color: const Color(0xFFF97316),
    ),
    GoalTemplate(
      id: 'streak_30_days',
      icon: Icons.emoji_events,
      title: '30-Day Challenge',
      description: 'Meditate for 30 consecutive days',
      type: GoalType.dailyStreak,
      period: GoalPeriod.allTime,
      targetValue: 30,
      category: 'Mindfulness',
      color: const Color(0xFFD946EF),
    ),
    GoalTemplate(
      id: 'weekly_5_days',
      icon: Icons.calendar_today,
      title: 'Weekly Warrior',
      description: 'Use the app 5 days this week',
      type: GoalType.weeklyUsage,
      period: GoalPeriod.weekly,
      targetValue: 5,
      category: 'Consistency',
      color: const Color(0xFF3B82F6),
    ),
  ];

  static List<GoalTemplate> get explorationGoals => [
    GoalTemplate(
      id: 'explorer_5',
      icon: Icons.explore,
      title: 'Explorer',
      description: 'Discover 5 new content categories',
      type: GoalType.categoryExplore,
      period: GoalPeriod.monthly,
      targetValue: 5,
      category: 'Discovery',
      color: const Color(0xFF06B6D4),
    ),
    GoalTemplate(
      id: 'explorer_10',
      icon: Icons.travel_explore,
      title: 'Master Explorer',
      description: 'Explore 10 different categories',
      type: GoalType.categoryExplore,
      period: GoalPeriod.allTime,
      targetValue: 10,
      category: 'Discovery',
      color: const Color(0xFF0EA5E9),
    ),
  ];

  static List<GoalTemplate> get timeGoals => [
    GoalTemplate(
      id: 'mindful_60_min',
      icon: Icons.timer,
      title: '60 Mindful Minutes',
      description: 'Spend 60 minutes on wellness content this week',
      type: GoalType.watchTime,
      period: GoalPeriod.weekly,
      targetValue: 60,
      category: 'Mindfulness',
      color: const Color(0xFF14B8A6),
    ),
    GoalTemplate(
      id: 'mindful_30_min',
      icon: Icons.hourglass_bottom,
      title: '30 Minutes of Calm',
      description: 'Spend 30 minutes meditating this week',
      type: GoalType.watchTime,
      period: GoalPeriod.weekly,
      targetValue: 30,
      category: 'Meditation',
      color: const Color(0xFF22C55E),
    ),
    GoalTemplate(
      id: 'daily_10_min',
      icon: Icons.access_time,
      title: 'Daily 10',
      description: 'Spend 10 minutes on wellness today',
      type: GoalType.watchTime,
      period: GoalPeriod.daily,
      targetValue: 10,
      category: 'Wellness',
      color: const Color(0xFF84CC16),
    ),
  ];

  /// Get template by ID
  static GoalTemplate? getById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get templates by category
  static List<GoalTemplate> getByCategory(String category) {
    return all.where((t) => t.category == category).toList();
  }

  /// Get popular/featured templates
  static List<GoalTemplate> get featured => [
    all.firstWhere((t) => t.id == 'streak_7_days'),
    all.firstWhere((t) => t.id == 'meditation_master'),
    all.firstWhere((t) => t.id == 'watch_5_videos_week'),
    all.firstWhere((t) => t.id == 'daily_10_min'),
  ];
}
