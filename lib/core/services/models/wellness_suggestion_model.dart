import 'package:flutter/material.dart';

/// A dynamic, AI-generated wellness suggestion
class WellnessSuggestion {
  final String id;
  final String title;
  final String body;
  final String category; // recovery, nutrition, sleep, mental, activity, celebration
  final String priority; // high, medium, low
  final String? actionRoute; // deep link (e.g., '/breathing-exercise')
  final String? actionLabel; // button text (e.g., 'Start Breathing')
  final bool isDismissible;

  const WellnessSuggestion({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.priority = 'medium',
    this.actionRoute,
    this.actionLabel,
    this.isDismissible = true,
  });

  factory WellnessSuggestion.fromJson(Map<String, dynamic> json) {
    return WellnessSuggestion(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? json['message'] ?? '',
      category: json['category'] ?? 'general',
      priority: json['priority'] ?? 'medium',
      actionRoute: json['action_route'] ?? json['action'],
      actionLabel: json['action_label'],
      isDismissible: json['is_dismissible'] ?? true,
    );
  }

  IconData get icon {
    switch (category) {
      case 'recovery':
        return Icons.healing_rounded;
      case 'nutrition':
        return Icons.restaurant_rounded;
      case 'sleep':
        return Icons.nightlight_rounded;
      case 'mental':
        return Icons.psychology_rounded;
      case 'activity':
        return Icons.directions_run_rounded;
      case 'hydration':
        return Icons.water_drop_rounded;
      case 'celebration':
        return Icons.emoji_events_rounded;
      case 'breathing':
        return Icons.air_rounded;
      default:
        return Icons.tips_and_updates_rounded;
    }
  }

  Color get color {
    switch (category) {
      case 'recovery':
        return const Color(0xFF6366F1);
      case 'nutrition':
        return const Color(0xFF10B981);
      case 'sleep':
        return const Color(0xFF8B5CF6);
      case 'mental':
        return const Color(0xFFEC4899);
      case 'activity':
        return const Color(0xFFF59E0B);
      case 'hydration':
        return const Color(0xFF3B82F6);
      case 'celebration':
        return const Color(0xFFFBBF24);
      case 'breathing':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF64748B);
    }
  }

  int get priorityScore {
    switch (priority) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 2;
    }
  }
}
