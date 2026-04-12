import 'package:flutter/material.dart';

/// Bedtime consistency gauge showing how regular the user's sleep pattern is.
/// Displays as a semicircular gauge (0-100%) with a label.
class BedtimeConsistencyWidget extends StatelessWidget {
  final double consistency; // 0.0 - 1.0
  final double avgQuality;

  const BedtimeConsistencyWidget({
    super.key,
    required this.consistency,
    required this.avgQuality,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (consistency * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          // Consistency metric
          Expanded(
            child: _buildMetric(
              '${percent}%',
              'Consistency',
              _getConsistencyLabel(consistency),
              _getConsistencyColor(consistency),
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withOpacity(0.08),
          ),
          // Average quality metric
          Expanded(
            child: _buildMetric(
              avgQuality.toStringAsFixed(1),
              'Avg Quality',
              _getQualityLabel(avgQuality),
              _getQualityColor(avgQuality),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String value, String title, String description, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  String _getConsistencyLabel(double c) {
    if (c >= 0.8) return 'Very stable';
    if (c >= 0.6) return 'Fairly stable';
    if (c >= 0.4) return 'Variable';
    return 'Inconsistent';
  }

  Color _getConsistencyColor(double c) {
    if (c >= 0.8) return const Color(0xFF22C55E);
    if (c >= 0.6) return const Color(0xFF84CC16);
    if (c >= 0.4) return const Color(0xFFEAB308);
    return const Color(0xFFF97316);
  }

  String _getQualityLabel(double q) {
    if (q >= 4) return 'Excellent';
    if (q >= 3) return 'Good';
    if (q >= 2) return 'Fair';
    return 'Poor';
  }

  Color _getQualityColor(double q) {
    if (q >= 4) return const Color(0xFF22C55E);
    if (q >= 3) return const Color(0xFF84CC16);
    if (q >= 2) return const Color(0xFFEAB308);
    return const Color(0xFFEF4444);
  }
}
