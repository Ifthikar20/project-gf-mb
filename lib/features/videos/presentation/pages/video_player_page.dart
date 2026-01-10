import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/streaming_service.dart';
import '../../../../core/services/recently_viewed_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_event.dart';
import '../../../library/presentation/bloc/library_state.dart';
import '../../data/repositories/videos_repository.dart';
import '../../domain/entities/video_entity.dart';
import '../../domain/entities/episode_entity.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoId;

  const VideoPlayerPage({super.key, required this.videoId});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _controller;
  VideoEntity? _video;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isPlaying = false;
  bool _showEpisodes = false;
  bool _isLiked = false;
  int _currentEpisode = 1;
  double _videoProgress = 0.0;
  String? _streamingUrl;
  
  // Episodes from API (replaces mock data)
  List<EpisodeEntity> _episodes = [];
  bool _isLoadingEpisodes = false;
  String? _currentEpisodeId;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      final repository = VideosRepository();
      final video = await repository.getVideoById(widget.videoId);
      
      if (video != null) {
        setState(() {
          _video = video;
          _currentEpisodeId = video.id;
          _currentEpisode = video.episodeNumber ?? 1;
        });
        
        // Load series episodes if this video belongs to a series
        if (video.belongsToSeries) {
          _loadSeriesEpisodes(video.seriesId!);
        }

        // Try to get HLS streaming URL from backend
        String videoUrl = video.videoUrl;
        
        // Get streaming URLs (uses s3_keys from content detail)
        try {
          final streamingUrls = await StreamingService.instance.getStreamingUrls(widget.videoId);
          videoUrl = streamingUrls.hlsMaster;
          _streamingUrl = videoUrl;
          debugPrint('📼 Using HLS stream: $videoUrl');
        } catch (e) {
          debugPrint('⚠️ Streaming failed, using fallback: $e');
          // Keep using video.videoUrl as fallback
        }

        _controller = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
        )..initialize().then((_) {
            setState(() => _isLoading = false);
            _controller!.play();
            _controller!.addListener(_videoListener);
            
            // Track as recently viewed
            RecentlyViewedService.instance.addItem(
              contentId: video.id,
              title: video.title,
              thumbnailUrl: video.thumbnailUrl,
              contentType: 'video',
              durationSeconds: video.durationInSeconds,
            );
            
            // Track video view (GA4 + Backend dual tracking)
            AnalyticsService.instance.trackVideoView(
              videoId: video.id,
              videoTitle: video.title,
              category: video.category,
              expert: video.instructor,
              durationSeconds: video.durationInSeconds,
            );
          }).catchError((error) {
            debugPrint('❌ Video initialization failed: $error');
            setState(() { _hasError = true; _isLoading = false; });
          });
      } else {
        setState(() { _hasError = true; _isLoading = false; });
      }
    } catch (e) {
      debugPrint('❌ Video loading failed: $e');
      setState(() { _hasError = true; _isLoading = false; });
    }
  }
  
  /// Load series episodes from API
  Future<void> _loadSeriesEpisodes(String seriesId) async {
    setState(() => _isLoadingEpisodes = true);
    try {
      final repository = VideosRepository();
      final episodes = await repository.getSeriesEpisodes(seriesId);
      setState(() {
        _episodes = episodes;
        _isLoadingEpisodes = false;
      });
      debugPrint('📺 Loaded ${episodes.length} episodes for series');
    } catch (e) {
      debugPrint('⚠️ Failed to load series episodes: $e');
      setState(() => _isLoadingEpisodes = false);
    }
  }
  
  /// Switch to a different episode in the series
  Future<void> _switchToEpisode(EpisodeEntity episode) async {
    setState(() {
      _showEpisodes = false;
      _isLoading = true;
      _currentEpisode = episode.episodeNumber;
      _currentEpisodeId = episode.id;
    });
    
    // Dispose current controller
    _controller?.removeListener(_videoListener);
    _controller?.pause();
    await _controller?.dispose();
    
    // Initialize new video controller with episode URL
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(episode.hlsPlaylistUrl),
    )..initialize().then((_) {
        setState(() => _isLoading = false);
        _controller!.play();
        _controller!.addListener(_videoListener);
        
        // Track as recently viewed
        RecentlyViewedService.instance.addItem(
          contentId: episode.id,
          title: episode.title,
          thumbnailUrl: episode.thumbnailUrl,
          contentType: 'video',
          durationSeconds: episode.durationSeconds,
        );
      }).catchError((error) {
        debugPrint('❌ Episode initialization failed: $error');
        setState(() { _hasError = true; _isLoading = false; });
      });
  }

  void _videoListener() {
    if (_controller != null && _controller!.value.isInitialized) {
      final duration = _controller!.value.duration;
      final position = _controller!.value.position;
      
      setState(() {
        _isPlaying = _controller!.value.isPlaying;
        if (duration.inMilliseconds > 0) {
          _videoProgress = position.inMilliseconds / duration.inMilliseconds;
        }
      });
    }
  }

  void _toggleLike() {
    if (_video != null) {
      final libraryBloc = context.read<LibraryBloc>();
      final isCurrentlyLiked = libraryBloc.isSaved(_video!.id);
      setState(() {
        _isLiked = !isCurrentlyLiked;
      });
      if (_isLiked) {
        libraryBloc.add(AddToLibrary(contentId: _video!.id, contentType: 'video'));
      } else {
        libraryBloc.add(RemoveFromLibrary(contentId: _video!.id));
      }
    }
  }

  @override
  void dispose() {
    // Track watch progress before disposing
    if (_video != null && _controller != null && _controller!.value.isInitialized) {
      final position = _controller!.value.position;
      final duration = _controller!.value.duration;
      final progressPercent = duration.inMilliseconds > 0 
          ? ((position.inMilliseconds / duration.inMilliseconds) * 100).round()
          : 0;
      
      // Track video progress/completion in GA4
      if (progressPercent >= 90) {
        AnalyticsService.instance.trackVideoComplete(
          videoId: _video!.id,
          videoTitle: _video!.title,
          watchTimeSeconds: position.inSeconds,
        );
      } else {
        AnalyticsService.instance.trackVideoProgress(
          videoId: _video!.id,
          progressPercent: progressPercent,
          watchTimeSeconds: position.inSeconds,
        );
      }
    }
    
    _controller?.removeListener(_videoListener);
    _controller?.pause();
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _hasError
              ? _buildErrorView()
              : _buildVideoPlayer(),
    );
  }

  Widget _buildErrorView() {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              const Text('Failed to load video', style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    label: const Text('Go Back', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() { _isLoading = true; _hasError = false; });
                      _loadVideo();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DB954),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Top-left back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    return Stack(
      children: [
        // Full screen video - clipped to screen bounds
        if (_controller != null && _controller!.value.isInitialized)
          Positioned.fill(
            child: ClipRect(
              child: GestureDetector(
                onTap: () {
                  if (_controller!.value.isPlaying) {
                    _controller!.pause();
                  } else {
                    _controller!.play();
                  }
                },
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),
            ),
          ),
        
        // Dark gradient overlay at bottom for readability (ignores touch)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: MediaQuery.of(context).size.height * 0.45,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.95),
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),
        ),
        
        // Play/Pause indicator - tappable
        if (!_isPlaying && _controller != null && _controller!.value.isInitialized)
          Center(
            child: GestureDetector(
              onTap: () {
                _controller!.play();
                setState(() => _isPlaying = true);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.play_arrow, size: 60, color: Colors.white),
              ),
            ),
          ),
        
        // Top bar with back button and actions
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? const Color(0xFFFF2D55) : Colors.white,
                    size: 26,
                  ),
                  onPressed: _toggleLike,
                ),
              ],
            ),
          ),
        ),
        
        // Bottom content section
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author section with profile, name, and description
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author row - tappable to view speaker profile
                      GestureDetector(
                        onTap: () {
                          if (_video != null) {
                            final speakerName = _video!.instructor ?? 'Wellness Guide';
                            final speakerImageUrl = 'https://picsum.photos/seed/${speakerName}/100/100';
                            context.push(
                              '${AppRouter.speakerProfile}?id=${_video!.id}&name=${Uri.encodeComponent(speakerName)}&imageUrl=${Uri.encodeComponent(speakerImageUrl)}',
                            );
                          }
                        },
                        child: Row(
                          children: [
                            // Profile picture
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF1DB954), width: 2),
                              ),
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: 'https://picsum.photos/seed/${_video?.instructor ?? 'author'}/100/100',
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Container(
                                    color: const Color(0xFF282828),
                                    child: const Icon(Icons.person, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Author name and category
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _video?.instructor ?? 'Wellness Guide',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _video?.category ?? 'Wellness Coach',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Arrow indicator for tap
                            const Icon(Icons.chevron_right, color: Colors.white54, size: 22),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Video title
                      Text(
                        _video?.title ?? 'Video Title',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Video description
                      Text(
                        _video?.description ?? 'Discover the art of mindfulness and inner peace through this guided wellness session. Learn techniques to reduce stress and improve your mental clarity.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Duration and category tags
                      Row(
                        children: [
                          _buildTag(Icons.access_time, _video?.formattedDuration ?? '5:00'),
                          const SizedBox(width: 12),
                          _buildTag(Icons.category_outlined, _video?.category ?? 'Wellness'),
                          const SizedBox(width: 12),
                          _buildTag(Icons.visibility_outlined, '${_video?.formattedViews ?? '0'} views'),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Video progress bar
                Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _videoProgress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DB954),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Episodes button - only show when video belongs to a series
                if (_video?.belongsToSeries == true || _episodes.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _showEpisodes = true),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _isLoadingEpisodes
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white70,
                                    ),
                                  )
                                : const Icon(Icons.playlist_play, color: Colors.white70, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'More Episodes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _episodes.isNotEmpty
                                      ? 'Episode $_currentEpisode of ${_episodes.length} • Tap to view all'
                                      : 'Loading episodes...',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.keyboard_arrow_up, color: Colors.white70, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        
        // Episodes modal overlay
        if (_showEpisodes)
          _buildEpisodesModal(),
      ],
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesModal() {
    return GestureDetector(
      onTap: () => setState(() => _showEpisodes = false),
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping content
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Handle bar with glow
                  GestureDetector(
                    onTap: () => setState(() => _showEpisodes = false),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Header with purple accent
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'All Episodes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_episodes.length} episodes available',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                            onPressed: () => setState(() => _showEpisodes = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.white.withOpacity(0.1),
                  ),
                  // Episodes list
                  Expanded(
                    child: _isLoadingEpisodes
                        ? const Center(
                            child: CircularProgressIndicator(color: Colors.white70),
                          )
                        : _episodes.isEmpty
                            ? Center(
                                child: Text(
                                  'No episodes available',
                                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _episodes.length,
                                itemBuilder: (context, index) {
                                  final episode = _episodes[index];
                                  final isPlaying = _currentEpisodeId == episode.id;
                                  final isLocked = episode.isPremium; // Based on access tier
                                  return _buildEpisodeCard(episode, isPlaying, isLocked);
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeCard(EpisodeEntity episode, bool isPlaying, bool isLocked) {
    return GestureDetector(
      onTap: isLocked ? _showPremiumDialog : () => _switchToEpisode(episode),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isPlaying
              ? const Color(0xFF1DB954).withOpacity(0.15)
              : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: isPlaying ? Border.all(color: const Color(0xFF1DB954), width: 1.5) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Thumbnail
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: episode.thumbnailUrl.isNotEmpty 
                              ? episode.thumbnailUrl 
                              : 'https://picsum.photos/seed/ep${episode.episodeNumber}/120/80',
                          width: 100,
                          height: 70,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFF282828),
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFF282828),
                            child: const Icon(Icons.video_library, color: Colors.white54),
                          ),
                        ),
                      ),
                      if (isLocked)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Icon(Icons.lock, color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                      if (isPlaying && !isLocked)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Icon(Icons.play_circle_fill, color: Color(0xFF1DB954), size: 28),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            episode.formattedDuration,
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Episode ${episode.episodeNumber}',
                              style: TextStyle(
                                color: isPlaying ? const Color(0xFF1DB954) : Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isLocked) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, color: Colors.white, size: 10),
                                    SizedBox(width: 2),
                                    Text('PRO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          episode.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (episode.description != null && episode.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  episode.description!,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Premium Content', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'This episode is available for Premium members. Upgrade to unlock all episodes and exclusive content.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Upgrade Now', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
