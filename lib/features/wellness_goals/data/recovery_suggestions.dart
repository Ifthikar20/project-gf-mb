import 'package:flutter/material.dart';
import 'models/fitness_profile_model.dart';

/// A single suggestion card for recovery, nutrition, or rest
class SuggestionItem {
  final String title;
  final String description;
  final IconData icon;
  final String category; // recovery, nutrition, rest, stretch
  final Color color;

  const SuggestionItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.color,
  });
}

/// Static knowledge base for workout recovery and nutrition suggestions.
/// No API calls -- all data is built-in.
class RecoverySuggestions {
  RecoverySuggestions._();

  /// Get recovery suggestions based on workout category and intensity.
  static List<SuggestionItem> getSuggestions({
    required String workoutCategory,
    required WorkoutIntensity intensity,
  }) {
    final recovery = _recoverySuggestions[workoutCategory] ?? _recoverySuggestions['cardio']!;
    final nutrition = _nutritionSuggestions[workoutCategory] ?? _nutritionSuggestions['cardio']!;
    final rest = _restSuggestions[intensity] ?? _restSuggestions[WorkoutIntensity.moderate]!;

    final suggestions = <SuggestionItem>[];

    // Always show nutrition first
    suggestions.addAll(nutrition);

    // Recovery depth depends on intensity
    switch (intensity) {
      case WorkoutIntensity.calm:
        // Light: just stretching
        suggestions.add(recovery.first);
        break;
      case WorkoutIntensity.moderate:
        // Moderate: stretching + 1 recovery
        suggestions.addAll(recovery.take(2));
        suggestions.add(rest.first);
        break;
      case WorkoutIntensity.aggressive:
        // Aggressive: full recovery plan
        suggestions.addAll(recovery);
        suggestions.addAll(rest);
        break;
    }

    return suggestions;
  }

  /// Nutrition tips mapped by workout category
  static final Map<String, List<SuggestionItem>> _nutritionSuggestions = {
    'cardio': [
      const SuggestionItem(
        title: 'Refuel with carbs + protein',
        description: 'After cardio, eat a 3:1 ratio of carbs to protein within 30 minutes. Try a banana with peanut butter or a recovery smoothie.',
        icon: Icons.restaurant_rounded,
        category: 'nutrition',
        color: Color(0xFF10B981),
      ),
      const SuggestionItem(
        title: 'Hydrate well',
        description: 'Replace fluids lost during your cardio session. Aim for 500ml of water with electrolytes in the next hour.',
        icon: Icons.water_drop_rounded,
        category: 'nutrition',
        color: Color(0xFF3B82F6),
      ),
    ],
    'strength': [
      const SuggestionItem(
        title: 'High protein meal',
        description: 'After strength training, prioritize protein -- 20-40g within an hour. Chicken, eggs, or a protein shake works great.',
        icon: Icons.restaurant_rounded,
        category: 'nutrition',
        color: Color(0xFF10B981),
      ),
      const SuggestionItem(
        title: 'Complex carbs for recovery',
        description: 'Pair your protein with complex carbs like sweet potato or brown rice to replenish glycogen stores.',
        icon: Icons.grain_rounded,
        category: 'nutrition',
        color: Color(0xFFF59E0B),
      ),
    ],
    'flexibility': [
      const SuggestionItem(
        title: 'Light anti-inflammatory foods',
        description: 'Support flexibility gains with anti-inflammatory foods: berries, leafy greens, nuts, and fatty fish.',
        icon: Icons.eco_rounded,
        category: 'nutrition',
        color: Color(0xFF10B981),
      ),
    ],
    'mindfulness': [
      const SuggestionItem(
        title: 'Herbal tea or warm water',
        description: 'After a mindfulness session, sip chamomile or green tea to extend the calm state.',
        icon: Icons.coffee_rounded,
        category: 'nutrition',
        color: Color(0xFF8B5CF6),
      ),
    ],
  };

