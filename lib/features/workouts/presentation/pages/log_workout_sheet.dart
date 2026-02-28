import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';
import '../../data/models/workout_models.dart';
import 'workout_summary_page.dart';

/// Bottom sheet for logging a manual workout
class LogWorkoutSheet extends StatefulWidget {
  final List<WorkoutTypeModel> workoutTypes;

  const LogWorkoutSheet({super.key, required this.workoutTypes});

  @override
  State<LogWorkoutSheet> createState() => _LogWorkoutSheetState();
}

class _LogWorkoutSheetState extends State<LogWorkoutSheet> {
  String? _selectedTypeId;
  int _durationMinutes = 30;
  DateTime _startedAt = DateTime.now();
  Timer? _estimateTimer;

  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _sheetBg = Color(0xFF1A1A1A);
  static const Color _chipBg = Color(0xFF2A2A2A);

  @override
  void dispose() {
    _estimateTimer?.cancel();
    super.dispose();
  }

  void _requestEstimate() {
    if (_selectedTypeId == null) return;
    _estimateTimer?.cancel();
    _estimateTimer = Timer(const Duration(milliseconds: 500), () {
      context.read<WorkoutBloc>().add(EstimateCalories(
        workoutTypeId: _selectedTypeId!,
        durationMinutes: _durationMinutes,
      ));
    });
  }

  void _selectType(String id) {
    setState(() => _selectedTypeId = id);
    _requestEstimate();
  }

  void _changeDuration(int delta) {
    setState(() {
      _durationMinutes = (_durationMinutes + delta).clamp(5, 300);
    });
    _requestEstimate();
  }

  void _completeWorkout() {
    if (_selectedTypeId == null) return;

    context.read<WorkoutBloc>().add(LogManualWorkout(
      workoutTypeId: _selectedTypeId!,
      durationMinutes: _durationMinutes,
      startedAt: _startedAt,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WorkoutBloc, WorkoutState>(
      listener: (context, state) {
        if (state is WorkoutLogSuccess) {
          Navigator.of(context).pop(); // Close sheet
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<WorkoutBloc>(),
                child: WorkoutSummaryPage(workout: state.workout, goals: state.updatedGoals),
              ),
            ),
          );
        } else if (state is WorkoutError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: _sheetBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'Log a Workout',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Workout Type section
                  _buildLabel('Workout Type'),
                  const SizedBox(height: 8),
                  _buildTypeChips(),
                  const SizedBox(height: 24),

                  // Duration
                  _buildLabel('Duration'),
                  const SizedBox(height: 8),
                  _buildDurationStepper(),
                  const SizedBox(height: 20),

                  // Calorie estimate
                  BlocBuilder<WorkoutBloc, WorkoutState>(
                    builder: (context, state) {
                      if (state is WorkoutLoaded && state.currentEstimate != null) {
                        return _buildCalorieEstimate(state.currentEstimate!);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 20),

                  // Time picker
                  _buildLabel('When did you start?'),
                  const SizedBox(height: 8),
                  _buildTimePicker(),
                  const SizedBox(height: 32),

                  // CTA
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _selectedTypeId != null ? _completeWorkout : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _purple.withValues(alpha: 0.3),
                        disabledForegroundColor: Colors.white54,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Complete Workout',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildTypeChips() {
    // Group by category
    final categories = <String, List<WorkoutTypeModel>>{};
    for (final t in widget.workoutTypes) {
      categories.putIfAbsent(t.category, () => []).add(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.key[0].toUpperCase() + entry.key.substring(1),
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.value.map((type) {
                final isSelected = type.id == _selectedTypeId;
                return GestureDetector(
                  onTap: () => _selectType(type.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? type.categoryColor.withValues(alpha: 0.2) : _chipBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? type.categoryColor : Colors.white10,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(type.icon, size: 16, color: isSelected ? type.categoryColor : Colors.white54),
                        const SizedBox(width: 6),
                        Text(
                          type.name,
                          style: GoogleFonts.inter(
                            color: isSelected ? type.categoryColor : Colors.white70,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDurationStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _chipBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _stepperButton(Icons.remove, () => _changeDuration(-5)),
          const SizedBox(width: 24),
          Text(
            '$_durationMinutes',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Text('min', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
          const SizedBox(width: 24),
          _stepperButton(Icons.add, () => _changeDuration(5)),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _purple.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _purple, size: 20),
      ),
    );
  }

  Widget _buildCalorieEstimate(CalorieEstimate estimate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFF6B6B).withValues(alpha: 0.12), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: Color(0xFFFF6B6B), size: 28),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '~${estimate.caloriesBurned} calories',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFF6B6B),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${estimate.workoutName} · ${estimate.durationMinutes} min · ${estimate.weightKg.toStringAsFixed(0)} kg',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker() {
    final hour = _startedAt.hour > 12 ? _startedAt.hour - 12 : (_startedAt.hour == 0 ? 12 : _startedAt.hour);
    final amPm = _startedAt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = 'Today, $hour:${_startedAt.minute.toString().padLeft(2, '0')} $amPm';

    return GestureDetector(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_startedAt),
        );
        if (time != null) {
          setState(() {
            _startedAt = DateTime(
              _startedAt.year,
              _startedAt.month,
              _startedAt.day,
              time.hour,
              time.minute,
            );
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _chipBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(timeStr, style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
            ),
            const Icon(Icons.access_time, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }
}
