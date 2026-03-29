import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/services/coaching_service.dart';
import '../../../../core/services/workout_plan_service.dart';

class FreeConsultationPage extends StatefulWidget {
  const FreeConsultationPage({super.key});

  @override
  State<FreeConsultationPage> createState() => _FreeConsultationPageState();
}

class _FreeConsultationPageState extends State<FreeConsultationPage> {
  ConsultationStatus? _status;
  List<Coach> _coaches = [];
  bool _loading = true;
  String? _error;

  Coach? _selectedCoach;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _booking = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        WorkoutPlanService.instance.getConsultationStatus(),
        CoachingService.instance.getCoaches(),
      ]);
      if (mounted) {
        setState(() {
          _status = results[0] as ConsultationStatus;
          _coaches = results[1] as List<Coach>;
          _loading = false;
        });
      }
    } on WorkoutPlanException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Failed to load data.'; });
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null && mounted) setState(() => _selectedTime = picked);
  }

  Future<void> _book(BuildContext context) async {
    if (_selectedCoach == null || _selectedDate == null || _selectedTime == null) return;

    final scheduledAt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    setState(() => _booking = true);
    try {
      final result = await WorkoutPlanService.instance.bookConsultation(
        coachId: _selectedCoach!.id,
        scheduledAt: scheduledAt,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Free consultation booked!'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        context.pushReplacement(AppRouter.coachingSessions);
      }
    } on WorkoutPlanException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _booking = false);
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
              'Free Consultation',
              style: GoogleFonts.inter(color: textColor, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(color: borderColor, height: 1),
            ),
          ),
          body: _loading
              ? Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2))
              : _error != null
                  ? _buildError(primaryColor, textSecondary)
                  : _buildContent(
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

  Widget _buildError(Color primaryColor, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: textSecondary, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: GoogleFonts.inter(color: textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _loadData,
            child: Text('Retry', style: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent({
    required bool isLight,
    required Color bgColor,
    required Color surfaceColor,
    required Color primaryColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
  }) {
    // Already used this month
    if (_status != null && !_status!.eligible) {
      return _buildUsedState(primaryColor, textColor, textSecondary, surfaceColor, borderColor);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Benefit card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.calendar_today_rounded, color: primaryColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You have 1 free 20-min session!',
                        style: GoogleFonts.inter(
                            color: textColor, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your coach will build a personalised plan after your session.',
                        style: GoogleFonts.inter(color: textSecondary, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Coach selection
          Text(
            'Select a Coach',
            style: GoogleFonts.inter(color: textColor, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (_coaches.isEmpty)
            Text('No coaches available.', style: GoogleFonts.inter(color: textSecondary, fontSize: 14))
          else
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _coaches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final coach = _coaches[i];
                  final selected = _selectedCoach?.id == coach.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCoach = coach),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 80,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? primaryColor.withValues(alpha: 0.1) : surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? primaryColor : borderColor,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: primaryColor.withValues(alpha: 0.15),
                            backgroundImage: coach.expert.avatarUrl != null
                                ? CachedNetworkImageProvider(coach.expert.avatarUrl!)
                                : null,
                            child: coach.expert.avatarUrl == null
                                ? Text(coach.expert.name[0],
                                    style: GoogleFonts.inter(
                                        color: primaryColor, fontWeight: FontWeight.w700))
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            coach.expert.name.split(' ').first,
                            style: GoogleFonts.inter(
                              color: selected ? primaryColor : textColor,
                              fontSize: 11,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 28),

          // Date & time pickers
          Text(
            'Pick a Date & Time',
            style: GoogleFonts.inter(color: textColor, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickDate(context),
                  child: _pickerTile(
                    icon: Icons.calendar_today_rounded,
                    label: _selectedDate != null
                        ? DateFormat('MMM d, yyyy').format(_selectedDate!)
                        : 'Select date',
                    isLight: isLight,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    primaryColor: primaryColor,
                    filled: _selectedDate != null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(context),
                  child: _pickerTile(
                    icon: Icons.access_time_rounded,
                    label: _selectedTime != null
                        ? _selectedTime!.format(context)
                        : 'Select time',
                    isLight: isLight,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    primaryColor: primaryColor,
                    filled: _selectedTime != null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Book button
          GestureDetector(
            onTap: (_selectedCoach != null && _selectedDate != null && _selectedTime != null && !_booking)
                ? () => _book(context)
                : null,
            child: AnimatedOpacity(
              opacity: (_selectedCoach != null && _selectedDate != null && _selectedTime != null)
                  ? 1.0
                  : 0.4,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _booking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Book Free Consultation',
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String label,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
    required bool filled,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: filled ? primaryColor.withValues(alpha: 0.07) : surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: filled ? primaryColor.withValues(alpha: 0.3) : borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: filled ? primaryColor : textSecondary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: filled ? textColor : textSecondary,
                fontSize: 13,
                fontWeight: filled ? FontWeight.w500 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsedState(Color primaryColor, Color textColor, Color textSecondary,
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
                color: textSecondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_busy_rounded, color: textSecondary, size: 34),
            ),
            const SizedBox(height: 20),
            Text(
              'Already used this month',
              style: GoogleFonts.inter(color: textColor, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _status?.message ?? 'You have already used your free consultation this month.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => context.push(AppRouter.myWorkoutPlan),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'View My Plan',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
