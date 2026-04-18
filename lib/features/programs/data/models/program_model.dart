/// Coach-led program model — combines Marketplace (browse/purchase)
/// and WorkoutPlan (schedule/progress) into one unified structure.

class ProgramCoach {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? title;
  final List<String> specialties;

  const ProgramCoach({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.title,
    this.specialties = const [],
  });

  factory ProgramCoach.fromJson(Map<String, dynamic> json) => ProgramCoach(
        id: json['id'] ?? '',
        name: json['name'] ?? 'Coach',
        avatarUrl: json['avatar_url'],
        title: json['title'],
        specialties: (json['specialties'] as List?)
                ?.map((s) => s.toString())
                .toList() ??
            [],
      );
}

class ProgramScheduleDay {
  final String id;
  final int weekNumber;
  final int dayOfWeek; // 1=Monday … 7=Sunday
  final String dayLabel; // "Week 1 - Monday"
  final String? contentId;
  final String? contentTitle;
  final String? contentThumbnailUrl;
  final int? contentDurationSeconds;
  final String? coachNotes;
  final bool isRestDay;
  final bool isCompleted;
  final String? completedAt;

  const ProgramScheduleDay({
    required this.id,
    required this.weekNumber,
    required this.dayOfWeek,
    required this.dayLabel,
    this.contentId,
    this.contentTitle,
    this.contentThumbnailUrl,
    this.contentDurationSeconds,
    this.coachNotes,
    this.isRestDay = false,
    this.isCompleted = false,
    this.completedAt,
  });

  int get contentDurationMinutes =>
      contentDurationSeconds != null ? (contentDurationSeconds! / 60).round() : 0;

  bool get hasContent => contentId != null && contentId!.isNotEmpty;

  factory ProgramScheduleDay.fromJson(Map<String, dynamic> json) =>
      ProgramScheduleDay(
        id: json['id'] ?? '',
        weekNumber: json['week_number'] ?? 1,
        dayOfWeek: json['day_of_week'] ?? 1,
        dayLabel: json['day_label'] ?? json['day_name'] ?? '',
        contentId: json['content_id'] ?? json['content']?['id'],
        contentTitle:
            json['content_title'] ?? json['content']?['title'],
        contentThumbnailUrl: json['content_thumbnail_url'] ??
            json['content']?['thumbnail_url'],
        contentDurationSeconds: json['content_duration_seconds'] ??
            json['content']?['duration_seconds'],
        coachNotes: json['coach_notes'],
        isRestDay: json['is_rest_day'] ?? false,
        isCompleted: json['is_completed'] ?? false,
        completedAt: json['completed_at'],
      );
}

class ProgramContentItem {
  final String id;
  final String title;
  final String contentType; // 'video', 'audio'
  final String? thumbnailUrl;
  final int? durationSeconds;
  final int sortOrder;

  const ProgramContentItem({
    required this.id,
    required this.title,
    required this.contentType,
    this.thumbnailUrl,
    this.durationSeconds,
    this.sortOrder = 0,
  });

  String get formattedDuration {
    if (durationSeconds == null) return '';
    final minutes = durationSeconds! ~/ 60;
    return '$minutes min';
  }

  factory ProgramContentItem.fromJson(Map<String, dynamic> json) =>
      ProgramContentItem(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        contentType: json['content_type'] ?? 'video',
        thumbnailUrl: json['thumbnail_url'],
        durationSeconds: json['duration_seconds'],
        sortOrder: json['sort_order'] ?? 0,
      );
}

class Program {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String? coverImageUrl;
  final String price; // "0.00" for free
  final ProgramCoach coach;
  final String? categoryName;
  final String? categoryId;
  final int durationWeeks;
  final String difficultyLevel; // beginner, intermediate, advanced
  final int contentCount;
  final int enrollmentCount;
  final bool isEnrolled;
  final bool isFree;
  final List<ProgramScheduleDay> schedulePreview; // first week only (for browse)
  final List<ProgramContentItem> contentPreview; // first 3 items (for browse)

  const Program({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    this.coverImageUrl,
    required this.price,
    required this.coach,
    this.categoryName,
    this.categoryId,
    required this.durationWeeks,
    this.difficultyLevel = 'beginner',
    required this.contentCount,
    required this.enrollmentCount,
    required this.isEnrolled,
    required this.isFree,
    this.schedulePreview = const [],
    this.contentPreview = const [],
  });

  String get durationLabel {
    if (durationWeeks == 1) return '1 Week';
    if (durationWeeks <= 4) return '$durationWeeks Weeks';
    final months = (durationWeeks / 4).round();
    return '$months Month${months > 1 ? 's' : ''}';
  }

  String get difficultyLabel {
    switch (difficultyLevel) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return difficultyLevel;
    }
  }

  String get priceLabel => isFree ? 'Free' : '\$$price';

  factory Program.fromJson(Map<String, dynamic> json) => Program(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        slug: json['slug'] ?? '',
        description: json['description'] ?? '',
        coverImageUrl: json['cover_image_url'],
        price: json['price'] ?? '0.00',
        coach: ProgramCoach.fromJson(json['coach'] ?? {}),
        categoryName: json['category_name'] ?? json['category']?['name'],
        categoryId: json['category_id'] ?? json['category']?['id'],
        durationWeeks: json['duration_weeks'] ?? 1,
        difficultyLevel: json['difficulty_level'] ?? 'beginner',
        contentCount: json['content_count'] ?? 0,
        enrollmentCount: json['enrollment_count'] ?? 0,
        isEnrolled: json['is_enrolled'] ?? false,
        isFree: json['is_free'] ?? (json['price'] == '0.00'),
        schedulePreview: (json['schedule_preview'] as List?)
                ?.map((d) => ProgramScheduleDay.fromJson(d))
                .toList() ??
            [],
        contentPreview: (json['content_preview'] as List?)
                ?.map((c) => ProgramContentItem.fromJson(c))
                .toList() ??
            [],
      );
}
