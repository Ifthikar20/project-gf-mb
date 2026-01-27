import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/recently_viewed_service.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_state.dart';
import '../../../videos/presentation/bloc/videos_bloc.dart';
import '../../../videos/presentation/bloc/videos_state.dart';
import '../../../meditation/presentation/bloc/meditation_bloc.dart';
import '../../../meditation/presentation/bloc/meditation_state.dart';
import '../widgets/mood_selector_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedFilter = 'Video';
  String? _selectedMoodId;
  VideoPlayerController? _bannerVideoController;
  
  // Theme state (updated in build)
  bool _isVintage = false;
  Color _primaryColor = const Color(0xFF8B4513);
  Color _textColor = const Color(0xFF1A1A1A);
  Color _textSecondary = const Color(0xFF4A4A4A);
  Color _surfaceColor = const Color(0xFFFAF8F3);
  
  @override
  void initState() {
    super.initState();
    _initBannerVideo();
  }
  
  Future<void> _initBannerVideo() async {
    _bannerVideoController = VideoPlayerController.networkUrl(
      Uri.parse(ApiEndpoints.bannerVideo),
    );
    
    await _bannerVideoController!.initialize();
    _bannerVideoController!.setLooping(true);
    _bannerVideoController!.setVolume(0); // Muted
    _bannerVideoController!.setPlaybackSpeed(0.5); // Slow motion
    _bannerVideoController!.play();
    
    if (mounted) setState(() {});
  }
  
  @override
  void dispose() {
    _bannerVideoController?.dispose();
    super.dispose();
  }
  
  // Content data for each filter
  final Map<String, List<Map<String, dynamic>>> _filterContent = {
    'Video': [
      {
        'title': 'Morning Meditation',
        'subtitle': 'Calm Mind',
        'duration': '10:24',
        'views': '8.74M',
        'imageUrl': 'https://picsum.photos/seed/video1/200/200',
      },
      {
        'title': 'Yoga for Beginners',
        'subtitle': 'Stretch & Relax',
        'duration': '15:30',
        'views': '15.3M',
        'imageUrl': 'https://picsum.photos/seed/video2/200/200',
      },
      {
        'title': 'Mindful Breathing',
        'subtitle': 'Focus Session',
        'duration': '9:45',
        'views': '9.73M',
        'imageUrl': 'https://picsum.photos/seed/video3/200/200',
      },
    ],
    'Audio': [
      {
        'title': 'Deep Sleep Sounds',
        'subtitle': 'Nature Ambience',
        'duration': '45:00',
        'views': '12.1M',
        'imageUrl': 'https://picsum.photos/seed/audio1/200/200',
      },
      {
        'title': 'Stress Relief',
        'subtitle': 'Calm Music',
        'duration': '30:15',
        'views': '8.5M',
        'imageUrl': 'https://picsum.photos/seed/audio2/200/200',
      },
      {
        'title': 'Focus Beats',
        'subtitle': 'Lo-fi Study',
        'duration': '60:00',
        'views': '20.3M',
        'imageUrl': 'https://picsum.photos/seed/audio3/200/200',
      },
    ],
    'Podcast': [
      {
        'title': 'Wellness Talk',
        'subtitle': 'Dr. Sarah Mind',
        'duration': '32:18',
        'views': '3.2M',
        'imageUrl': 'https://picsum.photos/seed/podcast1/200/200',
      },
      {
        'title': 'Sleep Stories',
        'subtitle': 'Bedtime Tales',
        'duration': '25:45',
        'views': '5.8M',
        'imageUrl': 'https://picsum.photos/seed/podcast2/200/200',
      },
      {
        'title': 'Mindset Matters',
        'subtitle': 'Daily Motivation',
        'duration': '18:30',
        'views': '4.1M',
        'imageUrl': 'https://picsum.photos/seed/podcast3/200/200',
      },
    ],
    'Sounds': [
      {
        'title': 'Rain on Window',
        'subtitle': 'Nature Sounds',
        'duration': '3:00:00',
        'views': '25.6M',
        'imageUrl': 'https://picsum.photos/seed/sounds1/200/200',
      },
      {
        'title': 'Ocean Waves',
        'subtitle': 'Beach Ambience',
        'duration': '2:30:00',
        'views': '18.9M',
        'imageUrl': 'https://picsum.photos/seed/sounds2/200/200',
      },
      {
        'title': 'Forest Morning',
        'subtitle': 'Bird Songs',
        'duration': '1:45:00',
        'views': '14.2M',
        'imageUrl': 'https://picsum.photos/seed/sounds3/200/200',
      },
    ],
  };

  // Recommendations will be built dynamically based on filter and mood
  List<Map<String, dynamic>> get _recommendations => _filterContent[_selectedFilter] ?? [];

  List<Map<String, dynamic>> get _recentlyViewed => _filterContent[_selectedFilter] ?? [];

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
        
        // Sync to class level for helper methods
        _isVintage = isVintage;
        _primaryColor = primaryColor;
        _textColor = textColor;
        _textSecondary = textSecondary;
        _surfaceColor = surfaceColor;
        
        return Scaffold(
          backgroundColor: bgColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
          // Large Header Banner with video background
          SliverToBoxAdapter(
            child: Stack(
              children: [
              // Background video
              ClipRect(
                child: Container(
                  height: 240,
                  color: bgColor,
                    child: _bannerVideoController != null &&
                            _bannerVideoController!.value.isInitialized
                        ? Stack(
                            children: [
                              // Video player - fills container
                              Positioned.fill(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _bannerVideoController!.value.size.width,
                                    height: _bannerVideoController!.value.size.height,
                                    child: VideoPlayer(_bannerVideoController!),
                                  ),
                                ),
                              ),
                            // Gradient overlay - theme-aware
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: isVintage 
                                      ? [
                                          ThemeColors.vintageBrass.withOpacity(0.3),
                                          bgColor.withOpacity(0.5),
                                          bgColor.withOpacity(0.9),
                                          bgColor,
                                        ]
                                      : [
                                          Colors.black.withOpacity(0.2),
                                          Colors.black.withOpacity(0.4),
                                          Colors.black.withOpacity(0.8),
                                          const Color(0xFF0A0A0A),
                                        ],
                                  stops: const [0.0, 0.4, 0.75, 1.0],
                                ),
                              ),
                            ),
                            ],
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white24,
                            ),
                          ),
                  ),
                ),
                // Content on banner
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // App Logo
                        Icon(
                          Icons.spa,
                          size: 48,
                          color: isVintage ? primaryColor : Colors.white,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Good evening',
                          style: isVintage
                              ? GoogleFonts.playfairDisplay(
                                  color: textColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                )
                              : const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ready for your daily wellness?',
                          style: TextStyle(
                            color: isVintage ? textSecondary : Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mood Check Section
          SliverToBoxAdapter(
            child: MoodSelectorWidget(
              selectedMoodId: _selectedMoodId,
              onMoodSelected: (mood) {
                setState(() {
                  _selectedMoodId = mood.id;
                });
                // Show snackbar confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Showing content for ${mood.label.toLowerCase()} mood'),
                    backgroundColor: mood.color,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),

          // Filter tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterTab('Video', isVintage, primaryColor, surfaceColor, textColor),
                    _buildFilterTab('Audio', isVintage, primaryColor, surfaceColor, textColor),
                    _buildFilterTab('Podcast', isVintage, primaryColor, surfaceColor, textColor),
                    _buildFilterTab('Sounds', isVintage, primaryColor, surfaceColor, textColor),
                  ],
                ),
              ),
            ),
          ),

          // Recommendations based on recent views (Horizontal scroll)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recommended for you',
                    style: isVintage
                        ? GoogleFonts.playfairDisplay(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          )
                        : const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                  ),
                  Text(
                    'See all',
                    style: TextStyle(
                      color: isVintage ? primaryColor : Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: isVintage ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: _buildRecommendationsSection(),
            ),
          ),

          // Recently Viewed Section (content changes based on filter)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recently Viewed',
                    style: isVintage
                        ? GoogleFonts.playfairDisplay(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          )
                        : const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                  ),
                  Text(
                    'See all',
                    style: TextStyle(
                      color: isVintage ? primaryColor : Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: isVintage ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ListenableBuilder(
              listenable: RecentlyViewedService.instance,
              builder: (context, child) {
                // Map filter names to content types
                String contentTypeFilter;
                switch (_selectedFilter) {
                  case 'Video':
                    contentTypeFilter = 'video';
                    break;
                  case 'Audio':
                    contentTypeFilter = 'audio';
                    break;
                  case 'Podcast':
                    contentTypeFilter = 'podcast';
                    break;
                  case 'Sounds':
                    contentTypeFilter = 'sounds';
                    break;
                  default:
                    contentTypeFilter = 'video';
                }
                
                // Filter by content type and limit to 3
                final recentItems = RecentlyViewedService.instance.items
                    .where((item) => item.contentType.toLowerCase() == contentTypeFilter)
                    .take(3)
                    .toList();
                
                if (recentItems.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(isVintage ? 12 : 12),
                      border: Border.all(color: isVintage ? primaryColor.withOpacity(0.2) : Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isVintage ? primaryColor.withOpacity(0.1) : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.history, color: isVintage ? primaryColor : Colors.white54, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No recent ${_selectedFilter.toLowerCase()}',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Watch ${_selectedFilter.toLowerCase()} content to see it here',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return Column(
                  children: recentItems.map((item) => _buildRecentlyViewedItem(item)).toList(),
                );
              },
            ),
          ),

          // My Library Section (Snippet view)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Library',
                    style: isVintage
                        ? GoogleFonts.playfairDisplay(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          )
                        : const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRouter.library),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        color: isVintage ? primaryColor : const Color(0xFF1DB954),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<LibraryBloc, LibraryState>(
              builder: (context, libraryState) {
                if (libraryState is LibraryLoaded && libraryState.savedIds.isNotEmpty) {
                  return BlocBuilder<VideosBloc, VideosState>(
                    builder: (context, videosState) {
                      if (videosState is VideosLoaded) {
                        final savedVideos = videosState.videos
                            .where((v) => libraryState.savedIds.contains(v.id))
                            .take(3)
                            .toList();
                        
                        if (savedVideos.isEmpty) {
                          return _buildEmptyLibrary();
                        }
                        
                        return SizedBox(
                          height: 140,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: savedVideos.length,
                            itemBuilder: (context, index) {
                              final video = savedVideos[index];
                              return _buildLibrarySnippetCard(
                                title: video.title,
                                subtitle: video.instructor,
                                imageUrl: video.thumbnailUrl,
                                onTap: () => context.push('${AppRouter.videoPlayer}?id=${video.id}'),
                              );
                            },
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  );
                }
                return _buildEmptyLibrary();
              },
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
      },
    );
  }

  Widget _buildFilterTab(String label, bool isVintage, Color primaryColor, Color surfaceColor, Color textColor) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isVintage
              ? (isSelected ? Colors.black : Colors.white) // Clean black/white for vintage
              : (isSelected ? Colors.white : const Color(0xFF1A1A1A)),
          borderRadius: BorderRadius.circular(20), // Pill shape like reference
          border: Border.all(
            color: isVintage 
                ? (isSelected ? Colors.black : ThemeColors.vintageBorder)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isVintage
                ? (isSelected ? Colors.white : Colors.black) // Clean black/white text
                : (isSelected ? Colors.black : Colors.white),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(_isVintage ? 12 : 8),
            child: CachedNetworkImage(
              imageUrl: item['imageUrl'],
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                width: 56,
                height: 56,
                color: _isVintage ? _surfaceColor : const Color(0xFF282828),
                child: Icon(Icons.music_note, color: _isVintage ? _primaryColor.withOpacity(0.5) : Colors.white24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['subtitle'],
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.play_arrow, color: _textSecondary.withOpacity(0.7), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${item['views']} • ${item['duration']}',
                      style: TextStyle(
                        color: _textSecondary.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Menu button
          IconButton(
            icon: Icon(Icons.more_horiz, color: _textSecondary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyViewedItem(RecentlyViewedItem item) {
    final isVideo = item.contentType == 'video';
    final duration = item.durationSeconds != null
        ? '${(item.durationSeconds! ~/ 60)}:${(item.durationSeconds! % 60).toString().padLeft(2, '0')}'
        : '';
    
    return GestureDetector(
      onTap: () {
        if (isVideo) {
          context.push('${AppRouter.videoPlayer}?id=${item.contentId}');
        } else {
          context.push('${AppRouter.audioPlayer}?id=${item.contentId}');
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(_isVintage ? 12 : 8),
              child: item.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.thumbnailUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 56,
                        height: 56,
                        color: _isVintage ? _surfaceColor : const Color(0xFF282828),
                        child: Icon(
                          isVideo ? Icons.play_circle_outline : Icons.music_note,
                          color: _isVintage ? _primaryColor.withOpacity(0.5) : Colors.white24,
                        ),
                      ),
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: _isVintage ? _surfaceColor : const Color(0xFF282828),
                      child: Icon(
                        isVideo ? Icons.play_circle_outline : Icons.music_note,
                        color: _isVintage ? _primaryColor.withOpacity(0.5) : Colors.white24,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.contentType.toUpperCase(),
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  if (duration.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isVideo ? Icons.videocam : Icons.headphones, 
                          color: _textSecondary.withOpacity(0.7), 
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: TextStyle(
                            color: _textSecondary.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Play icon
            Icon(Icons.play_arrow, color: _textSecondary),
          ],
        ),
      ),
    );
  }

  /// Builds recommendations section from real API data based on selected filter
  Widget _buildRecommendationsSection() {
    switch (_selectedFilter) {
      case 'Video':
        return BlocBuilder<VideosBloc, VideosState>(
          builder: (context, state) {
            if (state is VideosLoaded) {
              final videos = state.videos.take(5).toList();
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  // Determine badge: SERIES for collections, VIDEO for single
                  final badge = video.isSeries ? 'SERIES' : 'VIDEO';
                  final subtitle = video.isSeries 
                      ? '${video.episodeCount} episodes' 
                      : video.instructor;
                  return _buildApiRecommendationCard(
                    title: video.title,
                    subtitle: subtitle,
                    imageUrl: video.thumbnailUrl,
                    badge: badge,
                    onTap: () => context.push('${AppRouter.videoPlayer}?id=${video.id}'),
                  );
                },
              );
            }
            return const Center(child: CircularProgressIndicator(color: Colors.white24));
          },
        );
      case 'Audio':
        return BlocBuilder<MeditationBloc, MeditationState>(
          builder: (context, state) {
            if (state is MeditationLoaded) {
              // Show individual audios with AUDIO badge
              final audios = state.audios.take(5).toList();
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: audios.length,
                itemBuilder: (context, index) {
                  final audio = audios[index];
                  // Check if it's guided meditation or regular audio
                  final isGuided = audio.meditationType == 'guided' || 
                                   audio.meditationType == 'body-scan' ||
                                   audio.meditationType == 'breathing';
                  final badge = isGuided ? 'GUIDED' : 'AUDIO';
                  return _buildApiRecommendationCard(
                    title: audio.title,
                    subtitle: audio.category,
                    imageUrl: audio.imageUrl,
                    badge: badge,
                    onTap: () => context.push('${AppRouter.audioPlayer}?id=${audio.id}'),
                  );
                },
              );
            }
            return const Center(child: CircularProgressIndicator(color: Colors.white24));
          },
        );
      case 'Podcast':
        // Show static podcast content with PODCAST badge
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filterContent['Podcast']?.length ?? 0,
          itemBuilder: (context, index) {
            final item = _filterContent['Podcast']![index];
            return _buildApiRecommendationCard(
              title: item['title'],
              subtitle: item['subtitle'],
              imageUrl: item['imageUrl'],
              badge: 'PODCAST',
              onTap: () {},
            );
          },
        );
      case 'Sounds':
      default:
        // Show sounds content with SOUNDS badge
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filterContent['Sounds']?.length ?? 0,
          itemBuilder: (context, index) {
            final item = _filterContent['Sounds']![index];
            return _buildApiRecommendationCard(
              title: item['title'],
              subtitle: item['subtitle'],
              imageUrl: item['imageUrl'],
              badge: 'SOUNDS',
              onTap: () {},
            );
          },
        );
    }
  }

  Widget _buildApiRecommendationCard({
    required String title,
    required String subtitle,
    required String imageUrl,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with optional badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(_isVintage ? 12 : 8),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 130,
                    height: 130,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 130,
                      height: 130,
                      color: _isVintage ? _surfaceColor : const Color(0xFF282828),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 130,
                      height: 130,
                      color: _isVintage ? _surfaceColor : const Color(0xFF282828),
                      child: Icon(Icons.play_circle_outline, color: _isVintage ? _primaryColor.withOpacity(0.5) : Colors.white24, size: 40),
                    ),
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _isVintage ? _primaryColor : _getBadgeColor(badge),
                        borderRadius: BorderRadius.circular(_isVintage ? 4 : 4),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: _textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Get badge color based on content type
  Color _getBadgeColor(String badge) {
    switch (badge) {
      case 'SERIES':
        return const Color(0xFF7C3AED); // Purple - video collection
      case 'VIDEO':
        return const Color(0xFF3B82F6); // Blue - single video
      case 'AUDIO':
        return const Color(0xFF6366F1); // Indigo - single audio
      case 'GUIDED':
        return const Color(0xFF14B8A6); // Teal - guided meditation
      case 'PODCAST':
        return const Color(0xFFF97316); // Orange - podcast
      case 'SOUNDS':
        return const Color(0xFF22C55E); // Green - sounds/ambience
      case 'COLLECTION':
        return const Color(0xFFEC4899); // Pink - audio collection
      default:
        return Colors.black.withOpacity(0.7);
    }
  }

  Widget _buildRecommendationCard(Map<String, dynamic> item) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(_isVintage ? 12 : 8),
            child: CachedNetworkImage(
              imageUrl: item['imageUrl'],
              width: 130,
              height: 130,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                width: 130,
                height: 130,
                color: _isVintage ? _surfaceColor : const Color(0xFF282828),
                child: Icon(Icons.music_note, color: _isVintage ? _primaryColor.withOpacity(0.5) : Colors.white24, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item['title'],
            style: TextStyle(
              color: _textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            item['subtitle'],
            style: TextStyle(
              color: _textSecondary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLibrarySnippetCard({
    required String title,
    required String subtitle,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(_isVintage ? 16 : 12),
          border: _isVintage ? Border.all(color: _primaryColor.withOpacity(0.2)) : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(_isVintage ? 12 : 8),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: 80,
                  height: 80,
                  color: _isVintage ? _surfaceColor : const Color(0xFF282828),
                  child: Icon(Icons.favorite, color: _isVintage ? _primaryColor : const Color(0xFFFF2D55)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.favorite, color: _isVintage ? _primaryColor : const Color(0xFFFF2D55), size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLibrary() {
    return GestureDetector(
      onTap: () => context.push(AppRouter.library),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(_isVintage ? 16 : 12),
          border: Border.all(color: _isVintage ? _primaryColor.withOpacity(0.2) : Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isVintage ? _primaryColor.withOpacity(0.15) : const Color(0xFFFF2D55).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.favorite_border, color: _isVintage ? _primaryColor : const Color(0xFFFF2D55), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start Your Library',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Like videos to see them here',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _textSecondary.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}
