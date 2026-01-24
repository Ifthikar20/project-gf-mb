import 'package:equatable/equatable.dart';

/// Expert result from unified search
class UnifiedExpertResult extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final String? specialization;
  final int? contentCount;

  const UnifiedExpertResult({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.specialization,
    this.contentCount,
  });

  factory UnifiedExpertResult.fromJson(Map<String, dynamic> json) {
    return UnifiedExpertResult(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? json['id']?.toString() ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'],
      specialization: json['specialization'] ?? json['bio'],
      contentCount: json['content_count'],
    );
  }

  @override
  List<Object?> get props => [id, name, slug, imageUrl, specialization, contentCount];
}

/// Series result from unified search
class UnifiedSeriesResult extends Equatable {
  final String id;
  final String title;
  final String slug;
  final String? thumbnailUrl;
  final String? expertName;
  final int? episodeCount;
  final String? category;

  const UnifiedSeriesResult({
    required this.id,
    required this.title,
    required this.slug,
    this.thumbnailUrl,
    this.expertName,
    this.episodeCount,
    this.category,
  });

  factory UnifiedSeriesResult.fromJson(Map<String, dynamic> json) {
    String? expertName;
    if (json['expert'] is Map) {
      expertName = json['expert']['name'];
    } else if (json['expert_name'] != null) {
      expertName = json['expert_name'];
    }

    String? category;
    if (json['category'] is Map) {
      category = json['category']['name'] ?? json['category']['slug'];
    } else if (json['category'] is String) {
      category = json['category'];
    }

    return UnifiedSeriesResult(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? json['id']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? json['image_url'],
      expertName: expertName,
      episodeCount: json['episode_count'],
      category: category,
    );
  }

  @override
  List<Object?> get props => [id, title, slug, thumbnailUrl, expertName, episodeCount, category];
}

/// Content result from unified search
class UnifiedContentResult extends Equatable {
  final String id;
  final String title;
  final String contentType; // 'video', 'audio', 'podcast'
  final String? thumbnailUrl;
  final String? expertName;
  final int? durationSeconds;
  final String? category;

  const UnifiedContentResult({
    required this.id,
    required this.title,
    required this.contentType,
    this.thumbnailUrl,
    this.expertName,
    this.durationSeconds,
    this.category,
  });

  factory UnifiedContentResult.fromJson(Map<String, dynamic> json) {
    String? expertName;
    if (json['expert'] is Map) {
      expertName = json['expert']['name'];
    } else if (json['expert_name'] != null) {
      expertName = json['expert_name'];
    }

    String? category;
    if (json['category'] is Map) {
      category = json['category']['name'] ?? json['category']['slug'];
    } else if (json['category'] is String) {
      category = json['category'];
    }

    return UnifiedContentResult(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      contentType: json['content_type']?.toString().toLowerCase() ?? 'video',
      thumbnailUrl: json['thumbnail_url'] ?? json['image_url'],
      expertName: expertName,
      durationSeconds: json['duration_seconds'],
      category: category,
    );
  }

  /// Format duration as "X min"
  String? get formattedDuration {
    if (durationSeconds == null) return null;
    final minutes = durationSeconds! ~/ 60;
    return '$minutes min';
  }

  @override
  List<Object?> get props => [id, title, contentType, thumbnailUrl, expertName, durationSeconds, category];
}

/// Unified search result containing grouped results
class UnifiedSearchResult extends Equatable {
  final String query;
  final List<UnifiedExpertResult> experts;
  final List<UnifiedSeriesResult> series;
  final List<UnifiedContentResult> content;
  final int totalResults;

  const UnifiedSearchResult({
    required this.query,
    required this.experts,
    required this.series,
    required this.content,
    required this.totalResults,
  });

  factory UnifiedSearchResult.fromJson(Map<String, dynamic> json) {
    final expertsJson = json['experts'] as List<dynamic>? ?? [];
    final seriesJson = json['series'] as List<dynamic>? ?? [];
    final contentJson = json['content'] as List<dynamic>? ?? [];

    return UnifiedSearchResult(
      query: json['query'] ?? '',
      experts: expertsJson.map((e) => UnifiedExpertResult.fromJson(e)).toList(),
      series: seriesJson.map((s) => UnifiedSeriesResult.fromJson(s)).toList(),
      content: contentJson.map((c) => UnifiedContentResult.fromJson(c)).toList(),
      totalResults: json['total_results'] ?? 0,
    );
  }

  /// Check if there are any results
  bool get isEmpty => experts.isEmpty && series.isEmpty && content.isEmpty;

  bool get hasExperts => experts.isNotEmpty;
  bool get hasSeries => series.isNotEmpty;
  bool get hasContent => content.isNotEmpty;

  @override
  List<Object?> get props => [query, experts, series, content, totalResults];
}

/// Search suggestion for autocomplete
class SearchSuggestion extends Equatable {
  final String text;
  final String type; // 'query', 'expert', 'series', 'content'
  final String? id;

  const SearchSuggestion({
    required this.text,
    required this.type,
    this.id,
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      text: json['text'] ?? json['suggestion'] ?? '',
      type: json['type'] ?? 'query',
      id: json['id']?.toString(),
    );
  }

  @override
  List<Object?> get props => [text, type, id];
}
