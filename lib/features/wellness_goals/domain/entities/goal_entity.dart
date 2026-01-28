import 'package:equatable/equatable.dart';

/// Type of goal tracking mechanism
enum GoalType {
  manual,           // User manually updates progress
  videoCompletion,  // Auto-track video watches
  audioCompletion,  // Auto-track meditation/audio completions
  categoryExplore,  // Track unique categories viewed
  dailyStreak,      // Track consecutive days of activity
  weeklyUsage,      // Track days per week with activity
  watchTime,        // Track total minutes watched
}

/// Period for goal reset
enum GoalPeriod {
  daily,    // Resets every day
  weekly,   // Resets every week (Monday)
  monthly,  // Resets every month (1st)
  allTime,  // Never resets (for streaks)
}

class GoalEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final int targetValue;
  final int currentValue;
  final DateTime createdAt;
  final DateTime? targetDate;
  final bool isCompleted;
  
  // New fields for smart tracking
  final GoalType type;
  final GoalPeriod period;
  final DateTime periodStart;
  final Set<String> trackedIds;  // Content IDs already counted (prevents double counting)
  final int streakDays;          // Current streak count
  final DateTime? lastActivityDate;  // Last date activity was recorded
  final String? iconName;        // Icon name for display

  const GoalEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.targetValue,
    this.currentValue = 0,
    required this.createdAt,
    this.targetDate,
    this.isCompleted = false,
    this.type = GoalType.manual,
    this.period = GoalPeriod.allTime,
    DateTime? periodStart,
    this.trackedIds = const {},
    this.streakDays = 0,
    this.lastActivityDate,
    this.iconName,
  }) : periodStart = periodStart ?? createdAt;

  double get progress {
    if (targetValue == 0) return 0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  /// Check if this goal should auto-track
  bool get isAutoTracked => type != GoalType.manual;

  /// Check if the goal period has expired and needs reset
  bool needsPeriodReset(DateTime now) {
    if (period == GoalPeriod.allTime) return false;
    
    switch (period) {
      case GoalPeriod.daily:
        return !_isSameDay(periodStart, now);
      case GoalPeriod.weekly:
        final weekStart = _getWeekStart(now);
        return periodStart.isBefore(weekStart);
      case GoalPeriod.monthly:
        final monthStart = DateTime(now.year, now.month, 1);
        return periodStart.isBefore(monthStart);
      case GoalPeriod.allTime:
        return false;
    }
  }

  /// Reset the goal for a new period
  GoalEntity resetForNewPeriod(DateTime now) {
    DateTime newPeriodStart;
    switch (period) {
      case GoalPeriod.daily:
        newPeriodStart = DateTime(now.year, now.month, now.day);
        break;
      case GoalPeriod.weekly:
        newPeriodStart = _getWeekStart(now);
        break;
      case GoalPeriod.monthly:
        newPeriodStart = DateTime(now.year, now.month, 1);
        break;
      case GoalPeriod.allTime:
        newPeriodStart = periodStart;
        break;
    }
    
    return copyWith(
      currentValue: 0,
      isCompleted: false,
      periodStart: newPeriodStart,
      trackedIds: {},
    );
  }

  /// Check if streak is still valid (allows 1 day forgiveness)
  bool isStreakValid(DateTime now) {
    if (lastActivityDate == null) return true; // New goal
    
    final daysSinceLastActivity = now.difference(lastActivityDate!).inDays;
    // Allow today, yesterday, or 2 days ago (1-day forgiveness)
    return daysSinceLastActivity <= 2;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _getWeekStart(DateTime date) {
    // Get Monday of the current week
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  GoalEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? targetValue,
    int? currentValue,
    DateTime? createdAt,
    DateTime? targetDate,
    bool? isCompleted,
    GoalType? type,
    GoalPeriod? period,
    DateTime? periodStart,
    Set<String>? trackedIds,
    int? streakDays,
    DateTime? lastActivityDate,
    String? iconName,
  }) {
    return GoalEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      createdAt: createdAt ?? this.createdAt,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      type: type ?? this.type,
      period: period ?? this.period,
      periodStart: periodStart ?? this.periodStart,
      trackedIds: trackedIds ?? this.trackedIds,
      streakDays: streakDays ?? this.streakDays,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      iconName: iconName ?? this.iconName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        targetValue,
        currentValue,
        createdAt,
        targetDate,
        isCompleted,
        type,
        period,
        periodStart,
        trackedIds,
        streakDays,
        lastActivityDate,
        iconName,
      ];
}
