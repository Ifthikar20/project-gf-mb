import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/healthkit_service.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../workouts/presentation/bloc/workout_bloc.dart';
import '../../../workouts/presentation/bloc/workout_event.dart';
import '../../../workouts/presentation/bloc/workout_state.dart';
import '../../../workouts/presentation/widgets/workout_stats_graphs.dart';
import '../../../diet/presentation/bloc/diet_bloc.dart';
import '../../../diet/presentation/bloc/diet_state.dart';
import '../bloc/goals_bloc.dart';
import '../bloc/goals_state.dart';

/// Activity page — opened when tapping the wellness card on Home.
/// Shows steps, sleep, distance, flights, heart health, HR graph, and daily performance.
/// No calories/eaten/workouts here — those live on the Calories and Workout pages.
class HealthDetailPage extends StatefulWidget {
  const HealthDetailPage({super.key});

  @override
  State<HealthDetailPage> createState() => _HealthDetailPageState();
}

class _HealthDetailPageState extends State<HealthDetailPage> {
  int _steps = 0;
  int _sleepMin = 0;
  double _distanceM = 0;
  int _restingHR = 0;
  double _hrv = 0;
  int _flights = 0;
  List<HeartRatePoint> _hrData = [];
  List<HeartRatePoint> _hrWeekData = [];
  bool _loaded = false;
  bool _hrShowWeek = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hk = HealthKitService.instance;
    if (!hk.isEnabled || !hk.isAuthorized) {
      if (mounted) setState(() => _loaded = true);
      return;
    }

    final steps = await hk.getStepCount(days: 1);
    final sleep = await hk.getSleepMinutes(days: 1);
    final distance = await hk.getDistanceMeters(days: 1);
    final restHR = await hk.getRestingHeartRate(days: 7);
    final hrv = await hk.getHRV(days: 7);
    final flights = await hk.getFlightsClimbed(days: 1);
    var hrData = await hk.getHeartRateData(days: 1);
    if (hrData.isEmpty) {
      hrData = await hk.getCachedHeartRate();
    }
    // Fall back to simulated data so graph always shows
    if (hrData.isEmpty) {
      hrData = HealthKitService.simulatedHeartRate;
    }

    // Weekly HR data
    var hrWeek = await hk.getHeartRateData(days: 7);
    if (hrWeek.isEmpty) {
      // Generate simulated week data
      final now = DateTime.now();
      final rng = List.generate(70, (i) => HeartRatePoint(
        time: now.subtract(Duration(hours: (70 - i) * 2)),
        bpm: 65 + (i % 7) * 12.0 + (i.isEven ? 5 : -3),
      ));
      hrWeek = rng;
    }

