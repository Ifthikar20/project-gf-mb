import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/recently_viewed_service.dart';
import '../bloc/library_bloc.dart';
import '../bloc/library_event.dart';
import '../bloc/library_state.dart';
import '../../../videos/presentation/bloc/videos_bloc.dart';
import '../../../videos/presentation/bloc/videos_state.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1DB954),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Recently Viewed'),
            Tab(text: 'Saved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecentlyViewedTab(),
          _buildSavedTab(),
        ],
      ),
    );
  }
  
  Widget _buildRecentlyViewedTab() {
    return ListenableBuilder(
      listenable: RecentlyViewedService.instance,
      builder: (context, _) {
        final items = RecentlyViewedService.instance.items;
        
        if (items.isEmpty) {
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
                    Icons.history,
                    size: 64,
                    color: Colors.white24,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Recent Views',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Videos you watch will appear here',
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
                      'Start Watching',
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
        
        return Column(
          children: [
            // Clear all button
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${items.length} items',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () => _showClearAllDialog(),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          color: Color(0xFF1DB954),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildRecentlyViewedCard(item);
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildRecentlyViewedCard(RecentlyViewedItem item) {
    return GestureDetector(
      onTap: () {
        if (item.contentType == 'video') {
          context.push('${AppRouter.videoPlayer}?id=${item.contentId}');
        } else {
          context.push('${AppRouter.audioPlayer}?id=${item.contentId}');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
              child: item.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.thumbnailUrl!,
                      width: 100,
                      height: 75,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => _buildPlaceholder(item.contentType),
                    )
                  : _buildPlaceholder(item.contentType),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.contentType == 'video' 
                            ? const Color(0xFF448AFF) 
                            : const Color(0xFF1DB954),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.contentType.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 9, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(item.viewedAt),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Play icon
            Container(
              margin: const EdgeInsets.only(right: 8),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954).withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Color(0xFF1DB954),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlaceholder(String contentType) {
    return Container(
      width: 100,
      height: 75,
      color: const Color(0xFF282828),
      child: Icon(
        contentType == 'video' ? Icons.play_circle : Icons.headphones,
        color: Colors.white24,
      ),
    );
  }
  
  String _formatTime(DateTime viewedAt) {
    final now = DateTime.now();
    final diff = now.difference(viewedAt);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${viewedAt.day}/${viewedAt.month}/${viewedAt.year}';
    }
  }
  
  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear History?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will remove all your recently viewed items.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              RecentlyViewedService.instance.clearAll();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Color(0xFFFF2D55))),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSavedTab() {
    return BlocBuilder<LibraryBloc, LibraryState>(
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
                    'Content you save will appear here',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return BlocBuilder<VideosBloc, VideosState>(
            builder: (context, videosState) {
              if (videosState is VideosLoaded) {
                final savedVideos = videosState.videos
                    .where((v) => savedIds.contains(v.id))
                    .toList();
                
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954).withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.headphones, color: Color(0xFF1DB954), size: 28),
              ),
              const SizedBox(width: 16),
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
