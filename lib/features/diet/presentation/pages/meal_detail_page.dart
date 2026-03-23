import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/diet_models.dart';

/// Full-screen detail page for a logged meal group.
/// Shows hero image, per-item list, nutrition breakdown, warnings,
/// nutritional benefits, and calorie burn suggestions.
class MealDetailPage extends StatelessWidget {
  final List<MealLog> items;

  const MealDetailPage({super.key, required this.items});

  MealLog get _primary => items.first;

  int get _totalCal => items.fold(0, (s, m) => s + m.calories);
  int get _totalP => items.fold(0, (s, m) => s + m.proteinGrams);
  int get _totalC => items.fold(0, (s, m) => s + m.carbsGrams);
  int get _totalF => items.fold(0, (s, m) => s + m.fatGrams);
  int get _totalSugar => items.fold(0, (s, m) => s + m.sugarGrams);
  int get _totalFiber => items.fold(0, (s, m) => s + m.fiberGrams);
  int get _totalSodium => items.fold(0, (s, m) => s + m.sodiumMg);
  int get _totalCaffeine => items.fold(0, (s, m) => s + m.caffeineMg);

  /// Try local file first, then S3 URL
  bool get _hasLocalImage =>
      _primary.imagePath != null && File(_primary.imagePath!).existsSync();
  bool get _hasRemoteImage => _primary.imageUrl != null;
  bool get _hasImage => _hasLocalImage || _hasRemoteImage;

  String get _title {
    if (items.length == 1) return _primary.name;
    if (_primary.mealName != null) return _primary.mealName!;
    return '${_primary.mealType.label} · ${items.length} items';
  }

  String get _timeStr {
    final h = _primary.timestamp.hour > 12
        ? _primary.timestamp.hour - 12
        : (_primary.timestamp.hour == 0 ? 12 : _primary.timestamp.hour);
    final amPm = _primary.timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$h:${_primary.timestamp.minute.toString().padLeft(2, '0')} $amPm';
  }

  // ── JSON parsers ──

  List<Map<String, dynamic>> _parseJsonList(String? json) {
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> get _allWarnings {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final item in items) {
      for (final w in _parseJsonList(item.warningsJson)) {
        final key = '${w['type']}_${w['label']}';
        if (!seen.contains(key)) {
          seen.add(key);
          result.add(w);
        }
      }
    }
    return result;
  }

