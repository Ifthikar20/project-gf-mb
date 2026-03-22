import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../videos/presentation/bloc/videos_bloc.dart';
import '../../../videos/presentation/bloc/videos_event.dart';
import '../../../videos/presentation/bloc/videos_state.dart';
import '../../../meditation/presentation/bloc/meditation_bloc.dart';
import '../../../meditation/presentation/bloc/meditation_event.dart';
import '../../../meditation/presentation/bloc/meditation_state.dart';
import '../bloc/class_schedule_bloc.dart';
import '../bloc/class_schedule_event.dart';
import '../bloc/class_schedule_state.dart';
import '../../data/models/scheduled_class_model.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late DateTime _selectedDate;
  late DateTime _weekStart;
  late String _currentMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _weekStart = _getWeekStart(_selectedDate);
    _currentMonth = DateFormat('MMMM yyyy').format(_selectedDate);

    final videosState = context.read<VideosBloc>().state;
    if (videosState is VideosInitial) {
      context.read<VideosBloc>().add(const LoadVideos());
    }
    final meditationState = context.read<MeditationBloc>().state;
    if (meditationState is MeditationInitial) {
      context.read<MeditationBloc>().add(LoadMeditationAudios());
    }

    // Load classes for today
    context
        .read<ClassScheduleBloc>()
        .add(LoadClasses(date: _selectedDate));
  }

  DateTime _getWeekStart(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday % 7));
  }

  void _shiftWeek(int direction) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * direction));
      _currentMonth = DateFormat('MMMM yyyy').format(_weekStart);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    context.read<ClassScheduleBloc>().add(LoadClasses(date: date));
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSelected(DateTime date) {
    return date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
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
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Find Upcoming Classes',
                                style: GoogleFonts.inter(
                                  color: textColor,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push(AppRouter.search),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: borderColor),
                                ),
                                child: Icon(Icons.search,
                                    color: textColor, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Practice with our expert teachers and community.\nChoose from classes that fit your schedule and mood.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Week Calendar ──
              SliverToBoxAdapter(
                child: _buildWeekCalendar(
                  isLight: isLight,
                  textColor: textColor,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                  bgColor: bgColor,
                ),
              ),

              // ── Class Schedule (from bloc) ──
              _buildClassSchedule(
                isLight: isLight,
                bgColor: bgColor,
                surfaceColor: surfaceColor,
                textColor: textColor,
                textSecondary: textSecondary,
                borderColor: borderColor,
                primaryColor: primaryColor,
              ),

              // Bottom spacing
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────
  // Week calendar strip
  // ─────────────────────────────────
  Widget _buildWeekCalendar({
    required bool isLight,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
    required Color bgColor,
  }) {
    final dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          // Month + navigation arrows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentMonth,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _shiftWeek(-1),
                    child: Icon(Icons.chevron_left_rounded,
                        color: textSecondary, size: 26),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _shiftWeek(1),
                    child: Icon(Icons.chevron_right_rounded,
                        color: textSecondary, size: 26),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days.map((d) {
              final dayIndex = d.weekday % 7;
              return Expanded(
                child: Center(
                  child: Text(
                    _isToday(d) ? 'Today' : dayLabels[dayIndex],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Date numbers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days.map((d) {
              final selected = _isSelected(d);
              return Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(d),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: selected
                            ? (isLight ? Colors.black : Colors.white)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${d.day}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? (isLight ? Colors.white : Colors.black)
                                : textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Divider(color: borderColor, height: 1),
        ],
      ),
    );
  }

  // ─────────────────────────────────
  // Class Schedule — from ClassScheduleBloc
  // ─────────────────────────────────
  Widget _buildClassSchedule({
    required bool isLight,
    required Color bgColor,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return BlocBuilder<ClassScheduleBloc, ClassScheduleState>(
      builder: (context, state) {
        if (state is ClassScheduleLoaded) {
          final morning = state.morningClasses;
          final afternoon = state.afternoonClasses;

          if (morning.isEmpty && afternoon.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_available_rounded,
                          color: textSecondary, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No classes scheduled for this day',
                        style: GoogleFonts.inter(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Morning ──
                  if (morning.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.wb_sunny_outlined,
                            size: 18, color: textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'Morning',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...morning.map((cls) => _buildClassRow(
                          cls: cls,
                          isLight: isLight,
                          surfaceColor: surfaceColor,
                          textColor: textColor,
                          textSecondary: textSecondary,
                          borderColor: borderColor,
                          primaryColor: primaryColor,
                        )),
                  ],
                  // ── Afternoon ──
                  if (afternoon.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.wb_twilight_outlined,
                            size: 18, color: textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'Afternoon',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...afternoon.map((cls) => _buildClassRow(
                          cls: cls,
                          isLight: isLight,
                          surfaceColor: surfaceColor,
                          textColor: textColor,
                          textSecondary: textSecondary,
                          borderColor: borderColor,
                          primaryColor: primaryColor,
                        )),
                  ],
                ],
              ),
            ),
          );
        }
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(
                  color: primaryColor, strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }

  /// Individual class row with reminder toggle
  Widget _buildClassRow({
    required ScheduledClassModel cls,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: () {
        if (cls.videoId != null) {
          context.push('${AppRouter.videoPlayer}?id=${cls.videoId}');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: cls.thumbnailUrl ?? '',
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    memCacheHeight: 180,
                    memCacheWidth: 180,
                    placeholder: (_, __) => Container(
                      width: 90,
                      height: 90,
                      color: isLight
                          ? const Color(0xFFF3F4F6)
                          : const Color(0xFF2A2A2A),
                      child: Icon(Icons.play_circle_outline,
                          color: textSecondary, size: 28),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 90,
                      height: 90,
                      color: isLight
                          ? const Color(0xFFF3F4F6)
                          : const Color(0xFF2A2A2A),
                      child: Icon(Icons.play_circle_outline,
                          color: textSecondary, size: 28),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Class info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cls.timeRange,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    cls.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'With ${cls.instructor}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                  Text(
                    '${cls.durationMinutes} minutes • ${cls.level}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                  Text(
                    '${cls.category} • ${cls.signedUpCount} signed up',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Reminder toggle
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                final bloc = context.read<ClassScheduleBloc>();
                if (cls.hasReminder && cls.reminderId != null) {
                  bloc.add(CancelClassReminder(
                    classId: cls.id,
                    reminderId: cls.reminderId!,
                  ));
                } else {
                  bloc.add(SetClassReminder(classId: cls.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reminder set for ${cls.title}'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cls.hasReminder
                      ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                      : (isLight
                          ? Colors.black.withValues(alpha: 0.04)
                          : Colors.white.withValues(alpha: 0.06)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  cls.hasReminder
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  size: 18,
                  color: cls.hasReminder
                      ? const Color(0xFF22C55E)
                      : textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
