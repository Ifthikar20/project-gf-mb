import 'package:flutter/material.dart';
import '../../domain/entities/wellness_score.dart';

/// Horizontal bar showing a sub-score with emoji, label, and animated fill.
class SubScoreBar extends StatelessWidget {
  final SubScore subScore;

  const SubScoreBar({super.key, required this.subScore});

  Color _getColor(int score) {
    if (score < 30) return const Color(0xFFEF4444);
    if (score < 50) return const Color(0xFFF97316);
    if (score < 70) return const Color(0xFFEAB308);
    return const Color(0xFF22C55E);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(subScore.score);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Emoji
          SizedBox(
            width: 28,
            child: Text(
              subScore.category.emoji,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          // Label
          SizedBox(
            width: 72,
            child: Text(
              subScore.category.label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  // Background
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // Fill
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: subScore.score / 100),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return FractionallySizedBox(
                        widthFactor: value.clamp(0.02, 1.0),
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Score value
          SizedBox(
            width: 36,
            child: Text(
              '${subScore.score}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
