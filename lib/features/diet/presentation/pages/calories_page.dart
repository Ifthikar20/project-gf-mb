import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../bloc/diet_bloc.dart';
import '../bloc/diet_event.dart';
import '../bloc/diet_state.dart';
import '../widgets/meal_timeline_card.dart';
import '../widgets/nutrition_charts.dart';
import 'log_meal_sheet.dart';
import 'food_scan_sheet.dart';
import '../../data/models/diet_models.dart';

/// Calories tab — charts, grouped meal list with time range filter.
class CaloriesPage extends StatefulWidget {
  const CaloriesPage({super.key});

  @override
  State<CaloriesPage> createState() => _CaloriesPageState();
}

class _CaloriesPageState extends State<CaloriesPage> {
  int _mealListDays = 1; // 1=Today, 7=1W, 14=2W, 30=1M

  @override
  void initState() {
    super.initState();
    final bloc = context.read<DietBloc>();
    if (bloc.state is DietInitial) {
      bloc.add(LoadTodayMeals());
    }
  }

  void _openScanner() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<DietBloc>(),
          child: const FoodScanSheet(),
        ),
      ),
    );
  }

  void _openLogMeal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<DietBloc>(),
        child: const LogMealSheet(),
      ),
    );
  }

  void _showGoalEditor(BuildContext context, int currentGoal) {
    final controller = TextEditingController(text: '$currentGoal');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
        final text = isDark ? Colors.white : Colors.black;
        final subtle = isDark ? Colors.white54 : Colors.black54;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Calorie Goal',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: text)),
                const SizedBox(height: 6),
                Text('How many calories do you want to consume per day?',
                    style: GoogleFonts.inter(fontSize: 13, color: subtle)),
                const SizedBox(height: 20),
                // Quick presets
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [1500, 1800, 2000, 2200, 2500, 3000].map((v) {
                    final isSelected = controller.text == '$v';
                    return GestureDetector(
                      onTap: () => controller.text = '$v',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF8B5CF6)
                              : (isDark ? Colors.white10 : const Color(0xFFF0F0F0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('$v',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : text,
                            )),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Custom input
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: text),
                  decoration: InputDecoration(
                    suffix: Text('cal', style: GoogleFonts.inter(fontSize: 16, color: subtle)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: subtle.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Save button
                GestureDetector(
                  onTap: () {
                    final goal = int.tryParse(controller.text) ?? 2000;
                    final clamped = goal.clamp(500, 10000);
                    this.context.read<DietBloc>().add(SetCalorieGoal(goal: clamped));
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text('Set Goal',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _setMealRange(int days) {
    setState(() => _mealListDays = days);
    context.read<DietBloc>().add(LoadMealList(days: days));
  }

  /// Group meals by scanId. Null scanId → standalone card.
  List<List<MealLog>> _groupMeals(List<MealLog> meals) {
    final groups = <String, List<MealLog>>{};
    final standalones = <List<MealLog>>[];

    for (final meal in meals) {
      if (meal.scanId != null) {
        groups.putIfAbsent(meal.scanId!, () => []).add(meal);
      } else {
        standalones.add([meal]);
      }
    }

    final result = <List<MealLog>>[];
    result.addAll(groups.values);
    result.addAll(standalones);

    // Sort groups by first item's timestamp (newest first)
    result.sort((a, b) => b.first.timestamp.compareTo(a.first.timestamp));
    return result;
  }

  /// Group meals by date for multi-day views
  Map<String, List<List<MealLog>>> _groupByDate(List<MealLog> meals) {
    final byDate = <String, List<MealLog>>{};
    for (final meal in meals) {
      final key = DateFormat('yyyy-MM-dd').format(meal.timestamp);
      byDate.putIfAbsent(key, () => []).add(meal);
    }

    final result = <String, List<List<MealLog>>>{};
    for (final entry in byDate.entries) {
      result[entry.key] = _groupMeals(entry.value);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isLight = themeState.isLight;
        final bg = isLight ? const Color(0xFFF8F8FA) : const Color(0xFF111111);
        final card = isLight ? Colors.white : const Color(0xFF1A1A1A);
        final text = isLight ? Colors.black : Colors.white;
        final subtle = isLight ? Colors.black45 : Colors.white38;
        final border = isLight ? const Color(0xFFE8E8EC) : const Color(0xFF2A2A2A);

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            bottom: false,
            child: BlocBuilder<DietBloc, DietState>(
              builder: (context, state) {
                final meals = state is DietLoaded
                    ? (_mealListDays == 1 ? state.meals : state.mealListItems)
                    : <MealLog>[];

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: [
                    // ── Title + Camera button ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Calories',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: text,
                            )),
                        Row(
                          children: [
                            // Camera button
                            GestureDetector(
                              onTap: _openScanner,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    color: Colors.white, size: 22),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Daily Calorie Goal Card ──
                    if (state is DietLoaded)
                      _CalorieGoalCard(
                        summary: state.summary,
                        isLight: isLight,
                        onEditGoal: () => _showGoalEditor(context, state.summary.calorieGoal),
                      ),

                    const SizedBox(height: 20),

                    // ── Charts ──
                    if (state is DietLoaded) ...[
                      NutritionCharts(
                        todaySummary: state.summary,
                        rangeSummaries: state.rangeSummaries,
                        chartDays: state.chartDays,
                        onRangeChanged: (days) {
                          context.read<DietBloc>().add(LoadMealsForRange(days: days));
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Meals header + time range tabs ──
                    Row(
                      children: [
                        Text('Meals',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: text,
                            )),
                        const Spacer(),
                        // Time range pills
                        _rangePill('Today', 1, text, subtle, isLight),
                        const SizedBox(width: 6),
                        _rangePill('1W', 7, text, subtle, isLight),
                        const SizedBox(width: 6),
                        _rangePill('2W', 14, text, subtle, isLight),
                        const SizedBox(width: 6),
                        _rangePill('1M', 30, text, subtle, isLight),
                        const SizedBox(width: 10),
                        // Log button
                        GestureDetector(
                          onTap: _openLogMeal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text('Log',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Meal list ──
                    if (meals.isNotEmpty)
                      ..._buildMealList(meals, text, subtle, border, isLight),

                    // ── Empty state ──
                    if (meals.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.restaurant_rounded, size: 32, color: subtle),
                            const SizedBox(height: 8),
                            Text('No meals logged yet',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: text,
                                )),
                            const SizedBox(height: 4),
                            Text('Tap 📷 to scan food or + Log to add manually',
                                style: GoogleFonts.inter(fontSize: 12, color: subtle)),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Build meal list — grouped by date if multi-day, or just grouped by scanId
  List<Widget> _buildMealList(
      List<MealLog> meals, Color text, Color subtle, Color border, bool isLight) {
    if (_mealListDays == 1) {
      // Today — just group by scanId
      final groups = _groupMeals(meals);
      return groups
          .map((group) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MealGroupCard(
                  items: group,
                  onDelete: () {
                    for (final meal in group) {
                      if (meal.key != null) {
                        context.read<DietBloc>().add(DeleteMeal(key: meal.key!));
                      }
                    }
                  },
                ),
              ))
          .toList();
    }

    // Multi-day — group by date, then by scanId
    final byDate = _groupByDate(meals);
    final sortedDates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
    final widgets = <Widget>[];

    for (final dateKey in sortedDates) {
      final date = DateTime.parse(dateKey);
      final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateKey;
      final label = isToday
          ? 'Today'
          : DateFormat('EEEE, MMM d').format(date);

      // Date header
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: subtle,
            )),
      ));

      // Meal groups for this date
      for (final group in byDate[dateKey]!) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MealGroupCard(
            items: group,
            onDelete: () {
              for (final meal in group) {
                if (meal.key != null) {
                  context.read<DietBloc>().add(DeleteMeal(key: meal.key!));
                }
              }
            },
          ),
        ));
      }
    }
    return widgets;
  }

  Widget _rangePill(String label, int days, Color txtColor, Color subtle, bool isLight) {
    final active = _mealListDays == days;
    return GestureDetector(
      onTap: () => _setMealRange(days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? (isLight ? Colors.black : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: active ? null : Border.all(color: subtle.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active
                  ? (isLight ? Colors.white : Colors.black)
                  : subtle,
            )),
      ),
    );
  }
}

/// Compact calorie goal bar — Cal.ai style
class _CalorieGoalCard extends StatelessWidget {
  final DailyNutritionSummary summary;
  final bool isLight;
  final VoidCallback onEditGoal;

  const _CalorieGoalCard({
    required this.summary,
    required this.isLight,
    required this.onEditGoal,
  });

  @override
  Widget build(BuildContext context) {
    final consumed = summary.totalCalories;
    final goal = summary.calorieGoal;
    final remaining = (goal - consumed).clamp(0, goal);
    final progress = summary.calorieProgress.clamp(0.0, 1.0);
    final isOver = consumed > goal;

    final bg = isLight ? Colors.white : const Color(0xFF1A1A1A);
    final text = isLight ? Colors.black : Colors.white;
    final subtle = isLight ? Colors.black45 : Colors.white38;
    final border = isLight ? const Color(0xFFE8E8EC) : const Color(0xFF2A2A2A);
    final accentColor = isOver ? const Color(0xFFEF4444) : const Color(0xFF22C55E);

    return GestureDetector(
      onTap: onEditGoal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            // Top row: label + remaining
            Row(
              children: [
                Icon(Icons.local_fire_department, color: accentColor, size: 16),
                const SizedBox(width: 6),
                Text('$consumed', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                Text(' / $goal cal', style: GoogleFonts.inter(fontSize: 13, color: subtle)),
                const Spacer(),
                Text(
                  isOver ? '+${consumed - goal}' : '$remaining left',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: accentColor),
                ),
                const SizedBox(width: 4),
                Icon(Icons.edit_outlined, size: 12, color: subtle),
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isLight ? Colors.black.withOpacity(0.06) : Colors.white10,
                valueColor: AlwaysStoppedAnimation(accentColor),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
