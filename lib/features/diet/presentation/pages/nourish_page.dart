import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../bloc/diet_bloc.dart';
import '../bloc/diet_event.dart';
import '../bloc/diet_state.dart';
import '../widgets/meal_timeline_card.dart';
import 'log_meal_sheet.dart';
import 'food_scan_sheet.dart';
import 'barcode_scan_page.dart';

/// Calories tab — minimal, stable
class NourishPage extends StatefulWidget {
  const NourishPage({super.key});

  @override
  State<NourishPage> createState() => _NourishPageState();
}

class _NourishPageState extends State<NourishPage> {
  int _mode = 0; // 0 = food, 1 = barcode

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
    if (_mode == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<DietBloc>(),
            child: const FoodScanSheet(),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<DietBloc>(),
            child: const BarcodeScanPage(),
          ),
        ),
      );
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  children: [
                    // ── Title ──
                    Text(
                      'Calories',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: text,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Toggle: Food | Barcode ──
                    Container(
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isLight
                            ? const Color(0xFFF0F0F4)
                            : const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _tab('Food', Icons.camera_alt_rounded, 0, isLight, text, subtle),
                          _tab('Barcode', Icons.qr_code_scanner_rounded, 1, isLight, text, subtle),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Scan Button ──
                    GestureDetector(
                      onTap: _openScanner,
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _mode == 0
                                ? [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)]
                                : [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _mode == 0
                                    ? Icons.camera_alt_rounded
                                    : Icons.qr_code_scanner_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _mode == 0 ? 'Tap to scan food' : 'Tap to scan barcode',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _mode == 0
                                  ? 'AI estimates calories & macros'
                                  : 'Read nutrition from product label',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Today's Summary ──
                    if (state is DietLoaded) ...[
                      _summaryRow(state, text, subtle, card, border),
                      const SizedBox(height: 24),
                    ],

                    // ── Today's Meals ──
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
                              'Scan food or log a meal to get started',
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

  // ── Tab toggle ──
  Widget _tab(String label, IconData icon, int index, bool isLight, Color text, Color subtle) {
    final active = _mode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: active
                ? (isLight ? Colors.white : const Color(0xFF333333))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: active ? text : subtle),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? text : subtle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Compact summary row ──
  Widget _summaryRow(DietLoaded state, Color text, Color subtle, Color card, Color border) {
    final s = state.summary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('${s.totalCalories}', 'cal', const Color(0xFFEF4444)),
          _divider(border),
          _summaryItem('${s.totalProtein}g', 'protein', const Color(0xFF3B82F6)),
          _divider(border),
          _summaryItem('${s.totalCarbs}g', 'carbs', const Color(0xFFF59E0B)),
          _divider(border),
          _summaryItem('${s.totalFat}g', 'fat', const Color(0xFFEC4899)),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _divider(Color color) {
    return Container(width: 1, height: 30, color: color);
  }
}
