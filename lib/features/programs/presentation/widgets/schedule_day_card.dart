import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/program_model.dart';

/// Card for a single schedule day inside the program schedule view.
/// Closely mirrors the PlanDay card design from MyWorkoutPlanPage.
class ScheduleDayCard extends StatelessWidget {
  final ProgramScheduleDay day;
  final bool isLight;
  final Color surfaceColor;
  final Color primaryColor;
  final Color textColor;
  final Color textSecondary;
  final Color borderColor;
  final bool isToday;
  final bool isCompleting;
  final VoidCallback? onPlay;
  final VoidCallback? onComplete;

  const ScheduleDayCard({
    super.key,
    required this.day,
    required this.isLight,
    required this.surfaceColor,
    required this.primaryColor,
    required this.textColor,
    required this.textSecondary,
    required this.borderColor,
    this.isToday = false,
    this.isCompleting = false,
    this.onPlay,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = day.isCompleted;
    final isRest = day.isRestDay;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF22C55E).withOpacity(0.4)
              : isToday
                  ? primaryColor.withOpacity(0.5)
                  : borderColor,
          width: isToday && !isCompleted ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: thumbnail / status icon
            _buildLeading(),
            const SizedBox(width: 12),

            // Middle: info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day label + today badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          day.dayLabel,
                          style: GoogleFonts.inter(
                            color: primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isToday && !isCompleted) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'TODAY',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF3B82F6),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Title
                  Text(
                    isRest
                        ? '😴 Rest Day'
                        : day.contentTitle ?? 'Workout',
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Duration
                  if (!isRest && day.contentDurationMinutes > 0)
                    Text(
                      '${day.contentDurationMinutes} min',
                      style: GoogleFonts.inter(
                          color: textSecondary, fontSize: 12),
                    ),

                  // Coach notes
                  if (day.coachNotes != null && day.coachNotes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.sticky_note_2_outlined,
                            color: textSecondary, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            day.coachNotes!,
                            style: GoogleFonts.inter(
                              color: textSecondary,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Completed date
                  if (isCompleted && day.completedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '✓ Completed',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF22C55E),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Right: action buttons
            if (!isCompleted && !isRest && day.hasContent) ...[
              const SizedBox(width: 8),
              Column(
                children: [
                  GestureDetector(
                    onTap: onPlay,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Start',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: isCompleting ? null : onComplete,
                    child: isCompleting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: primaryColor,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Done',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF22C55E),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeading() {
    if (day.isCompleted) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Icon(Icons.check_circle_rounded,
              color: Color(0xFF22C55E), size: 28),
        ),
      );
    }

    if (day.isRestDay) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isLight
              ? const Color(0xFFF3F4F6)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Icon(Icons.bedtime_outlined,
              color: textSecondary.withOpacity(0.5), size: 24),
        ),
      );
    }

    if (day.contentThumbnailUrl != null) {
      return GestureDetector(
        onTap: onPlay,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: day.contentThumbnailUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 56,
                  height: 56,
                  color: isLight
                      ? const Color(0xFFF3F4F6)
                      : const Color(0xFF2A2A2A),
                ),
                errorWidget: (_, __, ___) => _buildPlayPlaceholder(),
              ),
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildPlayPlaceholder();
  }

  Widget _buildPlayPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.fitness_center_rounded,
          color: primaryColor, size: 24),
    );
  }
}
