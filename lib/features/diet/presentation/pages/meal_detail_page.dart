import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/diet_models.dart';

/// Premium meal detail page.
class MealDetailPage extends StatelessWidget {
  final List<MealLog> items;

  const MealDetailPage({super.key, required this.items});

  MealLog get _p => items.first;

  int get _totalCal => items.fold(0, (s, m) => s + m.calories);
  int get _totalP => items.fold(0, (s, m) => s + m.proteinGrams);
  int get _totalC => items.fold(0, (s, m) => s + m.carbsGrams);
  int get _totalF => items.fold(0, (s, m) => s + m.fatGrams);
  int get _totalSugar => items.fold(0, (s, m) => s + m.sugarGrams);
  int get _totalFiber => items.fold(0, (s, m) => s + m.fiberGrams);
  int get _totalSodium => items.fold(0, (s, m) => s + m.sodiumMg);
  int get _totalCaffeine => items.fold(0, (s, m) => s + m.caffeineMg);
  int get _wellnessScore => _p.safeWellnessScore;

  Map<String, dynamic>? get _wellnessBreakdown {
    final json = _p.wellnessBreakdownJson;
    if (json == null) return null;
    try { return Map<String, dynamic>.from(jsonDecode(json) as Map); }
    catch (_) { return null; }
  }

  bool get _hasLocalImage =>
      _p.imagePath != null && File(_p.imagePath!).existsSync();
  bool get _hasRemoteImage => _p.imageUrl != null;
  bool get _hasImage => _hasLocalImage || _hasRemoteImage;

  String get _title {
    if (items.length == 1) return _p.name;
    if (_p.mealName != null) return _p.mealName!;
    return '${_p.mealType.label} · ${items.length} items';
  }

  String get _time {
    final h = _p.timestamp.hour > 12
        ? _p.timestamp.hour - 12
        : (_p.timestamp.hour == 0 ? 12 : _p.timestamp.hour);
    final amPm = _p.timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$h:${_p.timestamp.minute.toString().padLeft(2, '0')} $amPm';
  }

