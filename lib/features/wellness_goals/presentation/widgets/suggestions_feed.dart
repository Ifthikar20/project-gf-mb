import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/fitness_profile_model.dart';
import '../../data/recovery_suggestions.dart';

/// Suggestions feed for the home page.
/// Shows recovery/nutrition/rest suggestions based on the previous workout.
/// Falls back to an empty state if no recent workout.
class SuggestionsFeed extends StatefulWidget {
  const SuggestionsFeed({super.key});

  @override
  State<SuggestionsFeed> createState() => _SuggestionsFeedState();
}

class _SuggestionsFeedState extends State<SuggestionsFeed> {
  List<SuggestionItem> _suggestions = [];
  String _workoutName = '';
  bool _hasSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      final box = await Hive.openBox('workout_feedback');
      final category = box.get('last_workout_category') as String?;
      final intensityIdx = box.get('last_workout_intensity') as int?;
      final dateStr = box.get('last_workout_date') as String?;
      final name = box.get('last_workout_name') as String?;

      if (category == null || intensityIdx == null || dateStr == null) {
        return;
      }

      final workoutDate = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(workoutDate).inHours;

      // Show suggestions for up to 48 hours after workout
      if (diff > 48) return;

      final intensity = WorkoutIntensity.values[intensityIdx.clamp(0, 2)];
      final suggestions = RecoverySuggestions.getSuggestions(
        workoutCategory: category,
        intensity: intensity,
      );

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _workoutName = name ?? 'Workout';
          _hasSuggestions = suggestions.isNotEmpty;
        });
      }
    } catch (_) {
      // Silent fail -- just don't show suggestions
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasSuggestions) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleColor = isDark ? Colors.white38 : Colors.black38;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your next steps',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Based on your $_workoutName session',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: subtleColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Suggestion cards (show top 4)
        ...(_suggestions.take(4).map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SuggestionCard(suggestion: s, isDark: isDark),
            ))),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final SuggestionItem suggestion;
  final bool isDark;

  const _SuggestionCard({required this.suggestion, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleColor = isDark ? Colors.white38 : Colors.black38;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: suggestion.color.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(suggestion.icon, color: suggestion.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: suggestion.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        suggestion.category.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: suggestion.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  suggestion.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: subtleColor,
                    height: 1.35,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