  /// Recovery exercises mapped by workout category
  static final Map<String, List<SuggestionItem>> _recoverySuggestions = {
    'cardio': [
      const SuggestionItem(
        title: 'Cool-down walk',
        description: '5-10 minute easy walk to gradually lower your heart rate. Avoid stopping suddenly after intense cardio.',
        icon: Icons.directions_walk_rounded,
        category: 'recovery',
        color: Color(0xFF6366F1),
      ),
      const SuggestionItem(
        title: 'Leg stretches',
        description: 'Hold hamstring, quad, and calf stretches for 30 seconds each. Focus on the muscle groups you used most.',
        icon: Icons.accessibility_new_rounded,
        category: 'stretch',
        color: Color(0xFFA78BFA),
      ),
      const SuggestionItem(
        title: 'Foam rolling',
        description: 'Spend 5 minutes foam rolling your calves, quads, and IT bands to reduce soreness tomorrow.',
        icon: Icons.sports_rounded,
        category: 'recovery',
        color: Color(0xFFEC4899),
      ),
    ],
    'strength': [
      const SuggestionItem(
        title: 'Targeted stretching',
        description: 'Stretch the muscle groups you trained for 30-60 seconds each. This reduces DOMS and improves recovery.',
        icon: Icons.accessibility_new_rounded,
        category: 'stretch',
        color: Color(0xFFA78BFA),
      ),
      const SuggestionItem(
        title: 'Light mobility work',
        description: 'Do 5 minutes of joint circles and gentle movement for the areas you trained. Keep blood flowing without loading.',
        icon: Icons.self_improvement_rounded,
        category: 'recovery',
        color: Color(0xFF6366F1),
      ),
      const SuggestionItem(
        title: 'Cold or contrast shower',
        description: 'Try a 2-minute cold shower or alternate 30s cold/warm to reduce inflammation and speed recovery.',
        icon: Icons.shower_rounded,
        category: 'recovery',
        color: Color(0xFF0EA5E9),
      ),
    ],
    'flexibility': [
      const SuggestionItem(
        title: 'Stay warm',
        description: 'Keep muscles warm after stretching -- light movement or warm clothing helps maintain flexibility gains.',
        icon: Icons.thermostat_rounded,
        category: 'recovery',
        color: Color(0xFFF97316),
      ),
    ],
    'mindfulness': [
      const SuggestionItem(
        title: 'Mindful breathing',
        description: 'Continue with 2 minutes of deep belly breathing to carry the calm into your next activity.',
        icon: Icons.air_rounded,
        category: 'recovery',
        color: Color(0xFF8B5CF6),
      ),
    ],
  };

  /// Rest suggestions based on intensity level
  static final Map<WorkoutIntensity, List<SuggestionItem>> _restSuggestions = {
    WorkoutIntensity.calm: [
      const SuggestionItem(
        title: 'Stay active tomorrow',
        description: 'Light workouts need minimal recovery. You can train the same muscles again in 24 hours.',
        icon: Icons.check_circle_rounded,
        category: 'rest',
        color: Color(0xFF10B981),
      ),
    ],
    WorkoutIntensity.moderate: [
      const SuggestionItem(
        title: 'Rest that muscle group',
        description: 'Give those muscles 24-48 hours before training them again. You can work different muscle groups tomorrow.',
        icon: Icons.bedtime_rounded,
        category: 'rest',
        color: Color(0xFF6366F1),
      ),
    ],
    WorkoutIntensity.aggressive: [
      const SuggestionItem(
        title: '48-72 hour recovery',
        description: 'After an aggressive session, those muscles need 2-3 days to fully repair. Train different areas tomorrow.',
        icon: Icons.bedtime_rounded,
        category: 'rest',
        color: Color(0xFFEF4444),
      ),
      const SuggestionItem(
        title: 'Prioritize sleep tonight',
        description: 'Aim for 7-9 hours of sleep. Most muscle repair happens during deep sleep -- this is when you actually grow stronger.',
        icon: Icons.nightlight_rounded,
        category: 'rest',
        color: Color(0xFF6366F1),
      ),
    ],
  };
}
