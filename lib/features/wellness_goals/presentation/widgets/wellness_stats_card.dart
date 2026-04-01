import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/healthkit_service.dart';
import '../../../workouts/presentation/bloc/workout_bloc.dart';
import '../../../workouts/presentation/bloc/workout_event.dart';
import '../../../workouts/presentation/bloc/workout_state.dart';
import '../../../diet/presentation/bloc/diet_bloc.dart';
import '../../../diet/presentation/bloc/diet_state.dart';

/// Primary wellness stats card — shows calories burned (big ring),
/// plus steps and calories eaten in a compact row below.
/// Includes inline Apple Health connect prompt if not connected.
class WellnessStatsCard extends StatefulWidget {
  const WellnessStatsCard({super.key});

  @override
  State<WellnessStatsCard> createState() => _WellnessStatsCardState();
}

class _WellnessStatsCardState extends State<WellnessStatsCard> {
  int _steps = 0;
  bool _healthConnected = false;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    final hk = HealthKitService.instance;

    // Always try to read steps regardless of flags
    int steps = 0;
    if (hk.isAuthorized || hk.isEnabled) {
      steps = await hk.getCachedSteps();
      if (steps == 0) {
        try {
          await hk.requestPermissions();
          steps = await hk.getStepCount(days: 1);
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() {
        _steps = steps;
        _healthConnected = steps > 0;
      });
    }
  }

  Future<void> _connectHealth() async {
    setState(() => _connecting = true);

    try {
      // Reset and try fresh
      await HealthKitService.instance.setEnabled(false);
      final success = await HealthKitService.instance.setEnabled(true);

      if (success && mounted) {
        await _loadHealthData();
        if (_steps > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connected! $_steps steps today'),
              backgroundColor: const Color(0xFF22C55E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connected but 0 steps. Go to Settings > Health > Data Access > Great Feel and enable all permissions.\n${HealthKitService.instance.lastError ?? ""}'),
              backgroundColor: const Color(0xFFF59E0B),
              duration: const Duration(seconds: 6),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${HealthKitService.instance.lastError ?? "Permission denied"}. Go to Settings > Health > Data Access and enable Great Feel.'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }

    if (mounted) setState(() => _connecting = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final text = isDark ? Colors.white : Colors.black;
    final subtle = isDark ? Colors.white38 : Colors.black38;

    return BlocBuilder<WorkoutBloc, WorkoutState>(
      builder: (context, workoutState) {
        if (workoutState is WorkoutInitial) {
          context.read<WorkoutBloc>().add(const LoadWorkoutData());
          return const SizedBox.shrink();
        }

        int burned = 0;
        int burnTarget = 2500;

        if (workoutState is WorkoutLoaded) {
          burned = workoutState.stats?.thisWeekCalories ?? 0;
          try {
            final goal = workoutState.goals.firstWhere((g) => g.goalType == 'calories_burned');
            burnTarget = goal.targetValue;
          } catch (_) {}
        }

        final burnProgress = burnTarget > 0 ? (burned / burnTarget).clamp(0.0, 1.0) : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                // ── Main: Calories Burned + Ring ──
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$burned', style: GoogleFonts.inter(fontSize: 44, fontWeight: FontWeight.w700, color: text, height: 1.0)),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Text('/$burnTarget', style: GoogleFonts.inter(fontSize: 16, color: subtle)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('Calories burned', style: GoogleFonts.inter(fontSize: 13, color: subtle)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CustomPaint(
                        painter: _CircularProgressPainter(progress: burnProgress, isDark: isDark),
                        child: Center(child: Icon(Icons.local_fire_department_rounded, color: isDark ? Colors.white70 : Colors.black54, size: 26)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(color: subtle.withOpacity(0.2), height: 1),
                const SizedBox(height: 14),

                // ── Steps + Calories Eaten row ──
                Row(
                  children: [
                    // Steps
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.directions_walk, color: const Color(0xFF3B82F6), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _healthConnected ? _formatSteps(_steps) : '--',
                            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: text),
                          ),
                          const SizedBox(width: 4),
                          Text('steps', style: GoogleFonts.inter(fontSize: 11, color: subtle)),
                        ],
                      ),
                    ),
                    // Divider
                    Container(width: 1, height: 20, color: subtle.withOpacity(0.2)),
                    // Calories eaten
                    Expanded(
                      child: BlocBuilder<DietBloc, DietState>(
                        builder: (context, dietState) {
                          final eaten = dietState is DietLoaded ? dietState.summary.totalCalories : 0;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.restaurant, color: const Color(0xFF22C55E), size: 16),
                              const SizedBox(width: 6),
                              Text('$eaten', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: text)),
                              const SizedBox(width: 4),
                              Text('eaten', style: GoogleFonts.inter(fontSize: 11, color: subtle)),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // ── Connect Apple Health prompt (if no step data) ──
                if (!_healthConnected) ...[
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _connecting ? null : _connectHealth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite_rounded, color: Color(0xFF8B5CF6), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              HealthKitService.instance.isEnabled
                                  ? 'No step data — tap to retry or check Settings > Health > Great Feel'
                                  : 'Connect Apple Health for steps & heart rate',
                              style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _connecting
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Color(0xFF8B5CF6), strokeWidth: 2))
                              : Text(
                                  HealthKitService.instance.isEnabled ? 'Retry' : 'Connect',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF8B5CF6)),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatSteps(int n) {
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _CircularProgressPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 6.0;

    canvas.drawCircle(center, radius, Paint()
      ..color = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = isDark ? Colors.white : Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter old) =>
      old.progress != progress || old.isDark != isDark;
}