  List<Map<String, dynamic>> _parseJson(String? json) {
    if (json == null) return [];
    try {
      return (jsonDecode(json) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> get _warnings {
    final seen = <String>{};
    final r = <Map<String, dynamic>>[];
    for (final item in items) {
      for (final w in _parseJson(item.warningsJson)) {
        final k = '${w['type']}_${w['label']}';
        if (seen.add(k)) r.add(w);
      }
    }
    return r;
  }

  List<Map<String, dynamic>> get _benefits {
    final seen = <String>{};
    final r = <Map<String, dynamic>>[];
    for (final item in items) {
      for (final b in _parseJson(item.benefitsJson)) {
        final k = b['title'] as String? ?? '';
        if (seen.add(k)) r.add(b);
      }
    }
    return r;
  }

  List<Map<String, dynamic>> get _burns {
    final sorted = List<MealLog>.from(items)
      ..sort((a, b) => b.calories.compareTo(a.calories));
    return _parseJson(sorted.first.calorieBurnJson);
  }

  @override
  Widget build(BuildContext context) {
    final dk = Theme.of(context).brightness == Brightness.dark;
    final bg = dk ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F7);
    final cardBg = dk ? const Color(0xFF161616) : Colors.white;
    final txt = dk ? Colors.white : const Color(0xFF1A1A1A);
    final sub = dk ? const Color(0xFF8A8A8E) : const Color(0xFF8A8A8E);
    final bdr = dk ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5EA);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero ──
          SliverAppBar(
            expandedHeight: _hasImage ? 300 : 0,
            pinned: true,
            stretch: true,
            backgroundColor: dk ? const Color(0xFF0A0A0A) : Colors.white,
            leading: _backBtn(),
            title: Text(_title,
                style: GoogleFonts.inter(
                    fontSize: 17, fontWeight: FontWeight.w600, color: txt)),
            flexibleSpace: _hasImage
                ? FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        _heroImage(dk),
                        // Bottom gradient
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  bg.withValues(alpha: 0.9),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── Meal type + time chip ──
                  Row(
                    children: [
                      _chip('${_p.mealType.emoji} ${_p.mealType.label}', dk),
                      const SizedBox(width: 8),
                      _chip(_time, dk),
                      const Spacer(),
                      _typeChip(_p.safeItemType, dk),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Calorie + macro ring card ──
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: bdr),
                    ),
                    child: Row(
                      children: [
                        // Ring
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CustomPaint(
                            painter: _MacroRingPainter(
                              protein: _totalP.toDouble(),
                              carbs: _totalC.toDouble(),
                              fat: _totalF.toDouble(),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('$_totalCal',
                                      style: GoogleFonts.inter(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: txt,
                                        height: 1,
                                      )),
                                  Text('cal',
                                      style: GoogleFonts.inter(
                                          fontSize: 12, color: sub)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Macro rows
                        Expanded(
                          child: Column(
                            children: [
                              _macroRow('Protein', '${_totalP}g',
                                  const Color(0xFF5E9EFF), txt, sub),
                              const SizedBox(height: 12),
                              _macroRow('Carbs', '${_totalC}g',
                                  const Color(0xFFFFBB38), txt, sub),
                              const SizedBox(height: 12),
                              _macroRow('Fat', '${_totalF}g',
                                  const Color(0xFFFF6B8A), txt, sub),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Micro row ──
                  Row(
                    children: [
                      _microCard('Sugar', '${_totalSugar}g',
                          Icons.cake_rounded, const Color(0xFFF97316),
                          cardBg, bdr, txt, sub),
                      const SizedBox(width: 8),
                      _microCard('Fiber', '${_totalFiber}g',
                          Icons.grass_rounded, const Color(0xFF34D399),
                          cardBg, bdr, txt, sub),
                      const SizedBox(width: 8),
                      _microCard('Sodium', '${_totalSodium}mg',
                          Icons.water_drop_outlined, const Color(0xFF60A5FA),
                          cardBg, bdr, txt, sub),
                      if (_totalCaffeine > 0) ...[
                        const SizedBox(width: 8),
                        _microCard('Caffeine', '${_totalCaffeine}mg',
                            Icons.bolt_rounded, const Color(0xFFA78BFA),
                            cardBg, bdr, txt, sub),
                      ],
                    ],
                  ),

                  // ── Items ──
                  if (items.length > 1) ...[
                    const SizedBox(height: 24),
                    _sectionLabel('Items', txt),
                    const SizedBox(height: 10),
                    ...items.map((m) => _itemTile(m, cardBg, bdr, txt, sub)),
                  ],

                  // ── Benefits (2-col grid) ──
                  if (_benefits.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionLabel('Good for you', txt),
                    const SizedBox(height: 10),
                    _benefitsGrid(_benefits, dk, cardBg, bdr, txt, sub),
                  ],

                  // ── Warnings ──
                  if (_warnings.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionLabel('Heads up', txt),
                    const SizedBox(height: 10),
                    ..._warnings.map((w) => _warningTile(w, dk, bdr)),
                  ],

                  // ── Burn it off (workout suggestions with Add button) ──
                  if (_burns.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionLabel('Burn it off', txt),
                    const SizedBox(height: 10),
                    ..._burns.map((b) => _burnRow(b, dk, cardBg, bdr, txt, sub)),
                  ],

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ── Widgets
  // ═══════════════════════════════════════════

  Widget _backBtn() {
    return GestureDetector(
      onTap: null, // handled by AppBar
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child:
            const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _heroImage(bool dk) {
    if (_hasLocalImage) {
      return Image.file(File(_p.imagePath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _networkOrPlaceholder(dk));
    }
    return _networkOrPlaceholder(dk);
  }

  Widget _networkOrPlaceholder(bool dk) {
    if (_hasRemoteImage) {
      return Image.network(_p.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: dk ? const Color(0xFF1A1A1A) : const Color(0xFFE5E5EA)));
    }
    return Container(color: dk ? const Color(0xFF1A1A1A) : const Color(0xFFE5E5EA));
  }

  Widget _chip(String label, bool dk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: dk ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEF0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: dk ? const Color(0xFFB0B0B0) : const Color(0xFF6B6B6B),
          )),
    );
  }

  Widget _typeChip(String type, bool dk) {
    final String label;
    final Color c;
    switch (type) {
      case 'beverage':
        label = '☕ Beverage';
        c = const Color(0xFF5E9EFF);
        break;
      case 'liquid':
        label = '🍲 Liquid';
        c = const Color(0xFF34D399);
        break;
      default:
        label = '🍽 Solid';
        c = const Color(0xFFA78BFA);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: dk ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600, color: c)),
    );
  }

  Widget _macroRow(
      String label, String value, Color color, Color txt, Color sub) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w500, color: sub)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700, color: txt)),
      ],
    );
  }

  Widget _microCard(String label, String value, IconData icon, Color color,
      Color cardBg, Color bdr, Color txt, Color sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bdr),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700, color: txt)),
            Text(label,
                style: GoogleFonts.inter(fontSize: 10, color: sub)),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700, color: color));
  }

  Widget _wellnessCard(bool dk, Color cardBg, Color bdr, Color txt, Color sub) {
    final score = _wellnessScore;
    final bd = _wellnessBreakdown;
    final label = bd?['label'] as String? ?? (score > 0 ? 'Good' : score < -20 ? 'Poor' : 'Okay');

    // Score color
    final Color accent;
    final Color bgColor;
    if (score >= 10) {
      accent = const Color(0xFF22C55E);
      bgColor = dk ? const Color(0xFF0D1F12) : const Color(0xFFF0FDF4);
    } else if (score >= -10) {
      accent = const Color(0xFFF59E0B);
      bgColor = dk ? const Color(0xFF1C1A0E) : const Color(0xFFFFFBEB);
    } else {
      accent = const Color(0xFFEF4444);
      bgColor = dk ? const Color(0xFF1C1111) : const Color(0xFFFEF2F2);
    }

    final perItem = (bd?['per_item'] as List<dynamic>?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [];
    final positive = (bd?['positive'] as List<dynamic>?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [];
    final negative = (bd?['negative'] as List<dynamic>?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: score badge + label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  score > 0 ? '+$score' : '$score',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wellness Impact',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700, color: txt)),
                  Text(label,
                      style: GoogleFonts.inter(fontSize: 13, color: accent, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),

          // Per-item scores
          if (perItem.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...perItem.map((item) {
              final s = item['score'] as int? ?? 0;
              final c = s >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(item['name'] as String? ?? '',
                          style: GoogleFonts.inter(fontSize: 13, color: txt)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s >= 0 ? '+$s' : '$s',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: c),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Positive factors
          if (positive.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...positive.map((f) => _factorRow(f, true, dk)),
          ],

          // Negative factors
          if (negative.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...negative.map((f) => _factorRow(f, false, dk)),
          ],
        ],
      ),
    );
  }

  Widget _factorRow(Map<String, dynamic> f, bool isPositive, bool dk) {
    final pts = f['points'] as int? ?? 0;
    final c = isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(isPositive ? Icons.add_circle_rounded : Icons.remove_circle_rounded,
              size: 14, color: c),
          const SizedBox(width: 6),
          Expanded(
            child: Text(f['label'] as String? ?? '',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
                    color: dk ? Colors.white70 : Colors.black54)),
          ),
          Text(pts > 0 ? '+$pts' : '$pts',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
        ],
      ),
    );
  }

  Widget _itemTile(
      MealLog m, Color cardBg, Color bdr, Color txt, Color sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bdr),
      ),
      child: Row(
        children: [
          _itemTypeIcon(m.safeItemType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name,
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600, color: txt)),
                const SizedBox(height: 2),
                Text(
                    'P ${m.proteinGrams}g · C ${m.carbsGrams}g · F ${m.fatGrams}g',
                    style: GoogleFonts.inter(fontSize: 12, color: sub)),
              ],
            ),
          ),
          Text('${m.calories}',
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w800, color: txt)),
          Text(' cal',
              style: GoogleFonts.inter(fontSize: 12, color: sub)),
        ],
      ),
    );
  }

  Widget _itemTypeIcon(String type) {
    final IconData icon;
    final Color c;
    switch (type) {
      case 'beverage':
        icon = Icons.local_cafe_rounded;
        c = const Color(0xFF5E9EFF);
        break;
      case 'liquid':
        icon = Icons.soup_kitchen_rounded;
        c = const Color(0xFF34D399);
        break;
      default:
        icon = Icons.restaurant_rounded;
        c = const Color(0xFFA78BFA);
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: c, size: 20),
    );
  }

  // ── Benefits: 2-column grid cards ──

  Widget _benefitsGrid(List<Map<String, dynamic>> benefits, bool dk,
      Color cardBg, Color bdr, Color txt, Color sub) {
    final colors = [
      const Color(0xFF34D399),
      const Color(0xFF5E9EFF),
      const Color(0xFFA78BFA),
      const Color(0xFFFFBB38),
      const Color(0xFFFF6B8A),
      const Color(0xFF60A5FA),
    ];

    return Column(
      children: benefits.asMap().entries.map((entry) {
        final i = entry.key;
        final b = entry.value;
        final c = colors[i % colors.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_benefitIcon(b['icon'] as String? ?? ''), size: 16, color: c),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: b['title'] as String? ?? '',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600, color: txt),
                      ),
                      if ((b['detail'] as String?)?.isNotEmpty == true) ...[
                        TextSpan(
                          text: ' — ${b['detail']}',
                          style: GoogleFonts.inter(fontSize: 13, color: sub),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _benefitIcon(String icon) {
    switch (icon) {
      case 'protein':
        return Icons.fitness_center_rounded;
      case 'fiber':
        return Icons.grass_rounded;
      case 'vitamins':
        return Icons.wb_sunny_rounded;
      case 'minerals':
        return Icons.diamond_rounded;
      case 'antioxidants':
        return Icons.shield_rounded;
      case 'healthy_fats':
        return Icons.favorite_rounded;
      case 'energy':
        return Icons.bolt_rounded;
      case 'hydration':
        return Icons.water_drop_rounded;
      case 'probiotics':
        return Icons.science_rounded;
      case 'low_calorie':
        return Icons.trending_down_rounded;
      default:
        return Icons.eco_rounded;
    }
  }

  // ── Warnings ──

  Widget _warningTile(Map<String, dynamic> w, bool dk, Color bdr) {
    final sev = w['severity'] as String? ?? 'low';
    final Color accent;
    final Color bg;
    if (sev == 'high') {
      accent = const Color(0xFFEF4444);
      bg = dk ? const Color(0xFF1C1111) : const Color(0xFFFEF2F2);
    } else if (sev == 'medium') {
      accent = const Color(0xFFF59E0B);
      bg = dk ? const Color(0xFF1C1A0E) : const Color(0xFFFFFBEB);
    } else {
      accent = const Color(0xFF64748B);
      bg = dk ? const Color(0xFF151618) : const Color(0xFFF8FAFC);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Icon(_warningIcon(w['type'] as String? ?? ''), size: 16, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w['label'] as String? ?? '',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600, color: accent)),
                if ((w['detail'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 3),
                  Text(w['detail'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: accent.withValues(alpha: 0.7),
                        height: 1.3,
                      )),
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
      case 'allergen':
        return Icons.warning_amber_rounded;
      case 'high_caffeine':
        return Icons.bolt_rounded;
      case 'high_sugar':
        return Icons.cake_rounded;
      case 'high_sodium':
        return Icons.water_drop_outlined;
      case 'high_sat_fat':
        return Icons.opacity_rounded;
      case 'high_calorie':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  // ── Burn it off ──

  Widget _burnRow(Map<String, dynamic> c, bool dk, Color cardBg, Color bdr, Color txt, Color sub) {
    final accent = const Color(0xFF8B5CF6);
    return Builder(
      builder: (ctx) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bdr),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_burnIcon(c['icon'] as String? ?? ''), size: 20, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c['activity'] as String? ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: txt)),
                  Text(c['duration'] as String? ?? '', style: GoogleFonts.inter(fontSize: 12, color: sub)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('${c['activity']} added to your goals'),
                    backgroundColor: const Color(0xFF22C55E),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
                child: Text('Add', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _burnTile(Map<String, dynamic> c, bool dk, Color cardBg, Color bdr,
      Color txt, Color sub) {
    final steps = c['steps'] as int?;
    final accent = const Color(0xFFF97316);
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _burnIcon(c['icon'] as String? ?? ''),
              size: 16,
              color: accent,
            ),
          ),
          const Spacer(),
          Text(c['activity'] as String? ?? '',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w700, color: txt)),
          Text(c['duration'] as String? ?? '',
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
          if (steps != null)
            Text('${_fmtSteps(steps)} steps',
                style: GoogleFonts.inter(fontSize: 11, color: sub)),
        ],
      ),
    );
  }

  IconData _burnIcon(String icon) {
    switch (icon) {
      case 'walking':
        return Icons.directions_walk_rounded;
      case 'running':
        return Icons.directions_run_rounded;
      case 'cycling':
        return Icons.directions_bike_rounded;
      case 'swimming':
        return Icons.pool_rounded;
      case 'yoga':
        return Icons.self_improvement_rounded;
      case 'jump_rope':
        return Icons.sports_rounded;
      case 'stairs':
        return Icons.stairs_rounded;
      case 'dancing':
        return Icons.music_note_rounded;
      case 'hiit':
        return Icons.timer_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  String _fmtSteps(int s) =>
      s >= 1000 ? '${(s / 1000).toStringAsFixed(s % 1000 == 0 ? 0 : 1)}k' : '$s';
}

// ═══════════════════════════════════════════
// Custom painter for macro donut ring
// ═══════════════════════════════════════════

class _MacroRingPainter extends CustomPainter {
  final double protein;
  final double carbs;
  final double fat;

  _MacroRingPainter({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = protein + carbs + fat;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 10.0;
    const gap = 0.06; // radians gap between segments

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -math.pi / 2;

    // Track bg
    paint.color = const Color(0xFF2A2A2A).withValues(alpha: 0.2);
    canvas.drawCircle(center, radius, paint);

    // Protein arc (blue)
    final pAngle = (protein / total) * 2 * math.pi - gap;
    paint.color = const Color(0xFF5E9EFF);
    canvas.drawArc(rect, startAngle, pAngle.clamp(0.01, 6.0), false, paint);
    startAngle += pAngle + gap;

    // Carbs arc (yellow)
    final cAngle = (carbs / total) * 2 * math.pi - gap;
    paint.color = const Color(0xFFFFBB38);
    canvas.drawArc(rect, startAngle, cAngle.clamp(0.01, 6.0), false, paint);
    startAngle += cAngle + gap;

    // Fat arc (pink)
    final fAngle = (fat / total) * 2 * math.pi - gap;
    paint.color = const Color(0xFFFF6B8A);
    canvas.drawArc(rect, startAngle, fAngle.clamp(0.01, 6.0), false, paint);
  }

  @override
  bool shouldRepaint(covariant _MacroRingPainter old) =>
      old.protein != protein || old.carbs != carbs || old.fat != fat;
}
