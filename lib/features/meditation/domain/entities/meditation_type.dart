import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Meditation category/type entity
/// Matches backend API response from /categories
class MeditationType extends Equatable {
  final String id;
  final String slug;
  final String name;
  final String description;
  final String imageUrl;
  final Color color;
  final String? icon;
  final String subtitle;
  final int contentCount;

  const MeditationType({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.color,
    this.icon,
    this.subtitle = '',
    this.contentCount = 0,
  });

  /// Create from API JSON response
  factory MeditationType.fromJson(Map<String, dynamic> json) {
    // Parse color from hex string
    Color color = const Color(0xFF7C3AED); // Default purple
    if (json['color'] != null) {
      try {
        final colorStr = json['color'].toString().replaceAll('#', '');
        color = Color(int.parse('FF$colorStr', radix: 16));
      } catch (_) {}
    }
    
    return MeditationType(
      id: json['id']?.toString() ?? '',
      slug: json['slug'] ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? json['thumbnail_url'] ?? 'https://picsum.photos/seed/${json['slug']}/400/400',
      color: color,
      icon: json['icon'],
      subtitle: json['subtitle'] ?? '',
      contentCount: json['content_count'] ?? 0,
    );
  }

  /// Create predefined category for fallback
  static const List<MeditationType> defaultCategories = [
    MeditationType(
      id: 'calm',
      slug: 'calm',
      name: 'Calm',
      description: 'Find your inner peace',
      imageUrl: 'https://picsum.photos/seed/calm/400/400',
      color: Color(0xFF6B9B8E),
    ),
    MeditationType(
      id: 'focus',
      slug: 'focus',
      name: 'Focus',
      description: 'Enhance concentration',
      imageUrl: 'https://picsum.photos/seed/focus/400/400',
      color: Color(0xFF8B7BA8),
    ),
    MeditationType(
      id: 'sleep',
      slug: 'sleep',
      name: 'Sleep',
      description: 'Drift off peacefully',
      imageUrl: 'https://picsum.photos/seed/sleep/400/400',
      color: Color(0xFF5C6BC0),
    ),
    MeditationType(
      id: 'breathe',
      slug: 'breathe',
      name: 'Breathe',
      description: 'Guided breathing exercises',
      imageUrl: 'https://picsum.photos/seed/breathe/400/400',
      color: Color(0xFF26A69A),
    ),
    MeditationType(
      id: 'stress',
      slug: 'stress',
      name: 'Stress Relief',
      description: 'Release tension and anxiety',
      imageUrl: 'https://picsum.photos/seed/stress/400/400',
      color: Color(0xFFEF5350),
    ),
    MeditationType(
      id: 'morning',
      slug: 'morning',
      name: 'Morning',
      description: 'Start your day right',
      imageUrl: 'https://picsum.photos/seed/morning/400/400',
      color: Color(0xFFFFA726),
    ),
  ];

  /// Mood-based categories
  static const List<MeditationType> moodCategories = [
    MeditationType(
      id: 'happy',
      slug: 'happy',
      name: 'Happy Vibes',
      description: 'Uplift your spirits',
      imageUrl: 'https://picsum.photos/seed/happy/400/400',
      color: Color(0xFFFFEB3B),
    ),
    MeditationType(
      id: 'relax',
      slug: 'relax',
      name: 'Deep Relax',
      description: 'Ultimate relaxation',
      imageUrl: 'https://picsum.photos/seed/relax/400/400',
      color: Color(0xFF9C27B0),
    ),
    MeditationType(
      id: 'energy',
      slug: 'energy',
      name: 'Energy Boost',
      description: 'Revitalize your mind',
      imageUrl: 'https://picsum.photos/seed/energy/400/400',
      color: Color(0xFFE91E63),
    ),
  ];

  @override
  List<Object?> get props => [id, slug, name, description, imageUrl, color, icon, subtitle, contentCount];
}
