import 'package:equatable/equatable.dart';
import 'episode_entity.dart';

/// Represents a series with its metadata and episodes
class SeriesEntity extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final int episodeCount;
  final List<EpisodeEntity> episodes;
  final String contentType; // "video" or "audio"
  final bool showOnExplore;
  final bool showOnMeditate;
  final String? expertName;

  const SeriesEntity({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.episodeCount,
    required this.episodes,
    this.contentType = 'video',
    this.showOnExplore = false,
    this.showOnMeditate = false,
    this.expertName,
  });

  /// Create from CMS API JSON response
  factory SeriesEntity.fromJson(Map<String, dynamic> json) {
    // Handle both nested 'series' object and flat response
    final seriesData = json['series'] ?? json;
    final episodesList = json['episodes'] as List<dynamic>? ?? [];

    return SeriesEntity(
      id: seriesData['id'] ?? seriesData['uuid'] ?? '',
      title: seriesData['title'] ?? '',
      description: seriesData['description'],
      thumbnailUrl: seriesData['thumbnail_url'],
      episodeCount: seriesData['episode_count'] ?? episodesList.length,
      episodes: episodesList.map((e) => EpisodeEntity.fromJson(e)).toList(),
      contentType: seriesData['content_type'] ?? 'video',
      showOnExplore: seriesData['show_on_explore'] ?? false,
      showOnMeditate: seriesData['show_on_meditate'] ?? false,
      expertName: seriesData['expert_name'],
    );
  }

  bool get isVideoSeries => contentType == 'video';
  bool get isAudioSeries => contentType == 'audio';

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        thumbnailUrl,
        episodeCount,
        episodes,
        contentType,
        showOnExplore,
        showOnMeditate,
        expertName,
      ];
}

