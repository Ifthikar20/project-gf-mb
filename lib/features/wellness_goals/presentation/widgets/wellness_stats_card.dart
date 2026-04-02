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
import '../pages/health_detail_page.dart';

class WellnessStatsCard extends StatefulWidget {
  const WellnessStatsCard({super.key});

  @override
  State<WellnessStatsCard> createState() => _WellnessStatsCardState();
}

class _WellnessStatsCardState extends State<WellnessStatsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  int _steps = 0;
  double _caloriesBurned = 0;
  int _sleepMin = 0;
  double _distanceM = 0;
  bool _healthConnected = false;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();
    _loadHealthData();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthData() async {
    final hk = HealthKitService.instance;
    // Mark connected if permissions were ever granted
    final connected = hk.isEnabled || hk.isAuthorized;
    if (!connected) return;

    var steps = await hk.getCachedSteps();
    if (steps == 0) { try { steps = await hk.getStepCount(days: 1); } catch (_) {} }

    double activeCal = 0;
    try {
      final workouts = await hk.getWorkoutSummaries(days: 1);
      if (workouts.isNotEmpty) activeCal = workouts.last.caloriesBurned;
    } catch (_) {}

    int sleep = await hk.getCachedSleep();
    double distance = await hk.getCachedDistance();
    if (sleep == 0) { try { sleep = await hk.getSleepMinutes(days: 1); } catch (_) {} }
    if (distance == 0) { try { distance = await hk.getDistanceMeters(days: 1); } catch (_) {} }

    if (mounted) {
      setState(() {
        _steps = steps;
        _caloriesBurned = activeCal;
        _sleepMin = sleep;
        _distanceM = distance;
        _healthConnected = true;
      });
    }
  }

  Future<void> _connectHealth() async {
    setState(() => _connecting = true);
    try {
      await HealthKitService.instance.setEnabled(false);
      final success = await HealthKitService.instance.setEnabled(true);
      if (success && mounted) {
        await _loadHealthData();
        final msg = _steps > 0
            ? 'Connected! $_steps steps today'
            : 'Connected but 0 steps. Check Settings > Health > Data Access > Great Feel.';
        final color = _steps > 0 ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg), backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: ${HealthKitService.instance.lastError ?? "Permission denied"}. Go to Settings > Health > Data Access.'),
          backgroundColor: const Color(0xFFEF4444), duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
    if (mounted) setState(() => _connecting = false);
  }

  Widget _miniStat(IconData icon, Color color, String value, String label, Color text, Color subtle, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: subtle)),
        ],
      ),
    );
  }

  // Calorie burn rates (cal/min) based on 70kg person
  // Walking brisk: ~5 cal/min, Running: ~11 cal/min, Cycling: ~8 cal/min
  _SmartTip? _buildSmartTip(int eaten, int burned, int steps) {
    final net = eaten - burned;

    if (eaten == 0 && burned == 0 && steps == 0) {
      return null; // No data, no tip
    }

    if (net > 0) {
      // Surplus — calculate real exercise to burn it
      final walkMin = (net / 5).round();   // 5 cal/min walking
      final runMin = (net / 11).round();    // 11 cal/min running
      if (net <= 200) {
        return _SmartTip('$net cal left — a ${walkMin}min walk burns $net cal', Icons.directions_walk, const Color(0xFF3B82F6));
      } else if (net <= 500) {
        return _SmartTip('$net cal over — a ${runMin}min jog or ${walkMin}min walk to balance', Icons.directions_run, const Color(0xFFF59E0B));
      } else {
        return _SmartTip('$net cal surplus — ${runMin}min run burns $net cal', Icons.directions_run, const Color(0xFFEF4444));
      }
    }

    if (net <= 0 && eaten > 0) {
      return _SmartTip('On track! ${net.abs()} cal deficit today', Icons.check_circle, const Color(0xFF22C55E));
    }

    if (burned > 0 && eaten == 0) {
      return _SmartTip('Burned $burned cal — grab a healthy snack to refuel', Icons.restaurant, const Color(0xFF22C55E));
    }

    if (steps > 0 && steps < 5000) {
      final stepsLeft = 10000 - steps;
      final calLeft = (stepsLeft * 0.05).round(); // ~0.05 cal per step
      return _SmartTip('${_formatSteps(stepsLeft)} steps to 10k — that\'s ~$calLeft cal', Icons.directions_walk, const Color(0xFF3B82F6));
    }

    if (steps >= 10000) {
      final calFromSteps = (steps * 0.05).round();
      return _SmartTip('${_formatSteps(steps)} steps today — burned ~$calFromSteps cal from walking alone', Icons.emoji_events, const Color(0xFF22C55E));
    }

    return null;
  }

  String _formatSteps(int n) {
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
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

        // Backend workout data
        int weekBurned = 0;
        if (workoutState is WorkoutLoaded) {
          weekBurned = workoutState.stats?.thisWeekCalories ?? 0;
        }

        // Total burned today:
        // 1. HealthKit active calories (most accurate — uses real HR)
        // 2. Estimate from steps if no active cal data
        // 3. Backend weekly average as last resort
        int todayBurned;
        if (_caloriesBurned > 0) {
          todayBurned = _caloriesBurned.round();
        } else if (_steps > 0) {
          todayBurned = HealthKitService.estimateCaloriesFromSteps(_steps);
        } else {
          todayBurned = weekBurned > 0 ? (weekBurned ~/ 7) : 0;
        }

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthDetailPage())),
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: BlocBuilder<DietBloc, DietState>(
            builder: (context, dietState) {
              final eaten = dietState is DietLoaded ? dietState.summary.totalCalories : 0;

              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                      spreadRadius: isDark ? 0 : 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top: 3 metric tiles ──
                    Row(
                      children: [
                        _metricTile(
                          icon: Icons.directions_walk,
                          iconColor: const Color(0xFF3B82F6),
                          value: _healthConnected ? _formatSteps(_steps) : '--',
                          label: 'Steps',
                          text: text, subtle: subtle, isDark: isDark,
                        ),
                        const SizedBox(width: 10),
                        _metricTile(
                          icon: Icons.restaurant,
                          iconColor: const Color(0xFF22C55E),
                          value: '$eaten',
                          label: 'Eaten',
                          text: text, subtle: subtle, isDark: isDark,
                        ),
                        const SizedBox(width: 10),
                        _metricTile(
                          icon: Icons.local_fire_department,
                          iconColor: const Color(0xFFEF4444),
                          value: '$todayBurned',
                          label: 'Burned',
                          text: text, subtle: subtle, isDark: isDark,
                        ),
                      ],
                    ),

                    // ── Second row: Sleep + Distance ──
                    if (_healthConnected && (_sleepMin > 0 || _distanceM > 0)) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (_sleepMin > 0)
                            Expanded(
                              child: _miniStat(
                                Icons.bedtime_rounded,
                                const Color(0xFF6366F1),
                                _sleepMin >= 60 ? '${_sleepMin ~/ 60}h ${_sleepMin % 60}m' : '${_sleepMin}m',
                                'Sleep',
                                text, subtle, isDark,
                              ),
                            ),
                          if (_sleepMin > 0 && _distanceM > 0)
                            const SizedBox(width: 10),
                          if (_distanceM > 0)
                            Expanded(
                              child: _miniStat(
                                Icons.route_rounded,
                                const Color(0xFF14B8A6),
                                _distanceM >= 1000 ? '${(_distanceM / 1000).toStringAsFixed(1)} km' : '${_distanceM.round()} m',
                                'Distance',
                                text, subtle, isDark,
                              ),
                            ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ── Net balance bar ──
                    _netBalanceBar(eaten, todayBurned, text, subtle, isDark),

                    const SizedBox(height: 12),

                    // ── Smart insight (single factual line) ──
                    Builder(
                      builder: (_) {
                        final tip = _buildSmartTip(eaten, todayBurned, _steps);
                        if (tip == null) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8F8FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(tip.icon, color: tip.color, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(tip.text, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, height: 1.3)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // ── Connect prompt ──
                    if (!_healthConnected) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _connecting ? null : _connectHealth,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite_rounded, color: Color(0xFF8B5CF6), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Connect Apple Health for real-time steps & activity',
                                  style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _connecting
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Color(0xFF8B5CF6), strokeWidth: 2))
                                  : Text('Connect', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF8B5CF6))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
                    // Shimmer glare overlay
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _ShimmerPainter(
                                progress: _shimmerController.value,
                                isDark: isDark,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        );
      },
    );
  }

  Widget _metricTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required Color text,
    required Color subtle,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8F8FA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: text)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: subtle)),
          ],
        ),
      ),
    );
  }

  Widget _netBalanceBar(int eaten, int burned, Color text, Color subtle, bool isDark) {
    final net = eaten - burned;
    final isDeficit = net <= 0;
    final maxVal = math.max(eaten, burned).clamp(1, 99999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Intake vs Output', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: subtle)),
            Text(
              isDeficit ? '${net.abs()} cal deficit' : '+$net cal surplus',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDeficit ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Intake bar
        _labeledBar('Intake', eaten, maxVal, const Color(0xFF22C55E), subtle, isDark),
        const SizedBox(height: 8),
        // Output bar
        _labeledBar('Output', burned, maxVal, const Color(0xFFEF4444), subtle, isDark),
      ],
    );
  }

  Widget _labeledBar(String label, int value, int maxVal, Color color, Color subtle, bool isDark) {
    final pct = (value / maxVal).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: subtle)),
        ),
        Expanded(
          child: SizedBox(
            height: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Stack(
                children: [
                  Container(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text('$value', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color), textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

class _SmartTip {
  final String text;
  final IconData icon;
  final Color color;
  const _SmartTip(this.text, this.icon, this.color);
}

/// Subtle shimmer glare that sweeps across the card
class _ShimmerPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  _ShimmerPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final shimmerWidth = size.width * 0.4;
    final x = -shimmerWidth + (size.width + shimmerWidth * 2) * progress;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          (isDark ? Colors.white : Colors.white).withValues(alpha: isDark ? 0.04 : 0.15),
          (isDark ? Colors.white : Colors.white).withValues(alpha: isDark ? 0.07 : 0.25),
          (isDark ? Colors.white : Colors.white).withValues(alpha: isDark ? 0.04 : 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(x, 0, shimmerWidth, size.height));

    canvas.drawRect(Rect.fromLTWH(x, 0, shimmerWidth, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) => old.progress != progress;
}
