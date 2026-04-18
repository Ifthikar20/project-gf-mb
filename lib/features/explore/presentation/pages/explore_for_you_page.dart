import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../videos/presentation/bloc/videos_bloc.dart';
import '../../../videos/presentation/bloc/videos_event.dart';
import '../../../videos/presentation/bloc/videos_state.dart';
import '../../../videos/domain/entities/video_entity.dart';
import '../../../meditation/presentation/bloc/meditation_bloc.dart';
import '../../../meditation/presentation/bloc/meditation_event.dart';
import '../../../meditation/presentation/bloc/meditation_state.dart';
import '../../../coaching/presentation/bloc/coaching_bloc.dart';
import '../../../../core/services/coaching_service.dart';
import '../../../coaching/presentation/bloc/coach_program_bloc.dart';
import '../../../coaching/data/models/coach_program_models.dart';
import '../../../marketplace/presentation/bloc/marketplace_bloc.dart';
import '../../../../core/services/marketplace_service.dart';

/// Glo-style Explore / For You feed.
/// Horizontal scrolling cards with thumbnails, level badges,
/// duration, ratings, instructor name, and category.
class ExploreForYouPage extends StatefulWidget {
  const ExploreForYouPage({super.key});

  @override
  State<ExploreForYouPage> createState() => _ExploreForYouPageState();
}

