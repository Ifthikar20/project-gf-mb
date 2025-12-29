import '../../domain/entities/video_entity.dart';

class VideosRepository {
  // Mock data - in a real app, this would fetch from an API
  Future<List<VideoEntity>> getVideos({String? category}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final allVideos = [
      const VideoEntity(
        id: '1',
        title: 'Morning Yoga Flow',
        description: 'Start your day with this energizing 15-minute yoga flow',
        thumbnailUrl: 'https://source.unsplash.com/600x400/?yoga',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        durationInSeconds: 900,
        category: 'Yoga',
        instructor: 'Sarah Johnson',
      ),
      const VideoEntity(
        id: '2',
        title: '5-Minute Breathing Exercise',
        description: 'Calm your mind with guided breathwork',
        thumbnailUrl: 'https://source.unsplash.com/600x400/?meditation',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        durationInSeconds: 300,
        category: 'Breathing',
        instructor: 'Dr. Michael Chen',
      ),
      const VideoEntity(
        id: '3',
        title: 'Full Body Workout',
        description: '20-minute home workout for all fitness levels',
        thumbnailUrl: 'https://source.unsplash.com/600x400/?fitness',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
        durationInSeconds: 1200,
        category: 'Exercises',
        instructor: 'Alex Martinez',
      ),
      const VideoEntity(
        id: '4',
        title: 'Mindfulness Meditation',
        description: 'Guided meditation for stress relief and clarity',
        thumbnailUrl: 'https://source.unsplash.com/600x400/?mindfulness',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
        durationInSeconds: 600,
        category: 'Mindfulness',
        instructor: 'Emma Wilson',
      ),
      const VideoEntity(
        id: '5',
        title: 'Evening Stretch Routine',
        description: 'Gentle stretches to wind down your day',
        thumbnailUrl: 'https://source.unsplash.com/600x400/?stretching',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
        durationInSeconds: 720,
        category: 'Yoga',
        instructor: 'Sarah Johnson',
      ),
      const VideoEntity(
        id: '6',
        title: 'Sleep Preparation Routine',
        description: 'Relax and prepare for a restful night',
        thumbnailUrl: 'https://source.unsplash.com/600x400/?sleep',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
        durationInSeconds: 900,
        category: 'Sleep',
        instructor: 'Dr. Lisa Park',
      ),
      const VideoEntity(
        id: '7',
        title: 'Advanced Breathing Techniques',
        description: 'Learn Wim Hof and Box Breathing methods',
        thumbnailUrl: 'https://source.unsplash.com/600x400/?breathing',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
        durationInSeconds: 840,
        category: 'Breathing',
        instructor: 'Dr. Michael Chen',
      ),
      const VideoEntity(
        id: '8',
        title: 'Core Strength Builder',
        description: 'Target your core with these effective exercises',
        thumbnailUrl: 'https://source.unsplash.com/600x400/?core,workout',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
        durationInSeconds: 900,
        category: 'Exercises',
        instructor: 'Alex Martinez',
      ),
    ];

    if (category == null || category == 'All') {
      return allVideos;
    }

    return allVideos.where((video) => video.category == category).toList();
  }

  Future<VideoEntity?> getVideoById(String id) async {
    final videos = await getVideos();
    try {
      return videos.firstWhere((video) => video.id == id);
    } catch (e) {
      return null;
    }
  }
}
