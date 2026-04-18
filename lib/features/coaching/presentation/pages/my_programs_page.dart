import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../../data/models/coach_program_models.dart';
import '../bloc/coach_program_bloc.dart';

/// Dashboard of the user's enrolled programs with progress tracking.
/// Quick-play next content and view calendar-at-a-glance.
class MyProgramsPage extends StatefulWidget {
  const MyProgramsPage({super.key});

  @override
  State<MyProgramsPage> createState() => _MyProgramsPageState();
}

class _MyProgramsPageState extends State<MyProgramsPage> {
  @override
  void initState() {
    super.initState();
    context.read<CoachProgramBloc>().add(const LoadMyEnrollments());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isLight = themeState.isLight;
        final bgColor = ThemeColors.background(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final primaryColor = ThemeColors.primary(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final borderColor = ThemeColors.border(mode);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'My Programs',
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.explore_outlined,
                    color: textColor, size: 22),
                onPressed: () => context.push(AppRouter.coachPrograms),
              ),
            ],
          ),
          body: BlocBuilder<CoachProgramBloc, CoachProgramState>(
            builder: (context, state) {
              if (state is CoachProgramLoading) {
                return Center(
                  child: CircularProgressIndicator(
                      color: primaryColor, strokeWidth: 2),
                );
              }
              if (state is CoachProgramError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          color: textSecondary, size: 48),
                      const SizedBox(height: 12),
                      Text(state.message,
                          style: GoogleFonts.inter(
                              color: textSecondary, fontSize: 14)),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => context
                            .read<CoachProgramBloc>()
                            .add(const LoadMyEnrollments()),
                        child: Text('Retry',
                            style: GoogleFonts.inter(
                                color: primaryColor,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
              }
              if (state is MyEnrollmentsLoaded) {
                if (state.programs.isEmpty) {
                  return _buildEmptyState(
                    textColor: textColor,
                    textSecondary: textSecondary,
                    primaryColor: primaryColor,
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: state.programs.length,
                  itemBuilder: (context, index) => _buildProgramCard(
                    program: state.programs[index],
                    isLight: isLight,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    primaryColor: primaryColor,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required Color textColor,
    required Color textSecondary,
    required Color primaryColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.school_outlined, color: primaryColor, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'No Programs Yet',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse coach programs and enroll to start your structured training journey.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.push(AppRouter.coachPrograms),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Browse Programs',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramCard({
    required CoachProgram program,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    final nextDay = program.nextIncompleteDay;

    return GestureDetector(
      onTap: () => context.push(
          '${AppRouter.coachProgramDetail}?id=${program.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isLight ? 0.04 : 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: thumbnail + info + progress ring
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: program.coverImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: program.coverImageUrl!,
                            fit: BoxFit.cover,
                            memCacheHeight: 140,
                            memCacheWidth: 140,
                            placeholder: (_, __) =>
                                Container(color: surfaceColor),
                            errorWidget: (_, __, ___) => Container(
                              color: surfaceColor,
                              child: Icon(Icons.fitness_center_rounded,
                                  color: textSecondary, size: 24),
                            ),
                          )
                        : Container(
                            color: surfaceColor,
                            child: Icon(Icons.fitness_center_rounded,
                                color: textSecondary, size: 24),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'With ${program.coach.name}  •  ${program.durationLabel}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Category + sessions
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              program.category,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${program.contentCount} sessions',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Progress ring
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          value: program.progressPercent,
                          strokeWidth: 3.5,
                          backgroundColor:
                              const Color(0xFF22C55E).withOpacity(0.12),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF22C55E)),
                        ),
                      ),
                      Center(
                        child: Text(
                          '${(program.progressPercent * 100).toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: program.progressPercent >= 1.0
                                ? const Color(0xFF22C55E)
                                : textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Next Up section ──
            if (nextDay != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    // Play icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        nextDay.contentType == 'audio'
                            ? Icons.headphones_rounded
                            : Icons.play_arrow_rounded,
                        size: 18,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Up',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Day ${nextDay.dayNumber}: ${nextDay.title}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${nextDay.durationMinutes} min',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Continue button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (nextDay.contentId != null) {
                          if (nextDay.contentType == 'audio') {
                            context.push(
                                '${AppRouter.audioPlayer}?id=${nextDay.contentId}');
                          } else {
                            context.push(
                                '${AppRouter.videoPlayer}?id=${nextDay.contentId}');
                          }
                        } else {
                          context.push(
                              '${AppRouter.coachProgramDetail}?id=${program.id}');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Continue',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Completed badge ──
            if (program.progressPercent >= 1.0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF22C55E).withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        size: 20, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Text(
                      'Program Completed!',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Week strip calendar-at-a-glance ──
            if (program.trainingCalendar.isNotEmpty) ...[
              const SizedBox(height: 14),
              // Show first incomplete week as mini-calendar
              Builder(
                builder: (context) {
                  // Find current week
                  CalendarWeek? currentWeek;
                  for (final w in program.trainingCalendar) {
                    if (!w.isComplete) {
                      currentWeek = w;
                      break;
                    }
                  }
                  currentWeek ??= program.trainingCalendar.last;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentWeek.title,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: currentWeek.days.map((day) {
                          return Expanded(
                            child: Container(
                              margin: EdgeInsets.only(
                                  right: day == currentWeek!.days.last
                                      ? 0
                                      : 4),
                              height: 6,
                              decoration: BoxDecoration(
                                color: day.isCompleted
                                    ? const Color(0xFF22C55E)
                                    : day.isRestDay
                                        ? const Color(0xFF8B5CF6)
                                            .withOpacity(0.3)
                                        : borderColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
