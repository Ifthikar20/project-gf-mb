/// Mood summary data model.
///
/// Aggregated mood data from the backend including weekly trends,
/// monthly distribution, and streak information.
class MoodSummary {
  final List<DailyMood> weeklyMoods;
  final Map<String, int> monthlyDistribution;
  final JournalStreak streak;

  const MoodSummary({
    required this.weeklyMoods,
    required this.monthlyDistribution,
    required this.streak,
  });

  factory MoodSummary.fromJson(Map<String, dynamic> json) {
    return MoodSummary(
      weeklyMoods: (json['weekly_moods'] as List? ?? [])
          .map((e) => DailyMood.fromJson(e))
          .toList(),
      monthlyDistribution: Map<String, int>.from(
        json['monthly_distribution'] ?? {},
      ),
      streak: JournalStreak.fromJson(json['streak'] ?? {}),
    );
  }

  /// Most frequent mood this month
  String? get dominantMood {
    if (monthlyDistribution.isEmpty) return null;
    return monthlyDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}

/// A single day's mood data for charts/heatmap.
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
      date: json['date'] ?? '',
      mood: json['mood'] ?? '',
      moodIntensity: json['mood_intensity'] ?? 3,
    );
  }
}

/// Journal streak data.
class JournalStreak {
  final int currentStreak;
  final int longestStreak;
  final String? lastEntryDate;
  final int totalEntries;

  const JournalStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastEntryDate,
    required this.totalEntries,
  });

  factory JournalStreak.fromJson(Map<String, dynamic> json) {
    return JournalStreak(
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      lastEntryDate: json['last_entry_date'],
      totalEntries: json['total_entries'] ?? 0,
    );
  }
}

/// Calendar heatmap data for a month.
class CalendarMonth {
  final String month;
  final List<DailyMood> days;

  const CalendarMonth({
    required this.month,
    required this.days,
  });

  factory CalendarMonth.fromJson(Map<String, dynamic> json) {
    return CalendarMonth(
      month: json['month'] ?? '',
      days: (json['days'] as List? ?? [])
          .map((e) => DailyMood.fromJson(e))
          .toList(),
    );
  }

  /// Get mood for a specific day (1-indexed)
  DailyMood? getMoodForDay(int day) {
    final dayStr = day.toString().padLeft(2, '0');
    final dateStr = '$month-$dayStr';
    try {
      return days.firstWhere((d) => d.date == dateStr);
    } catch (_) {
      return null;
    }
  }
}
