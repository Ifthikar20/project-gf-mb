import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../bloc/diet_bloc.dart';
import '../bloc/diet_event.dart';
import '../bloc/diet_state.dart';
import '../widgets/meal_timeline_card.dart';
import '../widgets/nutrition_charts.dart';
import 'log_meal_sheet.dart';
import 'food_scan_sheet.dart';

/// Calories tab — charts, meal list, camera button in title bar.
class CaloriesPage extends StatefulWidget {
  const CaloriesPage({super.key});

  @override
  State<CaloriesPage> createState() => _CaloriesPageState();
}

class _CaloriesPageState extends State<CaloriesPage> {
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
                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: [
                    // ── Title + Camera button ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Calories',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: text,
                          ),
                        ),
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
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Charts ──
                    if (state is DietLoaded) ...[
                      NutritionCharts(
                        todaySummary: state.summary,
                        rangeSummaries: state.rangeSummaries ?? const {},
                        chartDays: state.chartDays ?? 7,
                        onRangeChanged: (days) {
                          context.read<DietBloc>().add(LoadMealsForRange(days: days));
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Today's Meals header ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today\'s Meals',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: text,
                          ),
                        ),
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
                                Text(
                                  'Log',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Meal list
                    if (state is DietLoaded && state.meals.isNotEmpty)
                      ...state.meals.map((meal) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: MealTimelineCard(
                              meal: meal,
                              onDelete: () {
                                if (meal.key != null) {
                                  context.read<DietBloc>().add(DeleteMeal(key: meal.key!));
                                }
                              },
                            ),
                          )),

                    // Empty state
                    if (state is! DietLoaded || state.meals.isEmpty)
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
                            Text(
                              'No meals logged yet',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap 📷 to scan food or + Log to add manually',
                              style: GoogleFonts.inter(fontSize: 12, color: subtle),
                            ),
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
}
