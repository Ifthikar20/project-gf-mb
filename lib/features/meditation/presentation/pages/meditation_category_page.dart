import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/navigation/app_router.dart';
import '../bloc/meditation_bloc.dart';
import '../bloc/meditation_state.dart';
import '../../domain/entities/meditation_audio.dart';

class MeditationCategoryPage extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const MeditationCategoryPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: BlocBuilder<MeditationBloc, MeditationState>(
        builder: (context, state) {
          if (state is MeditationLoaded) {
            final categoryAudios = state.audios
                .where((audio) =>
                    audio.category.toLowerCase() == categoryId.toLowerCase())
                .toList();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Hero Header with gradient
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      // Hero image
                      Container(
                        height: 280,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFF282828),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: 'https://picsum.photos/seed/$categoryId/800/600',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFF282828),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFF282828),
                            child: const Icon(
                              Icons.self_improvement,
                              size: 64,
                              color: Colors.white24,
                            ),
                          ),
                        ),
                      ),
                      // Gradient overlay
                      Container(
                        height: 280,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                              const Color(0xFF121212),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                      // Top bar with back button
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios),
                                color: Colors.white,
                                onPressed: () => context.pop(),
                              ),
                              IconButton(
                                icon: const Icon(Icons.ios_share),
                                color: Colors.white,
                                onPressed: () {
                                  // Share functionality
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Category title
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Text(
                          categoryName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Featured Sessions section
                if (categoryAudios.isNotEmpty) ...[
                  _buildSectionHeader('Featured Sessions'),
                  _buildHorizontalList(context, categoryAudios),
                ],

                // Quick Sessions (under 10 mins)
                _buildSectionHeader('Quick Sessions'),
                _buildHorizontalList(
                  context,
                  state.audios.where((a) => a.durationInSeconds <= 600).toList(),
                ),

                // Deep Sessions (15+ mins)
                _buildSectionHeader('Deep Sessions'),
                _buildHorizontalList(
                  context,
                  state.audios.where((a) => a.durationInSeconds > 600).toList(),
                ),

                // Bottom spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            );
          }

          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF1DB954),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalList(BuildContext context, List<MeditationAudio> audios) {
    if (audios.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'No sessions available',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: audios.length,
          itemBuilder: (context, index) {
            final audio = audios[index];
            return _buildAudioCard(context, audio);
          },
        ),
      ),
    );
  }

  Widget _buildAudioCard(BuildContext context, MeditationAudio audio) {
    return GestureDetector(
      onTap: () {
        context.push('${AppRouter.audioPlayer}?id=${audio.id}');
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Album art style image
            Container(
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
                  imageUrl: audio.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFF282828),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white24,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFF282828),
                    child: const Icon(
                      Icons.headphones,
                      color: Colors.white24,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              audio.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Description - limit to 1 line to prevent overflow
            Text(
              audio.description,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
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
