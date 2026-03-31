import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../../data/models/workout_models.dart';
import '../widgets/workout_stats_graphs.dart';

/// Post-workout summary screen
/// Shows calories burned, duration, type, mood selector, note, and weekly progress
class WorkoutSummaryPage extends StatefulWidget {
  final WorkoutLogModel workout;
  final List<GoalProgress> goals;

  const WorkoutSummaryPage({
    super.key,
    required this.workout,
    this.goals = const [],
  });

  @override
  State<WorkoutSummaryPage> createState() => _WorkoutSummaryPageState();
}

class _WorkoutSummaryPageState extends State<WorkoutSummaryPage>
    with SingleTickerProviderStateMixin {
  String? _selectedMood;
  final _noteController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _card = Color(0xFF1A1A1A);

  final _moods = const [
    {'key': 'great', 'emoji': '', 'label': 'Great'},
    {'key': 'good', 'emoji': '', 'label': 'Good'},
    {'key': 'okay', 'emoji': '', 'label': 'Okay'},
    {'key': 'tired', 'emoji': '', 'label': 'Tired'},
    {'key': 'exhausted', 'emoji': '', 'label': 'Exhausted'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _done() {
    // Refresh workout data and go back to hub
    context.read<WorkoutBloc>().add(const RefreshWorkoutData());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Success icon
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 40),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Workout Complete!',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Main stats card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Calories
                    Text(
                      ' ${widget.workout.caloriesBurned}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFF6B6B),
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'calories burned',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                    ),
                    const SizedBox(height: 20),

                    // Duration + Type
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatChip(
                          '${widget.workout.durationMinutes} min',
                          'duration',
                          Icons.timer,
                        ),
                        const SizedBox(width: 16),
                        _buildStatChip(
                          widget.workout.workoutName,
                          'type',
                          widget.workout.workoutType?.icon ?? Icons.fitness_center,
                        ),
                      ],
                    ),

                    // (Apple Health extras removed — health data is local-only)
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Mood selector
              Text(
                'How are you feeling?',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _moods.map((mood) {
                  final isSelected = _selectedMood == mood['key'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = mood['key']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _purple.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _purple : Colors.white10,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(mood['emoji']!, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 2),
                          Text(
                            mood['label']!,
                            style: GoogleFonts.inter(
                              color: isSelected ? _purple : Colors.white38,
                              fontSize: 9,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Note field
              TextField(
                controller: _noteController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Add a note (optional)',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                  filled: true,
                  fillColor: _card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 24),

              // Weekly progress
              if (widget.goals.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Progress',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      ...widget.goals.map((goal) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${goal.label}: ${goal.currentValue} / ${goal.targetValue}',
                                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  '${goal.progressPercent}%',
                                  style: GoogleFonts.inter(
                                    color: goal.isComplete ? Colors.green : goal.color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (goal.progressPercent / 100).clamp(0.0, 1.0),
                                backgroundColor: goal.color.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation(
                                  goal.isComplete ? Colors.green : goal.color,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Workout performance graphs
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: WorkoutStatsGraphs(),
              ),

              // Done button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _done,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }
}
