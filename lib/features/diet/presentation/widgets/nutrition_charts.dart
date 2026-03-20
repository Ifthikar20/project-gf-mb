import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/diet_models.dart';

/// Nutrition charts — switchable pie/bar with time range selector.
/// Uses custom Canvas painters (no external chart library).
class NutritionCharts extends StatefulWidget {
  final DailyNutritionSummary todaySummary;
  final Map<DateTime, DailyNutritionSummary> rangeSummaries;
  final int chartDays;
  final ValueChanged<int> onRangeChanged;

  const NutritionCharts({
    super.key,
    required this.todaySummary,
    required this.rangeSummaries,
    required this.chartDays,
    required this.onRangeChanged,
  });

  @override
  State<NutritionCharts> createState() => _NutritionChartsState();
}

class _NutritionChartsState extends State<NutritionCharts>
    with SingleTickerProviderStateMixin {
  int _chartType = 0; // 0 = pie, 1 = bar
  late AnimationController _animCtrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void didUpdateWidget(NutritionCharts old) {
    super.didUpdateWidget(old);
    if (old.chartDays != widget.chartDays || old.todaySummary != widget.todaySummary) {
      _animCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final text = isDark ? Colors.white : Colors.black;
    final subtle = isDark ? Colors.white38 : Colors.black38;
    final border = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8EC);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Chart type + time range toggles ──
          Row(
            children: [
              // Chart type toggle
              _buildToggle(
                labels: ['Macros', 'Trends'],
                icons: [Icons.pie_chart_rounded, Icons.bar_chart_rounded],
                selected: _chartType,
                onChanged: (i) {
                  setState(() => _chartType = i);
                  _animCtrl.forward(from: 0);
                },
                isDark: isDark,
              ),
              const Spacer(),
              // Time range toggle (only for bar chart)
              if (_chartType == 1)
                _buildRangeToggle(isDark),
            ],
          ),
          const SizedBox(height: 20),

          // ── Chart Area ──
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) {
              if (_chartType == 0) {
                return _buildPieChart(text, subtle, isDark);
              } else {
                return _buildBarChart(text, subtle, isDark);
              }
            },
          ),
        ],
      ),
    );
  }

  // ─── Pie Chart (Today's Macros) ───
  Widget _buildPieChart(Color text, Color subtle, bool isDark) {
    final s = widget.todaySummary;
    final total = s.totalProtein + s.totalCarbs + s.totalFat;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: CustomPaint(
            size: const Size(180, 180),
            painter: _MacroPiePainter(
              protein: s.totalProtein.toDouble(),
              carbs: s.totalCarbs.toDouble(),
              fat: s.totalFat.toDouble(),
              progress: _anim.value,
              isDark: isDark,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _legendItem('Protein', '${s.totalProtein}g',
                total > 0 ? '${((s.totalProtein / total) * 100).round()}%' : '0%',
                const Color(0xFF3B82F6)),
            _legendItem('Carbs', '${s.totalCarbs}g',
                total > 0 ? '${((s.totalCarbs / total) * 100).round()}%' : '0%',
                const Color(0xFFF59E0B)),
            _legendItem('Fat', '${s.totalFat}g',
                total > 0 ? '${((s.totalFat / total) * 100).round()}%' : '0%',
                const Color(0xFFEC4899)),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(String label, String value, String pct, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black,
        )),
        Text('$label ($pct)', style: GoogleFonts.inter(
          fontSize: 11, color: isDark ? Colors.white38 : Colors.black45,
        )),
      ],
    );
  }

  // ─── Bar Chart (Daily Calories Over Time) ───
  Widget _buildBarChart(Color text, Color subtle, bool isDark) {
    final entries = widget.rangeSummaries.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (entries.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text('No data yet', style: GoogleFonts.inter(color: subtle)),
        ),
      );
    }

    final maxCal = entries.fold<int>(0, (m, e) => max(m, e.value.totalCalories));
    final goal = widget.todaySummary.calorieGoal;
    final chartMax = max(maxCal, goal).toDouble();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: CustomPaint(
            size: Size(MediaQuery.of(context).size.width - 72, 180),
            painter: _CalorieBarPainter(
              entries: entries,
              maxValue: chartMax,
              goal: goal.toDouble(),
              progress: _anim.value,
              isDark: isDark,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Goal legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 16, height: 2, color: const Color(0xFF10B981).withOpacity(0.5)),
            const SizedBox(width: 6),
            Text('Goal: $goal cal', style: GoogleFonts.inter(
              fontSize: 11, color: subtle,
            )),
          ],
        ),
      ],
    );
  }

  // ─── Toggle Buttons ───
  Widget _buildToggle({
    required List<String> labels,
    required List<IconData> icons,
    required int selected,
    required ValueChanged<int> onChanged,
    required bool isDark,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : const Color(0xFFF0F0F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final isActive = i == selected;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? (isDark ? const Color(0xFF333333) : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ] : null,
              ),
              child: Row(
                children: [
                  Icon(icons[i], size: 14,
                    color: isActive
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.white38 : Colors.black38)),
                  const SizedBox(width: 4),
                  Text(labels[i], style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.white38 : Colors.black38),
                  )),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRangeToggle(bool isDark) {
    const ranges = [7, 14, 30];
    const labels = ['7D', '14D', '30D'];

    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : const Color(0xFFF0F0F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final isActive = widget.chartDays == ranges[i];
          return GestureDetector(
            onTap: () => widget.onRangeChanged(ranges[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? (isDark ? const Color(0xFF333333) : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ] : null,
              ),
              child: Center(
                child: Text(labels[i], style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.white38 : Colors.black38),
                )),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ──────────────────────────────────────────
// Macro Pie Chart Painter
// ──────────────────────────────────────────
class _MacroPiePainter extends CustomPainter {
  final double protein, carbs, fat, progress;
  final bool isDark;

  _MacroPiePainter({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = protein + carbs + fat;
    if (total == 0) {
      // Draw empty ring
      final paint = Paint()
        ..color = isDark ? const Color(0xFF333333) : const Color(0xFFE8E8EC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width - 24,
          height: size.height - 24,
        ),
        -pi / 2, 2 * pi, false, paint,
      );
      return;
    }

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width - 24,
      height: size.height - 24,
    );

    const colors = [
      Color(0xFF3B82F6), // protein
      Color(0xFFF59E0B), // carbs
      Color(0xFFEC4899), // fat
    ];
    final values = [protein, carbs, fat];

    double startAngle = -pi / 2;
    for (int i = 0; i < 3; i++) {
      final sweep = (values[i] / total) * 2 * pi * progress;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }

    // Center text
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${(total * progress).round()}g\n',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          TextSpan(
            text: 'total',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _MacroPiePainter old) =>
      old.progress != progress || old.protein != protein ||
      old.carbs != carbs || old.fat != fat;
}

// ──────────────────────────────────────────
// Daily Calorie Bar Chart Painter
// ──────────────────────────────────────────
class _CalorieBarPainter extends CustomPainter {
  final List<MapEntry<DateTime, DailyNutritionSummary>> entries;
  final double maxValue, goal, progress;
  final bool isDark;

  _CalorieBarPainter({
    required this.entries,
    required this.maxValue,
    required this.goal,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty || maxValue == 0) return;

    final barAreaWidth = size.width;
    final barAreaHeight = size.height - 24; // room for labels
    final count = entries.length;
    final barW = (barAreaWidth / count) * 0.55;
    final gap = barAreaWidth / count;
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    // Goal line
    final goalY = barAreaHeight * (1 - goal / maxValue);
    final goalPaint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    // Dashed goal line
    const dashW = 6.0;
    const dashGap = 4.0;
    double x = 0;
    while (x < barAreaWidth) {
      canvas.drawLine(
        Offset(x, goalY),
        Offset(min(x + dashW, barAreaWidth), goalY),
        goalPaint,
      );
      x += dashW + dashGap;
    }

    // Bars
    for (int i = 0; i < count; i++) {
      final entry = entries[i];
      final cal = entry.value.totalCalories.toDouble();
      final barH = (cal / maxValue) * barAreaHeight * progress;
      final bx = gap * i + (gap - barW) / 2;
      final by = barAreaHeight - barH;

      // Bar gradient
      final isOverGoal = cal > goal;
      final barColor = isOverGoal
          ? const Color(0xFFEF4444)
          : const Color(0xFF3B82F6);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, barW, barH),
        const Radius.circular(4),
      );
      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [barColor, barColor.withOpacity(0.6)],
        ).createShader(rrect.outerRect);
      canvas.drawRRect(rrect, barPaint);

      // Date label
      final date = entry.key;
      String label;
      if (count <= 7) {
        label = days[date.weekday % 7];
      } else if (count <= 14) {
        label = '${date.day}';
      } else {
        // For 30 days, show every 5th label
        label = (i % 5 == 0 || i == count - 1)
            ? '${months[date.month]} ${date.day}'
            : '';
      }

      if (label.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: count > 14 ? 8 : 10,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(
          bx + (barW - tp.width) / 2,
          barAreaHeight + 6,
        ));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieBarPainter old) =>
      old.progress != progress || old.entries.length != entries.length;
}
