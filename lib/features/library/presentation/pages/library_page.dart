import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/app_router.dart';
import '../bloc/library_bloc.dart';
import '../bloc/library_event.dart';
import '../bloc/library_state.dart';
import '../../../videos/presentation/bloc/videos_bloc.dart';
import '../../../videos/presentation/bloc/videos_state.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Library',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, libraryState) {
          if (libraryState is LibraryLoaded) {
            final savedIds = libraryState.savedIds;
            
            if (savedIds.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A1A1A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Colors.white24,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Saved Content',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Videos and audio you save will appear here',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DB954),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text(
                          'Explore Content',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return BlocBuilder<VideosBloc, VideosState>(
              builder: (context, videosState) {
                if (videosState is VideosLoaded) {
                  // Filter videos that are in the library
                  final savedVideos = videosState.videos
                      .where((v) => savedIds.contains(v.id))
                      .toList();
                  
                  // Also get audio items (those starting with 'audio_')
                  final audioIds = savedIds
                      .where((id) => id.startsWith('audio_'))
                      .toList();
                  
                  if (savedVideos.isEmpty && audioIds.isEmpty) {
                    return const Center(
                      child: Text(
                        'No saved content found',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: savedVideos.length + audioIds.length,
                    itemBuilder: (context, index) {
                      if (index < savedVideos.length) {
                        final video = savedVideos[index];
                        return _buildVideoCard(context, video);
                      } else {
                        final audioId = audioIds[index - savedVideos.length];
                        return _buildAudioCard(context, audioId);
                      }
                    },
                  );
                }
                
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1DB954)),
                );
              },
            );
          }
          
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1DB954)),
          );
        },
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, dynamic video) {
    return GestureDetector(
      onTap: () {
        context.push('${AppRouter.videoPlayer}?id=${video.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: video.thumbnailUrl,
                width: 120,
                height: 90,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: 120,
                  height: 90,
                  color: const Color(0xFF282828),
                  child: const Icon(Icons.play_circle, color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF448AFF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'VIDEO',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.instructor,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Remove button
            IconButton(
              icon: const Icon(Icons.favorite, color: Color(0xFFFF2D55)),
              onPressed: () {
                context.read<LibraryBloc>().add(RemoveFromLibrary(contentId: video.id));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioCard(BuildContext context, String contentId) {
    // Extract the actual audio ID (remove 'audio_' prefix)
    final audioId = contentId.replaceFirst('audio_', '');
    
    return GestureDetector(
      onTap: () {
        context.push('${AppRouter.audioPlayer}?id=$audioId');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.headphones, color: Color(0xFF1DB954), size: 28),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DB954),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AUDIO',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Audio #$audioId',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Meditation Audio',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Remove button
              IconButton(
                icon: const Icon(Icons.bookmark, color: Color(0xFF1DB954)),
                onPressed: () {
                  context.read<LibraryBloc>().add(RemoveFromLibrary(contentId: contentId));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
