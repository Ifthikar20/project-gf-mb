import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/coaching_service.dart';
import '../bloc/coaching_bloc.dart';

class CoachesPage extends StatefulWidget {
  const CoachesPage({super.key});

  @override
  State<CoachesPage> createState() => _CoachesPageState();
}

class _CoachesPageState extends State<CoachesPage> {
  @override
  void initState() {
    super.initState();
    context.read<CoachingBloc>().add(const LoadCoaches());
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
              'Live Coaching',
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.calendar_today_outlined,
                    color: textColor, size: 20),
                onPressed: () => context.push(AppRouter.coachingSessions),
              ),
            ],
          ),
          body: BlocBuilder<CoachingBloc, CoachingState>(
            builder: (context, state) {
              if (state is CoachingLoading) {
                return Center(
                  child: CircularProgressIndicator(
                      color: primaryColor, strokeWidth: 2),
                );
              }
              if (state is CoachingError) {
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
                            .read<CoachingBloc>()
                            .add(const LoadCoaches()),
                        child: Text('Retry',
                            style: GoogleFonts.inter(
                                color: primaryColor,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
              }
              if (state is CoachesLoaded) {
                if (state.coaches.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_search_outlined,
                            color: textSecondary, size: 48),
                        const SizedBox(height: 12),
                        Text('No coaches available',
                            style: GoogleFonts.inter(
                                color: textSecondary, fontSize: 14)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: state.coaches.length,
                  itemBuilder: (context, index) => _buildCoachCard(
                    coach: state.coaches[index],
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

  Widget _buildCoachCard({
    required Coach coach,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: () =>
          context.push('${AppRouter.coachDetail}?id=${coach.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isLight ? 0.04 : 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: primaryColor.withOpacity(0.15),
              backgroundImage: coach.expert.avatarUrl != null
                  ? CachedNetworkImageProvider(coach.expert.avatarUrl!)
                  : null,
              child: coach.expert.avatarUrl == null
                  ? Text(
                      coach.expert.name[0],
                      style: GoogleFonts.inter(
                        color: primaryColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coach.expert.name,
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (coach.expert.title != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      coach.expert.title!,
                      style: GoogleFonts.inter(
                        color: textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Specialties
                  if (coach.specialties.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: coach.specialties
                          .take(3)
                          .map(
                            (s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                s,
                                style: GoogleFonts.inter(
                                  color: primaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 10),
                  // Price row
                  Row(
                    children: [
                      if (coach.discountedRate != null) ...[
                        Text(
                          '\$${coach.hourlyRate}',
                          style: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: 13,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '\$${coach.discountedRate}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF22C55E),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Premium',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF22C55E),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ] else
                        Text(
                          '\$${coach.hourlyRate}/hr',
                          style: GoogleFonts.inter(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const Spacer(),
                      if (coach.hasCalcom && coach.isAcceptingClients)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Book',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        Text(
                          'Coming soon',
                          style: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
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
    );
  }
}
