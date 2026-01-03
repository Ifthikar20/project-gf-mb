# Video Playback Architecture - Mobile App Documentation

## Overview

This document provides a comprehensive explanation of how the Better & Bliss mobile app reads, processes, and displays video content from the UI layer through the entire application stack.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Data Flow](#data-flow)
3. [Layer-by-Layer Breakdown](#layer-by-layer-breakdown)
4. [UI Components](#ui-components)
5. [Video Playback Implementation](#video-playback-implementation)
6. [Current Issues & Limitations](#current-issues--limitations)
7. [API Response Handling](#api-response-handling)

---

## Architecture Overview

The app follows **Clean Architecture** principles with **BLoC (Business Logic Component)** state management:

```
┌─────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  UI Widgets  │  │  BLoC State  │  │    Pages     │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                     DOMAIN LAYER                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Entities   │  │  Use Cases   │  │ Repositories │  │
│  │              │  │  (Business   │  │ (Interfaces) │  │
│  │ VideoEntity  │  │    Logic)    │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                      DATA LAYER                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Repositories │  │    Models    │  │ Data Sources │  │
│  │    (Impl)    │  │              │  │  (API/Local) │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## Data Flow

### Complete Video Playback Flow

```
1. User Interaction
   ↓
2. UI Widget (VideoCard) - User taps on video
   ↓
3. Navigation (GoRouter) - Routes to VideoPlayerPage with videoId
   ↓
4. VideoPlayerPage._loadVideo() - Fetches video data
   ↓
5. VideosRepository.getVideoById(id) - Retrieves video entity
   ↓
6. VideoEntity - Returns video data with videoUrl field
   ↓
7. VideoPlayerController.networkUrl() - Initializes player with URL
   ↓
8. Video Playback - Flutter video_player package renders video
```

---

## Layer-by-Layer Breakdown

### 1. Domain Layer - VideoEntity

**File:** `lib/features/videos/domain/entities/video_entity.dart`

```dart
class VideoEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String videoUrl;           // ⚠️ ONLY field used for playback
  final int durationInSeconds;
  final String category;
  final String instructor;

  const VideoEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.videoUrl,        // ⚠️ Single video URL field
    required this.durationInSeconds,
    required this.category,
    required this.instructor,
  });

  String get formattedDuration {
    final minutes = durationInSeconds ~/ 60;
    final seconds = durationInSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
```

**Key Points:**
- ✅ `videoUrl` is the **ONLY** video URL field
- ❌ **NO** `hlsMasterUrl` or `hls_master_url` field exists
- ❌ **NO** adaptive streaming support
- This entity represents the pure business object with no knowledge of data sources

---

### 2. Data Layer - VideosRepository

**File:** `lib/features/videos/data/repositories/videos_repository.dart`

```dart
class VideosRepository {
  // Mock data - simulates API response
  final List<VideoEntity> _videos = [
    const VideoEntity(
      id: '1',
      title: 'Morning Yoga Flow',
      description: 'Start your day with energizing yoga poses...',
      thumbnailUrl: 'https://picsum.photos/seed/yoga1/400/225',
      videoUrl: 'https://commondatastorage.googleapis.com/.../BigBuckBunny.mp4',
      durationInSeconds: 420,
      category: 'Yoga',
      instructor: 'Sarah Johnson',
    ),
    // ... 7 more videos
  ];

  Future<List<VideoEntity>> getVideos({String? category}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (category == null || category == 'All') {
      return _videos;
    }
    return _videos.where((v) => v.category == category).toList();
  }

  Future<VideoEntity?> getVideoById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _videos.firstWhere((video) => video.id == id);
    } catch (e) {
      return null;
    }
  }
}
```

**Key Points:**
- Currently uses **mock data** (hardcoded videos)
- In production, this would make HTTP calls to backend API
- Returns `VideoEntity` objects with only `videoUrl` field
- All current URLs are direct MP4 files from Google Cloud Storage

---

### 3. Presentation Layer - BLoC State Management

**Files:**
- `lib/features/videos/presentation/bloc/videos_bloc.dart`
- `lib/features/videos/presentation/bloc/videos_event.dart`
- `lib/features/videos/presentation/bloc/videos_state.dart`

#### Events
```dart
// User actions that trigger state changes
abstract class VideosEvent extends Equatable {}

class LoadVideos extends VideosEvent {
  final String? category;
  const LoadVideos({this.category});
}

class FilterVideosByCategory extends VideosEvent {
  final String category;
  const FilterVideosByCategory(this.category);
}

class SearchVideos extends VideosEvent {
  final String query;
  const SearchVideos(this.query);
}
```

#### States
```dart
abstract class VideosState extends Equatable {}

class VideosInitial extends VideosState {}

class VideosLoading extends VideosState {}

class VideosLoaded extends VideosState {
  final List<VideoEntity> videos;
  final String currentCategory;

  const VideosLoaded({
    required this.videos,
    this.currentCategory = 'All',
  });
}

class VideosError extends VideosState {
  final String message;
  const VideosError(this.message);
}
```

#### BLoC Logic
```dart
class VideosBloc extends Bloc<VideosEvent, VideosState> {
  final VideosRepository _repository;

  VideosBloc(this._repository) : super(VideosInitial()) {
    on<LoadVideos>(_onLoadVideos);
    on<FilterVideosByCategory>(_onFilterVideos);
    on<SearchVideos>(_onSearchVideos);
  }

  Future<void> _onLoadVideos(LoadVideos event, Emitter emit) async {
    emit(VideosLoading());
    try {
      final videos = await _repository.getVideos(category: event.category);
      emit(VideosLoaded(videos: videos, currentCategory: event.category ?? 'All'));
    } catch (e) {
      emit(VideosError(e.toString()));
    }
  }
  // ... other handlers
}
```

---

## UI Components

### 1. Videos Listing Page

**File:** `lib/features/videos/presentation/pages/videos_page.dart`

```dart
class VideosPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideosBloc, VideosState>(
      builder: (context, state) {
        if (state is VideosLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (state is VideosLoaded) {
          return GridView.builder(
            itemCount: state.videos.length,
            itemBuilder: (context, index) {
              final video = state.videos[index];
              return VideoCard(video: video);  // ← Displays video preview
            },
          );
        }

        if (state is VideosError) {
          return Center(child: Text('Error: ${state.message}'));
        }

        return SizedBox.shrink();
      },
    );
  }
}
```

**How it reads data:**
1. `BlocBuilder` listens to `VideosBloc` state changes
2. When state is `VideosLoaded`, it receives `List<VideoEntity>`
3. Each `VideoEntity` contains `videoUrl` field
4. Passes video entity to `VideoCard` widget

---

### 2. Video Card Widget

**File:** `lib/features/videos/presentation/widgets/video_card.dart`

```dart
class VideoCard extends StatelessWidget {
  final VideoEntity video;

  const VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to video player with video ID
        context.push('/video-player?id=${video.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Color(0xFF1E1E1E),
        ),
        child: Column(
          children: [
            // Thumbnail
            ClipRRect(
              child: CachedNetworkImage(
                imageUrl: video.thumbnailUrl,  // ← Reads thumbnailUrl
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            // Video metadata
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    video.title,              // ← Reads title
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    video.formattedDuration,  // ← Reads duration
                    style: TextStyle(color: Colors.white54),
                  ),
                  Row(
                    children: [
                      Text(video.instructor),  // ← Reads instructor
                      Text(video.category),    // ← Reads category
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Data Fields Used:**
- ✅ `thumbnailUrl` - Display preview image
- ✅ `title` - Video title
- ✅ `formattedDuration` - Video length
- ✅ `instructor` - Instructor name
- ✅ `category` - Video category
- ❌ `videoUrl` - NOT used here (only in player)

---

### 3. Video Player Page

**File:** `lib/features/videos/presentation/pages/video_player_page.dart`

This is where the actual video URL is read and used for playback.

#### Initialization Flow

```dart
class VideoPlayerPage extends StatefulWidget {
  final String videoId;  // Received from navigation

  const VideoPlayerPage({required this.videoId});
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _controller;
  VideoEntity? _video;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadVideo();  // ← Starts loading process
  }
}
```

#### Video Loading Process

```dart
Future<void> _loadVideo() async {
  try {
    // Step 1: Get repository instance
    final repository = VideosRepository();

    // Step 2: Fetch video by ID
    final video = await repository.getVideoById(widget.videoId);

    if (video != null) {
      setState(() => _video = video);

      // Step 3: Initialize video player with videoUrl
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(video.videoUrl),  // ⚠️ READS videoUrl field HERE
      )..initialize().then((_) {
          setState(() => _isLoading = false);
          _controller!.play();
          _controller!.addListener(_videoListener);
        }).catchError((error) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        });
    } else {
      setState(() { _hasError = true; _isLoading = false; });
    }
  } catch (e) {
    setState(() { _hasError = true; _isLoading = false; });
  }
}
```

**Critical Line - Video URL Reading:**

```dart
// Line 87-88 in video_player_page.dart
_controller = VideoPlayerController.networkUrl(
  Uri.parse(video.videoUrl),  // ← THIS IS WHERE videoUrl IS READ
)
```

#### Video Player Controller

```dart
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
```

#### UI Rendering

```dart
Widget _buildVideoPlayer() {
  return Stack(
    children: [
      // Full screen video display
      if (_controller != null && _controller!.value.isInitialized)
        Positioned.fill(
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
                child: VideoPlayer(_controller!),  // ← Renders video
              ),
            ),
          ),
        ),

      // Video metadata overlay
      Positioned(
        bottom: 0,
        child: Column(
          children: [
            Text(_video?.title ?? ''),        // ← Reads title
            Text(_video?.description ?? ''),  // ← Reads description
            Text(_video?.instructor ?? ''),   // ← Reads instructor
            Text(_video?.category ?? ''),     // ← Reads category
          ],
        ),
      ),

      // Progress bar
      Container(
        height: 4,
        child: FractionallySizedBox(
          widthFactor: _videoProgress,  // ← Displays progress
          child: Container(color: Color(0xFF1DB954)),
        ),
      ),
    ],
  );
}
```

---

## Video Playback Implementation

### Technology Stack

**Flutter Package:** `video_player: ^2.8.1`

#### Package Configuration

**File:** `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  video_player: ^2.8.1          # Video playback
  cached_network_image: ^3.3.0  # Thumbnail caching
  flutter_bloc: ^8.1.3          # State management
  equatable: ^2.0.5             # Value equality
  go_router: ^12.1.1            # Navigation
```

### Video Player Capabilities

The `video_player` package supports:
- ✅ MP4 files (direct URLs)
- ✅ HLS streams (.m3u8)
- ✅ Network URLs
- ✅ Local files
- ✅ Adaptive streaming (if HLS used)

**Current Usage:**
- ✅ Network URLs via `VideoPlayerController.networkUrl()`
- ❌ NOT using HLS despite package support

---

## Current Issues & Limitations

### 1. Missing HLS Support

**Problem:**
- Backend API may return `hls_master_url` field
- Mobile app **ONLY** reads `videoUrl` field
- HLS URLs are **IGNORED** even if present in API response

**Impact:**
```
┌─────────────────────────────────────────────────────┐
│              Backend API Response                   │
├─────────────────────────────────────────────────────┤
│ {                                                   │
│   "id": "123",                                      │
│   "title": "Morning Yoga",                          │
│   "video_url": "https://cdn.com/video.mp4",        │
│   "hls_master_url": "https://cdn.com/master.m3u8"  │ ← IGNORED
│ }                                                   │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│           Mobile App VideoEntity                    │
├─────────────────────────────────────────────────────┤
│ VideoEntity(                                        │
│   id: "123",                                        │
│   videoUrl: "https://cdn.com/video.mp4",           │ ← ONLY THIS USED
│   // hlsMasterUrl field DOESN'T EXIST             │
│ )                                                   │
└─────────────────────────────────────────────────────┘
```

### 2. No Adaptive Bitrate Streaming

**Current Behavior:**
- Uses single MP4 file regardless of network conditions
- No quality switching based on bandwidth
- Higher data usage on mobile networks
- Potential buffering issues on slow connections

**Expected Behavior with HLS:**
```
Good Network:  HLS → High quality stream (1080p)
Medium Network: HLS → Medium quality stream (720p)
Poor Network:   HLS → Low quality stream (480p)
```

### 3. Hardcoded Mock Data

**Current Implementation:**
```dart
// VideosRepository - Mock data
videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
```

**Production Requirement:**
- Needs HTTP client (Dio, http package)
- API integration for real video data
- Error handling for network failures
- Retry logic for failed requests

---

## API Response Handling

### Expected Backend API Response

**Endpoint:** `GET /api/videos/{id}`

```json
{
  "id": "video_123",
  "title": "Morning Yoga Flow",
  "description": "Start your day with energizing yoga poses",
  "thumbnail_url": "https://cdn.example.com/thumbnails/yoga1.jpg",
  "video_url": "https://cdn.example.com/videos/yoga1.mp4",
  "hls_master_url": "https://cdn.example.com/hls/yoga1/master.m3u8",
  "duration_seconds": 420,
  "category": "Yoga",
  "instructor": "Sarah Johnson",
  "created_at": "2024-01-15T10:30:00Z"
}
```

### Current Parsing Behavior

**What happens NOW:**
```dart
// Pseudo-code of current implementation
VideoEntity.fromJson(json) {
  return VideoEntity(
    id: json['id'],
    title: json['title'],
    videoUrl: json['video_url'],        // ✅ READS THIS
    // hls_master_url is IGNORED         // ❌ SKIPS THIS
  );
}
```

**What SHOULD happen:**
```dart
// Recommended implementation
VideoEntity.fromJson(json) {
  return VideoEntity(
    id: json['id'],
    title: json['title'],
    videoUrl: json['video_url'],
    hlsMasterUrl: json['hls_master_url'],  // ← SHOULD READ THIS TOO
  );
}
```

### Video Player Selection Logic

**Recommended Priority:**
```dart
String getPlaybackUrl(VideoEntity video) {
  // Priority 1: Use HLS for adaptive streaming
  if (video.hlsMasterUrl != null && video.hlsMasterUrl!.isNotEmpty) {
    return video.hlsMasterUrl!;
  }

  // Priority 2: Fallback to direct MP4
  return video.videoUrl;
}

// Usage in VideoPlayerPage
_controller = VideoPlayerController.networkUrl(
  Uri.parse(getPlaybackUrl(_video!)),
);
```

---

## Summary of Data Reading Flow

### Complete Flow Diagram

```
┌──────────────────────────────────────────────────────────────┐
│ 1. User taps VideoCard                                       │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 2. GoRouter navigates to VideoPlayerPage(videoId: "123")    │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 3. VideoPlayerPage.initState() calls _loadVideo()           │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 4. VideosRepository.getVideoById("123")                     │
│    - Searches mock data array                               │
│    - Returns VideoEntity                                    │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 5. VideoEntity contains:                                     │
│    - id: "123"                                               │
│    - title: "Morning Yoga Flow"                              │
│    - videoUrl: "https://...BigBuckBunny.mp4"  ← KEY FIELD   │
│    - thumbnailUrl: "https://..."                             │
│    - durationInSeconds: 420                                  │
│    - category: "Yoga"                                        │
│    - instructor: "Sarah Johnson"                             │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 6. VideoPlayerController.networkUrl(                        │
│      Uri.parse(video.videoUrl)  ← READS videoUrl HERE      │
│    )                                                         │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 7. video_player package:                                     │
│    - Downloads video from URL                                │
│    - Buffers video data                                      │
│    - Decodes video stream                                    │
│    - Renders to screen                                       │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 8. UI displays:                                              │
│    - Video player (fullscreen)                               │
│    - Title overlay (from video.title)                        │
│    - Description (from video.description)                    │
│    - Instructor name (from video.instructor)                 │
│    - Category badge (from video.category)                    │
│    - Progress bar (from controller listener)                 │
└──────────────────────────────────────────────────────────────┘
```

---

## Key Findings

### ✅ What Works

1. **Clean Architecture** - Well-organized layer separation
2. **BLoC State Management** - Predictable state changes
3. **Video Playback** - Flutter video_player works correctly
4. **UI/UX** - Smooth navigation and user experience
5. **Mock Data** - Properly simulates API responses

### ❌ What's Missing

1. **HLS Support** - No `hlsMasterUrl` field in VideoEntity
2. **Adaptive Streaming** - Always uses single quality MP4
3. **API Integration** - Uses hardcoded mock data
4. **Fallback Logic** - No URL priority handling
5. **Network Optimization** - No bandwidth-aware streaming

---

## Recommendations

### Immediate Fixes

1. **Add HLS field to VideoEntity:**
   ```dart
   class VideoEntity {
     final String videoUrl;
     final String? hlsMasterUrl;  // ← ADD THIS
   }
   ```

2. **Implement URL priority logic:**
   ```dart
   String _getPlaybackUrl() {
     return _video!.hlsMasterUrl ?? _video!.videoUrl;
   }
   ```

3. **Update repository to parse both fields:**
   ```dart
   VideoEntity.fromJson(Map<String, dynamic> json) {
     return VideoEntity(
       videoUrl: json['video_url'],
       hlsMasterUrl: json['hls_master_url'],
     );
   }
   ```

### Long-term Improvements

1. Replace mock repository with real HTTP API client
2. Add video quality selector UI
3. Implement offline video downloads
4. Add video analytics tracking
5. Support for subtitle/caption tracks

---

## File Reference Index

| File | Purpose | Line References |
|------|---------|----------------|
| `video_entity.dart` | Video data model | Line 8: `videoUrl` field |
| `video_player_page.dart` | Video playback UI | Line 88: URL parsing |
| `videos_repository.dart` | Data fetching | Lines 14-84: Mock data |
| `video_card.dart` | Video preview widget | Displays metadata |
| `videos_bloc.dart` | State management | Handles video loading |
| `app_router.dart` | Navigation | Routes to player page |

---

**Document Version:** 1.0
**Last Updated:** 2026-01-03
**Author:** Claude Code Assistant
**Status:** Current Implementation Analysis
