import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../videos/presentation/bloc/videos_bloc.dart';
import '../../../videos/presentation/bloc/videos_state.dart';
import '../../../meditation/presentation/bloc/meditation_bloc.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header with title and category chips
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
                        const Text(
                          'Explore',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Search icon button
                        GestureDetector(
                          onTap: () {
                            context.push(AppRouter.search);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(
                              Icons.search,
                              color: Colors.white,
                              size: 24,
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
          _buildSectionHeader('Top Trending', isPurple: true),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 240,
              child: _buildVideosSection(),
            ),
          ),

          // Top Speakers section - circular avatars
          _buildSectionHeader('Top Speakers'),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 120,
              child: _buildTopSpeakersSection(),
            ),
          ),

          // Top picks in wellness
          if (_selectedCategory == 'All' || _selectedCategory == 'Audio') ...[
            _buildSectionHeader('Top picks in wellness'),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: _buildAudioSection(),
              ),
            ),
          ],

          // Discover picks for you
          _buildSectionHeader('Discover picks for you'),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: _buildMadeForYouSection(),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSpeakersSection() {
    final speakers = [
      {'id': 'speaker1', 'name': 'Dr. Sarah', 'imageUrl': 'https://picsum.photos/seed/speaker1/200/200'},
      {'id': 'speaker2', 'name': 'Mark', 'imageUrl': 'https://picsum.photos/seed/speaker2/200/200'},
      {'id': 'speaker3', 'name': 'Emma', 'imageUrl': 'https://picsum.photos/seed/speaker3/200/200'},
      {'id': 'speaker4', 'name': 'James', 'imageUrl': 'https://picsum.photos/seed/speaker4/200/200'},
      {'id': 'speaker5', 'name': 'Lisa', 'imageUrl': 'https://picsum.photos/seed/speaker5/200/200'},
      {'id': 'speaker6', 'name': 'David', 'imageUrl': 'https://picsum.photos/seed/speaker6/200/200'},
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
            width: 80,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: speaker['imageUrl']!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFF282828),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF282828),
                        child: const Icon(Icons.person, color: Colors.white24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  speaker['name']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
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

  Widget _buildFeaturedCard() {
    return BlocBuilder<MeditationBloc, MeditationState>(
      builder: (context, state) {
        if (state is MeditationLoaded && state.meditationTypes.isNotEmpty) {
          final featured = state.meditationTypes.first;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                context.push(
                  '${AppRouter.meditationCategory}?id=${featured.id}&name=${Uri.encodeComponent(featured.name)}',
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B3A4B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Left side - image with badge
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl: featured.imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 100,
                              height: 100,
                              color: const Color(0xFF282828),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 100,
                              height: 100,
                              color: const Color(0xFF282828),
                              child: const Icon(Icons.music_note, color: Colors.white24),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1DB954),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.radio, color: Colors.white, size: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Right side - content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${featured.name} Radio',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(Icons.more_horiz, color: Colors.white54),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Curated',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '50 sessions • ${featured.subtitle}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white38),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.share_outlined, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Preview playlist',
                                      style: TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.white54),
                                onPressed: () {},
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1DB954),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMadeForYouFeaturedCard() {
    return BlocBuilder<MeditationBloc, MeditationState>(
      builder: (context, state) {
        if (state is MeditationLoaded && state.moodBasedTypes.isNotEmpty) {
          final featured = state.moodBasedTypes.first;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                context.push(
                  '${AppRouter.meditationCategory}?id=${featured.id}&name=${Uri.encodeComponent(featured.name)}',
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7C4DFF).withOpacity(0.3),
                      const Color(0xFF448AFF).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: featured.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${featured.name} Radio',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Curated',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.more_horiz, color: Colors.white54),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF7C3AED) // Purple when selected (matching Meditate page)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF7C3AED)
                  : Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isPurple = false}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(
          title,
          style: TextStyle(
            color: isPurple ? const Color(0xFF7C3AED) : Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentsSection() {
    return BlocBuilder<MeditationBloc, MeditationState>(
      builder: (context, state) {
        if (state is MeditationLoaded) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.meditationTypes.take(4).length,
            itemBuilder: (context, index) {
              final type = state.meditationTypes[index];
              return _buildRecentCard(
                title: type.name,
                subtitle: type.subtitle,
                imageUrl: type.imageUrl,
                onTap: () {
                  context.push(
                    '${AppRouter.meditationCategory}?id=${type.id}&name=${Uri.encodeComponent(type.name)}',
                  );
                },
              );
            },
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1DB954)),
        );
      },
    );
  }

  Widget _buildRecentCard({
    required String title,
    required String subtitle,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFF282828),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFF282828),
                    child: const Icon(Icons.person, color: Colors.white24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle.isNotEmpty ? subtitle.split(',').first : 'Artist',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideosSection() {
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
              );
            },
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1DB954)),
        );
      },
    );
  }

  /// Apple Music-style trending card - category and title on top, image card below
  Widget _buildTrendingCard({
    required String category,
    required String title,
    required String authorName,
    required String imageUrl,
    required VoidCallback onTap,
    bool isSeries = false,
    int? episodeCount,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category label
            Text(
              category,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            // Title
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Author name
            Text(
              authorName,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Large image card
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFF282828),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFF282828),
                          child: const Icon(Icons.play_circle_outline, color: Colors.white24, size: 48),
                        ),
                      ),
                      // Subtle gradient overlay at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.4),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Series episode count badge
                      if (isSeries && episodeCount != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.playlist_play, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '$episodeCount episodes',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
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

  Widget _buildAudioSection() {
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
                onTap: () {
                  context.push('${AppRouter.audioPlayer}?id=${audio.id}');
                },
              );
            },
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1DB954)),
        );
      },
    );
  }

  Widget _buildMadeForYouSection() {
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
                onTap: () {
                  context.push(
                    '${AppRouter.meditationCategory}?id=${type.id}&name=${Uri.encodeComponent(type.name)}',
                  );
                },
              );
            },
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1DB954)),
        );
      },
    );
  }

  Widget _buildContentCard({
    required String title,
    required String subtitle,
    required String imageUrl,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Square image with badge
            Stack(
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFF282828),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF282828),
                        child: const Icon(Icons.music_note, color: Colors.white24, size: 40),
                      ),
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
                        color: badge == 'VIDEO'
                            ? const Color(0xFF448AFF)
                            : const Color(0xFF1DB954),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
