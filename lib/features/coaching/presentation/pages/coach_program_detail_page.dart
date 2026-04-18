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

/// Immersive program detail screen with hero image, enrollment CTA,
/// week-by-week training calendar, and content episodes.
class CoachProgramDetailPage extends StatefulWidget {
  final String programId;
  const CoachProgramDetailPage({super.key, required this.programId});

  @override
  State<CoachProgramDetailPage> createState() => _CoachProgramDetailPageState();
}

class _CoachProgramDetailPageState extends State<CoachProgramDetailPage> {
  bool _enrolled = false;
  int _enrolledCount = 0;
  final Set<int> _expandedWeeks = {0}; // First week expanded by default

  @override
  void initState() {
    super.initState();
    context
        .read<CoachProgramBloc>()
        .add(LoadProgramDetail(programId: widget.programId));
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
        final primaryColor = ThemeColors.primary(mode);

        return Scaffold(
          backgroundColor: bgColor,
          body: BlocConsumer<CoachProgramBloc, CoachProgramState>(
            listener: (context, state) {
              if (state is CoachProgramEnrollmentSuccess) {
                setState(() {
                  _enrolled = true;
                  _enrolledCount++;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF22C55E),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
                // Reload to get updated calendar with progress
                context.read<CoachProgramBloc>().add(
                    LoadProgramDetail(programId: widget.programId));
              }
              if (state is CoachProgramDayCompleted) {
                // Reload detail to refresh progress
                context.read<CoachProgramBloc>().add(
                    LoadProgramDetail(programId: widget.programId));
              }
            },
            builder: (context, state) {
              if (state is CoachProgramLoading) {
                return Center(
                  child: CircularProgressIndicator(
                      color: primaryColor, strokeWidth: 2),
                );
              }
              if (state is CoachProgramError) {
                return _buildError(textColor, textSecondary, primaryColor);
              }
              if (state is CoachProgramDetailLoaded) {
                final program = state.program;
                if (!_enrolled && program.isEnrolled) {
                  _enrolled = true;
                }
                _enrolledCount = program.enrolledCount;
                return _buildContent(
                  program: program,
                  isLight: isLight,
                  bgColor: bgColor,
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildError(Color textColor, Color textSecondary, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: textSecondary),
          const SizedBox(height: 12),
          Text('Program not found',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Go back',
                style: GoogleFonts.inter(
                    color: primaryColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent({
    required CoachProgram program,
    required bool isLight,
    required Color bgColor,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    final rng = Random(program.id.hashCode);
    final displayEnrolled = _enrolledCount > 0
        ? _enrolledCount
        : (rng.nextInt(200) + 50);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero Image ──
        SliverToBoxAdapter(
          child: Stack(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.45,
                width: double.infinity,
                child: program.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: program.coverImageUrl!,
                        fit: BoxFit.cover,
                        memCacheHeight: 800,
                        memCacheWidth: 800,
                        placeholder: (_, __) => Container(
                          color: surfaceColor,
                          child: Center(
                            child: CircularProgressIndicator(
                                color: primaryColor, strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: surfaceColor,
                          child: Icon(Icons.fitness_center_rounded,
                              size: 48, color: textSecondary),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor.withOpacity(0.3),
                              primaryColor.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(Icons.fitness_center_rounded,
                              size: 64, color: primaryColor.withOpacity(0.4)),
                        ),
                      ),
              ),
              // Bottom gradient
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 200,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.75),
                      ],
                    ),
                  ),
                ),
              ),
              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
              // Overlaid info
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Duration + Level badges
                    Row(
                      children: [
                        _heroBadge(program.durationLabel),
                        const SizedBox(width: 8),
                        _heroBadge(program.level),
                        const SizedBox(width: 8),
                        _heroBadge(program.category),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      program.title,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Coach info
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(0.3),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1.5),
                          ),
                          child: program.coach.avatarUrl != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: program.coach.avatarUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    program.coach.name.isNotEmpty
                                        ? program.coach.name[0]
                                        : '?',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'With ${program.coach.name}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Body ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coach row + enrolled count
                Row(
                  children: [
                    // Coach avatar (larger)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.12),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          program.coach.name.isNotEmpty
                              ? program.coach.name[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Session count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${program.contentCount}',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'sessions',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Enrolled avatar stack
                    Row(
                      children: [
                        SizedBox(
                          width: 56,
                          height: 28,
                          child: Stack(
                            children: List.generate(3, (i) {
                              final colors = [
                                const Color(0xFF3B82F6),
                                const Color(0xFF8B5CF6),
                                const Color(0xFFF59E0B),
                              ];
                              return Positioned(
                                left: i * 16.0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: colors[i],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isLight
                                          ? Colors.white
                                          : const Color(0xFF111111),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(Icons.person,
                                        size: 14,
                                        color:
                                            Colors.white.withOpacity(0.9)),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$displayEnrolled enrolled',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Enroll Button ──
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    if (!_enrolled) {
                      setState(() => _enrolled = true);
                      context.read<CoachProgramBloc>().add(
                          EnrollInProgram(programId: widget.programId));
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _enrolled
                          ? const Color(0xFF22C55E)
                          : isLight
                              ? Colors.black
                              : Colors.white,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Center(
                      child: Text(
                        _enrolled
                            ? '✓  Enrolled'
                            : program.isFree
                                ? 'Enroll Free'
                                : 'Enroll  •  \$${program.price}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _enrolled
                              ? Colors.white
                              : isLight
                                  ? Colors.white
                                  : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Description ──
                if (program.description.isNotEmpty) ...[
                  Text(
                    program.description,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── What You'll Get ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What you\'ll get',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitRow(
                        Icons.play_lesson_rounded,
                        '${program.contentCount} guided sessions',
                        textColor,
                        textSecondary,
                      ),
                      const SizedBox(height: 8),
                      _buildBenefitRow(
                        Icons.calendar_month_rounded,
                        '${program.durationLabel} structured training calendar',
                        textColor,
                        textSecondary,
                      ),
                      const SizedBox(height: 8),
                      _buildBenefitRow(
                        Icons.person_rounded,
                        'Expert guidance from ${program.coach.name}',
                        textColor,
                        textSecondary,
                      ),
                      const SizedBox(height: 8),
                      _buildBenefitRow(
                        Icons.trending_up_rounded,
                        'Track your progress day by day',
                        textColor,
                        textSecondary,
                      ),
                    ],
                  ),
                ),

                // ── Progress (if enrolled) ──
                if (_enrolled && program.totalDays > 0) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              const Color(0xFF22C55E).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        // Progress ring
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: Stack(
                            children: [
                              CircularProgressIndicator(
                                value: program.progressPercent,
                                strokeWidth: 4,
                                backgroundColor:
                                    const Color(0xFF22C55E).withOpacity(0.15),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF22C55E)),
                              ),
                              Center(
                                child: Text(
                                  '${(program.progressPercent * 100).toInt()}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF22C55E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Progress',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                '${program.completedDays} of ${program.totalDays} days completed',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Training Calendar Header ──
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded,
                        size: 20, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Training Calendar',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Your coach\'s recommended schedule',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // ── Week Accordions ──
        if (program.trainingCalendar.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final week = program.trainingCalendar[index];
                  final isExpanded = _expandedWeeks.contains(index);
                  return _buildWeekAccordion(
                    week: week,
                    index: index,
                    isExpanded: isExpanded,
                    isLight: isLight,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    primaryColor: primaryColor,
                    programId: program.id,
                  );
                },
                childCount: program.trainingCalendar.length,
              ),
            ),
          ),

        // ── Empty calendar ──
        if (program.trainingCalendar.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 36, color: textSecondary),
                    const SizedBox(height: 8),
                    Text(
                      'Training calendar coming soon',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your coach is building your schedule',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textSecondary.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Content List Header ──
        if (program.contentItems.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                children: [
                  Text(
                    'All Content',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${program.contentItems.length} items',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
            ),
          ),

        // ── Content Items ──
        if (program.contentItems.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = program.contentItems[index];
                  return _buildContentRow(
                    item: item,
                    index: index,
                    isLight: isLight,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    primaryColor: primaryColor,
                  );
                },
                childCount: program.contentItems.length,
              ),
            ),
          ),

        // Bottom padding
        SliverToBoxAdapter(
          child:
              SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
        ),
      ],
    );
  }

  // ─────────────────────────────
  // Week Accordion
  // ─────────────────────────────
  Widget _buildWeekAccordion({
    required CalendarWeek week,
    required int index,
    required bool isExpanded,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
    required String programId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isLight ? 0.03 : 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Week header
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (isExpanded) {
                  _expandedWeeks.remove(index);
                } else {
                  _expandedWeeks.add(index);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Week number circle
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: week.isComplete
                          ? const Color(0xFF22C55E).withOpacity(0.12)
                          : primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: week.isComplete
                          ? const Icon(Icons.check_rounded,
                              size: 18, color: Color(0xFF22C55E))
                          : Text(
                              '${week.weekNumber}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Week title + progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          week.title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${week.completedCount}/${week.activeDayCount} days completed',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expand arrow
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: textSecondary, size: 24),
                  ),
                ],
              ),
            ),
          ),
          // Expanded days
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(height: 1, color: borderColor),
                ...week.days.map((day) => _buildCalendarDayRow(
                      day: day,
                      isLight: isLight,
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                      primaryColor: primaryColor,
                      programId: programId,
                    )),
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────
  // Calendar Day Row
  // ─────────────────────────────
  Widget _buildCalendarDayRow({
    required CalendarDay day,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
    required String programId,
  }) {
    if (day.isRestDay) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.self_improvement_rounded,
                    size: 16, color: Color(0xFF8B5CF6)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day.dayOfWeek.isNotEmpty ? day.dayOfWeek : "Day ${day.dayNumber}"}  •  Rest Day',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                  if (day.notes != null)
                    Text(
                      day.notes!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (day.contentId != null && _enrolled) {
          if (day.contentType == 'audio') {
            context.push('${AppRouter.audioPlayer}?id=${day.contentId}');
          } else {
            context.push('${AppRouter.videoPlayer}?id=${day.contentId}');
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Day number / completion
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: day.isCompleted
                    ? const Color(0xFF22C55E).withOpacity(0.12)
                    : primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: day.isCompleted
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Color(0xFF22C55E))
                    : Text(
                        '${day.dayNumber}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Day info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (day.dayOfWeek.isNotEmpty) ...[
                        Text(
                          day.dayOfWeek,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('•',
                            style: TextStyle(
                                color: textSecondary, fontSize: 11)),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          day.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            decoration: day.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 12, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${day.durationMinutes} min',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                      if (day.notes != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            day.notes!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: textSecondary.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Play / Complete buttons
            if (_enrolled) ...[
              if (!day.isCompleted)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<CoachProgramBloc>().add(
                        MarkDayComplete(
                            programId: programId, dayId: day.id));
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: textSecondary.withOpacity(0.3)),
                    ),
                    child: Icon(Icons.check_rounded,
                        size: 16, color: textSecondary),
                  ),
                ),
              const SizedBox(width: 8),
              if (day.contentId != null)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    day.contentType == 'audio'
                        ? Icons.headphones_rounded
                        : Icons.play_arrow_rounded,
                    size: 16,
                    color: primaryColor,
                  ),
                ),
            ] else
              Icon(Icons.lock_outline_rounded,
                  size: 18, color: textSecondary.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────
  // Content List Row
  // ─────────────────────────────
  Widget _buildContentRow({
    required ProgramContentItem item,
    required int index,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: () {
        if (_enrolled) {
          if (item.contentType == 'audio') {
            context.push('${AppRouter.audioPlayer}?id=${item.id}');
          } else {
            context.push('${AppRouter.videoPlayer}?id=${item.id}');
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.formattedDuration.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 12, color: textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          item.formattedDuration,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Type badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: item.contentType == 'audio'
                    ? const Color(0xFF8B5CF6).withOpacity(0.12)
                    : primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.contentType == 'audio'
                    ? Icons.headphones_rounded
                    : Icons.play_arrow_rounded,
                size: 14,
                color: item.contentType == 'audio'
                    ? const Color(0xFF8B5CF6)
                    : primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBenefitRow(
      IconData icon, String text, Color textColor, Color textSecondary) {
    return Row(
      children: [
        Icon(icon, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: textColor,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
