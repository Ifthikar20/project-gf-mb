import 'package:flutter/material.dart';
import '../../domain/entities/sleep_data.dart';

/// Weekly sleep quality bar chart.
/// Each bar is colored by quality: red < 3, yellow = 3, green > 3.
class SleepQualityChart extends StatelessWidget {
  final List<DailySleepQuality> weeklyData;

  const SleepQualityChart({super.key, required this.weeklyData});

  Color _getQualityColor(int quality) {
    switch (quality) {
      case 1: return const Color(0xFFEF4444);
      case 2: return const Color(0xFFF97316);
      case 3: return const Color(0xFFEAB308);
      case 4: return const Color(0xFF84CC16);
      case 5: return const Color(0xFF22C55E);
      default: return Colors.grey;
    }
  }

  String _getQualityLabel(int quality) {
    switch (quality) {
      case 1: return 'Awful';
      case 2: return 'Poor';
      case 3: return 'Okay';
      case 4: return 'Good';
      case 5: return 'Great';
      default: return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (weeklyData.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌙', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              'No sleep data yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Log sleep quality in your daily check-in',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          // Find data for this slot
          final data = index < weeklyData.length ? weeklyData[index] : null;
          final quality = data?.quality ?? 0;
          final barHeight = quality > 0 ? (quality / 5) * 120 : 4.0;
          final color = quality > 0 ? _getQualityColor(quality) : Colors.white.withOpacity(0.06);
          final dayLabel = data?.dayLabel ?? '';

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Quality label on top
                  if (quality > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '$quality',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  // Bar
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: barHeight),
                    duration: Duration(milliseconds: 600 + index * 100),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return Container(
                        height: value,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: quality > 0
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  // Day label
                  Text(
                    dayLabel,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
