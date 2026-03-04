import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/diet_models.dart';

/// Animated circular macro rings — calories center, protein/carbs/fat orbiting
class NutritionRingCard extends StatelessWidget {
  final DailyNutritionSummary summary;

  const NutritionRingCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleColor = isDark ? Colors.white38 : Colors.black38;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          // Ring + center cal text
          SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: _MacroRingPainter(
                calorieProgress: summary.calorieProgress,
                proteinProgress: summary.proteinProgress,
                carbsProgress: summary.carbsProgress,
                fatProgress: summary.fatProgress,
                isDark: isDark,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${summary.totalCalories}',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'of ${summary.calorieGoal} cal',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: subtleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.caloriesRemaining} left',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: summary.caloriesRemaining > 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Macro breakdown row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _macroStat('Protein', summary.totalProtein, summary.proteinGoal,
                  'g', const Color(0xFF3B82F6)),
              _macroStat('Carbs', summary.totalCarbs, summary.carbsGoal, 'g',
                  const Color(0xFFF59E0B)),
              _macroStat('Fat', summary.totalFat, summary.fatGoal, 'g',
                  const Color(0xFFEC4899)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroStat(
      String label, int value, int goal, String unit, Color color) {
    return Column(
      children: [
        Text(
          '$value$unit',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$label · ${goal}$unit',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.white38,
          ),
        ),
      ],
    );
  }
}

class _MacroRingPainter extends CustomPainter {
  final double calorieProgress;
  final double proteinProgress;
  final double carbsProgress;
  final double fatProgress;
  final bool isDark;

  _MacroRingPainter({
    required this.calorieProgress,
    required this.proteinProgress,
    required this.carbsProgress,
    required this.fatProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Calorie ring (outermost)
    _drawRing(canvas, center, size.width / 2 - 6, 8,
        const Color(0xFF10B981), calorieProgress.clamp(0.0, 1.0));

    // Protein ring
    _drawRing(canvas, center, size.width / 2 - 20, 6,
        const Color(0xFF3B82F6), proteinProgress.clamp(0.0, 1.0));

    // Carbs ring
    _drawRing(canvas, center, size.width / 2 - 32, 5,
        const Color(0xFFF59E0B), carbsProgress.clamp(0.0, 1.0));

    // Fat ring (innermost)
    _drawRing(canvas, center, size.width / 2 - 42, 4,
        const Color(0xFFEC4899), fatProgress.clamp(0.0, 1.0));
  }

  void _drawRing(Canvas canvas, Offset center, double radius,
      double strokeWidth, Color color, double progress) {
    // Background track
    final bgPaint = Paint()
      ..color = color.withOpacity(isDark ? 0.10 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MacroRingPainter old) {
    return old.calorieProgress != calorieProgress ||
        old.proteinProgress != proteinProgress ||
        old.carbsProgress != carbsProgress ||
        old.fatProgress != fatProgress;
  }
}
