import 'package:flutter/material.dart';

/// Static breathing pattern configurations
class BreathingPattern {
  final String name;
  final String description;
  final int inhaleSeconds;
  final int holdSeconds;
  final int exhaleSeconds;
  final int holdAfterExhaleSeconds;
  final IconData icon;
  final Color color;

  const BreathingPattern({
    required this.name,
    required this.description,
    required this.inhaleSeconds,
    required this.holdSeconds,
    required this.exhaleSeconds,
    this.holdAfterExhaleSeconds = 0,
    required this.icon,
    required this.color,
  });

  int get totalCycleSeconds =>
      inhaleSeconds + holdSeconds + exhaleSeconds + holdAfterExhaleSeconds;
}

class BreathingPatternsData {
  BreathingPatternsData._();

  static const List<BreathingPattern> patterns = [
    BreathingPattern(
      name: '4-7-8 Relaxing',
      description:
          'Calms the nervous system. Breathe in for 4s, hold for 7s, exhale for 8s. Great before sleep.',
      inhaleSeconds: 4,
      holdSeconds: 7,
      exhaleSeconds: 8,
      icon: Icons.nightlight_rounded,
      color: Color(0xFF6366F1),
    ),
    BreathingPattern(
      name: 'Box Breathing',
      description:
          'Used by Navy SEALs — equal phases create focus and calm. In 4s, hold 4s, out 4s, hold 4s.',
      inhaleSeconds: 4,
      holdSeconds: 4,
      exhaleSeconds: 4,
      holdAfterExhaleSeconds: 4,
      icon: Icons.crop_square_rounded,
      color: Color(0xFF3B82F6),
    ),
    BreathingPattern(
      name: 'Deep Calm',
      description:
          'Simple deep breathing for immediate stress relief. Long exhale activates your parasympathetic system.',
      inhaleSeconds: 5,
      holdSeconds: 2,
      exhaleSeconds: 7,
      icon: Icons.spa_rounded,
      color: Color(0xFF10B981),
    ),
    BreathingPattern(
      name: 'Energize',
      description:
          'Short, sharp breaths to wake up and boost alertness. Great for morning or pre-workout.',
      inhaleSeconds: 3,
      holdSeconds: 1,
      exhaleSeconds: 3,
      icon: Icons.bolt_rounded,
      color: Color(0xFFF59E0B),
    ),
  ];
}
