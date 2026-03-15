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
import 'food_scan_sheet.dart';
import 'barcode_scan_page.dart';
import '../../../advisor/presentation/widgets/advisor_suggestion_section.dart';

/// Cal tab — clean, minimal daily nutrition dashboard
class NourishPage extends StatefulWidget {
  const NourishPage({super.key});

  @override
  State<NourishPage> createState() => _NourishPageState();
}

class _NourishPageState extends State<NourishPage> {
  int _scanMode = 0; // 0 = food, 1 = barcode

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

  void _openFoodScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<DietBloc>(),
        child: const FoodScanSheet(),
      ),
    );
  }

  void _openBarcodeScanner() {
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

  void _openScanner() {
    if (_scanMode == 0) {
      _openFoodScanner();
    } else {
      _openBarcodeScanner();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isLight = themeState.isLight;

        final bgColor = ThemeColors.background(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final borderColor = ThemeColors.border(mode);

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            bottom: false,
            child: BlocBuilder<DietBloc, DietState>(
              builder: (context, state) {
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Header ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Text(
                          'Calories',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // ── Unified Scanner Card ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildScannerCard(
                          isLight: isLight,
                          surfaceColor: surfaceColor,
                          textColor: textColor,
                          textSecondary: textSecondary,
                          borderColor: borderColor,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // ── AI suggestions ──
                    const SliverToBoxAdapter(
                      child: AdvisorSuggestionSection(tabFilter: 'nourish'),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // ── Macro rings ──
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
                          child: _buildEmptyRings(
                              textColor, textSecondary, surfaceColor, borderColor),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // ── Tip of the day ──
                    if (state is DietLoaded)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildTipCard(state, textColor, textSecondary),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // ── Today's Meals ──
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
                            GestureDetector(
                              onTap: _openLogMeal,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add,
                                        color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Log meal',
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
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 10)),

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
                          child: _buildEmptyMeals(
                              textColor, textSecondary, surfaceColor, borderColor),
                        ),
                      ),

                    // Bottom padding
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

  // ─────────────────────────────────
  // Unified Scanner Card
  // One camera area, toggle between Food Scan and Barcode
  // ─────────────────────────────────
  Widget _buildScannerCard({
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isLight ? 0.04 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Toggle: Food Scan | Barcode
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: isLight
                    ? const Color(0xFFF3F4F6)
                    : const Color(0xFF252525),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildToggle(
                    label: 'Food Scan',
                    icon: Icons.camera_alt_rounded,
                    index: 0,
                    isLight: isLight,
                    textColor: textColor,
                    textSecondary: textSecondary,
                  ),
                  _buildToggle(
                    label: 'Barcode',
                    icon: Icons.qr_code_scanner_rounded,
                    index: 1,
                    isLight: isLight,
                    textColor: textColor,
                    textSecondary: textSecondary,
                  ),
                ],
              ),
            ),
          ),
          // Camera area
          GestureDetector(
            onTap: _openScanner,
            child: Container(
              margin: const EdgeInsets.all(14),
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _scanMode == 0
                      ? [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)]
                      : [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Corner scan brackets
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: CustomPaint(
                        painter: _ScanBracketPainter(),
                      ),
                    ),
                  ),
                  // Icon + text
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _scanMode == 0
                              ? Icons.camera_alt_rounded
                              : Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _scanMode == 0
                            ? 'Tap to scan food'
                            : 'Tap to scan barcode',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _scanMode == 0
                            ? 'AI estimates calories & ingredients'
                            : 'Read nutrition from product label',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String label,
    required IconData icon,
    required int index,
    required bool isLight,
    required Color textColor,
    required Color textSecondary,
  }) {
    final selected = _scanMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _scanMode = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected
                ? (isLight ? Colors.white : const Color(0xFF333333))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: selected ? textColor : textSecondary),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? textColor : textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRings(
      Color textColor, Color subtleColor, Color surfaceColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.restaurant_menu_rounded,
              size: 40, color: subtleColor),
          const SizedBox(height: 10),
          Text(
            'No meals logged yet',
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Scan food or log a meal to get started',
            style: GoogleFonts.inter(fontSize: 13, color: subtleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMeals(
      Color textColor, Color subtleColor, Color surfaceColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.fastfood_rounded, size: 28, color: subtleColor),
          const SizedBox(height: 6),
          Text(
            'Log your meals to see them here',
            style: GoogleFonts.inter(fontSize: 13, color: subtleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(
      DietLoaded state, Color textColor, Color textSecondary) {
    final tip = state.tipOfTheDay;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tip.color.withOpacity(0.12),
            tip.color.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tip.color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: tip.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(tip.icon, color: tip.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Tip',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: tip.color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
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
                    color: textSecondary,
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

/// Draws corner brackets for the scan area
class _ScanBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 24.0;

    // Top-left
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, len), paint);
    // Top-right
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, len), paint);
    // Bottom-left
    canvas.drawLine(
        Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height - len), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
