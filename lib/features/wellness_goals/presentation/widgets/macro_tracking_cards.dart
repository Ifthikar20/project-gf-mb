import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../workouts/presentation/bloc/workout_bloc.dart';
import '../../../workouts/presentation/bloc/workout_state.dart';
import '../bloc/goals_bloc.dart';
import '../bloc/goals_state.dart';

/// Three Cal AI-style metric cards showing Active Minutes, Workouts, and Goals.
/// Displayed in a horizontal scrollable row with mini circular progress rings.
class MacroTrackingCards extends StatelessWidget {
  const MacroTrackingCards({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<WorkoutBloc, WorkoutState>(
      builder: (context, workoutState) {
        // Active minutes
        int activeMinutes = 0;
        int activeMinutesTarget = 275;
        int workoutsCount = 0;
        int workoutsTarget = 5;

        if (workoutState is WorkoutLoaded) {
          activeMinutes = workoutState.stats?.thisWeekMinutes ?? 0;
          workoutsCount = workoutState.stats?.thisWeekCount ?? 0;
          try {
            final minGoal = workoutState.goals
                .firstWhere((g) => g.goalType == 'active_minutes');
            activeMinutesTarget = minGoal.targetValue;
          } catch (_) {}
          try {
            final countGoal = workoutState.goals
                .firstWhere((g) => g.goalType == 'workout_count');
            workoutsTarget = countGoal.targetValue;
          } catch (_) {}
        }

        return BlocBuilder<GoalsBloc, GoalsState>(
          builder: (context, goalsState) {
            int activeGoals = 0;
            int totalGoals = 3;
            if (goalsState is GoalsLoaded) {
              final goals = goalsState.goals;
              activeGoals =
                  goals.where((g) => g.isCompleted).length;
              totalGoals = goals.isEmpty ? 3 : goals.length;
            }

            final cards = [
              _MetricData(
                value: activeMinutes,
                target: activeMinutesTarget,
                label: 'Active minutes',
                icon: Icons.timer_rounded,
                color: const Color(0xFFFF6B6B),
                ringColor: const Color(0xFFFF6B6B),
              ),
              _MetricData(
                value: workoutsCount,
                target: workoutsTarget,
                label: 'Workouts done',
                icon: Icons.fitness_center_rounded,
                color: const Color(0xFFF59E0B),
                ringColor: const Color(0xFFF59E0B),
              ),
              _MetricData(
                value: activeGoals,
                target: totalGoals,
                label: 'Goals complete',
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFF3B82F6),
                ringColor: const Color(0xFF3B82F6),
              ),
            ];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: cards.map((data) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: data != cards.last ? 10 : 0,
                      ),
                      child: _MacroCard(data: data, isDark: isDark),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}

class _MetricData {
  final int value;
  final int target;
  final String label;
  final IconData icon;
  final Color color;
  final Color ringColor;

  const _MetricData({
    required this.value,
    required this.target,
    required this.label,
    required this.icon,
    required this.color,
    required this.ringColor,
  });
}

class _MacroCard extends StatelessWidget {
  final _MetricData data;
  final bool isDark;

  const _MacroCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final progress =
        data.target > 0 ? (data.value / data.target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Value / target
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${data.value}',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                  height: 1.0,
                ),
              ),
              Text(
                '/${data.target}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark ? Colors.white.withOpacity(0.40) : Colors.black38,
            ),
          ),
          const SizedBox(height: 12),
          // Mini ring + icon
          Row(
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CustomPaint(
                  painter: _MiniRingPainter(
                    progress: progress,
                    color: data.ringColor,
                    isDark: isDark,
                  ),
                  child: Center(
                    child: Icon(data.icon, size: 14, color: data.color),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _MiniRingPainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    const strokeWidth = 4.0;

    // Background track
    final bgPaint = Paint()
      ..color = color.withOpacity(isDark ? 0.12 : 0.10)
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

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}
