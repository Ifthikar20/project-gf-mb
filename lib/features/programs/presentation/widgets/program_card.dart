import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/program_model.dart';

/// Card widget for displaying a program in browse grids.
/// Shows cover image, coach info, title, duration, difficulty, and price.
class ProgramCard extends StatelessWidget {
  final Program program;
  final VoidCallback onTap;
  final bool isLight;
  final Color surfaceColor;
  final Color textColor;
  final Color textSecondary;
  final Color primaryColor;
  final Color borderColor;

  const ProgramCard({
    super.key,
    required this.program,
    required this.onTap,
    required this.isLight,
    required this.surfaceColor,
    required this.textColor,
    required this.textSecondary,
    required this.primaryColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            _buildCover(),

            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coach row
                  Row(
                    children: [
                      _buildCoachAvatar(size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          program.coach.name,
                          style: TextStyle(
                            color: textSecondary.withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    program.title,
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Meta chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildChip(program.durationLabel, Icons.calendar_today_outlined),
                      _buildChip(program.difficultyLabel, Icons.speed_outlined),
                      _buildChip('${program.contentCount} sessions',
                          Icons.play_circle_outline),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Price + enrollment count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: program.isFree
                              ? const Color(0xFF22C55E).withOpacity(0.12)
                              : primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          program.priceLabel,
                          style: GoogleFonts.inter(
                            color: program.isFree
                                ? const Color(0xFF22C55E)
                                : primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (program.enrollmentCount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline,
                                color: textSecondary.withOpacity(0.5),
                                size: 12),
                            const SizedBox(width: 3),
                            Text(
                              '${program.enrollmentCount}',
                              style: TextStyle(
                                color: textSecondary.withOpacity(0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  // Enrolled badge
                  if (program.isEnrolled) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF22C55E).withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '✓ Enrolled',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF22C55E),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (program.coverImageUrl != null)
            CachedNetworkImage(
              imageUrl: program.coverImageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: isLight
                    ? const Color(0xFFF3F4F6)
                    : const Color(0xFF2A2A2A),
              ),
              errorWidget: (_, __, ___) => _buildPlaceholderCover(),
            )
          else
            _buildPlaceholderCover(),

          // Category badge (top-left)
          if (program.categoryName != null)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  program.categoryName!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      color: isLight ? const Color(0xFFF3F4F6) : const Color(0xFF2A2A2A),
      child: Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: primaryColor.withOpacity(0.3),
          size: 40,
        ),
      ),
    );
  }

  Widget _buildCoachAvatar({required double size}) {
    if (program.coach.avatarUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: CachedNetworkImage(
          imageUrl: program.coach.avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _buildAvatarFallback(size),
        ),
      );
    }
    return _buildAvatarFallback(size);
  }

  Widget _buildAvatarFallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          program.coach.name.isNotEmpty ? program.coach.name[0] : '?',
          style: TextStyle(
            color: primaryColor,
            fontSize: size * 0.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isLight
            ? const Color(0xFFF3F4F6)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textSecondary.withOpacity(0.5), size: 10),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: textSecondary.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
