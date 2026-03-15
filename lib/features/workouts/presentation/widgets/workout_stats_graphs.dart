import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/healthkit_service.dart';

/// Workout performance graphs: weekly bar chart, effort ring, and HR line.
/// Reads real data from HealthKit when available, falls back to simulated data.
class WorkoutStatsGraphs extends StatefulWidget {
  const WorkoutStatsGraphs({super.key});

  @override
  State<WorkoutStatsGraphs> createState() => _WorkoutStatsGraphsState();
}

class _WorkoutStatsGraphsState extends State<WorkoutStatsGraphs> {
  List<DailyWorkoutSummary> _weeklyData = [];
  List<HeartRatePoint> _hrData = [];
  double _effortScore = 0.0;
  bool _isLoading = true;
  bool _usingRealData = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final hk = HealthKitService.instance;

    // Check if we have HealthKit permission
    final hasPerm = await hk.checkCachedPermission();

    if (hasPerm) {
      try {
        final weekly = await hk.getWorkoutSummaries(days: 7);
        final hr = await hk.getHeartRateData(days: 2);
        final effort = await hk.getEffortScore(days: 7);

        // Only use real data if we actually got some
        if (weekly.isNotEmpty || hr.isNotEmpty) {
          if (mounted) {
            setState(() {
              _weeklyData = weekly;
              _hrData = hr;
              _effortScore = effort;
              _usingRealData = true;
              _isLoading = false;
            });
          }
          return;
        }
      } catch (_) {
        // Fall through to simulated data
      }
    }

    // Fallback to simulated data
    if (mounted) {
      setState(() {
        _weeklyData = HealthKitService.simulatedWeekly;
        _hrData = HealthKitService.simulatedHeartRate;
        _effortScore = 0.72;
        _usingRealData = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;
    final surfaceColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F5);

    if (_isLoading) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: CircularProgressIndicator(
          color: isDark ? Colors.white24 : Colors.black12,
          strokeWidth: 2,
        ),
      );
    }

    // Extract data for painters
    final weeklyMinutes = _weeklyData.map((d) => d.totalMinutes).toList();
    final hrValues = _hrData.map((p) => p.bpm.round()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Source badge
        if (_usingRealData)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded,
                    color: Color(0xFF22C55E), size: 14),
                const SizedBox(width: 5),
                Text(
                  'Live from Apple Health',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF22C55E),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

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
              painter: _WeeklyBarPainter(
                data: weeklyMinutes.isNotEmpty
                    ? weeklyMinutes
                    : [45, 0, 30, 60, 20, 90, 0],
                isDark: isDark,
              ),
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
                      progress: _effortScore,
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
                    painter: _HeartRateLinePainter(
                      hrData: hrValues.isNotEmpty
                          ? hrValues
                          : [72, 85, 110, 135, 152, 148, 138, 120, 95, 78],
                      isDark: isDark,
                    ),
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
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
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
  final List<int> data;
  final bool isDark;
  _WeeklyBarPainter({required this.data, required this.isDark});

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void paint(Canvas canvas, Size size) {
    // Pad to 7 days if needed
    final paddedData = List<int>.from(data);
    while (paddedData.length < 7) paddedData.add(0);

    final maxVal = paddedData.reduce(max).toDouble();
    final barWidth = (size.width - 60) / 7;
    final chartHeight = size.height - 30;

    final labelStyle = TextStyle(
      color: isDark ? Colors.white38 : Colors.black38,
      fontSize: 11,
      fontFamily: 'Inter',
    );

    for (var i = 0; i < 7; i++) {
      final x = 8 + i * barWidth + (barWidth - 20) / 2;
      final val = paddedData[i];
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
  bool shouldRepaint(covariant _WeeklyBarPainter old) =>
      old.data != data;
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
  final List<int> hrData;
  final bool isDark;
  _HeartRateLinePainter({required this.hrData, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (hrData.isEmpty) return;
    final minHR = hrData.reduce(min).toDouble();
    final maxHR = hrData.reduce(max).toDouble();
    final range = maxHR - minHR;

    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < hrData.length; i++) {
      final x = i * size.width / (hrData.length - 1);
      final y = size.height -
          ((hrData[i] - minHR) / (range == 0 ? 1 : range)) * (size.height - 20) -
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
          const Color(0xFFEF4444).withValues(alpha: 0.15),
          const Color(0xFFEF4444).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // BPM label
    final tp = TextPainter(
      text: TextSpan(
        text: '${hrData.last} bpm',
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
  bool shouldRepaint(covariant _HeartRateLinePainter old) =>
      old.hrData != hrData;
}
