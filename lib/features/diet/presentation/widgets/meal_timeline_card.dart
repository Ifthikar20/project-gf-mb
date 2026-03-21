import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/diet_models.dart';

/// Expandable meal card that shows a grouped scan as one card.
/// Collapsed: photo + meal name + total calories + macro badges.
/// Expanded: individual items with per-item calories and macros.
class MealGroupCard extends StatefulWidget {
  final List<MealLog> items;
  final VoidCallback? onDelete;

  const MealGroupCard({super.key, required this.items, this.onDelete});

  @override
  State<MealGroupCard> createState() => _MealGroupCardState();
}

class _MealGroupCardState extends State<MealGroupCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  // Totals
  int get _totalCal => widget.items.fold(0, (s, m) => s + m.calories);
  int get _totalP => widget.items.fold(0, (s, m) => s + m.proteinGrams);
  int get _totalC => widget.items.fold(0, (s, m) => s + m.carbsGrams);
  int get _totalF => widget.items.fold(0, (s, m) => s + m.fatGrams);

  MealLog get _primary => widget.items.first;

  String get _timeStr {
    final h = _primary.timestamp.hour > 12
        ? _primary.timestamp.hour - 12
        : (_primary.timestamp.hour == 0 ? 12 : _primary.timestamp.hour);
    final amPm = _primary.timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$h:${_primary.timestamp.minute.toString().padLeft(2, '0')} $amPm';
  }

  String get _title {
    if (widget.items.length == 1) return _primary.name;
    // Use mealName from backend if available (e.g. "Burger")
    if (_primary.mealName != null) {
      return '${_primary.mealName} · ${widget.items.length} items';
    }
    // Fallback: use meal type
    return '${_primary.mealType.label} · ${widget.items.length} items';
  }

  bool get _hasImage =>
      _primary.imagePath != null && File(_primary.imagePath!).existsSync();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleColor = isDark ? Colors.white38 : Colors.black38;
    final isSingle = widget.items.length == 1;

    return GestureDetector(
      onTap: isSingle ? null : () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        child: Column(
          children: [
            // ── Main row (always visible) ──
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Food image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: _hasImage
                          ? Image.file(File(_primary.imagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _emojiPlaceholder(isDark))
                          : _emojiPlaceholder(isDark),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title + time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_title,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text('${_primary.mealType.emoji} $_timeStr',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: subtleColor)),
                            if (!isSingle) ...[
                              const SizedBox(width: 6),
                              Icon(
                                _expanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 16,
                                color: subtleColor,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Total calories + macros
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$_totalCal cal',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          )),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _macroBadge('P', _totalP, const Color(0xFF3B82F6), isDark),
                          const SizedBox(width: 4),
                          _macroBadge('C', _totalC, const Color(0xFFF59E0B), isDark),
                          const SizedBox(width: 4),
                          _macroBadge('F', _totalF, const Color(0xFFEC4899), isDark),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Expanded items ──
            if (_expanded && !isSingle)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Column(
                  children: widget.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: subtleColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(item.name,
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: textColor)),
                          ),
                          Text('${item.calories} cal',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              )),
                          const SizedBox(width: 10),
                          Text(
                            'P${item.proteinGrams} C${item.carbsGrams} F${item.fatGrams}',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: subtleColor),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emojiPlaceholder(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(_primary.mealType.emoji,
            style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _macroBadge(String label, int grams, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('$label${grams}g',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color,
          )),
    );
  }
}
