import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/fitness_profile_model.dart';
import '../../data/recovery_suggestions.dart';

/// Shown after completing a workout.
/// Asks about intensity and generates recovery suggestions.
class PostWorkoutFeedbackPage extends StatefulWidget {
  final String workoutName;
  final String workoutCategory; // cardio, strength, flexibility, mindfulness
  final int caloriesBurned;
  final int durationMinutes;

  const PostWorkoutFeedbackPage({
    super.key,
    required this.workoutName,
    required this.workoutCategory,
    required this.caloriesBurned,
    required this.durationMinutes,
  });

  @override
  State<PostWorkoutFeedbackPage> createState() =>
      _PostWorkoutFeedbackPageState();
}

class _PostWorkoutFeedbackPageState extends State<PostWorkoutFeedbackPage> {
  int _step = 0; // 0 = intensity, 1 = suggestions
  int _selectedIntensity = -1; // 0=calm, 1=moderate, 2=aggressive
  List<SuggestionItem> _suggestions = [];

  final _intensityOptions = [
    _IntensityOption(
      index: 0,
      label: 'Calm',
      subtitle: 'Light effort, felt easy',
      icon: Icons.spa_rounded,
      color: const Color(0xFF10B981),
    ),
    _IntensityOption(
      index: 1,
      label: 'Moderate',
      subtitle: 'Good effort, pushed a bit',
      icon: Icons.speed_rounded,
      color: const Color(0xFFF59E0B),
    ),
    _IntensityOption(
      index: 2,
      label: 'Aggressive',
      subtitle: 'Maxed out, felt the burn',
      icon: Icons.bolt_rounded,
      color: const Color(0xFFEF4444),
    ),
  ];

  void _selectIntensity(int index) {
    setState(() => _selectedIntensity = index);
  }

  Future<void> _generateSuggestions() async {
    final intensity = WorkoutIntensity.values[_selectedIntensity];

    // Save the last workout intensity for home page suggestions
    final box = await Hive.openBox('workout_feedback');
    await box.put('last_workout_category', widget.workoutCategory);
    await box.put('last_workout_intensity', _selectedIntensity);
    await box.put('last_workout_date', DateTime.now().toIso8601String());
    await box.put('last_workout_name', widget.workoutName);

    final suggestions = RecoverySuggestions.getSuggestions(
      workoutCategory: widget.workoutCategory,
      intensity: intensity,
    );

    setState(() {
      _suggestions = suggestions;
      _step = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFBFBFB);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleColor = isDark ? Colors.white38 : Colors.black38;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: _step == 0
            ? _buildIntensityStep(isDark, textColor, subtleColor)
            : _buildSuggestionsStep(isDark, textColor, subtleColor),
      ),
    );
  }

  Widget _buildIntensityStep(bool isDark, Color textColor, Color subtleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.close_rounded, color: textColor, size: 24),
          ),
          const SizedBox(height: 28),

          // Workout summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.04),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: const Color(0xFF10B981), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.workoutName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        '${widget.caloriesBurned} cal -- ${widget.durationMinutes} min',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: subtleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'How intense\nwas it?',
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This determines your recovery plan',
            style: GoogleFonts.inter(fontSize: 14, color: subtleColor),
          ),
          const SizedBox(height: 28),

          ..._intensityOptions.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _selectIntensity(option.index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _selectedIntensity == option.index
                          ? option.color.withOpacity(isDark ? 0.2 : 0.1)
                          : (isDark
                              ? const Color(0xFF1A1A1A)
                              : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedIntensity == option.index
                            ? option.color
                            : (isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.06)),
                        width: _selectedIntensity == option.index ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(option.icon, color: option.color, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.label,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                option.subtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: subtleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedIntensity == option.index)
                          Icon(Icons.check_circle_rounded,
                              color: option.color, size: 22),
                      ],
                    ),
                  ),
                ),
              )),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
                  _selectedIntensity >= 0 ? _generateSuggestions : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                disabledBackgroundColor: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.06),
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'See recovery plan',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSuggestionsStep(
      bool isDark, Color textColor, Color subtleColor) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Recovery Plan',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Suggestions list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            itemCount: _suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final s = _suggestions[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: s.color.withOpacity(isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(s.icon, color: s.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: s.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s.category.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: s.color,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.title,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.description,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: subtleColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _IntensityOption {
  final int index;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _IntensityOption({
    required this.index,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
