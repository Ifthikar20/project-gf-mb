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
  final List<MealLog> meals;

  const NutritionCharts({
    super.key,
    required this.todaySummary,
    required this.rangeSummaries,
    required this.chartDays,
    required this.onRangeChanged,
    this.meals = const [],
  });

  @override
  State<NutritionCharts> createState() => _NutritionChartsState();
}

class _NutritionChartsState extends State<NutritionCharts>
    with SingleTickerProviderStateMixin {
  int _chartType = 0; // 0 = pie, 1 = bar, 2 = line
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
          // ── Header: Chart type toggle (compact, icons only) ──
          Row(
            children: [
              Expanded(
                child: _buildToggle(
                  labels: ['Overall', 'Bar', 'Line', 'Breakdown'],
                  icons: [Icons.pie_chart_rounded, Icons.bar_chart_rounded, Icons.show_chart_rounded, Icons.list_alt_rounded],
                  selected: _chartType,
                  onChanged: (i) {
                    setState(() => _chartType = i);
                    _animCtrl.forward(from: 0);
                  },
                  isDark: isDark,
                ),
              ),
            ],
          ),
          // Time range toggle (only for bar or line)
          if (_chartType == 1 || _chartType == 2) ...[
            const SizedBox(height: 8),
            _buildRangeToggle(isDark),
          ],
          const SizedBox(height: 16),

          // ── Chart Area ──
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) {
              if (_chartType == 0) {
                return _buildPieChart(text, subtle, isDark);
              } else if (_chartType == 1) {
                return _buildBarChart(text, subtle, isDark);
              } else if (_chartType == 2) {
                return _buildLineChart(text, subtle, isDark);
              } else {
                return _buildBreakdown(text, subtle, isDark);
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
        children: List.generate(labels.length, (i) {
          final isActive = i == selected;
          final activeColor = isDark ? Colors.white : Colors.black;
          final inactiveColor = isDark ? Colors.white38 : Colors.black38;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive
                      ? (isDark ? const Color(0xFF333333) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isActive ? [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1)),
                  ] : null,
                ),
                child: isActive
                    ? Text(labels[i], style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: activeColor))
                    : Icon(icons[i], size: 16, color: inactiveColor),
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

  // ─── Line Chart (Daily Calories Trend) ───
  Widget _buildLineChart(Color text, Color subtle, bool isDark) {
    final entries = widget.rangeSummaries.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (entries.isEmpty) {
      return SizedBox(
        height: 200,
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
          height: 200,
          child: CustomPaint(
            size: Size(MediaQuery.of(context).size.width - 72, 200),
            painter: _CalorieLinePainter(
              entries: entries,
              maxValue: chartMax,
              goal: goal.toDouble(),
              progress: _anim.value,
              isDark: isDark,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 16, height: 3, decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6),
              borderRadius: BorderRadius.circular(2),
            )),
            const SizedBox(width: 6),
            Text('Calories', style: GoogleFonts.inter(fontSize: 11, color: subtle)),
            const SizedBox(width: 16),
            Container(width: 16, height: 2, color: const Color(0xFF10B981).withOpacity(0.5)),
            const SizedBox(width: 6),
            Text('Goal: $goal cal', style: GoogleFonts.inter(fontSize: 11, color: subtle)),
          ],
        ),
      ],
    );
  }

  // ─── Breakdown View (all nutrients) ───
  Widget _buildBreakdown(Color text, Color subtle, bool isDark) {
    final meals = widget.meals;
    if (meals.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(child: Text('Log a meal to see breakdown', style: GoogleFonts.inter(fontSize: 13, color: subtle))),
      );
    }

    int protein = 0, carbs = 0, fat = 0, sugar = 0, fiber = 0, sodium = 0, caffeine = 0;
    for (final m in meals) {
      protein += m.proteinGrams;
      carbs += m.carbsGrams;
      fat += m.fatGrams;
      sugar += m.sugarGrams;
      fiber += m.fiberGrams;
      sodium += m.sodiumMg;
      caffeine += m.caffeineMg;
    }

    final progress = _anim.value;
    return Column(
      children: [
        _bRow('Protein', '${protein}g', '/ 150g', protein / 150 * progress, const Color(0xFF3B82F6), text, subtle),
        _bRow('Carbs', '${carbs}g', '/ 250g', carbs / 250 * progress, const Color(0xFFF59E0B), text, subtle),
        _bRow('Fat', '${fat}g', '/ 65g', fat / 65 * progress, const Color(0xFFEC4899), text, subtle),
        Divider(color: subtle.withOpacity(0.15), height: 16),
        _bRow('Fiber', '${fiber}g', '/ 30g', fiber / 30 * progress, const Color(0xFF22C55E), text, subtle),
        _bRow('Sugar', '${sugar}g', '/ 50g', sugar / 50 * progress, const Color(0xFFF97316), text, subtle),
        _bRow('Sodium', '${sodium}mg', '/ 2300mg', sodium / 2300 * progress, const Color(0xFF6366F1), text, subtle),
        if (caffeine > 0)
          _bRow('Caffeine', '${caffeine}mg', '/ 400mg', caffeine / 400 * progress, const Color(0xFFA78BFA), text, subtle),
      ],
    );
  }

  Widget _bRow(String label, String value, String target, double ratio, Color color, Color text, Color subtle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          SizedBox(width: 60, child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: text))),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: text)),
          const SizedBox(width: 4),
          Text(target, style: GoogleFonts.inter(fontSize: 10, color: subtle)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 5,
              ),
            ),
          ),
        ],
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

