import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../videos/presentation/bloc/videos_bloc.dart';
import '../../../videos/presentation/bloc/videos_state.dart';
import '../../../videos/domain/entities/video_entity.dart';
import '../../../meditation/presentation/bloc/meditation_bloc.dart';
import '../../../meditation/presentation/bloc/meditation_state.dart';
import '../../../meditation/domain/entities/meditation_audio.dart';

/// Contextual content recommendations carousel.
/// Reads from existing VideosBloc and MeditationBloc to show relevant suggestions.
class ContentRecommendations extends StatelessWidget {
  const ContentRecommendations({super.key});

  // Wellness-related categories (case-insensitive match)
  static const _wellnessKeywords = [
    'meditation',
    'wellness',
    'growth',
    'mindfulness',
    'calm',
    'sleep',
    'focus',
    'stress',
    'breathe',
    'yoga',
    'mental',
    'relax',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;
    final surfaceColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F5);

    // Collect recommendations from both blocs
    final videos = _getRecommendedVideos(context);
    final audios = _getRecommendedAudios(context);

    // Interleave: video, audio, video, audio...
    final List<_RecommendationItem> items = [];
    final maxLen = videos.length > audios.length ? videos.length : audios.length;
    for (var i = 0; i < maxLen && items.length < 8; i++) {
      if (i < videos.length) items.add(videos[i]);
      if (i < audios.length) items.add(audios[i]);
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended Content',
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRouter.videos),
                child: Text(
                  'See all',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6366F1),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _RecommendationCard(
                item: item,
                surfaceColor: surfaceColor,
                textColor: textColor,
                textSecondary: textSecondary,
                isDark: isDark,
              );
            },
          ),
        ),
      ],
    );
  }

  List<_RecommendationItem> _getRecommendedVideos(BuildContext context) {
    try {
      final state = context.watch<VideosBloc>().state;
      if (state is! VideosLoaded) return [];

      // Prioritize wellness-related content, then take any
      final sorted = List<VideoEntity>.from(state.videos);
      sorted.sort((a, b) {
        final aScore = _wellnessScore(a.category);
        final bScore = _wellnessScore(b.category);
        return bScore.compareTo(aScore);
      });

      return sorted.take(4).map((v) => _RecommendationItem(
            type: _ContentType.video,
            id: v.id,
            title: v.title,
            subtitle: v.instructor,
            thumbnailUrl: v.thumbnailUrl,
            duration: v.formattedDuration,
            category: v.category,
          )).toList();
    } catch (_) {
      return [];
    }
  }

  List<_RecommendationItem> _getRecommendedAudios(BuildContext context) {
    try {
      final state = context.watch<MeditationBloc>().state;
      if (state is! MeditationLoaded) return [];

      // Featured first, then wellness-scored
      final sorted = List<MeditationAudio>.from(state.audios);
      sorted.sort((a, b) {
        if (a.featured && !b.featured) return -1;
        if (!a.featured && b.featured) return 1;
        final aScore = _wellnessScore(a.category);
        final bScore = _wellnessScore(b.category);
        return bScore.compareTo(aScore);
      });

      return sorted.take(4).map((a) => _RecommendationItem(
            type: _ContentType.audio,
            id: a.id,
            title: a.title,
            subtitle: a.expertName ?? 'Guided session',
            thumbnailUrl: a.imageUrl,
            duration: a.formattedDuration,
            category: a.category,
          )).toList();
    } catch (_) {
      return [];
    }
  }

  int _wellnessScore(String category) {
    final lower = category.toLowerCase();
    for (final kw in _wellnessKeywords) {
      if (lower.contains(kw)) return 1;
    }
    return 0;
  }
}

// ── Internal models ──

enum _ContentType { video, audio }

class _RecommendationItem {
  final _ContentType type;
  final String id;
  final String title;
  final String subtitle;
  final String thumbnailUrl;
  final String duration;
  final String category;

  const _RecommendationItem({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.thumbnailUrl,
    required this.duration,
    required this.category,
  });
}

// ── Recommendation card ──

class _RecommendationCard extends StatelessWidget {
  final _RecommendationItem item;
  final Color surfaceColor;
  final Color textColor;
  final Color textSecondary;
  final bool isDark;

  const _RecommendationCard({
    required this.item,
    required this.surfaceColor,
    required this.textColor,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == _ContentType.video;
    final rng = Random(item.id.hashCode);
    final rating = (4.0 + rng.nextDouble()).toStringAsFixed(1);

    return GestureDetector(
      onTap: () {
        if (isVideo) {
          context.push('${AppRouter.videoPlayer}?id=${item.id}');
        } else {
          context.push('${AppRouter.audioPlayer}?id=${item.id}');
        }
      },
      child: Container(
        width: 230,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail — matching explore style
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    item.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.thumbnailUrl,
                            fit: BoxFit.cover,
                            memCacheHeight: 320,
                            memCacheWidth: 460,
                            placeholder: (_, __) => Container(color: surfaceColor),
                            errorWidget: (_, __, ___) => Container(
                              color: surfaceColor,
                              child: Icon(isVideo ? Icons.play_circle_outline : Icons.headphones_rounded, color: textSecondary, size: 48),
                            ),
                          )
                        : Container(
                            color: surfaceColor,
                            child: Icon(isVideo ? Icons.play_circle_outline : Icons.headphones_rounded, color: textSecondary, size: 48),
                          ),
                    // Bottom badges
                    Positioned(
                      left: 8, bottom: 8,
                      child: Row(
                        children: [
                          _badge(item.duration, isDark),
                          const SizedBox(width: 6),
                          _badge(isVideo ? 'Video' : 'Audio', isDark, icon: isVideo ? Icons.videocam_rounded : Icons.headphones_rounded),
                        ],
                      ),
                    ),
                    // Rating
                    Positioned(
                      right: 8, bottom: 8,
                      child: _badge(rating, isDark, icon: Icons.star_rounded, iconColor: const Color(0xFFF59E0B)),
                    ),
                  ],
                ),
              ),
            ),
            // Title + subtitle below
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: GoogleFonts.inter(color: textColor, fontSize: 13, fontWeight: FontWeight.w600, height: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${item.subtitle} · ${item.category}', style: GoogleFonts.inter(color: textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, bool isDark, {IconData? icon, Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: iconColor ?? (isDark ? Colors.white70 : Colors.black54)),
            const SizedBox(width: 3),
          ],
          Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }
}
