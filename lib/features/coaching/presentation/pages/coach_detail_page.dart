import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/coaching_service.dart';
import '../../data/models/coach_program_models.dart';
import '../bloc/coaching_bloc.dart';
import '../bloc/coach_program_bloc.dart';

class CoachDetailPage extends StatefulWidget {
  final String coachId;
  const CoachDetailPage({super.key, required this.coachId});

  @override
  State<CoachDetailPage> createState() => _CoachDetailPageState();
}

class _CoachDetailPageState extends State<CoachDetailPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<CoachingBloc>()
        .add(LoadCoachDetail(coachId: widget.coachId));
    // Also load programs by this coach
    context
        .read<CoachProgramBloc>()
        .add(LoadCoachPrograms(coachId: widget.coachId));
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
        final primaryColor = ThemeColors.primary(mode);
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
              'Coach Profile',
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          body: BlocConsumer<CoachingBloc, CoachingState>(
            listener: (context, state) {
              if (state is CoachingBookingUrlReady) {
                _openBooking(state.bookingUrl);
              }
              if (state is CoachingError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is CoachingLoading) {
                return Center(
                  child: CircularProgressIndicator(
                      color: primaryColor, strokeWidth: 2),
                );
              }
              if (state is CoachDetailLoaded) {
                final coach = state.coach;
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile header
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: primaryColor.withOpacity(0.15),
                              backgroundImage: coach.expert.avatarUrl != null
                                  ? CachedNetworkImageProvider(
                                      coach.expert.avatarUrl!)
                                  : null,
                              child: coach.expert.avatarUrl == null
                                  ? Text(
                                      coach.expert.name[0],
                                      style: GoogleFonts.inter(
                                        color: primaryColor,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              coach.expert.name,
                              style: GoogleFonts.inter(
                                color: textColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (coach.expert.title != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                coach.expert.title!,
                                style: GoogleFonts.inter(
                                  color: textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Price card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.payments_outlined,
                                color: textSecondary, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              '\$${coach.hourlyRate}/hr',
                              style: GoogleFonts.inter(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // About
                      Text(
                        'About',
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        coach.bio,
                        style: GoogleFonts.inter(
                          color: textColor.withOpacity(0.8),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Specialties
                      if (coach.specialties.isNotEmpty) ...[
                        Text(
                          'Specialties',
                          style: GoogleFonts.inter(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: coach.specialties
                              .map(
                                (s) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: primaryColor.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    s,
                                    style: GoogleFonts.inter(
                                      color: primaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],

                      // ── Programs by this Coach ──
                      const SizedBox(height: 24),
                      BlocBuilder<CoachProgramBloc, CoachProgramState>(
                        builder: (context, programState) {
                          if (programState is CoachProgramsLoaded &&
                              programState.programs.isNotEmpty) {
                            return Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Programs',
                                      style: GoogleFonts.inter(
                                        color: textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => context.push(
                                          AppRouter.coachPrograms),
                                      child: Text(
                                        'See All',
                                        style: GoogleFonts.inter(
                                          color: textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...programState.programs
                                    .take(3)
                                    .map((prog) => _buildCoachProgramRow(
                                          program: prog,
                                          isLight: isLight,
                                          surfaceColor: surfaceColor,
                                          textColor: textColor,
                                          textSecondary: textSecondary,
                                          borderColor: borderColor,
                                          primaryColor: primaryColor,
                                        )),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Bottom book button
          bottomNavigationBar: BlocBuilder<CoachingBloc, CoachingState>(
            builder: (context, state) {
              if (state is CoachDetailLoaded) {
                final coach = state.coach;
                if (!coach.hasCalcom || !coach.isAcceptingClients) {
                  return Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border(
                        top: BorderSide(color: borderColor, width: 0.5),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Scheduling coming soon',
                          style: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border(
                      top: BorderSide(color: borderColor, width: 0.5),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () => context
                        .read<CoachingBloc>()
                        .add(GetBookingUrl(coachId: widget.coachId)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Book a Session',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
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

  Future<void> _openBooking(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildCoachProgramRow({
    required CoachProgram program,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: () => context.push(
          '${AppRouter.coachProgramDetail}?id=${program.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 56,
                child: program.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: program.coverImageUrl!,
                        fit: BoxFit.cover,
                        memCacheHeight: 112,
                        memCacheWidth: 112,
                        placeholder: (_, __) =>
                            Container(color: borderColor),
                        errorWidget: (_, __, ___) => Container(
                          color: borderColor,
                          child: Icon(Icons.fitness_center_rounded,
                              color: textSecondary, size: 20),
                        ),
                      )
                    : Container(
                        color: borderColor,
                        child: Icon(Icons.fitness_center_rounded,
                            color: textSecondary, size: 20),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${program.durationLabel}  •  ${program.contentCount} sessions',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
