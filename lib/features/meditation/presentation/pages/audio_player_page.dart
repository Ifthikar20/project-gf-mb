import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_event.dart';
import '../../data/repositories/meditation_repository.dart';
import '../../domain/entities/meditation_audio.dart';
import '../../../../core/services/goal_tracking_service.dart';

class AudioPlayerPage extends StatefulWidget {
  final String audioId;

  const AudioPlayerPage({super.key, required this.audioId});

  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  MeditationAudio? _audio;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSaved = false;
  Duration? _duration;
  Duration _position = Duration.zero;
  Timer? _sleepTimer;
  int? _sleepTimerMinutes;
  int _remainingSeconds = 0;
  double _playbackSpeed = 1.0;
  
  // Heads-up overlay state
  bool _showHeadsUpOverlay = true;
  Timer? _headsUpTimer;
  bool _hasTrackedCompletion = false; // Prevent double tracking

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _loadAudio();
    _setupAudioListeners();
    _startHeadsUpTimer();
  }

  void _startHeadsUpTimer() {
    _headsUpTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _showHeadsUpOverlay = false);
      }
    });
  }

  void _dismissHeadsUpOverlay() {
    _headsUpTimer?.cancel();
    setState(() => _showHeadsUpOverlay = false);
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(ApiEndpoints.sunsetWavesVideo),
    );
    
    await _videoController.initialize();
    _videoController.setLooping(true);
    _videoController.setVolume(0); // Muted - we're playing audio separately
    _videoController.play();
    
    if (mounted) {
      setState(() => _isVideoInitialized = true);
    }
  }

  void _setupAudioListeners() {
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        // Track goal completion when audio finishes
        if (_audio != null && _duration != null) {
          GoalTrackingService.instance.trackAudioCompletion(
            audioId: _audio!.id,
            category: _audio!.category ?? 'Meditation',
            durationSeconds: _duration!.inSeconds,
          );
        }
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
      }
    });
    
    // Also track if user reaches 80%+ progress
    _audioPlayer.positionStream.listen((position) {
      if (_audio != null && _duration != null && _duration!.inSeconds > 0) {
        final progress = position.inSeconds / _duration!.inSeconds;
        // Track at 80% completion (only once)
        if (progress >= 0.80 && !_hasTrackedCompletion) {
          _hasTrackedCompletion = true;
          GoalTrackingService.instance.trackAudioCompletion(
            audioId: _audio!.id,
            category: _audio!.category ?? 'Meditation',
            durationSeconds: _duration!.inSeconds,
          );
        }
      }
    });
  }

  Future<void> _loadAudio() async {
    try {
      final repository = MeditationRepository();
      
      // First, get audio details (from cache or API)
      var audio = repository.getAudioById(widget.audioId);
      audio ??= await repository.fetchAudioById(widget.audioId);

      if (audio != null) {
        setState(() => _audio = audio);

        // Check if saved (get context reference before async gap)
        if (!mounted) return;
        final libraryBloc = context.read<LibraryBloc>();
        _isSaved = libraryBloc.isSaved('audio_${audio.id}');

        // Check if this is mock/fallback content (non-UUID IDs like "1", "2")
        // Real backend content uses UUIDs like "550e8400-e29b-41d4-a716-446655440000"
        final isMockContent = !_isValidUuid(audio.id);
        
        if (isMockContent) {
          debugPrint('⚠️ Mock content detected (ID: ${audio.id}). Audio not available in backend.');
          debugPrint('💡 To fix: Upload audio content to the backend database.');
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
          return;
        }

        // Fetch the streaming URL from the backend API
        debugPrint('🎵 Fetching streaming URL for audio: ${audio.id}');
        final audioUrl = await repository.getAudioStreamingUrl(audio.id);
        
        if (audioUrl != null && audioUrl.isNotEmpty) {
          debugPrint('✅ Got streaming URL: $audioUrl');
          await _audioPlayer.setUrl(audioUrl);
          setState(() => _isLoading = false);
          await _audioPlayer.play();
        } else {
          // Fallback: If no streaming URL, show error
          debugPrint('⚠️ No streaming URL available for audio');
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      } else {
        debugPrint('❌ Audio not found: ${widget.audioId}');
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading audio: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  /// Check if a string is a valid UUID format
  bool _isValidUuid(String id) {
    // UUID format: 8-4-4-4-12 hexadecimal characters
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );
    return uuidRegex.hasMatch(id);
  }

  void _setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    setState(() {
      _sleepTimerMinutes = minutes;
      _remainingSeconds = minutes * 60;
    });

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            _audioPlayer.pause();
            _sleepTimer?.cancel();
            _sleepTimerMinutes = null;
            _showTimerCompleteSnackBar();
          }
        });
      }
    });
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    setState(() {
      _sleepTimerMinutes = null;
      _remainingSeconds = 0;
    });
  }

  void _showTimerCompleteSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sleep timer ended'),
        backgroundColor: Color(0xFF7C3AED),
      ),
    );
  }

  void _toggleSave() {
    if (_audio != null) {
      final contentId = 'audio_${_audio!.id}';
      final libraryBloc = context.read<LibraryBloc>();
      final isCurrentlySaved = libraryBloc.isSaved(contentId);
      
      setState(() => _isSaved = !isCurrentlySaved);
      
      if (_isSaved) {
        libraryBloc.add(AddToLibrary(contentId: contentId, contentType: 'audio'));
      } else {
        libraryBloc.add(RemoveFromLibrary(contentId: contentId));
      }
    }
  }

  void _setPlaybackSpeed(double speed) {
    _audioPlayer.setSpeed(speed);
    setState(() => _playbackSpeed = speed);
    Navigator.pop(context);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _headsUpTimer?.cancel();
    _videoController.dispose();
    _audioPlayer.dispose();
    _sleepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load audio', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _loadAudio();
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Video background
          if (_isVideoInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),
          // Dark overlay to ensure text readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // Heads-up overlay
          if (_showHeadsUpOverlay)
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismissHeadsUpOverlay,
                child: AnimatedOpacity(
                  opacity: _showHeadsUpOverlay ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    color: const Color(0xFF0A0A0A).withOpacity(0.95),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Visual warning image
                          Image.asset(
                            'assets/images/visual-warning-img.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 12),
                          // Main message
                          const Text(
                            'For the Best Experience',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Use headphones and close your eyes',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          // Tap to continue hint
                          const Text(
                            'Tap anywhere to continue',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Main content
          Column(
            children: [
              // Header with back button and actions
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      if (_sleepTimerMinutes != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bedtime, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${(_remainingSeconds ~/ 60)}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          _isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: _isSaved ? const Color(0xFF7C3AED) : Colors.white,
                        ),
                        onPressed: _toggleSave,
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white54),
                        onPressed: () => _showOptionsSheet(),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // Bottom controls section
              SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Progress Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                              activeTrackColor: const Color(0xFF7C3AED),
                              inactiveTrackColor: const Color(0xFF404040),
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: _position.inMilliseconds.toDouble(),
                              max: (_duration?.inMilliseconds ?? 1).toDouble(),
                              onChanged: (value) {
                                _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_position),
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                                Text(
                                  _formatDuration(_duration ?? Duration.zero),
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Playback Controls with Album Art
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: StreamBuilder<PlayerState>(
                        stream: _audioPlayer.playerStateStream,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data?.playing ?? false;
                          
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Small circular album art on the left
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: _audio!.imageUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Container(
                                    width: 56,
                                    height: 56,
                                    color: const Color(0xFF282828),
                                    child: const Icon(Icons.headphones, color: Colors.white24, size: 24),
                                  ),
                                ),
                              ),
                              
                              // Control buttons
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Rewind 15s
                                  IconButton(
                                    icon: const Icon(Icons.replay_10, color: Colors.white70),
                                    iconSize: 28,
                                    onPressed: () {
                                      final newPos = _position - const Duration(seconds: 15);
                                      _audioPlayer.seek(newPos < Duration.zero ? Duration.zero : newPos);
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  // Play/Pause
                                  GestureDetector(
                                    onTap: () {
                                      if (isPlaying) {
                                        _audioPlayer.pause();
                                      } else {
                                        _audioPlayer.play();
                                      }
                                    },
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF7C3AED),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isPlaying ? Icons.pause : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Forward 15s
                                  IconButton(
                                    icon: const Icon(Icons.forward_10, color: Colors.white70),
                                    iconSize: 28,
                                    onPressed: () {
                                      final newPos = _position + const Duration(seconds: 15);
                                      if (_duration != null && newPos > _duration!) {
                                        _audioPlayer.seek(_duration!);
                                      } else {
                                        _audioPlayer.seek(newPos);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              
                              // Quick Actions
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.bedtime_outlined,
                                      color: _sleepTimerMinutes != null ? const Color(0xFF7C3AED) : Colors.white54,
                                    ),
                                    iconSize: 24,
                                    onPressed: () => _showSleepTimerSheet(),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.speed,
                                      color: _playbackSpeed != 1.0 ? const Color(0xFF7C3AED) : Colors.white54,
                                    ),
                                    iconSize: 24,
                                    onPressed: () => _showSpeedSheet(),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _showSleepTimerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sleep Timer',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (_sleepTimerMinutes != null)
                  TextButton(
                    onPressed: () {
                      _cancelSleepTimer();
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel Timer', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [5, 10, 15, 20, 30, 45, 60].map((minutes) {
                return GestureDetector(
                  onTap: () {
                    _setSleepTimer(minutes);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF282828),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$minutes min',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSpeedSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Playback Speed',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                final isSelected = _playbackSpeed == speed;
                return GestureDetector(
                  onTap: () => _setPlaybackSpeed(speed),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF282828),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${speed}x',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add, color: Colors.white),
              title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text('About', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
