import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_event.dart';
import '../../data/repositories/meditation_repository.dart';
import '../../domain/entities/meditation_audio.dart';

class AudioPlayerPage extends StatefulWidget {
  final String audioId;

  const AudioPlayerPage({super.key, required this.audioId});

  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
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

  @override
  void initState() {
    super.initState();
    _loadAudio();
    _setupAudioListeners();
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
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
      }
    });
  }

  Future<void> _loadAudio() async {
    try {
      final repository = MeditationRepository();
      final audio = repository.getAudioById(widget.audioId);

      if (audio != null) {
        setState(() => _audio = audio);

        // Check if saved
        final libraryBloc = context.read<LibraryBloc>();
        _isSaved = libraryBloc.isSaved('audio_${audio.id}');

        await _audioPlayer.setUrl(
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        );

        setState(() => _isLoading = false);
        await _audioPlayer.play();
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
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
        backgroundColor: Color(0xFF1DB954),
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
          child: CircularProgressIndicator(color: Color(0xFF1DB954)),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DB954)),
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
          // Ambient background graphics
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1DB954).withOpacity(0.3),
                    const Color(0xFF1DB954).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C3AED).withOpacity(0.25),
                    const Color(0xFF7C3AED).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEC4899).withOpacity(0.2),
                    const Color(0xFFEC4899).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Main content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Header with back button
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
                              color: const Color(0xFF1DB954),
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
                            color: _isSaved ? const Color(0xFF1DB954) : Colors.white,
                          ),
                          onPressed: _toggleSave,
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onPressed: () => _showOptionsSheet(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Album Art - Smaller size
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 60),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1DB954).withOpacity(0.4),
                        blurRadius: 50,
                        offset: const Offset(0, 25),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: _audio!.imageUrl,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        height: 220,
                        color: const Color(0xFF282828),
                        child: const Icon(Icons.headphones, color: Colors.white24, size: 60),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

            // Title and Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text(
                    _audio!.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _audio!.description,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _audio!.category.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF1DB954),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

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
                      activeTrackColor: const Color(0xFF1DB954),
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

            const SizedBox(height: 20),

            // Simplified Playback Controls
            StreamBuilder<PlayerState>(
              stream: _audioPlayer.playerStateStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data?.playing ?? false;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Rewind 15s
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white70),
                      iconSize: 32,
                      onPressed: () {
                        final newPos = _position - const Duration(seconds: 15);
                        _audioPlayer.seek(newPos < Duration.zero ? Duration.zero : newPos);
                      },
                    ),
                    const SizedBox(width: 24),
                    // Play/Pause - smaller
                    GestureDetector(
                      onTap: () {
                        if (isPlaying) {
                          _audioPlayer.pause();
                        } else {
                          _audioPlayer.play();
                        }
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1DB954),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Forward 15s
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white70),
                      iconSize: 32,
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
                );
              },
            ),

            const SizedBox(height: 24),

            // Minimal Quick Actions - just 2 items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMinimalAction(
                    icon: Icons.bedtime_outlined,
                    label: _sleepTimerMinutes != null 
                        ? '${(_remainingSeconds ~/ 60)}m' 
                        : 'Timer',
                    isActive: _sleepTimerMinutes != null,
                    onTap: () => _showSleepTimerSheet(),
                  ),
                  _buildMinimalAction(
                    icon: Icons.speed,
                    label: '${_playbackSpeed}x',
                    isActive: _playbackSpeed != 1.0,
                    onTap: () => _showSpeedSheet(),
                  ),
                  _buildMinimalAction(
                    icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    label: 'Save',
                    isActive: _isSaved,
                    onTap: _toggleSave,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalAction({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF1DB954) : Colors.white54,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF1DB954) : Colors.white54,
              fontSize: 11,
            ),
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
                      color: isSelected ? const Color(0xFF1DB954) : const Color(0xFF282828),
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
