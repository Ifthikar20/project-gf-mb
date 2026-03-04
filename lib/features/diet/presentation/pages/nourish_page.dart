import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/diet_bloc.dart';
import '../bloc/diet_event.dart';
import '../bloc/diet_state.dart';
import '../widgets/nutrition_ring_card.dart';
import '../widgets/meal_timeline_card.dart';
import 'log_meal_sheet.dart';
import '../../../advisor/presentation/widgets/advisor_suggestion_section.dart';

/// Nourish tab — daily nutrition dashboard with macro rings, meal timeline, and tips
class NourishPage extends StatefulWidget {
  const NourishPage({super.key});

  @override
  State<NourishPage> createState() => _NourishPageState();
}

class _NourishPageState extends State<NourishPage> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<DietBloc>();
    if (bloc.state is DietInitial) {
      bloc.add(LoadTodayMeals());
    }
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
        final mode = themeState.mode;
        final isVintage = themeState.isVintage;

        final bgColor = ThemeColors.background(mode);
        final textColor = isVintage ? Colors.black : Colors.white;
        final subtleColor = isVintage ? Colors.black38 : Colors.white38;

        return Scaffold(
          backgroundColor: bgColor,
          floatingActionButton: FloatingActionButton(
            onPressed: _openLogMeal,
            backgroundColor: const Color(0xFF10B981),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
          body: SafeArea(
            bottom: false,
            child: BlocBuilder<DietBloc, DietState>(
              builder: (context, state) {
                return CustomScrollView(
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nourish',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Track your daily nutrition',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: subtleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // AI nutrition suggestions
                    const SliverToBoxAdapter(
                      child: AdvisorSuggestionSection(tabFilter: 'nourish'),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),

                    // Macro rings
                    if (state is DietLoaded)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: NutritionRingCard(summary: state.summary),
                        ),
                      ),
                    if (state is! DietLoaded)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildEmptyRings(textColor, subtleColor),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // Tip of the day
                    if (state is DietLoaded)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildTipCard(state, textColor),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // Meals section header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Today\'s Meals',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            if (state is DietLoaded)
                              Text(
                                '${state.meals.length} logged',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: subtleColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // Meal list
                    if (state is DietLoaded && state.meals.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final meal = state.meals[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: MealTimelineCard(
                                  meal: meal,
                                  onDelete: () {
                                    if (meal.key != null) {
                                      context
                                          .read<DietBloc>()
                                          .add(DeleteMeal(key: meal.key!));
                                    }
                                  },
                                ),
                              );
                            },
                            childCount: state.meals.length,
                          ),
                        ),
                      ),

                    // Empty state
                    if (state is! DietLoaded ||
                        (state is DietLoaded && state.meals.isEmpty))
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildEmptyMeals(textColor, subtleColor),
                        ),
                      ),

                    // Bottom padding for nav bar
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyRings(Color textColor, Color subtleColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.restaurant_menu_rounded,
              size: 48, color: subtleColor),
          const SizedBox(height: 12),
          Text(
            'No meals logged yet',
            style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to log your first meal',
            style: GoogleFonts.inter(fontSize: 13, color: subtleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMeals(Color textColor, Color subtleColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Icon(Icons.fastfood_rounded, size: 32, color: subtleColor),
          const SizedBox(height: 8),
          Text(
            'Log your meals to see them here',
            style: GoogleFonts.inter(fontSize: 13, color: subtleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(DietLoaded state, Color textColor) {
    final tip = state.tipOfTheDay;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tip.color.withOpacity(0.15),
            tip.color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tip.color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tip.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tip.icon, color: tip.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Daily Tip',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: tip.color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tip.body,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white54,
                    height: 1.4,
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
