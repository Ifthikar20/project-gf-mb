import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/diet_models.dart';
import '../pages/meal_detail_page.dart';

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

  bool get _hasLocalImage =>
      _primary.imagePath != null && File(_primary.imagePath!).existsSync();
  bool get _hasRemoteImage => _primary.imageUrl != null;
  bool get _hasImage => _hasLocalImage || _hasRemoteImage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleColor = isDark ? Colors.white38 : Colors.black38;
    final isSingle = widget.items.length == 1;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MealDetailPage(items: widget.items),
          ),
        );
      },
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
                  // Food image with color background
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _mealColor(_primary.mealType).withOpacity(0.15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildFoodImage(isDark),
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
                        Text('${_primary.mealType.emoji} $_timeStr',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: subtleColor)),
                      ],
                    ),
                  ),

                  // Total calories only (clean)
                  Text('$_totalCal',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      )),
                  const SizedBox(width: 2),
                  Text('cal',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: subtleColor,
                      )),
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

  Widget _buildFoodImage(bool isDark) {
    // 1. Try local file
    if (_hasLocalImage) {
      return Image.file(
        File(_primary.imagePath!),
        width: 52, height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _networkOrPlaceholder(isDark),
      );
    }
    // 2. Try remote URL
    return _networkOrPlaceholder(isDark);
  }

  Widget _networkOrPlaceholder(bool isDark) {
    if (_hasRemoteImage) {
      return CachedNetworkImage(
        imageUrl: _primary.imageUrl!,
        width: 52, height: 52,
        fit: BoxFit.cover,
        memCacheHeight: 104,
        memCacheWidth: 104,
        placeholder: (_, __) => Container(
          color: _mealColor(_primary.mealType).withOpacity(0.15),
          child: Center(
            child: SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _mealColor(_primary.mealType),
              ),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _emojiPlaceholder(isDark),
      );
    }
    return _emojiPlaceholder(isDark);
  }

  Color _mealColor(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return const Color(0xFFF59E0B); // warm amber
      case MealType.lunch:
        return const Color(0xFF22C55E); // green
      case MealType.dinner:
        return const Color(0xFF8B5CF6); // purple
      case MealType.snack:
        return const Color(0xFF3B82F6); // blue
    }
  }

  Widget _emojiPlaceholder(bool isDark) {
    return Center(
      child: Text(_primary.mealType.emoji,
          style: const TextStyle(fontSize: 22)),
    );
  }
}