// ──────────────────────────────────────────
// Daily Calorie Line Chart Painter
// ──────────────────────────────────────────
class _CalorieLinePainter extends CustomPainter {
  final List<MapEntry<DateTime, DailyNutritionSummary>> entries;
  final double maxValue, goal, progress;
  final bool isDark;

  _CalorieLinePainter({
    required this.entries,
    required this.maxValue,
    required this.goal,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty || maxValue == 0) return;

    final chartH = size.height - 28; // room for labels
    final chartW = size.width;
    final count = entries.length;
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    // ── Goal line (dashed) ──
    final goalY = chartH * (1 - goal / maxValue);
    final goalPaint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashW = 6.0;
    const dashGap = 4.0;
    double dx = 0;
    while (dx < chartW) {
      canvas.drawLine(
        Offset(dx, goalY),
        Offset(min(dx + dashW, chartW), goalY),
        goalPaint,
      );
      dx += dashW + dashGap;
    }

    // ── Build data points ──
    final points = <Offset>[];
    for (int i = 0; i < count; i++) {
      final x = count == 1 ? chartW / 2 : (i / (count - 1)) * chartW;
      final cal = entries[i].value.totalCalories.toDouble();
      final y = chartH * (1 - cal / maxValue);
      points.add(Offset(x, y));
    }

    // ── Animated visible count ──
    final visibleCount = (count * progress).ceil().clamp(0, count);
    if (visibleCount < 2) return;

    final visiblePoints = points.sublist(0, visibleCount);

    // ── Gradient fill under line ──
    final fillPath = Path()
      ..moveTo(visiblePoints.first.dx, chartH);
    for (final p in visiblePoints) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(visiblePoints.last.dx, chartH);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF8B5CF6).withOpacity(0.25),
          const Color(0xFF8B5CF6).withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, chartW, chartH));
    canvas.drawPath(fillPath, fillPaint);

    // ── Line ──
    final linePath = Path()..moveTo(visiblePoints.first.dx, visiblePoints.first.dy);
    for (int i = 1; i < visiblePoints.length; i++) {
      linePath.lineTo(visiblePoints[i].dx, visiblePoints[i].dy);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // ── Data points ──
    final dotPaint = Paint()..color = const Color(0xFF8B5CF6);
    final dotBorderPaint = Paint()
      ..color = isDark ? const Color(0xFF1A1A1A) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final p in visiblePoints) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(p, 4, dotBorderPaint);
    }

    // ── Date labels ──
    for (int i = 0; i < count; i++) {
      final date = entries[i].key;
      String label;
      if (count <= 7) {
        label = days[date.weekday % 7];
      } else if (count <= 14) {
        label = '${date.day}';
      } else {
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
        final x = count == 1 ? chartW / 2 : (i / (count - 1)) * chartW;
        tp.paint(canvas, Offset(x - tp.width / 2, chartH + 8));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieLinePainter old) =>
      old.progress != progress || old.entries.length != entries.length;
}
