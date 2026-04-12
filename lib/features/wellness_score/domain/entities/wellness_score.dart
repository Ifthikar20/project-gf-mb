/// Wellness Score entity — computed locally from Hive + HealthKit data.
///
/// A daily composite score (0-100) showing overall health status.
/// Composed of 6 sub-scores, each weighted differently.
class WellnessScore {
  final int totalScore;
  final SubScore sleep;
  final SubScore activity;
  final SubScore nutrition;
  final SubScore workout;
  final SubScore mood;
  final SubScore streak;
  final DateTime date;
  final ScoreTrend trend;

  const WellnessScore({
    required this.totalScore,
    required this.sleep,
    required this.activity,
    required this.nutrition,
    required this.workout,
    required this.mood,
    required this.streak,
    required this.date,
    this.trend = ScoreTrend.flat,
  });

  /// Score quality label
  String get label {
    if (totalScore >= 85) return 'Excellent';
    if (totalScore >= 70) return 'Good';
    if (totalScore >= 50) return 'Fair';
    if (totalScore >= 30) return 'Needs Attention';
    return 'Low';
  }

  /// Score quality emoji
  String get emoji {
    if (totalScore >= 85) return '🌟';
    if (totalScore >= 70) return '💪';
    if (totalScore >= 50) return '👍';
    if (totalScore >= 30) return '⚡';
    return '🔋';
  }

  /// All sub-scores as a list (for iteration in UI)
  List<SubScore> get allSubScores => [sleep, activity, nutrition, workout, mood, streak];

  /// Lowest scoring area — good for AI nudges
  SubScore get weakestArea {
    return allSubScores.reduce((a, b) => a.score < b.score ? a : b);
  }

  Map<String, dynamic> toJson() => {
    'total_score': totalScore,
    'sleep': sleep.score,
    'activity': activity.score,
    'nutrition': nutrition.score,
    'workout': workout.score,
    'mood': mood.score,
    'streak': streak.score,
    'date': date.toIso8601String(),
  };

  factory WellnessScore.fromJson(Map<String, dynamic> json) {
    return WellnessScore(
      totalScore: json['total_score'] ?? 0,
      sleep: SubScore(category: ScoreCategory.sleep, score: json['sleep'] ?? 0),
      activity: SubScore(category: ScoreCategory.activity, score: json['activity'] ?? 0),
      nutrition: SubScore(category: ScoreCategory.nutrition, score: json['nutrition'] ?? 0),
      workout: SubScore(category: ScoreCategory.workout, score: json['workout'] ?? 0),
      mood: SubScore(category: ScoreCategory.mood, score: json['mood'] ?? 0),
      streak: SubScore(category: ScoreCategory.streak, score: json['streak'] ?? 0),
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    );
  }

  /// Empty score for when no data is available
  factory WellnessScore.empty() => WellnessScore(
    totalScore: 0,
    sleep: SubScore(category: ScoreCategory.sleep, score: 0),
    activity: SubScore(category: ScoreCategory.activity, score: 0),
    nutrition: SubScore(category: ScoreCategory.nutrition, score: 0),
    workout: SubScore(category: ScoreCategory.workout, score: 0),
    mood: SubScore(category: ScoreCategory.mood, score: 0),
    streak: SubScore(category: ScoreCategory.streak, score: 0),
    date: DateTime.now(),
  );
}

/// Individual category sub-score
class SubScore {
  final ScoreCategory category;
  final int score; // 0-100

  const SubScore({
    required this.category,
    required this.score,
  });
}

/// Score categories with display metadata
enum ScoreCategory {
  sleep,
  activity,
  nutrition,
  workout,
  mood,
  streak;

  String get label {
    switch (this) {
      case ScoreCategory.sleep: return 'Sleep';
      case ScoreCategory.activity: return 'Activity';
      case ScoreCategory.nutrition: return 'Nutrition';
      case ScoreCategory.workout: return 'Workout';
      case ScoreCategory.mood: return 'Mood';
      case ScoreCategory.streak: return 'Streak';
    }
  }

  String get emoji {
    switch (this) {
      case ScoreCategory.sleep: return '😴';
      case ScoreCategory.activity: return '🏃';
      case ScoreCategory.nutrition: return '🍎';
      case ScoreCategory.workout: return '🏋️';
      case ScoreCategory.mood: return '😊';
      case ScoreCategory.streak: return '🔥';
    }
  }

  /// Weight used in composite score calculation
  double get weight {
    switch (this) {
      case ScoreCategory.sleep: return 0.30;
      case ScoreCategory.activity: return 0.20;
      case ScoreCategory.nutrition: return 0.15;
      case ScoreCategory.workout: return 0.15;
      case ScoreCategory.mood: return 0.10;
      case ScoreCategory.streak: return 0.10;
    }
  }
}

/// Score trend direction
enum ScoreTrend {
  up,
  down,
  flat;

  String get emoji {
    switch (this) {
      case ScoreTrend.up: return '↑';
      case ScoreTrend.down: return '↓';
      case ScoreTrend.flat: return '→';
    }
  }
}

/// Daily score snapshot for trend charts
class DailyScoreSnapshot {
  final DateTime date;
  final int score;

  const DailyScoreSnapshot({required this.date, required this.score});

  factory DailyScoreSnapshot.fromJson(Map<String, dynamic> json) {
    return DailyScoreSnapshot(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      score: json['score'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'score': score,
  };
}
