import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';

/// Goals Setup page — sliders for weekly calorie, minutes, and workout count goals
class GoalsSetupPage extends StatefulWidget {
  const GoalsSetupPage({super.key});

  @override
  State<GoalsSetupPage> createState() => _GoalsSetupPageState();
}

class _GoalsSetupPageState extends State<GoalsSetupPage> {
  double _calorieGoal = 2000;
  double _minutesGoal = 150;
  double _countGoal = 5;
  bool _isSaving = false;

  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _card = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    // Pre-fill from existing goals
    final state = context.read<WorkoutBloc>().state;
    if (state is WorkoutLoaded) {
      for (final goal in state.goals) {
        switch (goal.goalType) {
          case 'calories_burned':
            _calorieGoal = goal.targetValue.toDouble();
            break;
          case 'active_minutes':
            _minutesGoal = goal.targetValue.toDouble();
            break;
          case 'workout_count':
            _countGoal = goal.targetValue.toDouble();
            break;
        }
      }
    }
  }

  Future<void> _saveGoals() async {
    setState(() => _isSaving = true);

    final bloc = context.read<WorkoutBloc>();
    bloc.add(SetWorkoutGoal(goalType: 'calories_burned', targetValue: _calorieGoal.round()));
    bloc.add(SetWorkoutGoal(goalType: 'active_minutes', targetValue: _minutesGoal.round()));
    bloc.add(SetWorkoutGoal(goalType: 'workout_count', targetValue: _countGoal.round()));

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Weekly Goals',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Set targets for your week.\nProgress resets every Monday.',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 28),

              // Calorie goal
              _buildGoalSlider(
                icon: Icons.local_fire_department,
                iconColor: const Color(0xFFFF6B6B),
                label: 'Calorie Goal',
                value: _calorieGoal,
                min: 500,
                max: 5000,
                divisions: 18, // 250 cal increments
                suffix: 'cal/week',
                sliderColor: const Color(0xFFFF6B6B),
                onChanged: (v) => setState(() => _calorieGoal = v),
              ),
              const SizedBox(height: 20),

              // Active minutes goal
              _buildGoalSlider(
                icon: Icons.timer,
                iconColor: const Color(0xFF4ECDC4),
                label: 'Active Minutes Goal',
                value: _minutesGoal,
                min: 30,
                max: 600,
                divisions: 19, // 30 min increments
                suffix: 'min/week',
                sliderColor: const Color(0xFF4ECDC4),
                onChanged: (v) => setState(() => _minutesGoal = v),
              ),
              const SizedBox(height: 20),

              // Workout count goal
              _buildGoalSlider(
                icon: Icons.fitness_center,
                iconColor: const Color(0xFFA78BFA),
                label: 'Workout Count Goal',
                value: _countGoal,
                min: 1,
                max: 14,
                divisions: 13,
                suffix: 'workouts',
                sliderColor: const Color(0xFFA78BFA),
                onChanged: (v) => setState(() => _countGoal = v),
              ),

              const Spacer(),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveGoals,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _purple.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Save Goals',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalSlider({
    required IconData icon,
    required Color iconColor,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required Color sliderColor,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Value display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.round().toString(),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  suffix,
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: sliderColor,
              inactiveTrackColor: sliderColor.withValues(alpha: 0.15),
              thumbColor: sliderColor,
              overlayColor: sliderColor.withValues(alpha: 0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          // Range labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${min.round()}', style: GoogleFonts.inter(color: Colors.white24, fontSize: 10)),
              Text('${max.round()}', style: GoogleFonts.inter(color: Colors.white24, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
