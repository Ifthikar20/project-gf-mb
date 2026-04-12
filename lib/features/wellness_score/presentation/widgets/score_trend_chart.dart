import 'package:flutter/material.dart';
import '../../domain/entities/wellness_score.dart';

/// Line chart showing daily wellness scores over time.
/// Lightweight custom painter — no external chart library dependency.
class ScoreTrendChart extends StatelessWidget {
  final List<DailyScoreSnapshot> history;
  final int daysToShow;

  const ScoreTrendChart({
    super.key,
    required this.history,
    this.daysToShow = 7,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: Text(
          'Start tracking to see trends',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 13,
          ),
        ),
      );
    }

    // Get the last N days of data
    final data = history.length > daysToShow
        ? history.sublist(history.length - daysToShow)
        : history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120,
          child: CustomPaint(
            size: const Size(double.infinity, 120),
            painter: _TrendPainter(data: data),
          ),
        ),
        const SizedBox(height: 8),
        // Day labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: data.map((s) {
            final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            return Text(
              dayNames[s.date.weekday - 1],
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 10,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<DailyScoreSnapshot> data;

  _TrendPainter({required this.data});

  Color _getColor(int score) {
    if (score < 30) return const Color(0xFFEF4444);
    if (score < 50) return const Color(0xFFF97316);
    if (score < 70) return const Color(0xFFEAB308);
    return const Color(0xFF22C55E);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxScore = 100.0;
    final minScore = 0.0;
    final range = maxScore - minScore;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Calculate points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? size.width / 2
          : (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i].score - minScore) / range * size.height);
      points.add(Offset(x, y.clamp(4, size.height - 4)));
    }

    // Draw gradient fill under the line
    if (points.length >= 2) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, size.height);
      for (final p in points) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF22C55E).withOpacity(0.15),
            const Color(0xFF22C55E).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw line
    if (points.length >= 2) {
      final linePaint = Paint()
        ..color = const Color(0xFF22C55E)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Draw dots
    for (int i = 0; i < points.length; i++) {
      final color = _getColor(data[i].score);

      // Glow
      canvas.drawCircle(
        points[i],
        6,
        Paint()..color = color.withOpacity(0.2),
      );

      // Dot
      canvas.drawCircle(
        points[i],
        4,
        Paint()..color = color,
      );

      // Inner dot
      canvas.drawCircle(
        points[i],
        2,
        Paint()..color = Colors.white.withOpacity(0.8),
      );
    }
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) =>
      oldDelegate.data.length != data.length;
}
