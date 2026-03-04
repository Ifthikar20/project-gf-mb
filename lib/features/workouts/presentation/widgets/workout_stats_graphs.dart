import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Workout performance graphs: weekly bar chart, effort ring, and HR line.
/// Uses simulated data — replace with real data from wearable SDK later.
class WorkoutStatsGraphs extends StatelessWidget {
  const WorkoutStatsGraphs({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;
    final surfaceColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weekly Performance Bar Chart
        _buildSectionCard(
          title: 'Weekly Performance',
          surfaceColor: surfaceColor,
          textColor: textColor,
          textSecondary: textSecondary,
          isDark: isDark,
          child: SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _WeeklyBarPainter(isDark: isDark),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Row: Effort Ring + Heart Rate Mini
        Row(
          children: [
            Expanded(
              child: _buildSectionCard(
                title: 'Effort Score',
                surfaceColor: surfaceColor,
                textColor: textColor,
                textSecondary: textSecondary,
                isDark: isDark,
                child: SizedBox(
                  height: 130,
                  child: CustomPaint(
                    size: const Size(double.infinity, 130),
                    painter: _EffortRingPainter(
                      progress: 0.72,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildSectionCard(
                title: 'Heart Rate',
                surfaceColor: surfaceColor,
                textColor: textColor,
                textSecondary: textSecondary,
                isDark: isDark,
                child: SizedBox(
                  height: 130,
                  child: CustomPaint(
                    size: const Size(double.infinity, 130),
                    painter: _HeartRateLinePainter(isDark: isDark),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ──────────────────────────────────
// Weekly Bar Chart Painter
// ──────────────────────────────────
class _WeeklyBarPainter extends CustomPainter {
  final bool isDark;
  _WeeklyBarPainter({required this.isDark});

  // Simulated minutes per day (Mon-Sun)
  static const _data = [45, 0, 30, 60, 20, 90, 0];
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = _data.reduce(max).toDouble();
    final barWidth = (size.width - 60) / 7;
    final chartHeight = size.height - 30;

    final labelStyle = TextStyle(
      color: isDark ? Colors.white38 : Colors.black38,
      fontSize: 11,
      fontFamily: 'Inter',
    );

    for (var i = 0; i < _data.length; i++) {
      final x = 8 + i * barWidth + (barWidth - 20) / 2;
      final val = _data[i];
      final ratio = maxVal > 0 ? val / maxVal : 0.0;
      final barH = ratio * (chartHeight - 10);

      // Color based on intensity
      Color barColor;
      if (val == 0) {
        barColor = isDark ? Colors.white10 : Colors.black12;
      } else if (val < 30) {
        barColor = const Color(0xFF22C55E);
      } else if (val < 60) {
        barColor = const Color(0xFFF59E0B);
      } else {
        barColor = const Color(0xFFEF4444);
      }

      // Bar
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chartHeight - barH, 20, barH.clamp(4, chartHeight)),
        const Radius.circular(6),
      );
      canvas.drawRRect(barRect, Paint()..color = barColor);

      // Day label
      final tp = TextPainter(
        text: TextSpan(text: _days[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + 10 - tp.width / 2, chartHeight + 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ──────────────────────────────────
// Effort Score Ring Painter
// ──────────────────────────────────
class _EffortRingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final bool isDark;
  _EffortRingPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isDark ? Colors.white10 : Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    final gradient = SweepGradient(
      startAngle: -pi / 2,
      endAngle: 2 * pi,
      colors: const [
        Color(0xFF6366F1),
        Color(0xFF8B5CF6),
        Color(0xFFA78BFA),
      ],
    );

    final arcPaint = Paint()
      ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      arcPaint,
    );

    // Center text
    final pct = (progress * 100).round();
    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$pct',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          TextSpan(
            text: '%',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _EffortRingPainter old) =>
      old.progress != progress;
}

// ──────────────────────────────────
// Heart Rate Line Painter
// ──────────────────────────────────
class _HeartRateLinePainter extends CustomPainter {
  final bool isDark;
  _HeartRateLinePainter({required this.isDark});

  // Simulated HR data points over a session
  static const _hrData = [72, 85, 110, 135, 152, 148, 138, 120, 95, 78];

  @override
  void paint(Canvas canvas, Size size) {
    if (_hrData.isEmpty) return;
    final minHR = _hrData.reduce(min).toDouble();
    final maxHR = _hrData.reduce(max).toDouble();
    final range = maxHR - minHR;

    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < _hrData.length; i++) {
      final x = i * size.width / (_hrData.length - 1);
      final y = size.height -
          ((_hrData[i] - minHR) / (range == 0 ? 1 : range)) * (size.height - 20) -
          10;
      points.add(Offset(x, y));
    }

    // Smooth curve
    path.moveTo(points[0].dx, points[0].dy);
    for (var i = 0; i < points.length - 1; i++) {
      final cp1 = Offset(
        points[i].dx + (points[i + 1].dx - points[i].dx) / 3,
        points[i].dy,
      );
      final cp2 = Offset(
        points[i + 1].dx - (points[i + 1].dx - points[i].dx) / 3,
        points[i + 1].dy,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx,
          points[i + 1].dy);
    }

    // Line gradient
    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF22C55E), Color(0xFFF59E0B), Color(0xFFEF4444)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Area fill
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFEF4444).withOpacity(0.15),
          const Color(0xFFEF4444).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // BPM label
    final tp = TextPainter(
      text: TextSpan(
        text: '${_hrData.last} bpm',
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
          fontSize: 11,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width - 4, 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
