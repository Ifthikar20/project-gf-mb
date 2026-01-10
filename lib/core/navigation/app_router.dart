import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/pages/home_page.dart';
import '../auth/landing_page.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';
import '../../features/wellness_goals/presentation/pages/goal_detail_page.dart';
import '../../features/videos/presentation/pages/video_player_page.dart';
import '../../features/meditation/presentation/pages/meditation_category_page.dart';
import '../../features/meditation/presentation/pages/audio_player_page.dart';
import '../../features/library/presentation/pages/library_page.dart';
import '../../features/speakers/presentation/pages/speaker_page.dart';
import '../../features/search/presentation/pages/search_page.dart';

class AppRouter {
  static const String home = '/';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String register = '/register';
  static const String wellnessGoals = '/wellness-goals';
  static const String goalDetail = '/goal-detail';
  static const String videos = '/videos';
  static const String videoPlayer = '/video-player';
  static const String meditation = '/meditation';
  static const String meditationCategory = '/meditation-category';
  static const String audioPlayer = '/audio-player';
  static const String library = '/library';
  static const String speakerProfile = '/speaker';
  static const String search = '/search';

  static final GoRouter router = GoRouter(
    initialLocation: landing,
    routes: [
      GoRoute(
        path: home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: landing,
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterPage(),
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
        pageBuilder: (context, state) {
          final videoId = state.uri.queryParameters['id'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: VideoPlayerPage(videoId: videoId),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            opaque: true,
            barrierColor: Colors.black,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // No animation - just show/hide instantly
              return animation.isCompleted ? child : Container(color: Colors.black);
            },
          );
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
      GoRoute(
        path: speakerProfile,
        builder: (context, state) {
          final speakerId = state.uri.queryParameters['id'] ?? '';
          final speakerName = state.uri.queryParameters['name'] ?? 'Speaker';
          final speakerImageUrl = state.uri.queryParameters['imageUrl'] ?? '';
          return SpeakerPage(
            speakerId: speakerId,
            speakerName: Uri.decodeComponent(speakerName),
            speakerImageUrl: Uri.decodeComponent(speakerImageUrl),
          );
        },
      ),
      GoRoute(
        path: search,
        builder: (context, state) => const SearchPage(),
      ),
    ],
  );
}

