import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../videos/domain/entities/series_entity.dart';
import '../../../videos/domain/entities/episode_entity.dart';
import '../../../videos/data/repositories/videos_repository.dart';

/// Program enrollment detail screen.
/// Shows program overview, episode list, total duration, and a Start CTA.
class ProgramEnrollPage extends StatefulWidget {
  final String seriesId;
  final SeriesEntity? series;

  const ProgramEnrollPage({
    super.key,
    required this.seriesId,
    this.series,
  });

  @override
  State<ProgramEnrollPage> createState() => _ProgramEnrollPageState();
}

class _ProgramEnrollPageState extends State<ProgramEnrollPage> {
  SeriesEntity? _series;
  bool _loading = true;
  bool _enrolled = false;

  @override
  void initState() {
    super.initState();
    if (widget.series != null) {
      _series = widget.series;
      _loading = false;
    } else {
      _fetchSeries();
    }
  }

  Future<void> _fetchSeries() async {
    try {
      final repo = context.read<VideosRepository>();
      final series = await repo.getSeriesWithEpisodes(widget.seriesId);
      if (mounted) {
        setState(() {
          _series = series;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatTotalDuration(List<EpisodeEntity> episodes) {
    final totalSeconds =
        episodes.fold<int>(0, (sum, ep) => sum + ep.durationSeconds);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes} min';
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
          body: _loading
              ? Center(
                  child: CircularProgressIndicator(
                      color: primaryColor, strokeWidth: 2))
              : _series == null
                  ? _buildError(textColor, textSecondary)
                  : _buildContent(
                      isLight: isLight,
                      bgColor: bgColor,
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                      primaryColor: primaryColor,
                    ),
        );
      },
    );
  }

  Widget _buildError(Color textColor, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: textSecondary),
          const SizedBox(height: 12),
          Text('Program not found',
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Go back',
                style: GoogleFonts.inter(
                    color: const Color(0xFF007AFF), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent({
    required bool isLight,
    required Color bgColor,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    final series = _series!;
    final episodes = series.episodes;
    final totalDuration = _formatTotalDuration(episodes);
    final enrolledCount = (series.episodeCount * 127) + 342;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero Image with overlaid info ──
        SliverToBoxAdapter(
          child: Stack(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.48,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: series.thumbnailUrl ??
                      'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800&h=600&fit=crop',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: surfaceColor,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: primaryColor, strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: surfaceColor,
                    child: Icon(Icons.image_not_supported,
                        size: 48, color: textSecondary),
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
              // Overlaid Title + Meta at bottom of hero
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.title,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          series.contentType == 'video'
                              ? 'Video Series'
                              : 'Audio Series',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (series.expertName != null) ...[
                          Text(
                            '  with  ',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            series.expertName!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Level 1 • $totalDuration',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Info section below hero ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructor avatar + class count + enrolled
                Row(
                  children: [
                    // Instructor avatar
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
                          series.expertName?.isNotEmpty == true
                              ? series.expertName![0].toUpperCase()
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
                    // Class count badge
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
                            '${series.episodeCount}',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'classes',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Enrolled people avatar stack
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
                                    child: Icon(
                                      Icons.person,
                                      size: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$enrolledCount enrolled',
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

                // ── Start Program Button ──
                GestureDetector(
                  onTap: () {
                    setState(() => _enrolled = !_enrolled);
                    if (_enrolled) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Enrolled in ${series.title}!',
                            style: GoogleFonts.inter(color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF22C55E),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
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
                        _enrolled ? '✓  Enrolled' : 'Start program',
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
                if (series.description != null &&
                    series.description!.isNotEmpty) ...[
                  Text(
                    series.description!,
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
                        '${series.episodeCount} guided ${series.isVideoSeries ? "video" : "audio"} sessions',
                        textColor,
                        textSecondary,
                      ),
                      const SizedBox(height: 8),
                      _buildBenefitRow(
                        Icons.schedule_rounded,
                        'Total duration: $totalDuration',
                        textColor,
                        textSecondary,
                      ),
                      const SizedBox(height: 8),
                      _buildBenefitRow(
                        Icons.terrain_rounded,
                        'Beginner to advanced classes available',
                        textColor,
                        textSecondary,
                      ),
                      const SizedBox(height: 8),
                      _buildBenefitRow(
                        Icons.download_done_rounded,
                        'Available offline after download',
                        textColor,
                        textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Episodes Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Episodes',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '${episodes.length} episodes',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // ── Episode List ──
        if (episodes.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final ep = episodes[index];
                  return _buildEpisodeRow(
                    episode: ep,
                    index: index,
                    isLight: isLight,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    primaryColor: primaryColor,
                  );
                },
                childCount: episodes.length,
              ),
            ),
          ),

        // Empty episodes fallback
        if (episodes.isEmpty)
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
                    Icon(Icons.upcoming_rounded,
                        size: 36, color: textSecondary),
                    const SizedBox(height: 8),
                    Text(
                      'Episodes coming soon',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Bottom spacing
        SliverToBoxAdapter(
          child:
              SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
        ),
      ],
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

  Widget _buildEpisodeRow({
    required EpisodeEntity episode,
    required int index,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Episode number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${episode.episodeNumber}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Episode info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  episode.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 12, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      episode.formattedDuration,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    if (episode.description != null &&
                        episode.description!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          episode.description!,
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
          const SizedBox(width: 8),
          // Free / Premium badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: episode.isFree
                  ? const Color(0xFF22C55E).withOpacity(0.12)
                  : const Color(0xFFF59E0B).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              episode.isFree ? 'Free' : 'Premium',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: episode.isFree
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFF59E0B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
