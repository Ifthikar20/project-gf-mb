import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/expert_service.dart';
import '../../domain/entities/expert_entity.dart';

/// Glo-style instructor profile page.
/// Clean layout: back chevron → large name → specialties → class count →
/// Follow button → big portrait photo → bio → classes list.
class SpeakerPage extends StatefulWidget {
  final String speakerId;
  final String speakerName;
  final String speakerImageUrl;

  const SpeakerPage({
    super.key,
    required this.speakerId,
    required this.speakerName,
    required this.speakerImageUrl,
  });

  @override
  State<SpeakerPage> createState() => _SpeakerPageState();
}

class _SpeakerPageState extends State<SpeakerPage> {
  ExpertEntity? _expert;
  bool _isLoading = true;
  bool _useFallback = false;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadExpertProfile();
  }

  Future<void> _loadExpertProfile() async {
    try {
      final expert =
          await ExpertService.instance.getExpertBySlug(widget.speakerId);
      if (mounted) {
        setState(() {
          _expert = expert;
          _isLoading = false;
          if (expert == null) _useFallback = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _useFallback = true;
          _isLoading = false;
        });
      }
    }
  }

  String get _displayName => _expert?.name ?? widget.speakerName;
  String get _displayImage => _expert?.imageUrl ?? widget.speakerImageUrl;

  String get _specialtiesText {
    final specialties = _expert?.specialties ?? [];
    if (specialties.isEmpty) {
      return _expert?.specialization ?? 'Wellness, Mindfulness';
    }
    return specialties.join(', ');
  }

  int get _totalClasses {
    if (_expert == null) return 0;
    return _expert!.stats.videoCount +
        _expert!.stats.audioCount +
        _expert!.stats.seriesCount;
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
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                      color: primaryColor, strokeWidth: 2))
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Back button ──
                    SliverToBoxAdapter(
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: surfaceColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 18,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (_expert?.shareUrl != null)
                                GestureDetector(
                                  onTap: _shareProfile,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: surfaceColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Icon(Icons.share_outlined,
                                        size: 18, color: textColor),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Name + Specialties + Class Count + Follow ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name — large and bold
                            Text(
                              _displayName,
                              style: GoogleFonts.inter(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Specialties — comma-separated
                            Text(
                              _specialtiesText,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Class count
                            Text(
                              '$_totalClasses classes',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Follow button — black pill
                            GestureDetector(
                              onTap: () {
                                setState(
                                    () => _isFollowing = !_isFollowing);
                                if (_isFollowing) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Following $_displayName',
                                        style: GoogleFonts.inter(
                                            color: Colors.white),
                                      ),
                                      backgroundColor:
                                          const Color(0xFF22C55E),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              },
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 250),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 14),
                                decoration: BoxDecoration(
                                  color: _isFollowing
                                      ? surfaceColor
                                      : (isLight
                                          ? Colors.black
                                          : Colors.white),
                                  borderRadius:
                                      BorderRadius.circular(26),
                                  border: _isFollowing
                                      ? Border.all(color: borderColor)
                                      : null,
                                ),
                                child: Text(
                                  _isFollowing
                                      ? 'Following'
                                      : 'Follow',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _isFollowing
                                        ? textColor
                                        : (isLight
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Big Portrait Photo ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: CachedNetworkImage(
                            imageUrl: _displayImage,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: surfaceColor,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: primaryColor,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: surfaceColor,
                              child: Center(
                                child: Icon(Icons.person,
                                    size: 80, color: textSecondary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Bio ──
                    if ((_expert?.bio ?? _expert?.shortBio) != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 24, 20, 0),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'About',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                (_expert?.bio ?? _expert?.shortBio)!,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Social Links ──
                    if (_expert?.hasSocialLinks ?? false)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              if (_expert?.linkedinUrl != null)
                                _buildLinkPill(
                                  Icons.work_outline,
                                  'LinkedIn',
                                  _expert!.linkedinUrl!,
                                  const Color(0xFF0A66C2),
                                ),
                              if (_expert?.instagramUrl != null)
                                _buildLinkPill(
                                  Icons.camera_alt_outlined,
                                  'Instagram',
                                  _expert!.instagramUrl!,
                                  const Color(0xFFE4405F),
                                ),
                              if (_expert?.websiteUrl != null)
                                _buildLinkPill(
                                  Icons.link,
                                  'Website',
                                  _expert!.websiteUrl!,
                                  primaryColor,
                                ),
                            ],
                          ),
                        ),
                      ),

                    // ── Classes by this instructor ──
                    if (_expert != null &&
                        (_expert!.videos.isNotEmpty ||
                            _expert!.audioSessions.isNotEmpty))
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 28, 20, 12),
                          child: Text(
                            'Classes by $_displayName',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),

                    // ── Videos ──
                    if (_expert?.videos.isNotEmpty ?? false)
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20),
                            itemCount: _expert!.videos.length,
                            itemBuilder: (context, index) =>
                                _buildContentCard(
                              item: _expert!.videos[index],
                              isLight: isLight,
                              surfaceColor: surfaceColor,
                              textColor: textColor,
                              textSecondary: textSecondary,
                              borderColor: borderColor,
                            ),
                          ),
                        ),
                      ),

                    // ── Series ──
                    if (_expert?.series.isNotEmpty ?? false) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Text(
                            'Series',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildSeriesRow(
                              series: _expert!.series[index],
                              isLight: isLight,
                              surfaceColor: surfaceColor,
                              textColor: textColor,
                              textSecondary: textSecondary,
                              borderColor: borderColor,
                              primaryColor: primaryColor,
                            ),
                            childCount: _expert!.series.length,
                          ),
                        ),
                      ),
                    ],

                    // ── Audio ──
                    if (_expert?.audioSessions.isNotEmpty ?? false) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Text(
                            'Audio Sessions',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20),
                            itemCount: _expert!.audioSessions.length,
                            itemBuilder: (context, index) =>
                                _buildContentCard(
                              item: _expert!.audioSessions[index],
                              isLight: isLight,
                              surfaceColor: surfaceColor,
                              textColor: textColor,
                              textSecondary: textSecondary,
                              borderColor: borderColor,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Bottom padding
                    const SliverToBoxAdapter(
                        child: SizedBox(height: 40)),
                  ],
                ),
        );
      },
    );
  }

  // ── Content card (videos / audio) ──
  Widget _buildContentCard({
    required ExpertContentItem item,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: () {
        if (item.contentType == 'video') {
          context.push('${AppRouter.videoPlayer}?id=${item.id}');
        } else {
          context.push('${AppRouter.audioPlayer}?id=${item.id}');
        }
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: item.thumbnailUrl ?? '',
                    width: 200,
                    height: 140,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 200,
                      height: 140,
                      color: surfaceColor,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 200,
                      height: 140,
                      color: surfaceColor,
                      child: Icon(
                        item.contentType == 'video'
                            ? Icons.play_circle_outline
                            : Icons.headphones_rounded,
                        color: textSecondary,
                        size: 36,
                      ),
                    ),
                  ),
                  // Duration badge
                  if (item.formattedDuration != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.formattedDuration!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Lock overlay
                  if (item.isLocked)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.lock_outline,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.category != null)
              Text(
                item.category!,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Series row ──
  Widget _buildSeriesRow({
    required ExpertSeries series,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: () =>
          context.push('${AppRouter.programEnroll}?seriesId=${series.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: series.thumbnailUrl ?? '',
                width: 70,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 70,
                  height: 50,
                  color: surfaceColor,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 70,
                  height: 50,
                  color: surfaceColor,
                  child: Icon(Icons.playlist_play,
                      color: textSecondary, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    series.title,
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
                    '${series.episodeCount} episodes',
                    style: GoogleFonts.inter(
                      fontSize: 12,
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

  // ── Link pill ──
  Widget _buildLinkPill(
      IconData icon, String label, String url, Color color) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareProfile() async {
    final expert = _expert;
    if (expert?.shareUrl == null) return;
    _launchUrl(expert!.shareUrl!);
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}
