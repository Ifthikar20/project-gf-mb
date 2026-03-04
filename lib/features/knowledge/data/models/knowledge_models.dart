import 'package:flutter/material.dart';

/// Article model for the knowledge hub
class Article {
  final String id;
  final String title;
  final String summary;
  final String body;
  final String category; // nutrition, sleep, mindfulness, movement, mental-health
  final String? imageUrl;
  final int readTimeMinutes;
  final String author;

  const Article({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.category,
    this.imageUrl,
    required this.readTimeMinutes,
    required this.author,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      body: json['body'] ?? json['content'] ?? '',
      category: json['category'] ?? 'general',
      imageUrl: json['image_url'] ?? json['thumbnail'],
      readTimeMinutes: json['read_time_minutes'] ?? json['read_time'] ?? 5,
      author: json['author'] ?? 'Great Feel',
    );
  }

  IconData get categoryIcon {
    switch (category) {
      case 'nutrition':
        return Icons.restaurant_rounded;
      case 'sleep':
        return Icons.nightlight_rounded;
      case 'mindfulness':
        return Icons.self_improvement_rounded;
      case 'movement':
        return Icons.directions_run_rounded;
      case 'mental-health':
        return Icons.psychology_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'nutrition':
        return const Color(0xFF10B981);
      case 'sleep':
        return const Color(0xFF6366F1);
      case 'mindfulness':
        return const Color(0xFF8B5CF6);
      case 'movement':
        return const Color(0xFFF59E0B);
      case 'mental-health':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF3B82F6);
    }
  }
}

/// Short-form wellness tip
class WellnessTip {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final String category;

  const WellnessTip({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.category,
  });
}
