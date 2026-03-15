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
import '../widgets/breathing_exercise_card.dart';

/// Glo-style Explore / For You feed.
/// Horizontal scrolling cards with thumbnails, level badges,
/// duration, ratings, instructor name, and category.
class ExploreForYouPage extends StatefulWidget {
  const ExploreForYouPage({super.key});

  @override
  State<ExploreForYouPage> createState() => _ExploreForYouPageState();
}

class _ExploreForYouPageState extends State<ExploreForYouPage> {
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

              // ── Featured / For You ──
              _buildSectionTitle('For You', textColor),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 290,
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
                  height: 290,
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

              // ── Breathing Exercise ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: BreathingExerciseCard(isLight: isLight),
                ),
              ),

              // ── Trending ──
              _buildSectionTitle('Trending', textColor),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 290,
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
          final videos = state.videos;
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
          final videos = state.videos.reversed.toList();
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
        width: 280,
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
