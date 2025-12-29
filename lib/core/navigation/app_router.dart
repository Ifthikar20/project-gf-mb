import 'package:go_router/go_router.dart';
import '../presentation/pages/home_page.dart';
import '../../features/wellness_goals/presentation/pages/goal_detail_page.dart';
import '../../features/videos/presentation/pages/video_player_page.dart';
import '../../features/meditation/presentation/pages/meditation_category_page.dart';
import '../../features/meditation/presentation/pages/audio_player_page.dart';
import '../../features/library/presentation/pages/library_page.dart';

class AppRouter {
  static const String home = '/';
  static const String wellnessGoals = '/wellness-goals';
  static const String goalDetail = '/goal-detail';
  static const String videos = '/videos';
  static const String videoPlayer = '/video-player';
  static const String meditation = '/meditation';
  static const String meditationCategory = '/meditation-category';
  static const String audioPlayer = '/audio-player';
  static const String library = '/library';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    routes: [
      GoRoute(
        path: home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: goalDetail,
        builder: (context, state) {
          final goalId = state.uri.queryParameters['id'];
          return GoalDetailPage(goalId: goalId);
        },
      ),
      GoRoute(
        path: videoPlayer,
        builder: (context, state) {
          final videoId = state.uri.queryParameters['id'] ?? '';
          return VideoPlayerPage(videoId: videoId);
        },
      ),
      GoRoute(
        path: meditationCategory,
        builder: (context, state) {
          final categoryId = state.uri.queryParameters['id'] ?? '';
          final categoryName = state.uri.queryParameters['name'] ?? 'Meditation';
          return MeditationCategoryPage(
            categoryId: categoryId,
            categoryName: Uri.decodeComponent(categoryName),
          );
        },
      ),
      GoRoute(
        path: audioPlayer,
        builder: (context, state) {
          final audioId = state.uri.queryParameters['id'] ?? '';
          return AudioPlayerPage(audioId: audioId);
        },
      ),
      GoRoute(
        path: library,
        builder: (context, state) => const LibraryPage(),
      ),
    ],
  );
}
