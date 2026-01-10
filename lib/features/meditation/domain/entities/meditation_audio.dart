import 'package:equatable/equatable.dart';

/// Meditation audio content entity
/// Matches backend API response from /content/browse?content_type=audio
class MeditationAudio extends Equatable {
  final String id;
  final String title;
  final String description;
  final int durationInSeconds;
  final String category;         // Category slug: 'calm', 'focus', 'sleep'
  final String? categoryColor;   // Hex color: '#6B9B8E'
  final String imageUrl;         // Thumbnail URL
  final String? audioUrl;        // Direct audio URL (set after streaming request)
  final String accessTier;       // 'free' or 'premium'
  final String? meditationType;  // 'breathing', 'body-scan', 'soundscape', etc.
  final String? difficultyLevel; // 'beginner', 'intermediate', 'advanced'
  final List<String>? tags;      // ['sleep', 'anxiety', 'focus']
  final String? expertName;      // Expert/guide name
  final bool featured;

  const MeditationAudio({
    required this.id,
    required this.title,
    required this.description,
    required this.durationInSeconds,
    required this.category,
    this.categoryColor,
    required this.imageUrl,
    this.audioUrl,
    this.accessTier = 'free',
    this.meditationType,
    this.difficultyLevel,
    this.tags,
    this.expertName,
    this.featured = false,
  });

  /// Create from API JSON response
  factory MeditationAudio.fromJson(Map<String, dynamic> json) {
    // Extract category info
    String categorySlug = 'uncategorized';
    String? categoryColor;
    
    if (json['category'] is Map) {
      categorySlug = json['category']['slug'] ?? json['category']['name']?.toString().toLowerCase() ?? 'uncategorized';
      categoryColor = json['category']['color'];
    } else if (json['category_name'] != null) {
      categorySlug = json['category_name'].toString().toLowerCase();
      categoryColor = json['category_color'];
    } else if (json['category'] is String) {
      categorySlug = json['category'];
    }
    
    // Extract expert name
    String? expertName;
    if (json['expert'] is Map) {
      expertName = json['expert']['name'];
    } else if (json['expert_name'] != null) {
      expertName = json['expert_name'];
    }
    
    // Extract tags
    List<String>? tags;
    if (json['tags'] is List) {
      tags = (json['tags'] as List).map((e) => e.toString()).toList();
    }
    
    return MeditationAudio(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      durationInSeconds: json['duration_seconds'] ?? 0,
      category: categorySlug,
      categoryColor: categoryColor,
      imageUrl: json['thumbnail_url'] ?? json['image_url'] ?? '',
      audioUrl: json['audio_url'],
      accessTier: json['access_tier'] ?? 'free',
      meditationType: json['meditation_type'],
      difficultyLevel: json['difficulty_level'],
      tags: tags,
      expertName: expertName,
      featured: json['featured'] ?? false,
    );
  }

  /// Create a copy with new audio URL (for after streaming request)
  MeditationAudio copyWithAudioUrl(String url) {
    return MeditationAudio(
      id: id,
      title: title,
      description: description,
      durationInSeconds: durationInSeconds,
      category: category,
      categoryColor: categoryColor,
      imageUrl: imageUrl,
      audioUrl: url,
      accessTier: accessTier,
      meditationType: meditationType,
      difficultyLevel: difficultyLevel,
      tags: tags,
      expertName: expertName,
      featured: featured,
    );
  }

  String get formattedDuration {
    final minutes = durationInSeconds ~/ 60;
    final seconds = durationInSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  bool get isPremium => accessTier == 'premium';

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        durationInSeconds,
        category,
        categoryColor,
        imageUrl,
        audioUrl,
        accessTier,
        meditationType,
        difficultyLevel,
        tags,
        expertName,
        featured,
      ];
}
