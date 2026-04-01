import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/healthkit_service.dart';

/// Full health overview card showing all trackable metrics from Apple Health.
/// Displays: steps, calories burned, heart rate (avg/min/max), and a 7-day
/// combined activity graph.
class HealthOverviewCard extends StatefulWidget {
  const HealthOverviewCard({super.key});

  @override
  State<HealthOverviewCard> createState() => _HealthOverviewCardState();
}

class _HealthOverviewCardState extends State<HealthOverviewCard> {
  bool _isLoading = true;
  bool _isEnabled = false;
  int _steps = 0;
  int _avgHR = 0;
  int _minHR = 0;
  int _maxHR = 0;
  int _latestHR = 0;
  double _caloriesBurned = 0;
  int _activeMinutes = 0;
  int _workoutCount = 0;
  List<DailyWorkoutSummary> _weeklyData = [];
  List<HeartRatePoint> _hrData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final hk = HealthKitService.instance;
    _isEnabled = hk.isEnabled;

    if (!_isEnabled) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Try cached data first, then live
    final cachedSteps = await hk.getCachedSteps();
    final cachedWorkouts = await hk.getCachedWorkouts();
    final cachedHR = await hk.getCachedHeartRate();

    // Use live data if available, otherwise cached
    List<DailyWorkoutSummary> weekly = cachedWorkouts;
    List<HeartRatePoint> hr = cachedHR;
    int steps = cachedSteps;

    if (hk.isAuthorized) {
      try {
        final liveWeekly = await hk.getWorkoutSummaries(days: 7);
        final liveHR = await hk.getHeartRateData(days: 2);
        final liveSteps = await hk.getStepCount(days: 1);
        if (liveWeekly.isNotEmpty) weekly = liveWeekly;
        if (liveHR.isNotEmpty) hr = liveHR;
        if (liveSteps > 0) steps = liveSteps;
      } catch (_) {}
    }

    // Calculate heart rate stats
    int avgHR = 0, minHR = 0, maxHR = 0, latestHR = 0;
    if (hr.isNotEmpty) {
      final bpms = hr.map((p) => p.bpm.round()).toList();
      avgHR = (bpms.reduce((a, b) => a + b) / bpms.length).round();
      minHR = bpms.reduce(min);
      maxHR = bpms.reduce(max);
      latestHR = bpms.last;
    }

    // Calculate weekly totals
    double totalCal = 0;
    int totalMin = 0;
    int totalWorkouts = 0;
    for (final day in weekly) {
      totalCal += day.caloriesBurned;
      totalMin += day.totalMinutes;
      totalWorkouts += day.workoutCount;
    }