  List<Map<String, dynamic>> get _allBenefits {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final item in items) {
      for (final b in _parseJsonList(item.benefitsJson)) {
        final key = b['title'] as String? ?? '';
        if (!seen.contains(key)) {
          seen.add(key);
          result.add(b);
        }
      }
    }
    return result;
  }

  List<Map<String, dynamic>> get _allCalorieBurn {
    // Use calorie_burn from the primary (highest calorie) item
    final sorted = List<MealLog>.from(items)
      ..sort((a, b) => b.calories.compareTo(a.calories));
    return _parseJsonList(sorted.first.calorieBurnJson);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111111) : const Color(0xFFF8F8FA);
    final card = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final text = isDark ? Colors.white : Colors.black;
    final subtle = isDark ? Colors.white38 : Colors.black38;
    final border = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8EC);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero image + back button ──
          SliverAppBar(
            expandedHeight: _hasImage ? 280 : 0,
            pinned: true,
            backgroundColor: card,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
            ),
            title: Text('Meal Details',
                style: GoogleFonts.inter(
                  fontSize: 17, fontWeight: FontWeight.w700, color: text,
                )),
            flexibleSpace: _hasImage
                ? FlexibleSpaceBar(
                    background: _hasLocalImage
                        ? Image.file(
                            File(_primary.imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _remoteOrPlaceholder(isDark),
                          )
                        : _remoteOrPlaceholder(isDark),
                  )
                : null,
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title + time ──
                  Row(
                    children: [
                      _typeIcon(_primary.safeItemType, isDark),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_title,
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: text,
                                )),
                            const SizedBox(height: 2),
                            Text(
                              '${_primary.mealType.emoji} ${_primary.mealType.label} · $_timeStr',
                              style: GoogleFonts.inter(fontSize: 13, color: subtle),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Calorie hero ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text('Total Calories',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            )),
                        const SizedBox(height: 4),
                        Text('$_totalCal',
                            style: GoogleFonts.inter(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            )),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _calMacro('Protein', '${_totalP}g'),
                            _calMacro('Carbs', '${_totalC}g'),
                            _calMacro('Fat', '${_totalF}g'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Items list ──
                  if (items.length > 1) ...[
                    Text('Items',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: text,
                        )),
                    const SizedBox(height: 10),
                    ...items.map((item) => _itemRow(item, text, subtle, card, border)),
                    const SizedBox(height: 20),
                  ],

                  // ── Nutrition breakdown ──
                  Text('Nutrition Breakdown',
                      style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700, color: text,
                      )),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      children: [
                        _progressRow('Protein', '${_totalP}g', _totalP / 50, const Color(0xFF3B82F6), text, subtle),
                        _progressRow('Carbs', '${_totalC}g', _totalC / 100, const Color(0xFFF59E0B), text, subtle),
                        _progressRow('Fat', '${_totalF}g', _totalF / 65, const Color(0xFFEC4899), text, subtle),
                        _progressRow('Sugar', '${_totalSugar}g', _totalSugar / 50, const Color(0xFFF97316), text, subtle),
                        _progressRow('Fiber', '${_totalFiber}g', _totalFiber / 30, const Color(0xFF22C55E), text, subtle),
                        const SizedBox(height: 4),
                        _infoRow('Sodium', '${_totalSodium}mg', text, subtle),
                        if (_totalCaffeine > 0)
                          _infoRow('Caffeine', '${_totalCaffeine}mg', text, subtle),
                      ],
                    ),
                  ),

                  // ── Benefits ──
                  if (_allBenefits.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Nutritional Benefits',
                        style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700, color: text,
                        )),
                    const SizedBox(height: 10),
                    ..._allBenefits.map((b) => _benefitRow(b, card, border, text, subtle)),
                  ],

                  // ── Warnings ──
                  if (_allWarnings.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Health Alerts',
                        style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700, color: text,
                        )),
                    const SizedBox(height: 10),
                    ..._allWarnings.map((w) => _warningRow(w, border)),
                  ],

                  // ── Burn it off ──
                  if (_allCalorieBurn.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text('Burn it off',
                            style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w700, color: text,
                            )),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _allCalorieBurn.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) =>
                            _burnCard(_allCalorieBurn[i], card, border, text, subtle),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──

  Widget _remoteOrPlaceholder(bool isDark) {
    if (_hasRemoteImage) {
      return Image.network(
        _primary.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: isDark ? Colors.black : Colors.grey[200]),
      );
    }
    return Container(color: isDark ? Colors.black : Colors.grey[200]);
  }

  Widget _typeIcon(String type, bool isDark) {
    final IconData icon;
    final Color color;
    switch (type) {
      case 'beverage':
        icon = Icons.local_cafe_rounded;
        color = const Color(0xFF3B82F6);
        break;
      case 'liquid':
        icon = Icons.soup_kitchen_rounded;
        color = const Color(0xFF22C55E);
        break;
      default:
        icon = Icons.restaurant_rounded;
        color = const Color(0xFF8B5CF6);
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _calMacro(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.inter(
              fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white,
            )),
        Text(label,
            style: GoogleFonts.inter(
              fontSize: 11, color: Colors.white70,
            )),
      ],
    );
  }

  Widget _itemRow(MealLog item, Color text, Color subtle, Color card, Color border) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          _typeIcon(item.safeItemType, false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: text,
                    )),
                const SizedBox(height: 2),
                Text(
                  'P${item.proteinGrams}g · C${item.carbsGrams}g · F${item.fatGrams}g',
                  style: GoogleFonts.inter(fontSize: 11, color: subtle),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${item.calories} cal',
                  style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF10B981),
                  )),
              if (item.isLiquidOrBeverage)
                Text(item.isBeverage ? 'Beverage' : 'Liquid',
                    style: GoogleFonts.inter(fontSize: 10, color: subtle)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressRow(String label, String value, double ratio, Color color,
      Color text, Color subtle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: subtle))),
          SizedBox(width: 48, child: Text(value,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: text))),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color text, Color subtle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: subtle))),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: text)),
        ],
      ),
    );
  }

  Widget _benefitRow(Map<String, dynamic> b, Color card, Color border, Color text, Color subtle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          Icon(_benefitIcon(b['icon'] as String? ?? ''), size: 18, color: const Color(0xFF16A34A)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b['title'] as String? ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A),
                    )),
                if ((b['detail'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(b['detail'] as String,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF15803D), height: 1.3)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _benefitIcon(String icon) {
    switch (icon) {
      case 'protein': return Icons.fitness_center_rounded;
      case 'fiber': return Icons.grass_rounded;
      case 'vitamins': return Icons.wb_sunny_rounded;
      case 'minerals': return Icons.diamond_rounded;
      case 'antioxidants': return Icons.shield_rounded;
      case 'healthy_fats': return Icons.favorite_rounded;
      case 'energy': return Icons.bolt_rounded;
      case 'hydration': return Icons.water_drop_rounded;
      case 'probiotics': return Icons.science_rounded;
      case 'low_calorie': return Icons.trending_down_rounded;
      default: return Icons.eco_rounded;
    }
  }

  Widget _warningRow(Map<String, dynamic> w, Color border) {
    final severity = w['severity'] as String? ?? 'low';
    final Color bg, fg;

    if (severity == 'high') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    } else if (severity == 'medium') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF64748B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(_warningIcon(w['type'] as String? ?? ''), size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w['label'] as String? ?? '',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                if ((w['detail'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(w['detail'] as String,
                      style: GoogleFonts.inter(fontSize: 12, color: fg.withValues(alpha: 0.7), height: 1.3)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _warningIcon(String type) {
    switch (type) {
      case 'allergen': return Icons.warning_amber_rounded;
      case 'high_caffeine': return Icons.bolt_rounded;
      case 'high_sugar': return Icons.cake_rounded;
      case 'high_sodium': return Icons.water_drop_outlined;
      case 'high_sat_fat': return Icons.opacity_rounded;
      case 'high_calorie': return Icons.local_fire_department_rounded;
      default: return Icons.info_outline_rounded;
    }
  }

  Widget _burnCard(Map<String, dynamic> c, Color card, Color border, Color text, Color subtle) {
    final steps = c['steps'] as int?;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_burnIcon(c['icon'] as String? ?? ''), size: 22, color: const Color(0xFFF97316)),
          const SizedBox(height: 8),
          Text(c['activity'] as String? ?? '',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
          const SizedBox(height: 2),
          Text(c['duration'] as String? ?? '',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFF97316))),
          if (steps != null)
            Text('${_formatSteps(steps)} steps',
                style: GoogleFonts.inter(fontSize: 11, color: subtle)),
        ],
      ),
    );
  }

  IconData _burnIcon(String icon) {
    switch (icon) {
      case 'walking': return Icons.directions_walk_rounded;
      case 'running': return Icons.directions_run_rounded;
      case 'cycling': return Icons.directions_bike_rounded;
      case 'swimming': return Icons.pool_rounded;
      case 'yoga': return Icons.self_improvement_rounded;
      case 'jump_rope': return Icons.sports_rounded;
      case 'stairs': return Icons.stairs_rounded;
      case 'dancing': return Icons.music_note_rounded;
      case 'hiit': return Icons.timer_rounded;
      default: return Icons.fitness_center_rounded;
    }
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(steps % 1000 == 0 ? 0 : 1)}k';
    }
    return steps.toString();
  }
}
