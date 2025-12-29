import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_state.dart';
import '../../../videos/presentation/bloc/videos_bloc.dart';
import '../../../videos/presentation/bloc/videos_state.dart';
import '../widgets/mood_selector_widget.dart';

class WellnessGoalsPage extends StatefulWidget {
  const WellnessGoalsPage({super.key});

  @override
  State<WellnessGoalsPage> createState() => _WellnessGoalsPageState();
}

class _WellnessGoalsPageState extends State<WellnessGoalsPage> {
  String _selectedFilter = 'Video';
  String? _selectedMoodId;
  
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

  // Recommendations data
  final List<Map<String, dynamic>> _recommendations = [
    {
      'title': 'Evening Calm',
      'subtitle': 'Based on your views',
      'imageUrl': 'https://picsum.photos/seed/rec1/200/200',
    },
    {
      'title': 'Sleep Better',
      'subtitle': 'Recommended',
      'imageUrl': 'https://picsum.photos/seed/rec2/200/200',
    },
    {
      'title': 'Daily Peace',
      'subtitle': 'For you',
      'imageUrl': 'https://picsum.photos/seed/rec3/200/200',
    },
  ];

  List<Map<String, dynamic>> get _recentlyViewed => _filterContent[_selectedFilter] ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Large Header Banner with wallpaper image
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Background wallpaper image
                Container(
                  height: 240,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage('https://picsum.photos/seed/wellness-banner/800/400'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Dark gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.black.withOpacity(0.5),
                              const Color(0xFF0A0A0A),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content on banner
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Home',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Good evening',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ready for your daily wellness?',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
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
                    _buildFilterTab('Video'),
                    _buildFilterTab('Audio'),
                    _buildFilterTab('Podcast'),
                    _buildFilterTab('Sounds'),
                  ],
                ),
              ),
            ),
          ),

          // Recently Viewed Section (content changes based on filter)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recently Viewed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'See all',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Column(
                key: ValueKey(_selectedFilter),
                children: _recentlyViewed.map((item) => _buildTrendingItem(item)).toList(),
              ),
            ),
          ),

          // Recommendations based on recent views (Horizontal scroll)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recommended for you',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'See all',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _recommendations.length,
                itemBuilder: (context, index) => _buildRecommendationCard(_recommendations[index]),
              ),
            ),
          ),

          // My Library Section (Snippet view)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Library',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRouter.library),
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        color: Color(0xFF1DB954),
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
  }

  Widget _buildFilterTab(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
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
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item['imageUrl'],
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                width: 56,
                height: 56,
                color: const Color(0xFF282828),
                child: const Icon(Icons.music_note, color: Colors.white24),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['subtitle'],
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.play_arrow, color: Colors.white38, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${item['views']} • ${item['duration']}',
                      style: const TextStyle(
                        color: Colors.white38,
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
            icon: const Icon(Icons.more_horiz, color: Colors.white54),
            onPressed: () {},
          ),
        ],
      ),
    );
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
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item['imageUrl'],
              width: 130,
              height: 130,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                width: 130,
                height: 130,
                color: const Color(0xFF282828),
                child: const Icon(Icons.music_note, color: Colors.white24, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item['title'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            item['subtitle'],
            style: const TextStyle(
              color: Colors.white54,
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
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: 80,
                  height: 80,
                  color: const Color(0xFF282828),
                  child: const Icon(Icons.favorite, color: Color(0xFFFF2D55)),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.favorite, color: Color(0xFFFF2D55), size: 16),
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
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF2D55).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.favorite_border, color: Color(0xFFFF2D55), size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start Your Library',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Like videos to see them here',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
