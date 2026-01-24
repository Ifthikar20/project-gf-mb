import 'package:equatable/equatable.dart';

/// Statistics for an expert's content performance
class ExpertStats extends Equatable {
  final int totalViews;
  final int videoCount;
  final int seriesCount;
  final int audioCount;
  final int totalContentCount;

  const ExpertStats({
    this.totalViews = 0,
    this.videoCount = 0,
    this.seriesCount = 0,
    this.audioCount = 0,
    this.totalContentCount = 0,
  });

  factory ExpertStats.fromJson(Map<String, dynamic> json) {
    return ExpertStats(
      totalViews: json['total_views'] ?? json['views'] ?? 0,
      videoCount: json['video_count'] ?? json['videos'] ?? 0,
      seriesCount: json['series_count'] ?? json['series'] ?? 0,
      audioCount: json['audio_count'] ?? json['audio'] ?? 0,
      totalContentCount: json['total_content_count'] ?? json['total'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [totalViews, videoCount, seriesCount, audioCount, totalContentCount];
}

/// A content item associated with an expert
class ExpertContentItem extends Equatable {
  final String slug;
  final String? accessTier;
  final bool isLocked;
  final String? lockMessage;

  const ExpertContentItem({
    required this.id,
    required this.title,
    required this.contentType,
    required this.slug,
    this.thumbnailUrl,
    this.durationSeconds,
    this.category,
    this.episodeNumber,
    this.seriesId,
    this.viewCount,
    this.accessTier,
    this.isLocked = false,
    this.lockMessage,
  });

  factory ExpertContentItem.fromJson(Map<String, dynamic> json) {
    String? category;
    if (json['category'] is Map) {
      category = json['category']['name'] ?? json['category']['slug'];
    } else if (json['category'] is String) {
      category = json['category'];
    }

    return ExpertContentItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      contentType: json['content_type']?.toString().toLowerCase() ?? 'video',
      thumbnailUrl: json['thumbnail_url'] ?? json['image_url'],
      durationSeconds: json['duration_seconds'],
      category: category,
      episodeNumber: json['episode_number'],
      seriesId: json['series_id']?.toString(),
      viewCount: json['view_count'] ?? json['views'],
      accessTier: json['access_tier'],
      isLocked: json['is_locked'] ?? false,
      lockMessage: json['lock_message'],
    );
  }

  /// Format duration as "X min"
  String? get formattedDuration {
    if (durationSeconds == null) return null;
    final minutes = durationSeconds! ~/ 60;
    return '$minutes min';
  }

  @override
  List<Object?> get props => [
    id, title, slug, contentType, thumbnailUrl, durationSeconds, 
    category, episodeNumber, seriesId, viewCount, accessTier, isLocked,
  ];
}

/// A series associated with an expert
class ExpertSeries extends Equatable {
  final int totalEpisodes;
  final String? accessTier;
  final bool isLocked;
  final String? lockMessage;

  const ExpertSeries({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    this.episodeCount = 0,
    this.totalEpisodes = 0,
    this.category,
    this.description,
    this.accessTier,
    this.isLocked = false,
    this.lockMessage,
  });

  factory ExpertSeries.fromJson(Map<String, dynamic> json) {
    String? category;
    if (json['category'] is Map) {
      category = json['category']['name'] ?? json['category']['slug'];
    } else if (json['category'] is String) {
      category = json['category'];
    }

    return ExpertSeries(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? json['image_url'],
      episodeCount: json['episode_count'] ?? json['total_episodes'] ?? 0,
      totalEpisodes: json['total_episodes'] ?? json['episode_count'] ?? 0,
      category: category,
      description: json['description'],
      accessTier: json['access_tier'],
      isLocked: json['is_locked'] ?? false,
      lockMessage: json['lock_message'],
    );
  }

  @override
  List<Object?> get props => [id, title, thumbnailUrl, episodeCount, category, description];
}

/// Full expert entity with all profile details and content
class ExpertEntity extends Equatable {
  final String id;
  final String slug;
  final String name;
  final String? title;
  final String? bio;
  final String? shortBio;
  final String? imageUrl;
  final String? backgroundImageUrl;
  final List<String> specialties;
  final String? linkedinUrl;
  final String? instagramUrl;
  final String? websiteUrl;
  final int? yearsExperience;
  final String? specialization;
  final String? primaryCategory;
  final String? shareUrl;
  final String? shareText;
  final bool verified;
  final bool featured;
  final List<ExpertContentItem> videos;
  final List<ExpertSeries> series;
  final List<ExpertContentItem> audioSessions;
  final ExpertStats stats;

  const ExpertEntity({
    required this.id,
    required this.slug,
    required this.name,
    this.title,
    this.bio,
    this.shortBio,
    this.imageUrl,
    this.backgroundImageUrl,
    this.specialties = const [],
    this.linkedinUrl,
    this.instagramUrl,
    this.websiteUrl,
    this.yearsExperience,
    this.specialization,
    this.primaryCategory,
    this.shareUrl,
    this.shareText,
    this.verified = false,
    this.featured = false,
    this.videos = const [],
    this.series = const [],
    this.audioSessions = const [],
    this.stats = const ExpertStats(),
  });

  factory ExpertEntity.fromJson(Map<String, dynamic> json) {
    final videosJson = json['videos'] as List<dynamic>? ?? [];
    final seriesJson = json['series'] as List<dynamic>? ?? [];
    final audioJson = json['audio_sessions'] ?? json['audio'] as List<dynamic>? ?? [];
    final statsJson = json['stats'] as Map<String, dynamic>? ?? {};

    // specialties can be a list of strings
    List<String> specialties = [];
    if (json['specialties'] is List) {
      specialties = (json['specialties'] as List).map((e) => e.toString()).toList();
    }

    return ExpertEntity(
      id: json['id']?.toString() ?? '',
      slug: json['slug'] ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      title: json['title'],
      bio: json['bio'],
      shortBio: json['short_bio'],
      imageUrl: json['avatar_url'] ?? json['image_url'] ?? json['imageUrl'],
      backgroundImageUrl: json['background_image_url'] ?? json['backgroundImageUrl'],
      specialties: specialties,
      linkedinUrl: json['linkedin_url'] ?? json['linkedinUrl'],
      instagramUrl: json['instagram_url'] ?? json['instagramUrl'],
      websiteUrl: json['website_url'] ?? json['websiteUrl'],
      yearsExperience: json['years_experience'],
      specialization: json['specialization'] ?? (specialties.isNotEmpty ? specialties.first : null),
      primaryCategory: json['primary_category'],
      shareUrl: json['share_url'],
      shareText: json['share_text'],
      verified: json['verified'] ?? false,
      featured: json['featured'] ?? false,
      videos: videosJson.map((v) => ExpertContentItem.fromJson(v)).toList(),
      series: seriesJson.map((s) => ExpertSeries.fromJson(s)).toList(),
      audioSessions: (audioJson is List) 
          ? audioJson.map((a) => ExpertContentItem.fromJson(a)).toList() 
          : [],
      stats: ExpertStats.fromJson(statsJson),
    );
  }

  /// Check if expert has social links
  bool get hasSocialLinks => linkedinUrl != null || instagramUrl != null || websiteUrl != null;

  /// Check if expert has content
  bool get hasContent => videos.isNotEmpty || series.isNotEmpty || audioSessions.isNotEmpty;

  /// Total content count
  int get totalContentCount => videos.length + series.length + audioSessions.length;

  @override
  List<Object?> get props => [
    id, slug, name, title, bio, shortBio, imageUrl, backgroundImageUrl, specialties,
    linkedinUrl, instagramUrl, websiteUrl, yearsExperience, specialization, 
    primaryCategory, shareUrl, shareText, verified, featured,
    videos, series, audioSessions, stats,
  ];
}
