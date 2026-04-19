import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/coaching_service.dart';
import '../../data/models/coach_program_models.dart';
import '../bloc/coaching_bloc.dart';
import '../bloc/coach_program_bloc.dart';
import '../bloc/coach_chat_bloc.dart';

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
          body: BlocListener<CoachChatBloc, CoachChatState>(
            listener: (context, chatState) {
              if (chatState is CoachAdded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${chatState.chat.coach.name} is now your coach!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF22C55E),
                  ),
                );
                Navigator.pop(context);
              }
              if (chatState is CoachChatError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(chatState.message),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: BlocConsumer<CoachingBloc, CoachingState>(
              listener: (context, state) {
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
                  return Stack(
                    children: [
                      _buildProfile(
                        coach: state.coach,
                        isLight: isLight,
                        bgColor: bgColor,
                        surfaceColor: surfaceColor,
                        textColor: textColor,
                        textSecondary: textSecondary,
                        primaryColor: primaryColor,
                        borderColor: borderColor,
                      ),
                      // ── Airbnb-style bottom bar ──
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _buildBottomBar(
                          coach: state.coach,
                          isLight: isLight,
                          bgColor: bgColor,
                          textColor: textColor,
                          textSecondary: textSecondary,
                          borderColor: borderColor,
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar({
    required Coach coach,
    required bool isLight,
    required Color bgColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return BlocBuilder<CoachChatBloc, CoachChatState>(
      builder: (context, chatState) {
        final isAdding = chatState is AddingCoach;
        final hasThisCoach = chatState is CoachChatLoaded;

        return Container(
          padding: EdgeInsets.fromLTRB(
            20, 16, 20,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              top: BorderSide(color: borderColor, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Subscription info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Included with subscription',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '1-on-1 personal coaching',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // CTA button
              GestureDetector(
                onTap: hasThisCoach || isAdding
                    ? null
                    : () => context
                        .read<CoachChatBloc>()
                        .add(AddCoachEvent(widget.coachId)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: hasThisCoach
                        ? null
                        : const LinearGradient(
                            colors: [
                              Color(0xFFE51D53),
                              Color(0xFFD70466),
                            ],
                          ),
                    color: hasThisCoach
                        ? (isLight
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFF1B3A1E))
                        : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isAdding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          hasThisCoach
                              ? '✓ Your Coach'
                              : 'Add as My Coach',
                          style: GoogleFonts.inter(
                            color: hasThisCoach
                                ? const Color(0xFF22C55E)
                                : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfile({
    required Coach coach,
    required bool isLight,
    required Color bgColor,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color primaryColor,
    required Color borderColor,
  }) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Airbnb-style header with back button ──
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_rounded,
                        color: textColor, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Avatar + Name (Airbnb host-style) ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Large avatar
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.1),
                    ),
                    child: coach.expert.avatarUrl != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: coach.expert.avatarUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Center(
                                child: Text(
                                  coach.expert.name[0],
                                  style: GoogleFonts.inter(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Center(
                                child: Text(
                                  coach.expert.name[0],
                                  style: GoogleFonts.inter(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              coach.expert.name[0],
                              style: GoogleFonts.inter(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                Center(
                  child: Text(
                    coach.expert.name,
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                // Title
                if (coach.expert.title != null) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      coach.expert.title!,
                      style: GoogleFonts.inter(
                        color: textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Stats row (Airbnb review-style) ──
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(
                        value: '✓',
                        label: 'included',
                        textColor: textColor,
                        textSecondary: textSecondary,
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: borderColor,
                      ),
                      _buildStat(
                        value: '${coach.specialties.length}',
                        label: 'specialties',
                        textColor: textColor,
                        textSecondary: textSecondary,
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: borderColor,
                      ),
                      _buildStat(
                        value: '⭐',
                        label: 'top rated',
                        textColor: textColor,
                        textSecondary: textSecondary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Divider ──
                Container(height: 1, color: borderColor),
                const SizedBox(height: 28),

                // ── About section ──
                Text(
                  'About ${coach.expert.name.split(' ').first}',
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  coach.bio,
                  style: GoogleFonts.inter(
                    color: textColor.withOpacity(0.8),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 28),

                // ── Divider ──
                Container(height: 1, color: borderColor),
                const SizedBox(height: 28),

                // ── What they offer (specialties) ──
                if (coach.specialties.isNotEmpty) ...[
                  Text(
                    'What ${coach.expert.name.split(' ').first} offers',
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...coach.specialties.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(Icons.check_rounded,
                                color: primaryColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s,
                                style: GoogleFonts.inter(
                                  color: textColor,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 16),
                  Container(height: 1, color: borderColor),
                  const SizedBox(height: 28),
                ],

                // ── Programs ──
                BlocBuilder<CoachProgramBloc, CoachProgramState>(
                  builder: (context, programState) {
                    if (programState is CoachProgramsLoaded &&
                        programState.programs.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Programs',
                            style: GoogleFonts.inter(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...programState.programs
                              .take(3)
                              .map((prog) => _buildProgramCard(
                                    program: prog,
                                    isLight: isLight,
                                    surfaceColor: surfaceColor,
                                    textColor: textColor,
                                    textSecondary: textSecondary,
                                    borderColor: borderColor,
                                    primaryColor: primaryColor,
                                  )),
                          const SizedBox(height: 16),
                          Container(height: 1, color: borderColor),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Bottom spacing for the button
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStat({
    required String value,
    required String label,
    required Color textColor,
    required Color textSecondary,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
      ],
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
    return GestureDetector(
      onTap: () => context.push(
          '${AppRouter.coachProgramDetail}?id=${program.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
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
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: textSecondary, size: 22),
          ],
        ),
      ),
    );
  }
}
