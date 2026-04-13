/// Mood summary data from `/api/journal/mood-summary/`.
///
/// Contains weekly mood trends, monthly distribution, and streak info.
class MoodSummary {
  final List<DailyMood> weeklyMoods;
  final Map<String, int> monthlyDistribution;
  final StreakData streak;

  const MoodSummary({
    this.weeklyMoods = const [],
    this.monthlyDistribution = const {},
    this.streak = const StreakData(),
  });

  factory MoodSummary.fromJson(Map<String, dynamic> json) {
    return MoodSummary(
      weeklyMoods: (json['weekly_moods'] as List<dynamic>?)
              ?.map((e) => DailyMood.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      monthlyDistribution:
          (json['monthly_distribution'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, v as int)) ??
              {},
      streak: json['streak'] != null
          ? StreakData.fromJson(json['streak'] as Map<String, dynamic>)
          : const StreakData(),
    );
  }
}

/// A single day's mood data point (used in charts and heatmaps).
class DailyMood {
  final String date;
  final String mood;
  final int moodIntensity;

  const DailyMood({
    required this.date,
    required this.mood,
    required this.moodIntensity,
  });

  factory DailyMood.fromJson(Map<String, dynamic> json) {
    return DailyMood(
      date: json['date'] as String? ?? '',
      mood: json['mood'] as String? ?? '',
      moodIntensity: json['mood_intensity'] as int? ?? 3,
    );
  }
}

/// Streak tracking data.
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final String? lastEntryDate;
  final int totalEntries;

  const StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastEntryDate,
    this.totalEntries = 0,
  });

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastEntryDate: json['last_entry_date'] as String?,
      totalEntries: json['total_entries'] as int? ?? 0,
    );
  }
}

/// Calendar heatmap data from `/api/journal/calendar/`.
class CalendarData {
  final String month;
  final List<DailyMood> days;

  const CalendarData({
    required this.month,
    this.days = const [],
  });

  factory CalendarData.fromJson(Map<String, dynamic> json) {
    return CalendarData(
      month: json['month'] as String? ?? '',
      days: (json['days'] as List<dynamic>?)
              ?.map((e) => DailyMood.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