class _ExploreForYouPageState extends State<ExploreForYouPage> {
  String _selectedCategory = 'All';
  @override
  void initState() {
    super.initState();
    final videosState = context.read<VideosBloc>().state;
    if (videosState is VideosInitial) {
      context.read<VideosBloc>().add(const LoadVideos());
    }
    final meditationState = context.read<MeditationBloc>().state;
    if (meditationState is MeditationInitial) {
      context.read<MeditationBloc>().add(LoadMeditationAudios());
    }
    // Load coaches and marketplace programs for explore sections
    context.read<CoachingBloc>().add(const LoadCoaches());
    context.read<CoachProgramBloc>().add(const LoadCoachPrograms());
    context.read<MarketplaceBloc>().add(const LoadPrograms());
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Explore',
                          style: GoogleFonts.inter(
                            color: textColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
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
                  ),
                ),
              ),

              // ── Category Pills ──
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    children: [
                      'All', 'Wellness', 'Fitness', 'Mindfulness',
                      'Yoga', 'HIIT', 'Pilates', 'Meditation', 'Nutrition',
                    ].map((cat) {
                      final isActive = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? (isLight ? Colors.black : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive
                                    ? Colors.transparent
                                    : borderColor,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isActive
                                    ? (isLight ? Colors.white : Colors.black)
                                    : textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // ── Featured / For You ──
              _buildSectionTitle('For You', textColor),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: _buildFeaturedRow(
                    isLight: isLight,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    primaryColor: primaryColor,
                    isNew: false,
                  ),
                ),
              ),

              // ── New Classes ──
              _buildSectionTitle('New Classes', textColor),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: _buildFeaturedRow(
                    isLight: isLight,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    primaryColor: primaryColor,
                    isNew: true,
                  ),
                ),
              ),

              // ── Trending ──
              _buildSectionTitle('Trending', textColor),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: _buildTrendingRow(
                    isLight: isLight,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    primaryColor: primaryColor,
                  ),
                ),
              ),

              // ── Live Coaching ──
              _buildSectionTitleWithAction(
                'Live Coaching',
                'See All',
                textColor,
                textSecondary,
                () => context.push(AppRouter.coaches),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: _buildCoachesRow(
                    isLight: isLight,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    primaryColor: primaryColor,
                  ),
                ),
              ),

              // ── Coach Programs ──
              _buildSectionTitleWithAction(
                'Coach Programs',
                'See All',
                textColor,
                textSecondary,
                () => context.push(AppRouter.coachPrograms),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: _buildCoachProgramsRow(
                    isLight: isLight,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    primaryColor: primaryColor,
                  ),
                ),
              ),

              // ── Marketplace Programs ──
              _buildSectionTitleWithAction(
                'Programs',
                'Browse All',
                textColor,
                textSecondary,
                () => context.push(AppRouter.marketplace),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 230,
                  child: _buildMarketplaceRow(
                    isLight: isLight,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    primaryColor: primaryColor,
                  ),
                ),
              ),

              // ── Wellness Audio ──
              _buildSectionTitle('Wellness Audio', textColor),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: _buildAudioRow(
                    isLight: isLight,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    primaryColor: primaryColor,
                  ),
                ),
              ),

              // Bottom spacing
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────
  // Featured / For You row
  // ─────────────────────────────────
  Widget _buildFeaturedRow({
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
    required bool isNew,
  }) {
    return BlocBuilder<VideosBloc, VideosState>(
      builder: (context, state) {
        if (state is VideosLoaded) {
          var videos = state.videos;
          // Filter by category
          if (_selectedCategory != 'All') {
            videos = videos
                .where((v) => v.category.toLowerCase()
                    .contains(_selectedCategory.toLowerCase()))
                .toList();
          }
          // Split list: first half for "For You", second for "New"
          final start = isNew ? (videos.length ~/ 2) : 0;
          final end = isNew ? videos.length : (videos.length ~/ 2);
          final subset = videos.sublist(
            start.clamp(0, videos.length),
            end.clamp(0, videos.length),
          );
          if (subset.isEmpty) {
            return Center(
              child: Text('No classes yet',
                  style: GoogleFonts.inter(color: textSecondary)),
            );
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: subset.length,
            itemBuilder: (context, index) {
              return _buildClassCard(
                video: subset[index],
                isLight: isLight,
                surfaceColor: surfaceColor,
                textColor: textColor,
                textSecondary: textSecondary,
                borderColor: borderColor,
                showNewBadge: isNew,
              );
            },
          );
        }
        return Center(
          child:
              CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
        );
      },
    );
  }

  // ─────────────────────────────────
  // Trending row (reversed order)
  // ─────────────────────────────────
  Widget _buildTrendingRow({
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return BlocBuilder<VideosBloc, VideosState>(
      builder: (context, state) {
        if (state is VideosLoaded) {
          var videos = state.videos.reversed.toList();
          if (_selectedCategory != 'All') {
            videos = videos
                .where((v) => v.category.toLowerCase()
                    .contains(_selectedCategory.toLowerCase()))
                .toList();
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              return _buildClassCard(
                video: videos[index],
                isLight: isLight,
                surfaceColor: surfaceColor,
                textColor: textColor,
                textSecondary: textSecondary,
                borderColor: borderColor,
                showNewBadge: false,
              );
            },
          );
        }
        return Center(
          child:
              CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
        );
      },
    );
  }

  /// Glo-style class card — large thumbnail, level badge, duration badge,
  /// rating star, title below, instructor • category
  Widget _buildClassCard({
    required VideoEntity video,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    bool showNewBadge = false,
  }) {
    final durationMin =
        video.durationInSeconds > 0 ? video.durationInSeconds ~/ 60 : 30;
    final rng = Random(video.id.hashCode);
    final rating = (4.0 + rng.nextDouble()).toStringAsFixed(1);
    final level = 'Level ${rng.nextInt(2) + 1}${rng.nextBool() ? '-${rng.nextInt(2) + 2}' : ''}';

    return GestureDetector(
      onTap: () {
        if (video.isSeries && video.seriesId != null) {
          context.push(
              '${AppRouter.programEnroll}?seriesId=${video.seriesId}');
        } else {
          context.push('${AppRouter.videoPlayer}?id=${video.id}');
        }
      },
      child: Container(
        width: 230,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ──
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: video.thumbnailUrl,
                      fit: BoxFit.cover,
                      memCacheHeight: 320,
                      memCacheWidth: 460,
                      placeholder: (_, __) => Container(color: surfaceColor),
                      errorWidget: (_, __, ___) => Container(
                        color: surfaceColor,
                        child: Icon(Icons.play_circle_outline,
                            color: textSecondary, size: 48),
                      ),
                    ),
                    // Bottom badges
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Row(
                        children: [
                          // Level badge
                          _badge(
                            icon: Icons.bar_chart_rounded,
                            text: level,
                            isLight: isLight,
                          ),
                          const SizedBox(width: 6),
                          // Duration badge
                          _badge(
                            icon: null,
                            text: '$durationMin mins',
                            isLight: isLight,
                          ),
                        ],
                      ),
                    ),
                    // Rating star — top right
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: _badge(
                        icon: Icons.star_rounded,
                        text: rating,
                        isLight: isLight,
                        iconColor: const Color(0xFFF59E0B),
                      ),
                    ),
                    // New badge
                    if (showNewBadge)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLight
                                ? Colors.black.withOpacity(0.7)
                                : Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'New',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isLight ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // ── Title row ──
            Row(
              children: [
                Text(
                  '···',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textSecondary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    video.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // ── Instructor • Category ──
            Text(
              '${video.instructor.isNotEmpty ? video.instructor : "Guest Teacher"} • ${video.category.isNotEmpty ? video.category : "Wellness"}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // ── Series badge + description ──
            if (video.isSeries && video.episodeCount != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.playlist_play_rounded,
                      size: 16, color: textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${video.episodeCount} episodes',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            if (video.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                video.description,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: textSecondary.withValues(alpha: 0.7),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge({
    IconData? icon,
    required String text,
    required bool isLight,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.black.withOpacity(0.55)
            : Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: iconColor ?? Colors.white),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitleWithAction(
    String title,
    String actionText,
    Color textColor,
    Color textSecondary,
    VoidCallback onAction,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionText,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────
  // Live Coaching row
  // ─────────────────────────────────
  Widget _buildCoachesRow({
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return BlocBuilder<CoachingBloc, CoachingState>(
      builder: (context, state) {
        if (state is CoachesLoaded && state.coaches.isNotEmpty) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: state.coaches.length,
            itemBuilder: (context, index) {
              final coach = state.coaches[index];
              return _buildCoachCard(
                coach: coach,
                isLight: isLight,
                surfaceColor: surfaceColor,
                textColor: textColor,
                textSecondary: textSecondary,
                borderColor: borderColor,
                primaryColor: primaryColor,
              );
            },
          );
        }
        if (state is CoachingLoading) {
          return Center(
            child: CircularProgressIndicator(
                color: primaryColor, strokeWidth: 2),
          );
        }
        // Empty or error — show placeholder
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.video_camera_front_outlined,
                    color: textSecondary, size: 36),
                const SizedBox(height: 8),
                Text(
                  'Book 1:1 sessions with expert coaches',
                  style: GoogleFonts.inter(
                      color: textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────
  // Coach Programs row
  // ─────────────────────────────────
  Widget _buildCoachProgramsRow({
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return BlocBuilder<CoachProgramBloc, CoachProgramState>(
      builder: (context, state) {
        if (state is CoachProgramsLoaded && state.programs.isNotEmpty) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: state.programs.length,
            itemBuilder: (context, index) {
              final program = state.programs[index];
              return _buildCoachProgramCard(
                program: program,
                isLight: isLight,
                surfaceColor: surfaceColor,
                textColor: textColor,
                textSecondary: textSecondary,
                borderColor: borderColor,
                primaryColor: primaryColor,
              );
            },
          );
        }
        if (state is CoachProgramLoading) {
          return Center(
            child: CircularProgressIndicator(
                color: primaryColor, strokeWidth: 2),
          );
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined,
                    color: textSecondary, size: 36),
                const SizedBox(height: 8),
                Text(
                  'Structured training programs from expert coaches',
                  style: GoogleFonts.inter(
                      color: textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoachProgramCard({
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
        width: 200,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isLight ? 0.04 : 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (program.coverImageUrl != null)
                      CachedNetworkImage(
                        imageUrl: program.coverImageUrl!,
                        fit: BoxFit.cover,
                        memCacheHeight: 240,
                        memCacheWidth: 400,
                        placeholder: (_, __) =>
                            Container(color: surfaceColor),
                        errorWidget: (_, __, ___) => Container(
                          color: surfaceColor,
                          child: Icon(Icons.fitness_center_rounded,
                              color: textSecondary, size: 32),
                        ),
                      )
                    else
                      Container(
                        color: surfaceColor,
                        child: Icon(Icons.fitness_center_rounded,
                            color: textSecondary, size: 32),
                      ),
                    // Duration badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          program.durationLabel,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'With ${program.coach.name}  •  ${program.level}',
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
      ),
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
        width: 160,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isLight ? 0.04 : 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: primaryColor.withOpacity(0.15),
              backgroundImage: coach.expert.avatarUrl != null
                  ? CachedNetworkImageProvider(coach.expert.avatarUrl!)
                  : null,
              child: coach.expert.avatarUrl == null
                  ? Text(
                      coach.expert.name[0],
                      style: GoogleFonts.inter(
                        color: primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            // Name
            Text(
              coach.expert.name,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (coach.expert.title != null) ...[
              const SizedBox(height: 2),
              Text(
                coach.expert.title!,
                style: GoogleFonts.inter(
                  color: textSecondary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
            const Spacer(),
            // Price + live indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  coach.discountedRate != null
                      ? '\$${coach.discountedRate}/hr'
                      : '\$${coach.hourlyRate}/hr',
                  style: GoogleFonts.inter(
                    color: coach.discountedRate != null
                        ? const Color(0xFF22C55E)
                        : textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────
  // Marketplace Programs row
  // ─────────────────────────────────
  Widget _buildMarketplaceRow({
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return BlocBuilder<MarketplaceBloc, MarketplaceState>(
      builder: (context, state) {
        if (state is MarketplaceProgramsLoaded && state.programs.isNotEmpty) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: state.programs.length,
            itemBuilder: (context, index) {
              final program = state.programs[index];
              return _buildProgramCard(
                program: program,
                isLight: isLight,
                surfaceColor: surfaceColor,
                textColor: textColor,
                textSecondary: textSecondary,
                borderColor: borderColor,
                primaryColor: primaryColor,
              );
            },
          );
        }
        if (state is MarketplaceLoading) {
          return Center(
            child: CircularProgressIndicator(
                color: primaryColor, strokeWidth: 2),
          );
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront_outlined,
                    color: textSecondary, size: 36),
                const SizedBox(height: 8),
                Text(
                  'Creator programs coming soon',
                  style: GoogleFonts.inter(
                      color: textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgramCard({
    required MarketplaceProgram program,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: () =>
          context.push('${AppRouter.marketplaceDetail}?id=${program.id}'),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: program.coverImageUrl ?? '',
                      fit: BoxFit.cover,
                      memCacheHeight: 300,
                      memCacheWidth: 400,
                      placeholder: (_, __) =>
                          Container(color: surfaceColor),
                      errorWidget: (_, __, ___) => Container(
                        color: surfaceColor,
                        child: Icon(Icons.image_outlined,
                            color: textSecondary, size: 36),
                      ),
                    ),
                    // Price badge
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '\$${program.price}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Purchased badge
                    if (program.isPurchased)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Owned',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              program.title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Creator + lessons
            Text(
              '${program.creator.displayName} • ${program.contentCount} lessons',
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
    );
  }

  // ─────────────────────────────────
  // Audio / Wellness row
  // ─────────────────────────────────
  Widget _buildAudioRow({
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return BlocBuilder<MeditationBloc, MeditationState>(
      builder: (context, state) {
        if (state is MeditationLoaded) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: state.audios.length,
            itemBuilder: (context, index) {
              final audio = state.audios[index];
              return GestureDetector(
                onTap: () {
                  context.push('${AppRouter.audioPlayer}?id=${audio.id}');
                },
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 130,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: audio.imageUrl,
                            fit: BoxFit.cover,
                            width: 150,
                            memCacheHeight: 260,
                            memCacheWidth: 300,
                            placeholder: (_, __) =>
                                Container(color: surfaceColor),
                            errorWidget: (_, __, ___) => Container(
                              color: surfaceColor,
                              child: Icon(Icons.headphones_rounded,
                                  color: textSecondary, size: 32),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        audio.title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        audio.description,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        return Center(
          child:
              CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
        );
      },
    );
  }
}
