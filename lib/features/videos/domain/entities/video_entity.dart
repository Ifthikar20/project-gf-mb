import 'package:equatable/equatable.dart';

class VideoEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String videoUrl;
  final int durationInSeconds;
  final String category;
  final String instructor;
  final String accessTier; // 'free', 'basic', or 'premium'
  final int viewCount; // View count from backend analytics
  final String? expertSlug; // Expert's slug for navigation to profile
  final String? expertAvatarUrl; // Expert's avatar for display
  
  // Series fields
  final bool isSeries;
  final String? seriesId;
  final int? episodeNumber;
  final int? episodeCount;

  const VideoEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.durationInSeconds,
    required this.category,
    required this.instructor,
    this.accessTier = 'free',
    this.viewCount = 0,
    this.expertSlug,
    this.expertAvatarUrl,
    this.isSeries = false,
    this.seriesId,
    this.episodeNumber,
    this.episodeCount,
  });

  String get formattedDuration {
    final minutes = durationInSeconds ~/ 60;
    final seconds = durationInSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
  
  /// Format view count for display (e.g., 1234 → "1.2k", 5678901 → "5.7M")
  String get formattedViews {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}k';
    }
    return viewCount.toString();
  }
  
  bool get isPremium => accessTier == 'premium';
  bool get isFree => accessTier == 'free';
  
  /// Check if this video belongs to a series
  bool get belongsToSeries => seriesId != null && seriesId!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        thumbnailUrl,
        videoUrl,
        durationInSeconds,
        category,
        instructor,
        accessTier,
        viewCount,
        expertSlug,
        expertAvatarUrl,
        isSeries,
        seriesId,
        episodeNumber,
        episodeCount,
      ];
}


