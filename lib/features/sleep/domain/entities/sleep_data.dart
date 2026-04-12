/// Sleep data entities — computed locally from Hive check-in data.
class SleepScore {
  final int score; // 0-100
  final String label;
  final List<DailySleepQuality> weeklyData;
  final double avgQuality; // 1.0-5.0
  final double consistency; // 0.0-1.0 (how consistent quality is)
  final SleepTrend trend;

  const SleepScore({
    required this.score,
    required this.label,
    required this.weeklyData,
    required this.avgQuality,
    required this.consistency,
    this.trend = SleepTrend.stable,
  });

  factory SleepScore.empty() => const SleepScore(
    score: 0,
    label: 'No Data',
    weeklyData: [],
    avgQuality: 0,
    consistency: 0,
  );

  bool get hasData => weeklyData.isNotEmpty;
}

/// Single day's sleep quality from check-in
class DailySleepQuality {
  final DateTime date;
  final int quality; // 1-5 from WellnessCheckInModel
  final String dayLabel; // "Mon", "Tue", etc.

  const DailySleepQuality({
    required this.date,
    required this.quality,
    required this.dayLabel,
  });
}

/// Sleep trend
enum SleepTrend {
  improving,
  declining,
  stable;

  String get label {
    switch (this) {
      case SleepTrend.improving: return 'Improving';
      case SleepTrend.declining: return 'Declining';
      case SleepTrend.stable: return 'Stable';
    }
  }

  String get emoji {
    switch (this) {
      case SleepTrend.improving: return '📈';
      case SleepTrend.declining: return '📉';
      case SleepTrend.stable: return '➡️';
    }
  }
}

/// Local sleep insight — pattern-based, no AI call needed
class SleepInsight {
  final String title;
  final String body;
  final String emoji;
  final String category; // tip, warning, celebration

  const SleepInsight({
    required this.title,
    required this.body,
    required this.emoji,
    required this.category,
  });
}
