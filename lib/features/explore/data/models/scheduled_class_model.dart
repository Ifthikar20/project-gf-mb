import 'package:equatable/equatable.dart';

/// A real scheduled class from the backend.
class ScheduledClassModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String instructor;
  final String category;
  final String level;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String? thumbnailUrl;
  final String? videoId;
  final int signedUpCount;
  final bool hasReminder;
  final String? reminderId;

  const ScheduledClassModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.instructor,
    required this.category,
    required this.level,
    required this.scheduledAt,
    required this.durationMinutes,
    this.thumbnailUrl,
    this.videoId,
    this.signedUpCount = 0,
    this.hasReminder = false,
    this.reminderId,
  });

  /// Whether this class is in the morning (before 12pm)
  bool get isMorning => scheduledAt.hour < 12;

  /// Formatted time range: "06:00 - 06:45"
  String get timeRange {
    final start = scheduledAt;
    final end = start.add(Duration(minutes: durationMinutes));
    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${fmt(start)} - ${fmt(end)}';
  }

  factory ScheduledClassModel.fromJson(Map<String, dynamic> json) {
    return ScheduledClassModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      instructor: json['instructor'] as String? ?? 'Guest Teacher',
      category: json['category'] as String? ?? 'Wellness',
      level: json['level'] as String? ?? 'All Levels',
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 30,
      thumbnailUrl: json['thumbnail_url'] as String?,
      videoId: json['video_id'] as String?,
      signedUpCount: json['signed_up_count'] as int? ?? 0,
      hasReminder: json['has_reminder'] as bool? ?? false,
      reminderId: json['reminder_id'] as String?,
    );
  }

  /// Return a copy with updated reminder state
  ScheduledClassModel copyWithReminder({
    required bool hasReminder,
    String? reminderId,
  }) {
    return ScheduledClassModel(
      id: id,
      title: title,
      description: description,
      instructor: instructor,
      category: category,
      level: level,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      thumbnailUrl: thumbnailUrl,
      videoId: videoId,
      signedUpCount: signedUpCount,
      hasReminder: hasReminder,
      reminderId: reminderId,
    );
  }

  @override
  List<Object?> get props => [
        id, title, description, instructor, category, level,
        scheduledAt, durationMinutes, thumbnailUrl, videoId,
        signedUpCount, hasReminder, reminderId,
      ];
}