    if (mounted) {
      setState(() {
        _steps = steps;
        _avgHR = avgHR;
        _minHR = minHR;
        _maxHR = maxHR;
        _latestHR = latestHR;
        _caloriesBurned = totalCal;
        _activeMinutes = totalMin;
        _workoutCount = totalWorkouts;
        _weeklyData = weekly;
        _hrData = hr;
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
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05);

    if (_isLoading) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: isDark ? Colors.white24 : Colors.black12, strokeWidth: 2),
      );
    }

    if (!_isEnabled) {
      return _buildEnablePrompt(surfaceColor, textColor, textSecondary, cardBorder);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 18),
            const SizedBox(width: 6),
            Text(
              'Health Overview',
              style: GoogleFonts.inter(color: textColor, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Apple Health', style: GoogleFonts.inter(color: const Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Today's metrics — 2x2 grid
        Row(
          children: [
            Expanded(child: _buildMetricTile(
              icon: Icons.directions_walk, iconColor: const Color(0xFF3B82F6),
              value: _formatNumber(_steps), label: 'Steps Today',
              surfaceColor: surfaceColor, textColor: textColor, textSecondary: textSecondary, cardBorder: cardBorder,
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricTile(
              icon: Icons.favorite_rounded, iconColor: const Color(0xFFEF4444),
              value: _latestHR > 0 ? '$_latestHR' : '--', label: 'Heart Rate',
              unit: 'bpm',
              surfaceColor: surfaceColor, textColor: textColor, textSecondary: textSecondary, cardBorder: cardBorder,
            )),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildMetricTile(
              icon: Icons.local_fire_department, iconColor: const Color(0xFFFF6B6B),
              value: _caloriesBurned.round().toString(), label: 'Cal Burned (7d)',
              surfaceColor: surfaceColor, textColor: textColor, textSecondary: textSecondary, cardBorder: cardBorder,
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricTile(
              icon: Icons.timer_outlined, iconColor: const Color(0xFF4ECDC4),
              value: '$_activeMinutes', label: 'Active Min (7d)',
              unit: 'min',
              surfaceColor: surfaceColor, textColor: textColor, textSecondary: textSecondary, cardBorder: cardBorder,
            )),
          ],
        ),

        // Heart Rate Summary bar
        if (_avgHR > 0) ...[
          const SizedBox(height: 14),
          _buildHeartRateSummary(surfaceColor, textColor, textSecondary, cardBorder, isDark),
        ],

        // 7-Day Activity Graph
        if (_weeklyData.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildWeeklyGraph(surfaceColor, textColor, textSecondary, cardBorder, isDark),
        ],

        // Heart Rate Trend Graph
        if (_hrData.length > 3) ...[
          const SizedBox(height: 14),
          _buildHeartRateGraph(surfaceColor, textColor, textSecondary, cardBorder, isDark),
        ],
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    String? unit,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color cardBorder,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: GoogleFonts.inter(color: textColor, fontSize: 24, fontWeight: FontWeight.w700)),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Text(unit, style: GoogleFonts.inter(color: textSecondary, fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(color: textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildHeartRateSummary(Color surfaceColor, Color textColor, Color textSecondary, Color cardBorder, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Heart Rate Range', style: GoogleFonts.inter(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          // Visual range bar
          SizedBox(
            height: 40,
            child: CustomPaint(
              size: const Size(double.infinity, 40),
              painter: _HRRangePainter(minHR: _minHR, avgHR: _avgHR, maxHR: _maxHR, isDark: isDark),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _hrStat('Min', '$_minHR', const Color(0xFF22C55E), textSecondary),
              _hrStat('Avg', '$_avgHR', const Color(0xFFF59E0B), textSecondary),
              _hrStat('Max', '$_maxHR', const Color(0xFFEF4444), textSecondary),
              _hrStat('Now', '$_latestHR', const Color(0xFF8B5CF6), textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hrStat(String label, String value, Color color, Color textSecondary) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label, style: GoogleFonts.inter(color: textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildWeeklyGraph(Color surfaceColor, Color textColor, Color textSecondary, Color cardBorder, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('7-Day Activity', style: GoogleFonts.inter(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('$_workoutCount workouts', style: GoogleFonts.inter(color: textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _ActivityGraphPainter(data: _weeklyData, isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateGraph(Color surfaceColor, Color textColor, Color textSecondary, Color cardBorder, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Heart Rate Trend', style: GoogleFonts.inter(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('Last 48h', style: GoogleFonts.inter(color: textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 100,
            child: CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _HRTrendPainter(data: _hrData, isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }

  bool _connecting = false;

  Future<void> _connectAppleHealth() async {
    setState(() => _connecting = true);
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Turn ON all categories in the next screen, then tap Allow'),
            backgroundColor: const Color(0xFF8B5CF6),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      await Future.delayed(const Duration(milliseconds: 500));
      final success = await HealthKitService.instance.setEnabled(true);
      if (success && mounted) {
        await _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not connect: ${HealthKitService.instance.lastError ?? "Permission denied"}. Check Settings > Health > Data Access.'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
    if (mounted) setState(() => _connecting = false);
  }

  Widget _buildEnablePrompt(Color surfaceColor, Color textColor, Color textSecondary, Color cardBorder) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Steps, Heart Rate & More', style: GoogleFonts.inter(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Connect Apple Health to track your activity', style: GoogleFonts.inter(color: textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _connecting ? null : _connectAppleHealth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _connecting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Connect', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ──────────────────────────────────
// HR Range Painter
// ──────────────────────────────────
class _HRRangePainter extends CustomPainter {
  final int minHR, avgHR, maxHR;
  final bool isDark;
  _HRRangePainter({required this.minHR, required this.avgHR, required this.maxHR, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rangeMin = (minHR - 10).clamp(40, 200).toDouble();
    final rangeMax = (maxHR + 10).clamp(40, 200).toDouble();
    final range = rangeMax - rangeMin;
    if (range <= 0) return;

    final y = size.height / 2;

    // Track
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, y - 4, size.width, 8), const Radius.circular(4)),
      Paint()..color = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
    );

    // Active range (min to max)
    final startX = ((minHR - rangeMin) / range) * size.width;
    final endX = ((maxHR - rangeMin) / range) * size.width;
    final gradient = LinearGradient(colors: [const Color(0xFF22C55E), const Color(0xFFF59E0B), const Color(0xFFEF4444)]);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(startX, y - 4, endX - startX, 8), const Radius.circular(4)),
      Paint()..shader = gradient.createShader(Rect.fromLTWH(startX, 0, endX - startX, 8)),
    );

    // Avg marker
    final avgX = ((avgHR - rangeMin) / range) * size.width;
    canvas.drawCircle(Offset(avgX, y), 8, Paint()..color = const Color(0xFFF59E0B));
    canvas.drawCircle(Offset(avgX, y), 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _HRRangePainter old) => old.avgHR != avgHR;
}

// ──────────────────────────────────
// 7-Day Activity Graph Painter (stacked: calories + minutes)
// ──────────────────────────────────
class _ActivityGraphPainter extends CustomPainter {
  final List<DailyWorkoutSummary> data;
  final bool isDark;
  _ActivityGraphPainter({required this.data, required this.isDark});

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final chartHeight = size.height - 24;
    final barWidth = (size.width - 16) / data.length;

    final maxCal = data.map((d) => d.caloriesBurned).reduce(max);
    final maxMin = data.map((d) => d.totalMinutes).reduce(max);
    final maxVal = max(maxCal, maxMin.toDouble());
    if (maxVal == 0) return;

    final labelStyle = TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontFamily: 'Inter');

    for (var i = 0; i < data.length; i++) {
      final x = 8 + i * barWidth;
      final d = data[i];

      // Calories bar (back, wider)
      final calH = (d.caloriesBurned / maxVal) * (chartHeight - 4);
      if (calH > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x + 2, chartHeight - calH, barWidth - 8, calH.clamp(3, chartHeight)), const Radius.circular(5)),
          Paint()..color = const Color(0xFFFF6B6B).withValues(alpha: 0.25),
        );
      }

      // Minutes bar (front, narrower)
      final minH = (d.totalMinutes / maxVal) * (chartHeight - 4);
      if (minH > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x + 6, chartHeight - minH, barWidth - 16, minH.clamp(3, chartHeight)), const Radius.circular(4)),
          Paint()..color = const Color(0xFF8B5CF6),
        );
      }

      // Day label
      final dayIdx = (DateTime.now().subtract(Duration(days: data.length - 1 - i)).weekday - 1) % 7;
      final tp = TextPainter(text: TextSpan(text: _days[dayIdx], style: labelStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x + barWidth / 2 - tp.width / 2, chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityGraphPainter old) => true;
}

// ──────────────────────────────────
// HR Trend Line Painter (48h)
// ──────────────────────────────────
class _HRTrendPainter extends CustomPainter {
  final List<HeartRatePoint> data;
  final bool isDark;
  _HRTrendPainter({required this.data, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final bpms = data.map((p) => p.bpm).toList();
    final minV = bpms.reduce(min);
    final maxV = bpms.reduce(max);
    final range = maxV - minV;

    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < data.length; i++) {
      final x = i * size.width / (data.length - 1);
      final y = size.height - ((data[i].bpm - minV) / (range == 0 ? 1 : range)) * (size.height - 16) - 8;
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);
    for (var i = 0; i < points.length - 1; i++) {
      final cp1 = Offset(points[i].dx + (points[i + 1].dx - points[i].dx) / 3, points[i].dy);
      final cp2 = Offset(points[i + 1].dx - (points[i + 1].dx - points[i].dx) / 3, points[i + 1].dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
    }

    // Line
    final linePaint = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFFF59E0B), Color(0xFFEF4444)])
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Fill
    final fillPath = Path.from(path)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(fillPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFEF4444).withValues(alpha: 0.12), const Color(0xFFEF4444).withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    // Latest value label
    final tp = TextPainter(
      text: TextSpan(text: '${bpms.last.round()} bpm', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 11, fontFamily: 'Inter')),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width - 2, 0));

    // Zone labels
    final minTp = TextPainter(
      text: TextSpan(text: '${minV.round()}', style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 9, fontFamily: 'Inter')),
      textDirection: TextDirection.ltr,
    )..layout();
    minTp.paint(canvas, Offset(0, size.height - 10));
  }

  @override
  bool shouldRepaint(covariant _HRTrendPainter old) => true;
}
