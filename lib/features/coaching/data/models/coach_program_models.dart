import 'package:equatable/equatable.dart';
import '../../../../core/services/coaching_service.dart';

// ─────────────────────────────────────────────────────────
// Coach Program — A structured training program by a coach
// ─────────────────────────────────────────────────────────

class CoachProgram extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? coverImageUrl;
  final CoachExpert coach;
  final int durationWeeks;
  final String level; // beginner, intermediate, advanced
  final String category; // Yoga, HIIT, Mindfulness, etc.
  final int contentCount;
  final int enrolledCount;
  final bool isEnrolled;
  final String price; // "0.00" for free, or a real price
  final List<CalendarWeek> trainingCalendar;
  final List<ProgramContentItem> contentItems;
  final DateTime? createdAt;

  const CoachProgram({
    required this.id,
    required this.title,
    required this.description,
    this.coverImageUrl,
    required this.coach,
    required this.durationWeeks,
    this.level = 'All Levels',
    this.category = 'Wellness',
    this.contentCount = 0,
    this.enrolledCount = 0,
    this.isEnrolled = false,
    this.price = '0.00',
    this.trainingCalendar = const [],
    this.contentItems = const [],
    this.createdAt,
  });

  factory CoachProgram.fromJson(Map<String, dynamic> json) {
    return CoachProgram(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      coverImageUrl: json['cover_image_url'],
      coach: CoachExpert.fromJson(json['coach'] ?? {}),
      durationWeeks: json['duration_weeks'] ?? 4,
      level: json['level'] ?? 'All Levels',
      category: json['category'] ?? 'Wellness',
      contentCount: json['content_count'] ?? 0,
      enrolledCount: json['enrolled_count'] ?? 0,
      isEnrolled: json['is_enrolled'] ?? false,
      price: json['price'] ?? '0.00',
      trainingCalendar: (json['training_calendar'] as List?)
              ?.map((w) => CalendarWeek.fromJson(w))
              .toList() ??
          [],
      contentItems: (json['content_items'] as List?)
              ?.map((c) => ProgramContentItem.fromJson(c))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  bool get isFree => price == '0.00' || price == '0' || price.isEmpty;

  String get durationLabel {
    if (durationWeeks == 1) return '1 Week';
    if (durationWeeks <= 4) return '$durationWeeks Weeks';
    final months = durationWeeks ~/ 4;
    final remaining = durationWeeks % 4;
    if (remaining == 0) {
      return months == 1 ? '1 Month' : '$months Months';
    }
    return '$durationWeeks Weeks';
  }

  int get totalDays =>
      trainingCalendar.fold(0, (sum, w) => sum + w.days.length);

  int get completedDays => trainingCalendar.fold(
      0, (sum, w) => sum + w.days.where((d) => d.isCompleted).length);

  double get progressPercent =>
      totalDays > 0 ? completedDays / totalDays : 0.0;

  /// Find the next incomplete day across all weeks
  CalendarDay? get nextIncompleteDay {
    for (final week in trainingCalendar) {
      for (final day in week.days) {
        if (!day.isCompleted && !day.isRestDay) return day;
      }
    }
    return null;
  }

  CoachProgram copyWith({bool? isEnrolled, int? enrolledCount}) {
    return CoachProgram(
      id: id,
      title: title,
      description: description,
      coverImageUrl: coverImageUrl,
      coach: coach,
      durationWeeks: durationWeeks,
      level: level,
      category: category,
      contentCount: contentCount,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      price: price,
      trainingCalendar: trainingCalendar,
      contentItems: contentItems,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        durationWeeks,
        isEnrolled,
        enrolledCount,
        trainingCalendar,
      ];
}

// ─────────────────────────────────────────────────────────
// Calendar Week — One week of a training program
// ─────────────────────────────────────────────────────────

class CalendarWeek extends Equatable {
  final int weekNumber;
  final String title;
  final String? description;
  final List<CalendarDay> days;

  const CalendarWeek({
    required this.weekNumber,
    required this.title,
    this.description,
    this.days = const [],
  });

  factory CalendarWeek.fromJson(Map<String, dynamic> json) {
    return CalendarWeek(
      weekNumber: json['week_number'] ?? 1,
      title: json['title'] ?? 'Week ${json['week_number'] ?? 1}',
      description: json['description'],
      days: (json['days'] as List?)
              ?.map((d) => CalendarDay.fromJson(d))
              .toList() ??
          [],
    );
  }

  bool get isComplete => days.every((d) => d.isCompleted || d.isRestDay);

  int get completedCount => days.where((d) => d.isCompleted).length;
  int get activeDayCount => days.where((d) => !d.isRestDay).length;

  @override
  List<Object?> get props => [weekNumber, title, days];
}

// ─────────────────────────────────────────────────────────
// Calendar Day — A single day's training plan
// ─────────────────────────────────────────────────────────

class CalendarDay extends Equatable {
  final String id;
  final int dayNumber;
  final String dayOfWeek; // Mon, Tue, Wed, etc.
  final String title;
  final String? contentId;
  final String contentType; // video, audio
  final int durationMinutes;
  final String? notes; // coach's notes for this day
  final bool isRestDay;
  final bool isCompleted;
  final String? thumbnailUrl;

  const CalendarDay({
    required this.id,
    required this.dayNumber,
    this.dayOfWeek = '',
    required this.title,
    this.contentId,
    this.contentType = 'video',
    this.durationMinutes = 30,
    this.notes,
    this.isRestDay = false,
    this.isCompleted = false,
    this.thumbnailUrl,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      id: json['id'] ?? '',
      dayNumber: json['day_number'] ?? 1,
      dayOfWeek: json['day_of_week'] ?? '',
      title: json['title'] ?? 'Training',
      contentId: json['content_id'],
      contentType: json['content_type'] ?? 'video',
      durationMinutes: json['duration_minutes'] ?? 30,
      notes: json['notes'],
      isRestDay: json['is_rest_day'] ?? false,
      isCompleted: json['is_completed'] ?? false,
      thumbnailUrl: json['thumbnail_url'],
    );
  }

  CalendarDay copyWith({bool? isCompleted}) {
    return CalendarDay(
      id: id,
      dayNumber: dayNumber,
      dayOfWeek: dayOfWeek,
      title: title,
      contentId: contentId,
      contentType: contentType,
      durationMinutes: durationMinutes,
      notes: notes,
      isRestDay: isRestDay,
      isCompleted: isCompleted ?? this.isCompleted,
      thumbnailUrl: thumbnailUrl,
    );
  }

  @override
  List<Object?> get props => [id, dayNumber, title, isCompleted, isRestDay];
}

// ─────────────────────────────────────────────────────────
// Program Content Item (reused from marketplace concept)
// ─────────────────────────────────────────────────────────

class ProgramContentItem extends Equatable {
  final String id;
  final String title;
  final String contentType; // video, audio
  final String? thumbnailUrl;
  final int? durationSeconds;
  final int sortOrder;

  const ProgramContentItem({
    required this.id,
    required this.title,
    this.contentType = 'video',
    this.thumbnailUrl,
    this.durationSeconds,
    this.sortOrder = 0,
  });

  factory ProgramContentItem.fromJson(Map<String, dynamic> json) {
    return ProgramContentItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      contentType: json['content_type'] ?? 'video',
      thumbnailUrl: json['thumbnail_url'],
      durationSeconds: json['duration_seconds'],
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  String get formattedDuration {
    if (durationSeconds == null) return '';
    final min = durationSeconds! ~/ 60;
    return '$min min';
  }

  @override
  List<Object?> get props => [id, title, contentType, sortOrder];
}
