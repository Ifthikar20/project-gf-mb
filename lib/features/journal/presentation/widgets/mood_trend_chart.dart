import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/presentation/widgets/mood_selector_widget.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/mood_summary.dart';

/// 7-day mood trend chart rendered with CustomPaint.
///
/// Displays mood intensity as a line chart with mood-colored dots.
/// No external charting dependency — pure Canvas painting.
class MoodTrendChart extends StatelessWidget {
  final List<DailyMood> weeklyMoods;

  const MoodTrendChart({super.key, required this.weeklyMoods});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isLight = themeState.isLight;
        final textColor = ThemeColors.textPrimary(themeState.mode);
        final textSecondary = ThemeColors.textSecondary(themeState.mode);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isLight
                ? Colors.white
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLight
                  ? Colors.grey.shade200
                  : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart_rounded,
                      color: textColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Mood Trend',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Last 7 days',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (weeklyMoods.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Start journaling to see your mood trends',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 120,
                  child: CustomPaint(
                    size: const Size(double.infinity, 120),
                    painter: _MoodTrendPainter(
                      moods: weeklyMoods,
                      isLight: isLight,
                    ),
                  ),
                ),

              // Day labels below chart
              if (weeklyMoods.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: weeklyMoods.map((m) {
                    return SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          _dayLabel(m.date),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _dayLabel(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    } catch (_) {
      return '';
    }
  }
}

class _MoodTrendPainter extends CustomPainter {
  final List<DailyMood> moods;
  final bool isLight;

  _MoodTrendPainter({required this.moods, required this.isLight});

  @override
  void paint(Canvas canvas, Size size) {
    if (moods.isEmpty) return;

    final padding = 12.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    final step = moods.length > 1 ? chartWidth / (moods.length - 1) : 0.0;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = (isLight ? Colors.grey : Colors.white).withOpacity(0.08)
      ..strokeWidth = 1;
    for (int i = 1; i <= 5; i++) {
      final y = padding + chartHeight - (i / 5) * chartHeight;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Build points
    final points = <Offset>[];
    for (int i = 0; i < moods.length; i++) {
      final x = padding + i * step;
      final normalizedY = moods[i].moodIntensity / 5;
      final y = padding + chartHeight - normalizedY * chartHeight;
      points.add(Offset(x, y));
    }

    // Draw gradient fill
    if (points.length >= 2) {
      final fillPath = Path()
        ..moveTo(points.first.dx, size.height - padding);
      for (final p in points) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath.lineTo(points.last.dx, size.height - padding);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF81C784).withOpacity(0.2),
            const Color(0xFF81C784).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw line
    if (points.length >= 2) {
      final linePaint = Paint()
        ..color = const Color(0xFF81C784)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        // Smooth curve using cubic bezier
        final prev = points[i - 1];
        final curr = points[i];
        final cp1x = prev.dx + (curr.dx - prev.dx) * 0.4;
        final cp2x = prev.dx + (curr.dx - prev.dx) * 0.6;
        linePath.cubicTo(cp1x, prev.dy, cp2x, curr.dy, curr.dx, curr.dy);
      }
      canvas.drawPath(linePath, linePaint);
    }

    // Draw dots
    for (int i = 0; i < points.length; i++) {
      final moodColor =
          Moods.getById(moods[i].mood)?.color ?? const Color(0xFF81C784);

      // Outer glow
      canvas.drawCircle(
        points[i],
        8,
        Paint()..color = moodColor.withOpacity(0.15),
      );

      // Inner dot
      canvas.drawCircle(
        points[i],
        5,
        Paint()..color = moodColor,
      );

      // White center
      canvas.drawCircle(
        points[i],
        2.5,
        Paint()..color = isLight ? Colors.white : const Color(0xFF141414),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MoodTrendPainter oldDelegate) {
    return oldDelegate.moods != moods || oldDelegate.isLight != isLight;
  }
}
