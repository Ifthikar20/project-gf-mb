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

/// Enhanced Speaker/Expert Profile Page with rich data from API
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
  String? _error;
  bool _useFallback = false; // Show basic info when API fails

  @override
  void initState() {
    super.initState();
    _loadExpertProfile();
  }

  Future<void> _loadExpertProfile() async {
    try {
      final expert = await ExpertService.instance.getExpertBySlug(widget.speakerId);
      if (mounted) {
        setState(() {
          _expert = expert;
          _isLoading = false;
          if (expert == null) {
            _error = 'Expert not found';
          }
        });
      }
    } catch (e) {
      // Gracefully fall back to basic info when API fails (e.g., 404)
      if (mounted) {
        setState(() {
          _error = e.toString();
          _useFallback = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isVintage = themeState.isVintage;
        
        // Dynamic colors
        final bgColor = ThemeColors.background(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final primaryColor = ThemeColors.primary(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);

        return Scaffold(
          backgroundColor: bgColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero App Bar with background image
              _buildHeroAppBar(
                bgColor: bgColor,
                surfaceColor: surfaceColor,
                primaryColor: primaryColor,
                textColor: textColor,
                textSecondary: textSecondary,
                isVintage: isVintage,
              ),
              
              // Loading state
              if (_isLoading)
                SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                ),
              
              // Error state  
              if (_error != null && !_isLoading && !_useFallback)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: textSecondary, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load profile',
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _error!,
                            style: TextStyle(color: textSecondary, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            _loadExpertProfile();
                          },
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Content (either loaded expert or fallback basic info)
              if (!_isLoading && (_error == null || _useFallback)) ...[
                // Bio section
                _buildBioSection(
                  surfaceColor: surfaceColor,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  textSecondary: textSecondary,
                  isVintage: isVintage,
                ),
                
                // Stats section
                if (_expert != null)
                  _buildStatsSection(
                    surfaceColor: surfaceColor,
                    primaryColor: primaryColor,
                    textColor: textColor,
                    textSecondary: textSecondary,
                    isVintage: isVintage,
                  ),
                
                // Social links
                if (_expert?.hasSocialLinks ?? false)
                  _buildSocialLinksSection(
                    surfaceColor: surfaceColor,
                    primaryColor: primaryColor,
                    textColor: textColor,
                    textSecondary: textSecondary,
                    isVintage: isVintage,
                  ),
                
                // Videos section
                if (_expert?.videos.isNotEmpty ?? false)
                  _buildContentSection(
                    title: 'Videos',
                    icon: Icons.play_circle_outline,
                    items: _expert!.videos,
                    surfaceColor: surfaceColor,
                    primaryColor: primaryColor,
                    textColor: textColor,
                    textSecondary: textSecondary,
                    isVintage: isVintage,
                    badgeColor: Colors.redAccent,
                  ),
                
                // Series section
                if (_expert?.series.isNotEmpty ?? false)
                  _buildSeriesSection(
                    surfaceColor: surfaceColor,
                    primaryColor: primaryColor,
                    textColor: textColor,
                    textSecondary: textSecondary,
                    isVintage: isVintage,
                  ),
                
                // Audio section
                if (_expert?.audioSessions.isNotEmpty ?? false)
                  _buildContentSection(
                    title: 'Audio Sessions',
                    icon: Icons.headphones,
                    items: _expert!.audioSessions,
                    surfaceColor: surfaceColor,
                    primaryColor: primaryColor,
                    textColor: textColor,
                    textSecondary: textSecondary,
                    isVintage: isVintage,
                    badgeColor: Colors.purpleAccent,
                  ),
                
                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroAppBar({
    required Color bgColor,
    required Color surfaceColor,
    required Color primaryColor,
    required Color textColor,
    required Color textSecondary,
    required bool isVintage,
  }) {
    final backgroundImageUrl = _expert?.backgroundImageUrl;
    final imageUrl = _expert?.imageUrl ?? widget.speakerImageUrl;
    final name = _expert?.name ?? widget.speakerName;
    final specialization = _expert?.specialization ?? _expert?.title;
    final primaryCategory = _expert?.primaryCategory;
    final isVerified = _expert?.verified ?? false;

    return SliverAppBar(
      backgroundColor: bgColor,
      expandedHeight: 340,
      pinned: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(isVintage ? 8 : 20),
          ),
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        if (_expert?.shareUrl != null)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(isVintage ? 8 : 20),
              ),
              child: const Icon(Icons.share, color: Colors.white, size: 18),
            ),
            onPressed: () => _shareProfile(),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image or gradient
            if (backgroundImageUrl != null && backgroundImageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: backgroundImageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [primaryColor.withAlpha(102), bgColor],
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [primaryColor.withAlpha(102), bgColor],
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isVintage ? ThemeColors.vintageBrass : primaryColor).withAlpha(102),
                      bgColor,
                    ],
                  ),
                ),
              ),
            
            // Gradient overlay for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    bgColor.withAlpha(200),
                    bgColor,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
            
            // Profile content
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: isVintage ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: isVintage ? BorderRadius.circular(12) : null,
                      border: Border.all(color: primaryColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withAlpha(102),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: isVintage ? BorderRadius.circular(8) : BorderRadius.circular(60),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: surfaceColor,
                          child: Icon(Icons.person, color: textSecondary, size: 40),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: surfaceColor,
                          child: Icon(Icons.person, color: textSecondary, size: 40),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: isVintage
                            ? GoogleFonts.playfairDisplay(
                                color: textColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              )
                            : TextStyle(
                                color: textColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.verified, color: primaryColor, size: 20),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Specialization & experience
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (specialization != null && specialization.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: surfaceColor.withAlpha(153),
                            borderRadius: BorderRadius.circular(isVintage ? 4 : 16),
                            border: isVintage ? Border.all(color: primaryColor.withAlpha(77)) : null,
                          ),
                          child: Text(
                            specialization,
                            style: TextStyle(color: textSecondary, fontSize: 14),
                          ),
                        ),
                      ],
                      if (primaryCategory != null && primaryCategory.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withAlpha(26),
                            borderRadius: BorderRadius.circular(isVintage ? 4 : 16),
                            border: Border.all(color: primaryColor.withAlpha(51)),
                          ),
                          child: Text(
                            primaryCategory,
                            style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                      if (_expert?.yearsExperience != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withAlpha(51),
                            borderRadius: BorderRadius.circular(isVintage ? 4 : 16),
                          ),
                          child: Text(
                            '${_expert!.yearsExperience}+ years',
                            style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
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

  Widget _buildBioSection({
    required Color surfaceColor,
    required Color primaryColor,
    required Color textColor,
    required Color textSecondary,
    required bool isVintage,
  }) {
    final bio = _expert?.bio ?? _expert?.shortBio;
    
    if (bio == null || bio.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor.withAlpha(128),
          borderRadius: BorderRadius.circular(isVintage ? 8 : 16),
          border: isVintage ? Border.all(color: primaryColor.withAlpha(51)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'About',
                  style: isVintage
                      ? GoogleFonts.playfairDisplay(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )
                      : TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              bio,
              style: isVintage
                  ? GoogleFonts.lora(color: textSecondary, fontSize: 15, height: 1.5)
                  : TextStyle(color: textSecondary, fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection({
    required Color surfaceColor,
    required Color primaryColor,
    required Color textColor,
    required Color textSecondary,
    required bool isVintage,
  }) {
    final stats = _expert?.stats ?? const ExpertStats();
    
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildStatCard(
              icon: Icons.visibility,
              value: _formatNumber(stats.totalViews),
              label: 'Views',
              surfaceColor: surfaceColor,
              primaryColor: primaryColor,
              textColor: textColor,
              textSecondary: textSecondary,
              isVintage: isVintage,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.play_circle_filled,
              value: '${stats.videoCount}',
              label: 'Videos',
              surfaceColor: surfaceColor,
              primaryColor: primaryColor,
              textColor: textColor,
              textSecondary: textSecondary,
              isVintage: isVintage,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.headphones,
              value: '${stats.audioCount}',
              label: 'Audio',
              surfaceColor: surfaceColor,
              primaryColor: primaryColor,
              textColor: textColor,
              textSecondary: textSecondary,
              isVintage: isVintage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color surfaceColor,
    required Color primaryColor,
    required Color textColor,
    required Color textSecondary,
    required bool isVintage,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: surfaceColor.withAlpha(128),
          borderRadius: BorderRadius.circular(isVintage ? 8 : 12),
          border: isVintage ? Border.all(color: primaryColor.withAlpha(51)) : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: primaryColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinksSection({
    required Color surfaceColor,
    required Color primaryColor,
    required Color textColor,
    required Color textSecondary,
    required bool isVintage,
  }) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor.withAlpha(128),
          borderRadius: BorderRadius.circular(isVintage ? 8 : 16),
          border: isVintage ? Border.all(color: primaryColor.withAlpha(51)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_expert?.linkedinUrl != null)
                  _buildSocialButton(
                    icon: Icons.work_outline,
                    label: 'LinkedIn',
                    url: _expert!.linkedinUrl!,
                    color: const Color(0xFF0A66C2),
                  ),
                if (_expert?.instagramUrl != null) ...[
                  const SizedBox(width: 12),
                  _buildSocialButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Instagram',
                    url: _expert!.instagramUrl!,
                    color: const Color(0xFFE4405F),
                  ),
                ],
                if (_expert?.websiteUrl != null) ...[
                  const SizedBox(width: 12),
                  _buildSocialButton(
                    icon: Icons.language,
                    label: 'Website',
                    url: _expert!.websiteUrl!,
                    color: primaryColor,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required String url,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection({
    required String title,
    required IconData icon,
    required List<ExpertContentItem> items,
    required Color surfaceColor,
    required Color primaryColor,
    required Color textColor,
    required Color textSecondary,
    required bool isVintage,
    required Color badgeColor,
  }) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              children: [
                Icon(icon, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: isVintage
                      ? GoogleFonts.playfairDisplay(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )
                      : TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildContentCard(
                  item: item,
                  surfaceColor: surfaceColor,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  textSecondary: textSecondary,
                  isVintage: isVintage,
                  badgeColor: badgeColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard({
    required ExpertContentItem item,
    required Color surfaceColor,
    required Color primaryColor,
    required Color textColor,
    required Color textSecondary,
    required bool isVintage,
    required Color badgeColor,
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
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(isVintage ? 8 : 12),
                  child: CachedNetworkImage(
                    imageUrl: item.thumbnailUrl ?? '',
                    width: 140,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 140,
                      height: 100,
                      color: surfaceColor,
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 140,
                      height: 100,
                      color: surfaceColor,
                      child: Icon(
                        item.contentType == 'video' ? Icons.play_circle : Icons.headphones,
                        color: textSecondary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                // Duration badge
                if (item.formattedDuration != null)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.formattedDuration!,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                // Lock overlay
                if (item.isLocked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(isVintage ? 8 : 12),
                      ),
                      child: const Center(
                        child: Icon(Icons.lock, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              item.title,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeriesSection({
    required Color surfaceColor,
    required Color primaryColor,
    required Color textColor,
    required Color textSecondary,
    required bool isVintage,
  }) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              children: [
                Icon(Icons.playlist_play, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Series',
                  style: isVintage
                      ? GoogleFonts.playfairDisplay(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )
                      : TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(51),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_expert?.series.length ?? 0}',
                    style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          ..._expert!.series.map((series) => _buildSeriesCard(
            series: series,
            surfaceColor: surfaceColor,
            primaryColor: primaryColor,
            textColor: textColor,
            textSecondary: textSecondary,
            isVintage: isVintage,
          )),
        ],
      ),
    );
  }

  Widget _buildSeriesCard({
    required ExpertSeries series,
    required Color surfaceColor,
    required Color primaryColor,
    required Color textColor,
    required Color textSecondary,
    required bool isVintage,
  }) {
    return GestureDetector(
      onTap: () => context.push('${AppRouter.videoPlayer}?id=${series.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor.withAlpha(128),
          borderRadius: BorderRadius.circular(isVintage ? 8 : 12),
          border: isVintage ? Border.all(color: primaryColor.withAlpha(51)) : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: series.thumbnailUrl ?? '',
                width: 80,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 80,
                  height: 60,
                  color: surfaceColor,
                ),
                errorWidget: (context, url, error) => Container(
                  width: 80,
                  height: 60,
                  color: surfaceColor,
                  child: const Icon(Icons.playlist_play, color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(51),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SERIES',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    series.title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${series.episodeCount} episodes',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                      if (series.isLocked) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.lock, color: primaryColor, size: 14),
                      ],
                    ],
                  ),
                  if (series.isLocked && series.lockMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        series.lockMessage!,
                        style: TextStyle(color: primaryColor.withAlpha(204), fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Future<void> _shareProfile() async {
    final expert = _expert;
    if (expert == null || expert.shareUrl == null) return;
    
    // For now, we'll just launch the URL as a placeholder for sharing
    // Ideally, we'd use a share package like share_plus
    _launchUrl(expert.shareUrl!);
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Silently fail
    }
  }
}