    if (mounted) {
      setState(() {
        _steps = steps;
        _sleepMin = sleep;
        _distanceM = distance;
        _restingHR = restHR;
        _hrv = hrv;
        _flights = flights;
        _hrData = hrData;
        _hrWeekData = hrWeek;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isLight = themeState.isLight;
        final bg = ThemeColors.background(mode);
        final text = ThemeColors.textPrimary(mode);
        final subtle = ThemeColors.textSecondary(mode);
        final surface = ThemeColors.surface(mode);
        final border = isLight ? const Color(0xFFE8E8EC) : const Color(0xFF2A2A2A);

        return Scaffold(
          backgroundColor: bg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_rounded, color: text, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text('Activity', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: text)),
                        const Spacer(),
                        if (HealthKitService.instance.isEnabled)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Text('Apple Health', style: GoogleFonts.inter(color: const Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              if (!_loaded)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else ...[
                // ── Today's Activity ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Today', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
                        const SizedBox(height: 12),
                        // Steps + Distance
                        Row(
                          children: [
                            _tile(Icons.directions_walk, const Color(0xFF3B82F6), _fmtSteps(_steps), 'Steps', '/ 10,000', surface, text, subtle, border),
                            const SizedBox(width: 10),
                            _tile(Icons.route_rounded, const Color(0xFF14B8A6), _fmtDist(_distanceM), 'Distance', 'walked', surface, text, subtle, border),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Sleep + Flights
                        Row(
                          children: [
                            _tile(Icons.bedtime_rounded, const Color(0xFF6366F1), _fmtSleep(_sleepMin), 'Sleep', _sleepMin > 0 ? 'last night' : '--', surface, text, subtle, border),
                            const SizedBox(width: 10),
                            _tile(Icons.stairs_rounded, const Color(0xFFF59E0B), '$_flights', 'Flights', 'climbed', surface, text, subtle, border),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Mindful Minutes + Workouts Done
                        BlocBuilder<WorkoutBloc, WorkoutState>(
                          builder: (context, ws) {
                            final mins = ws is WorkoutLoaded ? (ws.stats?.thisWeekMinutes ?? 0) : 0;
                            final count = ws is WorkoutLoaded ? (ws.stats?.thisWeekCount ?? 0) : 0;
                            return Row(
                              children: [
                                _tile(Icons.timer_rounded, const Color(0xFFFF6B6B), '$mins', 'Active Min', 'this week', surface, text, subtle, border),
                                const SizedBox(width: 10),
                                _tile(Icons.fitness_center_rounded, const Color(0xFFF59E0B), '$count', 'Workouts', 'this week', surface, text, subtle, border),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        // Calories Today + Goals Complete
                        Row(
                          children: [
                            BlocBuilder<DietBloc, DietState>(
                              builder: (context, ds) {
                                final cal = ds is DietLoaded ? ds.summary.totalCalories : 0;
                                final goal = ds is DietLoaded ? ds.summary.calorieGoal : 2000;
                                return _tile(Icons.local_fire_department_rounded, const Color(0xFF22C55E), '$cal', 'Calories', '/ $goal goal', surface, text, subtle, border);
                              },
                            ),
                            const SizedBox(width: 10),
                            BlocBuilder<GoalsBloc, GoalsState>(
                              builder: (context, gs) {
                                final done = gs is GoalsLoaded ? gs.goals.where((g) => g.isCompleted).length : 0;
                                final total = gs is GoalsLoaded ? gs.goals.length : 0;
                                return _tile(Icons.emoji_events_rounded, const Color(0xFF3B82F6), '$done', 'Goals', '/ $total complete', surface, text, subtle, border);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Heart Health ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Heart Health', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _compactStat(Icons.favorite, const Color(0xFFEF4444), _restingHR > 0 ? '$_restingHR' : '--', 'Resting HR', 'bpm', surface, text, subtle, border),
                            const SizedBox(width: 10),
                            _compactStat(Icons.show_chart, const Color(0xFF8B5CF6), _hrv > 0 ? '${_hrv.round()}' : '--', 'HRV', 'ms', surface, text, subtle, border),
                            const SizedBox(width: 10),
                            _compactStat(
                              _hrv > 50 ? Icons.sentiment_satisfied : Icons.sentiment_neutral,
                              _hrv > 50 ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                              _hrv > 50 ? 'Low' : (_hrv > 20 ? 'Mod' : '--'),
                              'Stress', _hrv > 50 ? 'relaxed' : 'moderate',
                              surface, text, subtle, border,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Heart Rate Throughout the Day ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 16),
                              const SizedBox(width: 6),
                              Text('Heart Rate', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
                              const Spacer(),
                              // Today / Week toggle
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: isLight ? const Color(0xFFE8E8EC) : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(() => _hrShowWeek = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: !_hrShowWeek ? (isLight ? Colors.white : Colors.white.withValues(alpha: 0.15)) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text('Today', style: GoogleFonts.inter(fontSize: 11, fontWeight: !_hrShowWeek ? FontWeight.w600 : FontWeight.w400, color: text)),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(() => _hrShowWeek = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _hrShowWeek ? (isLight ? Colors.white : Colors.white.withValues(alpha: 0.15)) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text('Week', style: GoogleFonts.inter(fontSize: 11, fontWeight: _hrShowWeek ? FontWeight.w600 : FontWeight.w400, color: text)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_hrData.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('${(_hrShowWeek ? _hrWeekData : _hrData).last.bpm.round()} bpm latest', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFEF4444))),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 140,
                            child: CustomPaint(
                              size: const Size(double.infinity, 140),
                              painter: _HRDayGraphPainter(data: _hrShowWeek ? _hrWeekData : _hrData, isLight: isLight),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _hrShowWeek
                                ? [
                                    Text('Mon', style: GoogleFonts.inter(fontSize: 9, color: subtle)),
                                    Text('Tue', style: GoogleFonts.inter(fontSize: 9, color: subtle)),
                                    Text('Wed', style: GoogleFonts.inter(fontSize: 9, color: subtle)),
                                    Text('Thu', style: GoogleFonts.inter(fontSize: 9, color: subtle)),
                                    Text('Fri', style: GoogleFonts.inter(fontSize: 9, color: subtle)),
                                    Text('Sat', style: GoogleFonts.inter(fontSize: 9, color: subtle)),
                                    Text('Sun', style: GoogleFonts.inter(fontSize: 9, color: subtle)),
                                  ]
                                : [
                                    Text('12 AM', style: GoogleFonts.inter(fontSize: 9, color: subtle)),
                                    Text('6 AM', style: GoogleFonts.inter(fontSize: 9, color: subtle)),
                                    Text('12 PM', style: GoogleFonts.inter(fontSize: 9, color: subtle)),
                                    Text('6 PM', style: GoogleFonts.inter(fontSize: 9, color: subtle)),
                                    Text('Now', style: GoogleFonts.inter(fontSize: 9, color: subtle)),
                                  ],
                          ),
                          if (!HealthKitService.instance.isAuthorized) ...[
                            const SizedBox(height: 6),
                            Text('Demo data — connect Apple Health for real readings', style: GoogleFonts.inter(fontSize: 10, color: subtle, fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Day's Performance ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Text("Today's Performance", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: WorkoutStatsGraphs(),
                  ),
                ),

                // ── Recent Workouts ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Row(
                      children: [
                        Text('Recent Workouts', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/workouts'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text('Log', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: BlocBuilder<WorkoutBloc, WorkoutState>(
                      builder: (context, ws) {
                        if (ws is! WorkoutLoaded || ws.recentWorkouts.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: border),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.fitness_center, color: subtle, size: 28),
                                const SizedBox(height: 8),
                                Text('No workouts logged yet', style: GoogleFonts.inter(fontSize: 13, color: subtle)),
                              ],
                            ),
                          );
                        }
                        return Column(
                          children: ws.recentWorkouts.take(5).map((w) {
                            final color = w.workoutType?.categoryColor ?? const Color(0xFF8B5CF6);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(w.workoutType?.icon ?? Icons.fitness_center, color: color, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(w.workoutName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
                                        Text('${w.durationMinutes} min', style: GoogleFonts.inter(fontSize: 11, color: subtle)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${w.caloriesBurned}', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444))),
                                      Text('cal', style: GoogleFonts.inter(fontSize: 10, color: subtle)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ),

                // ── Privacy Note ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFF0F4FF) : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined, color: subtle, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'All health data stays on your device. Nothing is uploaded to our servers.',
                              style: GoogleFonts.inter(fontSize: 11, color: subtle, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _tile(IconData icon, Color color, String value, String label, String sub, Color surface, Color text, Color subtle, Color border) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: text)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: subtle)),
            Text(sub, style: GoogleFonts.inter(fontSize: 10, color: subtle.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  Widget _compactStat(IconData icon, Color color, String value, String label, String unit, Color surface, Color text, Color subtle, Color border) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: text)),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: subtle)),
            Text(unit, style: GoogleFonts.inter(fontSize: 9, color: subtle.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }

  String _fmtSteps(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
  String _fmtSleep(int m) => m >= 60 ? '${m ~/ 60}h ${m % 60}m' : '${m}m';
  String _fmtDist(double m) => m >= 1000 ? '${(m / 1000).toStringAsFixed(1)}km' : '${m.round()}m';
}

/// Heart rate graph showing readings throughout the day with time axis
class _HRDayGraphPainter extends CustomPainter {
  final List<HeartRatePoint> data;
  final bool isLight;
  _HRDayGraphPainter({required this.data, required this.isLight});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final bpms = data.map((p) => p.bpm).toList();
    final minV = bpms.reduce(min);
    final maxV = bpms.reduce(max);
    final range = maxV - minV;
    if (range == 0) return;

    // Map time to x-position (0 = midnight, 24 = now-ish)
    final dayStart = DateTime(data.first.time.year, data.first.time.month, data.first.time.day);
    final dayEnd = DateTime.now();
    final dayRange = dayEnd.difference(dayStart).inSeconds.toDouble();

    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < data.length; i++) {
      final timeFraction = data[i].time.difference(dayStart).inSeconds / (dayRange > 0 ? dayRange : 1);
      final x = timeFraction.clamp(0.0, 1.0) * size.width;
      final y = size.height - ((data[i].bpm - minV) / range) * (size.height - 16) - 8;
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);
    for (var i = 0; i < points.length - 1; i++) {
      final cp1 = Offset(points[i].dx + (points[i + 1].dx - points[i].dx) / 3, points[i].dy);
      final cp2 = Offset(points[i + 1].dx - (points[i + 1].dx - points[i].dx) / 3, points[i + 1].dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
    }

    // Line with gradient
    final linePaint = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFFF59E0B), Color(0xFFEF4444)])
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Area fill
    final fillPath = Path.from(path)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(fillPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFEF4444).withValues(alpha: 0.12),
          const Color(0xFFEF4444).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    // Zone lines
    final zoneColor = isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.06);
    final zonePaint = Paint()..color = zoneColor..strokeWidth = 0.5;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), zonePaint);
    }

    // Min/Max labels
    final maxLabel = TextPainter(
      text: TextSpan(text: '${maxV.round()}', style: TextStyle(color: isLight ? Colors.black38 : Colors.white38, fontSize: 9, fontFamily: 'Inter')),
      textDirection: TextDirection.ltr,
    )..layout();
    maxLabel.paint(canvas, const Offset(2, 0));

    final minLabel = TextPainter(
      text: TextSpan(text: '${minV.round()}', style: TextStyle(color: isLight ? Colors.black38 : Colors.white38, fontSize: 9, fontFamily: 'Inter')),
      textDirection: TextDirection.ltr,
    )..layout();
    minLabel.paint(canvas, Offset(2, size.height - 12));
  }

  @override
  bool shouldRepaint(covariant _HRDayGraphPainter old) => true;
}
