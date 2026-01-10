import 'package:equatable/equatable.dart';

/// Type of search result
enum SearchResultType {
  speaker,
  video,
  audio,
  podcast,
}

/// Unified search result model representing speakers or content items
class SearchResult extends Equatable {
  final String id;
  final SearchResultType type;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? authorName;
  final int? durationInSeconds;
  final String? category;

  const SearchResult({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.authorName,
    this.durationInSeconds,
    this.category,
  });

  /// Format duration as "X min"
  String? get formattedDuration {
    if (durationInSeconds == null) return null;
    final minutes = durationInSeconds! ~/ 60;
    return '$minutes min';
  }

  /// Get display type label
  String get typeLabel {
    switch (type) {
      case SearchResultType.speaker:
        return 'Narrator';
      case SearchResultType.video:
        return 'Video';
      case SearchResultType.audio:
        return 'Audio';
      case SearchResultType.podcast:
        return 'Podcast';
    }
  }

  /// Check if this is a speaker result
  bool get isSpeaker => type == SearchResultType.speaker;

  /// Create from video JSON
  factory SearchResult.fromVideoJson(Map<String, dynamic> json) {
    String? instructor;
    if (json['expert'] is Map) {
      instructor = json['expert']['name'];
    } else if (json['expert_name'] != null) {
      instructor = json['expert_name'];
    } else if (json['instructor'] != null) {
      instructor = json['instructor'];
    }

    String categorySlug = 'uncategorized';
    if (json['category'] is Map) {
      categorySlug = json['category']['slug'] ?? json['category']['name']?.toString().toLowerCase() ?? 'uncategorized';
    } else if (json['category_name'] != null) {
      categorySlug = json['category_name'].toString().toLowerCase();
    } else if (json['category'] is String) {
      categorySlug = json['category'];
    }

    return SearchResult(
      id: json['id']?.toString() ?? '',
      type: SearchResultType.video,
      title: json['title'] ?? '',
      subtitle: categorySlug,
      imageUrl: json['thumbnail_url'] ?? json['image_url'] ?? '',
      authorName: instructor,
      durationInSeconds: json['duration_seconds'],
      category: categorySlug,
    );
  }

  /// Create from audio JSON
  factory SearchResult.fromAudioJson(Map<String, dynamic> json) {
    String? expertName;
    if (json['expert'] is Map) {
      expertName = json['expert']['name'];
    } else if (json['expert_name'] != null) {
      expertName = json['expert_name'];
    }

    String categorySlug = 'uncategorized';
    if (json['category'] is Map) {
      categorySlug = json['category']['slug'] ?? json['category']['name']?.toString().toLowerCase() ?? 'uncategorized';
    } else if (json['category_name'] != null) {
      categorySlug = json['category_name'].toString().toLowerCase();
    } else if (json['category'] is String) {
      categorySlug = json['category'];
    }

    final contentType = json['content_type']?.toString().toLowerCase() ?? 'audio';
    
    return SearchResult(
      id: json['id']?.toString() ?? '',
      type: contentType == 'podcast' ? SearchResultType.podcast : SearchResultType.audio,
      title: json['title'] ?? '',
      subtitle: categorySlug,
      imageUrl: json['thumbnail_url'] ?? json['image_url'] ?? '',
      authorName: expertName,
      durationInSeconds: json['duration_seconds'],
      category: categorySlug,
    );
  }

  /// Create from speaker/expert JSON
  factory SearchResult.fromSpeakerJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id']?.toString() ?? '',
      type: SearchResultType.speaker,
      title: json['name'] ?? '',
      subtitle: json['specialization'] ?? json['bio'] ?? 'Narrator',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      authorName: null,
      durationInSeconds: null,
      category: null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        subtitle,
        imageUrl,
        authorName,
        durationInSeconds,
        category,
      ];
}
