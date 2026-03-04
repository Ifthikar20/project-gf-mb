import 'package:flutter/material.dart';

/// A single nutrition/wellness tip card
class NutritionTip {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final String category; // hydration, pre-workout, post-workout, sleep, general

  const NutritionTip({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.category,
  });
}

/// Static curated nutrition tips — no API needed
class NutritionTipsData {
  NutritionTipsData._();

  /// Get a daily tip based on today's date (deterministic rotation)
  static NutritionTip getTipOfTheDay() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return allTips[dayOfYear % allTips.length];
  }

  /// Get tips by category
  static List<NutritionTip> getByCategory(String category) {
    return allTips.where((t) => t.category == category).toList();
  }

  static const List<NutritionTip> allTips = [
    // ── Hydration ──
    NutritionTip(
      title: 'Start your day with water',
      body: 'Drink a full glass of water first thing in the morning to kickstart your metabolism and rehydrate after sleep.',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF3B82F6),
      category: 'hydration',
    ),
    NutritionTip(
      title: 'Electrolytes matter',
      body: 'After intense workouts, plain water isn\'t enough. Add a pinch of sea salt and lemon, or use an electrolyte mix.',
      icon: Icons.bolt_rounded,
      color: Color(0xFF0EA5E9),
      category: 'hydration',
    ),
    NutritionTip(
      title: 'Hydration check',
      body: 'Your urine color is the best hydration indicator — aim for pale yellow. Dark yellow means you need more fluids.',
      icon: Icons.water_drop_outlined,
      color: Color(0xFF06B6D4),
      category: 'hydration',
    ),

    // ── Pre-Workout ──
    NutritionTip(
      title: 'Fuel up 30 min before',
      body: 'A small snack with simple carbs — like a banana or toast with honey — gives you quick energy for your workout.',
      icon: Icons.timer_rounded,
      color: Color(0xFFF59E0B),
      category: 'pre-workout',
    ),
    NutritionTip(
      title: 'Caffeine timing',
      body: 'If you drink coffee before training, have it 30-60 minutes early. Caffeine peaks at 45 min and enhances endurance.',
      icon: Icons.coffee_rounded,
      color: Color(0xFF92400E),
      category: 'pre-workout',
    ),
    NutritionTip(
      title: 'Don\'t train on empty',
      body: 'Fasted training can work for light cardio, but strength sessions need fuel. Even a handful of nuts helps.',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFEF4444),
      category: 'pre-workout',
    ),

    // ── Post-Workout ──
    NutritionTip(
      title: 'The protein window',
      body: 'Consume 20-40g of protein within 2 hours after training. This supports muscle repair and growth.',
      icon: Icons.egg_rounded,
      color: Color(0xFF10B981),
      category: 'post-workout',
    ),
    NutritionTip(
      title: 'Carbs after cardio',
      body: 'After running or cycling, replenish glycogen with a 3:1 carb-to-protein ratio. Rice, pasta, or fruit work great.',
      icon: Icons.grain_rounded,
      color: Color(0xFFF97316),
      category: 'post-workout',
    ),
    NutritionTip(
      title: 'Recovery smoothie',
      body: 'Blend: 1 banana, 1 scoop protein, handful spinach, almond milk, ice. Fast, easy, and covers all recovery bases.',
      icon: Icons.blender_rounded,
      color: Color(0xFF8B5CF6),
      category: 'post-workout',
    ),

    // ── Sleep & Recovery ──
    NutritionTip(
      title: 'Magnesium before bed',
      body: 'Magnesium supports muscle relaxation and sleep quality. Try magnesium glycinate 30 minutes before bed.',
      icon: Icons.nightlight_rounded,
      color: Color(0xFF6366F1),
      category: 'sleep',
    ),
    NutritionTip(
      title: 'No caffeine after 2 PM',
      body: 'Caffeine has a half-life of 5-6 hours. An afternoon coffee can still be in your system at midnight.',
      icon: Icons.do_not_disturb_on_rounded,
      color: Color(0xFFDC2626),
      category: 'sleep',
    ),
    NutritionTip(
      title: 'Tart cherry juice',
      body: 'Natural source of melatonin. Two servings daily has been shown to improve sleep duration by 84 minutes.',
      icon: Icons.local_drink_rounded,
      color: Color(0xFFBE185D),
      category: 'sleep',
    ),

    // ── General Wellness ──
    NutritionTip(
      title: 'Eat the rainbow',
      body: 'Different colored fruits and vegetables contain different phytonutrients. Aim for 5 colors on your plate daily.',
      icon: Icons.palette_rounded,
      color: Color(0xFF059669),
      category: 'general',
    ),
    NutritionTip(
      title: 'Fiber is your friend',
      body: 'Most people only get half the recommended 25-38g of fiber daily. Add beans, oats, or berries to close the gap.',
      icon: Icons.eco_rounded,
      color: Color(0xFF16A34A),
      category: 'general',
    ),
    NutritionTip(
      title: 'Healthy fats are essential',
      body: 'Don\'t fear fat — avocado, olive oil, nuts, and fatty fish support brain health, hormones, and satiety.',
      icon: Icons.favorite_rounded,
      color: Color(0xFFEC4899),
      category: 'general',
    ),
    NutritionTip(
      title: 'Protein at every meal',
      body: 'Spread protein intake across meals for better absorption. 20-30g per meal is optimal for most adults.',
      icon: Icons.restaurant_menu_rounded,
      color: Color(0xFF14B8A6),
      category: 'general',
    ),
    NutritionTip(
      title: 'Mindful eating',
      body: 'Eating slowly and without screens helps you recognize fullness cues. It takes 20 minutes for satiety signals to kick in.',
      icon: Icons.self_improvement_rounded,
      color: Color(0xFF7C3AED),
      category: 'general',
    ),
    NutritionTip(
      title: 'Meal prep saves the week',
      body: 'Spending 1-2 hours on Sunday prepping proteins and vegetables sets you up for healthy choices all week.',
      icon: Icons.kitchen_rounded,
      color: Color(0xFFD97706),
      category: 'general',
    ),
  ];
}
