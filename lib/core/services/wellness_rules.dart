import 'models/wellness_suggestion_model.dart';
import 'wellness_context.dart';

/// Local rule engine — pattern-matches on [WellnessContext] signals
/// to generate dynamic, prioritized suggestions without any API call.
///
/// Rules are evaluated in order; matching rules emit suggestions
/// which are ranked by priority and de-duplicated by category.
class WellnessRules {
  WellnessRules._();

  /// Evaluate all rules against the given context.
  /// Returns the top suggestions sorted by priority (high first).
  static List<WellnessSuggestion> evaluate(WellnessContext ctx) {
    final suggestions = <WellnessSuggestion>[];

    // ────────────────────────────────────────────
    // SLEEP SIGNALS
    // ────────────────────────────────────────────

    if (ctx.sleepQuality != null && ctx.sleepQuality! <= 2) {
      suggestions.add(const WellnessSuggestion(
        id: 'sleep-low-quality',
        title: 'Having trouble sleeping?',
        body:
            'Poor sleep drains energy and recovery. Try the 4-7-8 breathing exercise tonight — it activates your parasympathetic nervous system and helps you fall asleep faster.',
        category: 'sleep',
        priority: 'high',
        actionRoute: '/breathing-exercise',
        actionLabel: 'Try Now',
      ));
    }

    if (ctx.sleepQuality != null && ctx.sleepQuality! <= 2 && ctx.currentHour >= 20) {
      suggestions.add(const WellnessSuggestion(
        id: 'sleep-bedtime-routine',
        title: 'Wind down before bed',
        body:
            'It\'s getting late. Avoid screens for the next 30 minutes. Try a warm shower, dim the lights, and do some gentle stretching to signal your body it\'s time to rest.',
        category: 'sleep',
        priority: 'high',
      ));
    }

    // ────────────────────────────────────────────
    // POST-WORKOUT RECOVERY
    // ────────────────────────────────────────────

    if (ctx.lastWorkoutHoursAgo != null && ctx.lastWorkoutHoursAgo! <= 3) {
      // Recent heavy workout
      if (ctx.lastWorkoutDurationMinutes != null &&
          ctx.lastWorkoutDurationMinutes! > 45) {
        suggestions.add(WellnessSuggestion(
          id: 'recovery-heavy-workout',
          title: 'Heavy session — prioritize recovery',
          body:
              'That ${ctx.lastWorkoutName ?? 'workout'} was intense! Hydrate with electrolytes, foam roll, and get quality sleep tonight. Your muscles repair during rest, not during the workout.',
          category: 'recovery',
          priority: 'high',
        ));
      }

      suggestions.add(const WellnessSuggestion(
        id: 'recovery-protein-window',
        title: 'Refuel with protein',
        body:
            'You worked out recently — your muscles are primed for nutrients. Aim for 20-40g of protein in the next hour to maximize muscle recovery and growth.',
        category: 'nutrition',
        priority: 'high',
        actionLabel: 'Log Meal',
      ));
    }

    // Muscle strain risk after aggressive workouts
    if (ctx.lastWorkoutHoursAgo != null &&
        ctx.lastWorkoutHoursAgo! <= 24 &&
        ctx.intensityPref == 'aggressive') {
      suggestions.add(const WellnessSuggestion(
        id: 'recovery-muscle-strain',
        title: 'Muscle soreness coming?',
        body:
            'After aggressive training, DOMS peaks 24-48 hours later. Light movement, foam rolling, and a warm bath with Epsom salt help. Avoid training the same muscle group for 48-72 hours.',
        category: 'recovery',
        priority: 'medium',
      ));
    }

    // ────────────────────────────────────────────
    // MOOD & MENTAL HEALTH
    // ────────────────────────────────────────────

    if (ctx.mood != null && ctx.mood! <= 2 && !ctx.meditatedToday) {
      suggestions.add(const WellnessSuggestion(
        id: 'mental-low-mood-breathe',
        title: 'Feeling low? Take a breath.',
        body:
            'A 5-minute breathing exercise can measurably shift your emotional state. It won\'t fix everything, but it creates space between you and the stress.',
        category: 'breathing',
        priority: 'high',
        actionRoute: '/breathing-exercise',
        actionLabel: 'Start Breathing',
      ));
    }

    if (ctx.mood != null && ctx.mood! <= 2 && ctx.meditatedToday) {
      suggestions.add(const WellnessSuggestion(
        id: 'mental-low-mood-journal',
        title: 'Write it out',
        body:
            'You already meditated today — great. When mood stays low, journaling helps process emotions. Write down 3 things weighing on you and 1 thing you\'re grateful for.',
        category: 'mental',
        priority: 'medium',
      ));
    }

    if (ctx.mood != null && ctx.mood! >= 4 && ctx.energy != null && ctx.energy! >= 4) {
      suggestions.add(const WellnessSuggestion(
        id: 'mental-high-energy-capitalize',
        title: 'You\'re in a great state!',
        body:
            'High mood + high energy is your peak window. This is the best time for a challenging workout, creative work, or tackling something you\'ve been putting off.',
        category: 'activity',
        priority: 'low',
      ));
    }

    // ────────────────────────────────────────────
    // NUTRITION & FUELING
    // ────────────────────────────────────────────

    if (ctx.energy != null && ctx.energy! <= 2 &&
        (ctx.todayCalories == null || ctx.todayCalories! < 500) &&
        ctx.currentHour >= 11) {
      suggestions.add(const WellnessSuggestion(
        id: 'nutrition-underfueling',
        title: 'Low energy? You might be under-fueling.',
        body:
            'It\'s past midday and your calorie intake is very low. Your body needs fuel to function. Try a balanced snack with protein and carbs — nuts with fruit, or yogurt with granola.',
        category: 'nutrition',
        priority: 'high',
        actionLabel: 'Log a Meal',
      ));
    }

    if (ctx.todayProtein != null &&
        ctx.todayProtein! < 30 &&
        ctx.todayMealCount != null &&
        ctx.todayMealCount! >= 2) {
      suggestions.add(const WellnessSuggestion(
        id: 'nutrition-low-protein',
        title: 'Your protein is low today',
        body:
            'You\'ve had meals but protein is under 30g. Protein is critical for muscle repair, satiety, and energy. Add eggs, chicken, fish, beans, or a shake to your next meal.',
        category: 'nutrition',
        priority: 'medium',
      ));
    }

    if (ctx.todayMealCount == null && ctx.currentHour >= 9 && ctx.currentHour <= 12) {
      suggestions.add(const WellnessSuggestion(
        id: 'nutrition-skip-breakfast',
        title: 'Don\'t skip breakfast',
        body:
            'It\'s mid-morning and no meals logged. A protein-rich breakfast stabilizes blood sugar, improves focus, and reduces cravings later in the day.',
        category: 'nutrition',
        priority: 'medium',
        actionLabel: 'Log Breakfast',
      ));
    }

    // ────────────────────────────────────────────
    // HYDRATION (time-based)
    // ────────────────────────────────────────────

    if (ctx.currentHour >= 7 && ctx.currentHour <= 9) {
      suggestions.add(const WellnessSuggestion(
        id: 'hydration-morning',
        title: 'Morning hydration',
        body:
            'Start your day with a full glass of water. After 6-8 hours of sleep, your body is dehydrated. Warm water with lemon is even better for digestion.',
        category: 'hydration',
        priority: 'low',
      ));
    }

    if (ctx.lastWorkoutHoursAgo != null && ctx.lastWorkoutHoursAgo! <= 2) {
      suggestions.add(const WellnessSuggestion(
        id: 'hydration-post-workout',
        title: 'Rehydrate after your workout',
        body:
            'You lose 500-1000ml of water per hour of exercise. Drink at least 500ml with electrolytes in the next hour. Dark yellow urine = you need more.',
        category: 'hydration',
        priority: 'medium',
      ));
    }

    // ────────────────────────────────────────────
    // INACTIVITY
    // ────────────────────────────────────────────

    if ((ctx.workoutsThisWeek == null || ctx.workoutsThisWeek == 0) &&
        (ctx.dayOfWeek == 'Wednesday' ||
            ctx.dayOfWeek == 'Thursday' ||
            ctx.dayOfWeek == 'Friday')) {
      suggestions.add(const WellnessSuggestion(
        id: 'activity-no-workouts-midweek',
        title: 'No workouts this week yet',
        body:
            'It\'s midweek and you haven\'t logged any movement. Even a 10-minute walk counts. Start small — momentum builds motivation.',
        category: 'activity',
        priority: 'medium',
      ));
    }

    // ────────────────────────────────────────────
    // STREAKS & CELEBRATIONS
    // ────────────────────────────────────────────

    if (ctx.currentStreak != null && ctx.currentStreak == 7) {
      suggestions.add(const WellnessSuggestion(
        id: 'celebration-7-day-streak',
        title: '🔥 7-day streak! You\'re building a habit.',
        body:
            'Research shows 7 consecutive days creates neural pathways for habit formation. Keep it going — the next milestone is 14 days.',
        category: 'celebration',
        priority: 'medium',
        isDismissible: true,
      ));
    }

    if (ctx.currentStreak != null && ctx.currentStreak! >= 30) {
      suggestions.add(const WellnessSuggestion(
        id: 'celebration-30-day-streak',
        title: '🏆 30+ day streak! Wellness is your lifestyle now.',
        body:
            'You\'ve shown up for yourself every single day for a month. This isn\'t a streak anymore — it\'s who you are. Incredible.',
        category: 'celebration',
        priority: 'high',
        isDismissible: true,
      ));
    }

    // ────────────────────────────────────────────
    // EVENING WIND-DOWN
    // ────────────────────────────────────────────

    if (ctx.currentHour >= 21 && !ctx.meditatedToday) {
      suggestions.add(const WellnessSuggestion(
        id: 'evening-meditate',
        title: 'End the day with calm',
        body:
            'A short breathing or meditation session before bed improves sleep quality. Even 3 minutes of deep breathing can lower cortisol by 20%.',
        category: 'breathing',
        priority: 'medium',
        actionRoute: '/breathing-exercise',
        actionLabel: 'Breathe',
      ));
    }

    // ────────────────────────────────────────────
    // FITNESS GOAL-SPECIFIC
    // ────────────────────────────────────────────

    if (ctx.fitnessGoal == 'loseWeight' &&
        ctx.todayCalories != null &&
        ctx.todayCalories! > 2200) {
      suggestions.add(const WellnessSuggestion(
        id: 'goal-calorie-surplus',
        title: 'Calorie intake is high today',
        body:
            'Your goal is weight loss, and today\'s calories are above maintenance. That\'s okay occasionally — just be mindful at dinner. More protein, fewer simple carbs.',
        category: 'nutrition',
        priority: 'medium',
      ));
    }

    if (ctx.fitnessGoal == 'buildMuscle' &&
        ctx.todayProtein != null &&
        ctx.todayProtein! < 50 &&
        ctx.currentHour >= 15) {
      suggestions.add(const WellnessSuggestion(
        id: 'goal-muscle-protein',
        title: 'Need more protein for muscle gain',
        body:
            'For muscle building, aim for 1.6-2.2g protein per kg bodyweight daily. You\'re under 50g by mid-afternoon. Consider a protein shake or high-protein dinner.',
        category: 'nutrition',
        priority: 'high',
        actionLabel: 'Log Meal',
      ));
    }

    // ── Sort by priority (high first) and limit to top 5 ──
    suggestions.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    // De-duplicate by category (keep highest priority per category)
    final seen = <String>{};
    final deduped = <WellnessSuggestion>[];
    for (final s in suggestions) {
      if (!seen.contains(s.category) || s.priority == 'high') {
        deduped.add(s);
        seen.add(s.category);
      }
    }

    return deduped.take(5).toList();
  }
}
