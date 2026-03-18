import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/models/wellness_suggestion_model.dart';

/// A single suggestion card — shows AI-driven contextual advice
/// with optional action button and swipe-to-dismiss.
class WellnessSuggestionCard extends StatelessWidget {
  final WellnessSuggestion suggestion;
  final VoidCallback? onDismiss;

  const WellnessSuggestionCard({
    super.key,
    required this.suggestion,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isHigh = suggestion.priority == 'high';

    return Dismissible(
      key: ValueKey(suggestion.id),
      direction: suggestion.isDismissible
          ? DismissDirection.horizontal
          : DismissDirection.none,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(Icons.check_rounded,
            color: Colors.white.withOpacity(0.3), size: 22),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.close_rounded,
            color: Colors.white.withOpacity(0.3), size: 22),
      ),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isHigh
                ? suggestion.color.withOpacity(0.35)
                : Colors.white.withOpacity(0.06),
          ),
          boxShadow: isHigh
              ? [
                  BoxShadow(
                    color: suggestion.color.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: icon + priority badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: suggestion.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(suggestion.icon, color: suggestion.color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    suggestion.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Body
            Flexible(
              child: Text(
                suggestion.body,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white54,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Action button
            if (suggestion.actionLabel != null ||
                suggestion.actionRoute != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  if (suggestion.actionRoute != null) {
                    context.push(suggestion.actionRoute!);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: suggestion.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: suggestion.color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        suggestion.actionLabel ?? 'Go',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: suggestion.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          color: suggestion.color, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
