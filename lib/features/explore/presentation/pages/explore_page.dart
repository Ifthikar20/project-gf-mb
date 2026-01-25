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
import '../../../meditation/presentation/bloc/meditation_bloc.dart';
import '../../../meditation/presentation/bloc/meditation_event.dart';
import '../../../meditation/presentation/bloc/meditation_state.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Video', 'Audio', 'Podcasts'];

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
        final isVintage = themeState.isVintage;
        
        // Dynamic colors based on theme
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
              // Header with theme-aware styling
              SliverToBoxAdapter(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Explore',
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
                            GestureDetector(
                              onTap: () {
                                context.push(AppRouter.search);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(isVintage ? 8 : 25),
                                  border: isVintage ? Border.all(color: primaryColor.withOpacity(0.3)) : null,
                                ),
                                child: Icon(
                                  Icons.search,
                                  color: textColor,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _categories.map((category) {
                              return _buildChip(
                                category,
                                _selectedCategory == category,
                                () => setState(() => _selectedCategory = category),
                                primaryColor, textColor, textSecondary, isVintage, bgColor,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Top Trending section
              _buildSectionHeader('Top Trending', icon: Icons.local_fire_department, textColor: textColor, primaryColor: primaryColor, isVintage: isVintage),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: _buildVideosSection(isVintage, primaryColor, surfaceColor, textColor, textSecondary, bgColor),
                ),
              ),

              // Top Speakers section
              _buildSectionHeader('Top Speakers', icon: Icons.people_alt_outlined, textColor: textColor, primaryColor: primaryColor, isVintage: isVintage),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: _buildTopSpeakersSection(isVintage, primaryColor, surfaceColor, textColor, textSecondary),
                ),
              ),

              // Top picks in wellness
              if (_selectedCategory == 'All' || _selectedCategory == 'Audio') ...[
                _buildSectionHeader('Top picks in wellness', icon: Icons.spa, textColor: textColor, primaryColor: primaryColor, isVintage: isVintage),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: _buildAudioSection(isVintage, primaryColor, surfaceColor, textColor, textSecondary, bgColor),
                  ),
                ),
              ],

              // Discover picks for you
              _buildSectionHeader('Discover picks for you', icon: Icons.auto_awesome, textColor: textColor, primaryColor: primaryColor, isVintage: isVintage),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: _buildMadeForYouSection(isVintage, primaryColor, surfaceColor, textColor, textSecondary, bgColor),
                ),
              ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopSpeakersSection(bool isVintage, Color primaryColor, Color surfaceColor, Color textColor, Color textSecondary) {
    // Using real expert slugs from the backend
    final speakers = [
      {'id': 'dr-sarah-johnson', 'name': 'Dr. Sarah', 'imageUrl': 'https://picsum.photos/seed/sarah/200/200'},
      {'id': 'dr-michael-chen', 'name': 'Dr. Michael', 'imageUrl': 'https://picsum.photos/seed/michael/200/200'},
      {'id': 'dr-emily-rodriguez', 'name': 'Dr. Emily', 'imageUrl': 'https://picsum.photos/seed/emily/200/200'},
      {'id': 'dr-james-wilson', 'name': 'Dr. James', 'imageUrl': 'https://picsum.photos/seed/james/200/200'},
      {'id': 'dr-lisa-park', 'name': 'Dr. Lisa', 'imageUrl': 'https://picsum.photos/seed/lisa/200/200'},
      {'id': 'dr-david-brown', 'name': 'Dr. David', 'imageUrl': 'https://picsum.photos/seed/david/200/200'},
    ];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: speakers.length,
      itemBuilder: (context, index) {
        final speaker = speakers[index];
        return GestureDetector(
          onTap: () {
            context.push(
              '${AppRouter.speakerProfile}?id=${speaker['id']}&name=${Uri.encodeComponent(speaker['name']!)}&imageUrl=${Uri.encodeComponent(speaker['imageUrl']!)}',
            );
          },
          child: Container(
            width: 85,
            margin: const EdgeInsets.only(right: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Theme-aware avatar frame
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: isVintage ? BorderRadius.circular(8) : null,
                    shape: isVintage ? BoxShape.rectangle : BoxShape.circle,
                    border: Border.all(color: primaryColor.withOpacity(0.6), width: 1.5),
                  ),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: isVintage ? BorderRadius.circular(6) : null,
                      shape: isVintage ? BoxShape.rectangle : BoxShape.circle,
                    ),
                    child: ClipRRect(
                      borderRadius: isVintage ? BorderRadius.circular(6) : BorderRadius.circular(32),
                      child: CachedNetworkImage(
                        imageUrl: speaker['imageUrl']!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: surfaceColor,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: surfaceColor,
                          child: Icon(Icons.person, color: textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  speaker['name']!,
                  style: isVintage
                      ? GoogleFonts.lora(color: textColor, fontSize: 12)
                      : TextStyle(color: textColor, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap, Color primaryColor, Color textColor, Color textSecondary, bool isVintage, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isVintage 
                ? (isSelected ? Colors.black : Colors.white) // Clean black/white for vintage
                : (isSelected ? primaryColor : Colors.transparent),
            borderRadius: BorderRadius.circular(20), // Pill shape like reference
            border: Border.all(
              color: isVintage 
                  ? (isSelected ? Colors.black : ThemeColors.vintageBorder)
                  : (isSelected ? primaryColor : textSecondary.withOpacity(0.5)),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isVintage 
                  ? (isSelected ? Colors.white : Colors.black)
                  : (isSelected ? Colors.white : textColor),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon, required Color textColor, required Color primaryColor, required bool isVintage}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Row(
          children: [
            if (icon != null && !isVintage) ...[ // Hide icons in vintage for cleaner look
              Icon(icon, color: primaryColor, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: isVintage
                  ? GoogleFonts.playfairDisplay(
                      color: Colors.black, // Clean black text
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    )
                  : TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
            ),
            // Removed decorative line for cleaner look in vintage mode
          ],
        ),
      ),
    );
  }

  Widget _buildVideosSection(bool isVintage, Color primaryColor, Color surfaceColor, Color textColor, Color textSecondary, Color bgColor) {
    return BlocBuilder<VideosBloc, VideosState>(
      builder: (context, state) {
        if (state is VideosLoaded) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.videos.length,
            itemBuilder: (context, index) {
              final video = state.videos[index];
              return _buildTrendingCard(
                category: video.category.toUpperCase(),
                title: video.title,
                authorName: video.instructor.isNotEmpty ? video.instructor : 'Playlist',
                imageUrl: video.thumbnailUrl,
                isSeries: video.isSeries,
                episodeCount: video.episodeCount,
                onTap: () {
                  context.push('${AppRouter.videoPlayer}?id=${video.id}');
                },
                isVintage: isVintage,
                primaryColor: primaryColor,
                surfaceColor: surfaceColor,
                textColor: textColor,
                textSecondary: textSecondary,
                bgColor: bgColor,
              );
            },
          );
        }
        return Center(
          child: CircularProgressIndicator(color: primaryColor),
        );
      },
    );
  }

  Widget _buildTrendingCard({
    required String category,
    required String title,
    required String authorName,
    required String imageUrl,
    required VoidCallback onTap,
    bool isSeries = false,
    int? episodeCount,
    required bool isVintage,
    required Color primaryColor,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color bgColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: TextStyle(
                color: textSecondary.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: isVintage
                  ? GoogleFonts.playfairDisplay(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)
                  : TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              authorName,
              style: isVintage
                  ? GoogleFonts.lora(color: textSecondary.withOpacity(0.6), fontSize: 13, fontStyle: FontStyle.italic)
                  : TextStyle(color: textSecondary.withOpacity(0.6), fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isVintage ? 6 : 10),
                  border: isVintage ? Border.all(color: primaryColor.withOpacity(0.3)) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isVintage ? 5 : 10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: surfaceColor),
                        errorWidget: (context, url, error) => Container(
                          color: surfaceColor,
                          child: Icon(Icons.play_circle_outline, color: textSecondary, size: 48),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isVintage
                                ? [ThemeColors.vintageBrass.withOpacity(0.1), Colors.transparent, bgColor.withOpacity(0.5)]
                                : [Colors.transparent, bgColor.withOpacity(0.4)],
                          ),
                        ),
                      ),
                      if (isSeries && episodeCount != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: surfaceColor.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(isVintage ? 4 : 6),
                              border: isVintage ? Border.all(color: primaryColor.withOpacity(0.5)) : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.playlist_play, color: primaryColor, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '$episodeCount episodes',
                                  style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSection(bool isVintage, Color primaryColor, Color surfaceColor, Color textColor, Color textSecondary, Color bgColor) {
    return BlocBuilder<MeditationBloc, MeditationState>(
      builder: (context, state) {
        if (state is MeditationLoaded) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.audios.length,
            itemBuilder: (context, index) {
              final audio = state.audios[index];
              return _buildContentCard(
                title: audio.title,
                subtitle: audio.description,
                imageUrl: audio.imageUrl,
                badge: 'AUDIO',
                badgeColor: isVintage ? ThemeColors.sageGreen : ThemeColors.classicPrimary,
                onTap: () {
                  context.push('${AppRouter.audioPlayer}?id=${audio.id}');
                },
                isVintage: isVintage,
                primaryColor: primaryColor,
                surfaceColor: surfaceColor,
                textColor: textColor,
                textSecondary: textSecondary,
              );
            },
          );
        }
        return Center(child: CircularProgressIndicator(color: primaryColor));
      },
    );
  }

  Widget _buildMadeForYouSection(bool isVintage, Color primaryColor, Color surfaceColor, Color textColor, Color textSecondary, Color bgColor) {
    return BlocBuilder<MeditationBloc, MeditationState>(
      builder: (context, state) {
        if (state is MeditationLoaded) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.moodBasedTypes.length,
            itemBuilder: (context, index) {
              final type = state.moodBasedTypes[index];
              return _buildContentCard(
                title: type.name,
                subtitle: type.subtitle,
                imageUrl: type.imageUrl,
                badge: 'FOR YOU',
                badgeColor: isVintage ? ThemeColors.dustyRose : ThemeColors.classicSecondary,
                onTap: () {
                  context.push(
                    '${AppRouter.meditationCategory}?id=${type.id}&name=${Uri.encodeComponent(type.name)}',
                  );
                },
                isVintage: isVintage,
                primaryColor: primaryColor,
                surfaceColor: surfaceColor,
                textColor: textColor,
                textSecondary: textSecondary,
              );
            },
          );
        }
        return Center(child: CircularProgressIndicator(color: primaryColor));
      },
    );
  }

  Widget _buildContentCard({
    required String title,
    required String subtitle,
    required String imageUrl,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
    required bool isVintage,
    required Color primaryColor,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isVintage ? 6 : 8),
                    border: isVintage ? Border.all(color: primaryColor.withOpacity(0.3)) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isVintage ? 5 : 8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: surfaceColor),
                          errorWidget: (context, url, error) => Container(
                            color: surfaceColor,
                            child: Icon(Icons.music_note, color: textSecondary, size: 40),
                          ),
                        ),
                        if (isVintage)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [ThemeColors.vintageBrass.withOpacity(0.1), Colors.transparent],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (badge != null)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor ?? primaryColor,
                        borderRadius: BorderRadius.circular(isVintage ? 4 : 12),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: isVintage
                  ? GoogleFonts.playfairDisplay(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)
                  : TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: textSecondary.withOpacity(0.65),
                fontSize: 11,
                fontStyle: isVintage ? FontStyle.italic : FontStyle.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
