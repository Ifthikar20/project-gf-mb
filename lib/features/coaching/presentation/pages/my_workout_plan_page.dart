import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/services/workout_plan_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyWorkoutPlanPage extends StatefulWidget {
  const MyWorkoutPlanPage({super.key});

  @override
  State<MyWorkoutPlanPage> createState() => _MyWorkoutPlanPageState();
}

class _MyWorkoutPlanPageState extends State<MyWorkoutPlanPage> {
  WorkoutPlan? _plan;
  bool _loading = true;
  String? _error;
  bool _isPremiumRequired = false;
  final Set<String> _completing = {};

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() {
      _loading = true;
      _error = null;
      _isPremiumRequired = false;
    });
    try {
      final plan = await WorkoutPlanService.instance.getMyPlan();
      if (mounted) setState(() { _plan = plan; _loading = false; });
    } on WorkoutPlanException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _isPremiumRequired = e.isPremiumRequired;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Failed to load plan.'; });
    }
  }

  Future<void> _markComplete(PlanDay day) async {
    if (_completing.contains(day.id)) return;
    setState(() => _completing.add(day.id));
    try {
      await WorkoutPlanService.instance.completePlanDay(day.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout completed! 💪'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        _loadPlan();
      }
    } on WorkoutPlanException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _completing.remove(day.id));
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
        final primaryColor = ThemeColors.primary(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final borderColor = ThemeColors.border(mode);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'My Workout Plan',
              style: GoogleFonts.inter(color: textColor, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(color: borderColor, height: 1),
            ),
          ),
          body: _buildBody(
            isLight: isLight,
            bgColor: bgColor,
            surfaceColor: surfaceColor,
            primaryColor: primaryColor,
            textColor: textColor,
            textSecondary: textSecondary,
            borderColor: borderColor,
          ),
        );
      },
    );
  }

  Widget _buildBody({
    required bool isLight,
    required Color bgColor,
    required Color surfaceColor,
    required Color primaryColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
  }) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2));
    }

    if (_isPremiumRequired) {
      return _buildUpgradePrompt(primaryColor, textColor, textSecondary, surfaceColor, borderColor);
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: textSecondary, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: GoogleFonts.inter(color: textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loadPlan,
              child: Text('Retry', style: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    if (_plan == null) {
      return _buildEmptyPlan(primaryColor, textColor, textSecondary, surfaceColor, borderColor);
    }

    return RefreshIndicator(
      onRefresh: _loadPlan,
      color: primaryColor,
      child: _buildPlanContent(
        plan: _plan!,
        isLight: isLight,
        surfaceColor: surfaceColor,
        primaryColor: primaryColor,
        textColor: textColor,
        textSecondary: textSecondary,
        borderColor: borderColor,
      ),
    );
  }

  // ── No Plan Yet ──────────────────────────────────────────────────────────────

  Widget _buildEmptyPlan(Color primaryColor, Color textColor, Color textSecondary,
      Color surfaceColor, Color borderColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.fitness_center_rounded, color: primaryColor, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'No active plan yet',
              style: GoogleFonts.inter(color: textColor, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Book a free 20-min consultation and your coach will create a personalised plan just for you.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => context.push(AppRouter.freeConsultation),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Book Free Consultation',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Premium Upsell ───────────────────────────────────────────────────────────

  Widget _buildUpgradePrompt(Color primaryColor, Color textColor,
      Color textSecondary, Color surfaceColor, Color borderColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Premium Feature',
              style: GoogleFonts.inter(color: textColor, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Custom workout plans and free monthly consultations are available on the Premium plan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => context.push(AppRouter.subscriptionPlans),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Upgrade to Premium — \$44.99/mo',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Plan Content ─────────────────────────────────────────────────────────────

  Widget _buildPlanContent({
    required WorkoutPlan plan,
    required bool isLight,
    required Color surfaceColor,
    required Color primaryColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
  }) {
    final daysByWeek = plan.daysByWeek;
    final weeks = daysByWeek.keys.toList()..sort();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        // ── Progress header ──
        _buildProgressHeader(plan, isLight, primaryColor, textColor, textSecondary, surfaceColor, borderColor),
        const SizedBox(height: 20),

        // ── Coach note ──
        if (plan.notesForClient != null && plan.notesForClient!.isNotEmpty) ...[
          _buildCoachNote(plan.notesForClient!, isLight, primaryColor, textColor, borderColor),
          const SizedBox(height: 20),
        ],

        // ── Weeks ──
        for (final week in weeks) ...[
          Text(
            'WEEK $week',
            style: GoogleFonts.inter(
              color: primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ...daysByWeek[week]!.map((day) => _buildDayCard(
                day: day,
                isLight: isLight,
                surfaceColor: surfaceColor,
                primaryColor: primaryColor,
                textColor: textColor,
                textSecondary: textSecondary,
                borderColor: borderColor,
              )),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildProgressHeader(
    WorkoutPlan plan,
    bool isLight,
    Color primaryColor,
    Color textColor,
    Color textSecondary,
    Color surfaceColor,
    Color borderColor,
  ) {
    final pct = plan.progress.percent / 100.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (plan.coach.avatarUrl != null)
                CircleAvatar(
                  radius: 20,
                  backgroundImage: CachedNetworkImageProvider(plan.coach.avatarUrl!),
                )
              else
                CircleAvatar(
                  radius: 20,
                  backgroundColor: primaryColor.withValues(alpha: 0.15),
                  child: Text(
                    plan.coach.name[0],
                    style: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: GoogleFonts.inter(color: textColor, fontSize: 15, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'by ${plan.coach.name}',
                      style: GoogleFonts.inter(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${plan.progress.completedDays}/${plan.progress.totalDays} workouts done',
                style: GoogleFonts.inter(color: textSecondary, fontSize: 12),
              ),
              Text(
                '${plan.progress.percent}%',
                style: GoogleFonts.inter(
                    color: primaryColor, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: primaryColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachNote(
    String note,
    bool isLight,
    Color primaryColor,
    Color textColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, color: primaryColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Coach's Note",
                  style: GoogleFonts.inter(
                      color: primaryColor, fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: GoogleFonts.inter(color: textColor, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard({
    required PlanDay day,
    required bool isLight,
    required Color surfaceColor,
    required Color primaryColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
  }) {
    final isCompleting = _completing.contains(day.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: day.isCompleted
              ? const Color(0xFF22C55E).withValues(alpha: 0.4)
              : borderColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail / completed icon
            if (day.isCompleted)
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.check_circle_rounded,
                      color: Color(0xFF22C55E), size: 32),
                ),
              )
            else if (day.content?.thumbnailUrl != null)
              GestureDetector(
                onTap: () => _launchContent(day.content!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: day.content!.thumbnailUrl!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 72,
                          height: 72,
                          color: isLight ? const Color(0xFFF3F4F6) : const Color(0xFF2A2A2A),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          color: isLight ? const Color(0xFFF3F4F6) : const Color(0xFF2A2A2A),
                          child: Icon(Icons.play_circle_outline, color: textSecondary, size: 28),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.fitness_center_rounded, color: primaryColor, size: 28),
              ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          day.dayName,
                          style: GoogleFonts.inter(
                              color: primaryColor, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.content?.title ?? 'Rest Day',
                    style: GoogleFonts.inter(
                        color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (day.content != null)
                    Text(
                      '${day.content!.durationMinutes} min',
                      style: GoogleFonts.inter(color: textSecondary, fontSize: 12),
                    ),
                  if (day.coachNotes != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.sticky_note_2_outlined, color: textSecondary, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            day.coachNotes!,
                            style: GoogleFonts.inter(
                                color: textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (day.isCompleted && day.completedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Completed ${_formatDate(day.completedAt!)}',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),

            // CTA button
            if (!day.isCompleted && day.content != null) ...[
              const SizedBox(width: 8),
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _launchContent(day.content!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Start',
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: isCompleting ? null : () => _markComplete(day),
                    child: isCompleting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: primaryColor, strokeWidth: 2),
                          )
                        : Text(
                            'Done',
                            style: GoogleFonts.inter(
                                color: const Color(0xFF22C55E),
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
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

  void _launchContent(PlanContent content) {
    context.push('${AppRouter.videoPlayer}?id=${content.id}');
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return '';
    }
  }
}
