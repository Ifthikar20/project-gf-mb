/// User's enrollment in a coach-led program.
/// Tracks progress through the schedule and completion state.
import 'program_model.dart';

class EnrollmentProgress {
  final int totalDays;
  final int completedDays;
  final int percent;

  const EnrollmentProgress({
    required this.totalDays,
    required this.completedDays,
    required this.percent,
  });

  factory EnrollmentProgress.fromJson(Map<String, dynamic> json) =>
      EnrollmentProgress(
        totalDays: json['total_days'] ?? 0,
        completedDays: json['completed_days'] ?? 0,
        percent: json['percent'] ?? 0,
      );
}

class Enrollment {
  final String id;
  final String programId;
  final String programTitle;
  final String? programCoverImageUrl;
  final ProgramCoach coach;
  final int durationWeeks;
  final String status; // active, completed, paused, cancelled
  final String enrolledAt;
  final String? startDate;
  final String? completedAt;
  final EnrollmentProgress progress;
  final List<ProgramScheduleDay> schedule;
  final List<ProgramContentItem> content;
  final String? coachMessageForYou; // personalized notes

  const Enrollment({
    required this.id,
    required this.programId,
    required this.programTitle,
    this.programCoverImageUrl,
    required this.coach,
    required this.durationWeeks,
    required this.status,
    required this.enrolledAt,
    this.startDate,
    this.completedAt,
    required this.progress,
    this.schedule = const [],
    this.content = const [],
    this.coachMessageForYou,
  });

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isPaused => status == 'paused';

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'paused':
        return 'Paused';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Schedule days grouped by week number (sorted).
  Map<int, List<ProgramScheduleDay>> get scheduleByWeek {
    final map = <int, List<ProgramScheduleDay>>{};
    for (final day in schedule) {
      map.putIfAbsent(day.weekNumber, () => []).add(day);
    }
    // Sort days within each week by day_of_week
    for (final week in map.values) {
      week.sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
    }
    return map;
  }

  /// Today's scheduled workout (if any).
  ProgramScheduleDay? get todaysWorkout {
    if (startDate == null || schedule.isEmpty) return null;
    final start = DateTime.tryParse(startDate!);
    if (start == null) return null;

    final today = DateTime.now();
    final daysSinceStart = today.difference(start).inDays;
    if (daysSinceStart < 0) return null;

    // Calculate which week and day of week we're on
    final currentWeek = (daysSinceStart ~/ 7) + 1;
    final currentDayOfWeek = today.weekday; // 1=Mon … 7=Sun

    return schedule.cast<ProgramScheduleDay?>().firstWhere(
          (d) =>
              d!.weekNumber == currentWeek &&
              d.dayOfWeek == currentDayOfWeek,
          orElse: () => null,
        );
  }

  factory Enrollment.fromJson(Map<String, dynamic> json) => Enrollment(
        id: json['id'] ?? '',
        programId: json['program_id'] ?? json['program']?['id'] ?? '',
        programTitle:
            json['program_title'] ?? json['program']?['title'] ?? '',
        programCoverImageUrl: json['program_cover_image_url'] ??
            json['program']?['cover_image_url'],
        coach: ProgramCoach.fromJson(json['coach'] ?? json['program']?['coach'] ?? {}),
        durationWeeks: json['duration_weeks'] ??
            json['program']?['duration_weeks'] ??
            1,
        status: json['status'] ?? 'active',
        enrolledAt: json['enrolled_at'] ?? '',
        startDate: json['start_date'],
        completedAt: json['completed_at'],
        progress:
            EnrollmentProgress.fromJson(json['progress'] ?? {}),
        schedule: (json['schedule'] as List?)
                ?.map((d) => ProgramScheduleDay.fromJson(d))
                .toList() ??
            [],
        content: (json['content'] as List?)
                ?.map((c) => ProgramContentItem.fromJson(c))
                .toList() ??
            [],
        coachMessageForYou: json['coach_message'],
      );
}
