import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../videos/presentation/bloc/videos_bloc.dart';
import '../../../videos/presentation/bloc/videos_state.dart';
import '../../../meditation/presentation/bloc/meditation_bloc.dart';
import '../../../meditation/presentation/bloc/meditation_state.dart';

class SpeakerPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar with back button
          SliverAppBar(
            backgroundColor: const Color(0xFF121212),
            expandedHeight: 280,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF7C3AED).withOpacity(0.6),
                      const Color(0xFF121212),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Speaker avatar
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: speakerImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: const Color(0xFF282828),
                              child: const Icon(Icons.person, color: Colors.white24, size: 40),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFF282828),
                              child: const Icon(Icons.person, color: Colors.white24, size: 40),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Speaker name
                      Text(
                        speakerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Speaker specialization
                      Text(
                        'Wellness Expert',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bio section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      color: Color(0xFF7C3AED),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$speakerName is a renowned wellness expert specializing in mindfulness and meditation practices. With years of experience, they have helped thousands of people find inner peace and balance.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Videos Section
          SliverToBoxAdapter(
            child: _buildSectionHeader('Videos'),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: _buildVideosSection(context),
            ),
          ),

          // Audio Content Section
          SliverToBoxAdapter(
            child: _buildSectionHeader('Audio Sessions'),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: _buildAudioSection(context),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVideosSection(BuildContext context) {
    return BlocBuilder<VideosBloc, VideosState>(
      builder: (context, state) {
        if (state is VideosLoaded) {
          // Filter or show all videos (for now, showing sample)
          final videos = state.videos.take(5).toList();
          if (videos.isEmpty) {
            return _buildEmptyState('No videos available');
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return _buildContentCard(
                title: video.title,
                subtitle: video.category,
                imageUrl: video.thumbnailUrl,
                badge: 'VIDEO',
                onTap: () {
                  context.push('${AppRouter.videoPlayer}?id=${video.id}');
                },
              );
            },
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        );
      },
    );
  }

  Widget _buildAudioSection(BuildContext context) {
    return BlocBuilder<MeditationBloc, MeditationState>(
      builder: (context, state) {
        if (state is MeditationLoaded) {
          // Filter or show all audios (for now, showing sample)
          final audios = state.audios.take(5).toList();
          if (audios.isEmpty) {
            return _buildEmptyState('No audio sessions available');
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: audios.length,
            itemBuilder: (context, index) {
              final audio = audios[index];
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
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 14,
        ),
      ),
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
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Square image with badge
            Stack(
              children: [
                Container(
                  width: 140,
                  height: 140,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
