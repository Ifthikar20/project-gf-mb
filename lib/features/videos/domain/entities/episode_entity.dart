import 'package:equatable/equatable.dart';

/// Represents an episode within a series
class EpisodeEntity extends Equatable {
  final String id;
  final String title;
  final int episodeNumber;
  final int durationSeconds;
  final String thumbnailUrl;
  final String hlsPlaylistUrl;
  final String? description;
  final String accessTier;

  const EpisodeEntity({
    required this.id,
    required this.title,
    required this.episodeNumber,
    required this.durationSeconds,
    required this.thumbnailUrl,
    required this.hlsPlaylistUrl,
    this.description,
    this.accessTier = 'free',
  });

  /// Create from JSON response
  factory EpisodeEntity.fromJson(Map<String, dynamic> json) {
    return EpisodeEntity(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Episode ${json['episode_number'] ?? 1}',
      episodeNumber: json['episode_number'] ?? 1,
      durationSeconds: json['duration_seconds'] ?? 0,
      thumbnailUrl: json['thumbnail_url'] ?? '',
      hlsPlaylistUrl: json['hls_playlist_url'] ?? json['video_url'] ?? '',
      description: json['description'],
      accessTier: json['access_tier'] ?? 'free',
    );
  }

  /// Format duration for display (e.g., "5:30")
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  bool get isPremium => accessTier == 'premium';
  bool get isFree => accessTier == 'free';

  @override
  List<Object?> get props => [
        id,
        title,
        episodeNumber,
        durationSeconds,
        thumbnailUrl,
        hlsPlaylistUrl,
        description,
        accessTier,
      ];
}
