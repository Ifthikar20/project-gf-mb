import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../presentation/pages/home_page.dart';
import '../auth/landing_page.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';
import '../auth/forgot_password_page.dart';
import '../auth/reset_password_page.dart';
import '../auth/onboarding_page.dart';
import '../auth/change_password_page.dart';
import '../auth/account_settings_page.dart';
import '../auth/auth_bloc.dart';

import '../../features/videos/presentation/pages/video_player_page.dart';

import '../../features/workouts/presentation/pages/body_profile_page.dart';
import '../../features/workouts/presentation/pages/workout_hub_page.dart';
import '../../features/profile/presentation/pages/help_center_page.dart';
import '../../features/profile/presentation/pages/notifications_page.dart';
import '../../features/workouts/presentation/pages/goals_setup_page.dart';
import '../../features/workouts/presentation/bloc/workout_bloc.dart';
import '../../features/meditation/presentation/pages/meditation_category_page.dart';
import '../../features/meditation/presentation/pages/audio_player_page.dart';
import '../../features/library/presentation/pages/library_page.dart';
import '../../features/library/presentation/pages/watch_history_page.dart';
import '../../features/speakers/presentation/pages/speaker_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/meditation/presentation/pages/breathing_exercise_page.dart';

import '../../features/workouts/presentation/pages/workout_check_page.dart';
import '../../features/explore/presentation/pages/program_enroll_page.dart';

import '../../features/subscription/presentation/pages/subscription_plans_page.dart';
import '../../features/marketplace/presentation/pages/marketplace_page.dart';
import '../../features/marketplace/presentation/pages/program_detail_page.dart';
import '../../features/marketplace/presentation/pages/my_purchases_page.dart';
import '../../features/coaching/presentation/pages/coaches_page.dart';
import '../../features/coaching/presentation/pages/coach_detail_page.dart';
import '../../features/coaching/presentation/pages/coaching_sessions_page.dart';
import '../../features/coaching/presentation/pages/my_workout_plan_page.dart';
import '../../features/coaching/presentation/pages/free_consultation_page.dart';
import '../../features/journal/presentation/pages/journal_page.dart';
import '../../features/antigravity_chat/presentation/pages/antigravity_chat_page.dart';

class AppRouter {
  static const String home = '/';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String wellnessGoals = '/wellness-goals';
  static const String onboarding = '/onboarding';
  static const String changePassword = '/change-password';
  static const String accountSettings = '/account-settings';
  static const String workouts = '/workouts';
  static const String workoutSummary = '/workout-summary';
  static const String bodyProfile = '/body-profile';
  static const String goalsSetup = '/goals-setup';
  static const String workoutCheck = '/workout-check';

  static const String videos = '/videos';
  static const String videoPlayer = '/video-player';
  static const String meditation = '/meditation';
  static const String meditationCategory = '/meditation-category';
  static const String audioPlayer = '/audio-player';
  static const String library = '/library';
  static const String watchHistory = '/watch-history';
  static const String speakerProfile = '/speaker';
  static const String search = '/search';
  static const String breathingExercise = '/breathing-exercise';
  static const String articleDetail = '/article-detail';
  static const String programEnroll = '/program-enroll';

  // Monetization routes
  static const String subscriptionPlans = '/subscription-plans';
  static const String marketplace = '/marketplace';
  static const String marketplaceDetail = '/marketplace-detail';
  static const String myPurchases = '/my-purchases';
  static const String coaches = '/coaches';
  static const String coachDetail = '/coach-detail';
  static const String coachingSessions = '/coaching-sessions';
  static const String myWorkoutPlan = '/my-workout-plan';
  static const String freeConsultation = '/free-consultation';
  static const String antigravityChat = '/antigravity-chat';
  static const String helpCenter = '/help-center';
  static const String notifications = '/notifications';
  static const String journal = '/journal';

  // Public routes that don't require authentication
  static const List<String> _publicRoutes = [
    landing,
    login,
    register,
    forgotPassword,
    resetPassword,
    onboarding,
  ];

  // Routes that should NOT redirect on transient auth changes (e.g. 401 during playback)
  // These pages handle auth errors locally with error UI instead of redirecting.
  static const List<String> _mediaRoutes = [
    videoPlayer,
    audioPlayer,
  ];

  /// Creates a GoRouter with auth-aware redirect
  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: landing,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final isAuthenticated = authState is AuthAuthenticated;
        final needsOnboarding = authState is AuthNeedsOnboarding;
        final currentPath = state.uri.path;
        final isPublicRoute = _publicRoutes.contains(currentPath);
        
        // User needs onboarding — redirect to onboarding
        if (needsOnboarding && currentPath != onboarding) {
          return onboarding;
        }
        
        // If not authenticated and not needs-onboarding, and trying a protected route
        if (!isAuthenticated && !needsOnboarding && !isPublicRoute) {
          // Allow OAuth callbacks to pass through
          if (currentPath.contains('/auth/callback')) {
            return null;
          }
          // Don't redirect away from media player pages — they handle auth errors locally
          if (_mediaRoutes.contains(currentPath)) {
            return null;
          }
          // Redirect to landing page
          return landing;
        }
        
        // If fully authenticated, don't allow access to landing/login/register/onboarding
        if (isAuthenticated && (currentPath == landing || currentPath == login || currentPath == register || currentPath == onboarding)) {
          return home;
        }
        
        return null; // No redirect needed
      },
      // Handle OAuth callback and unknown routes gracefully
      errorBuilder: (context, state) {
        // Check if this is an OAuth callback - don't show error page
        if (state.uri.path.contains('/auth/callback') || 
            state.uri.toString().contains('betterbliss://auth')) {
          // OAuth callbacks are handled by OAuthService via app_links
          // Return to landing page silently
          return const LandingPage();
        }
        // For other unknown routes, go to landing
        return const LandingPage();
      },
      routes: [
        GoRoute(
          path: home,
          builder: (context, state) => const MainShell(),
        ),
        GoRoute(
          path: landing,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const LandingPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 120),
          ),
        ),
        GoRoute(
          path: login,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const LoginPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 120),
          ),
        ),
        GoRoute(
          path: register,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const RegisterPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 120),
          ),
        ),
        GoRoute(
          path: forgotPassword,
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: resetPassword,
          builder: (context, state) {
            final email = Uri.decodeComponent(state.uri.queryParameters['email'] ?? '');
            final emailRegex = RegExp(r'^[\w\-\.]+@[\w\-]+\.[a-z]{2,}$');
            if (!emailRegex.hasMatch(email)) {
              return const LandingPage();
            }
            return ResetPasswordPage(email: email);
          },
        ),

        GoRoute(
          path: onboarding,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const OnboardingPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 120),
          ),
        ),
        GoRoute(
          path: changePassword,
          builder: (context, state) => const ChangePasswordPage(),
        ),
        GoRoute(
          path: accountSettings,
          builder: (context, state) => const AccountSettingsPage(),
        ),
        GoRoute(
          path: bodyProfile,
          builder: (context, state) => BlocProvider.value(
            value: context.read<WorkoutBloc>(),
            child: const BodyProfilePage(),
          ),
        ),
        GoRoute(
          path: goalsSetup,
          builder: (context, state) => BlocProvider.value(
            value: context.read<WorkoutBloc>(),
            child: const GoalsSetupPage(),
          ),
        ),
        GoRoute(
          path: workoutCheck,
          builder: (context, state) => const WorkoutCheckPage(),
        ),
        GoRoute(
          path: workouts,
          builder: (context, state) => BlocProvider.value(
            value: context.read<WorkoutBloc>(),
            child: const WorkoutHubPage(),
          ),
        ),
        GoRoute(
          path: videoPlayer,
          pageBuilder: (context, state) {
            final videoId = state.uri.queryParameters['id'] ?? '';
            if (videoId.isEmpty) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const LandingPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 120),
              );
            }
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
            if (categoryId.isEmpty) {
              return const LandingPage();
            }
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
            if (audioId.isEmpty) {
              return const LandingPage();
            }
            return AudioPlayerPage(audioId: audioId);
          },
        ),
        GoRoute(
          path: library,
          builder: (context, state) => const LibraryPage(),
        ),
        GoRoute(
          path: watchHistory,
          builder: (context, state) => const WatchHistoryPage(),
        ),
        GoRoute(
          path: speakerProfile,
          builder: (context, state) {
            final speakerId = state.uri.queryParameters['id'] ?? '';
            if (speakerId.isEmpty) {
              return const LandingPage();
            }
            final speakerName = state.uri.queryParameters['name'] ?? 'Speaker';
            final rawImageUrl = Uri.decodeComponent(state.uri.queryParameters['imageUrl'] ?? '');
            final speakerImageUrl = rawImageUrl.isNotEmpty && !rawImageUrl.startsWith('https://')
                ? ''
                : rawImageUrl;
            return SpeakerPage(
              speakerId: speakerId,
              speakerName: Uri.decodeComponent(speakerName),
              speakerImageUrl: speakerImageUrl,
            );
          },
        ),
        GoRoute(
          path: search,
          builder: (context, state) => const SearchPage(),
        ),
        GoRoute(
          path: breathingExercise,
          builder: (context, state) => const BreathingExercisePage(),
        ),
        GoRoute(
          path: programEnroll,
          builder: (context, state) {
            final seriesId = state.uri.queryParameters['seriesId'] ?? '';
            if (seriesId.isEmpty) {
              return const LandingPage();
            }
            return ProgramEnrollPage(seriesId: seriesId);
          },
        ),

        // ============================================
        // Monetization Routes
        // ============================================
        GoRoute(
          path: subscriptionPlans,
          builder: (context, state) => const SubscriptionPlansPage(),
        ),
        GoRoute(
          path: marketplace,
          builder: (context, state) => const MarketplacePage(),
        ),
        GoRoute(
          path: marketplaceDetail,
          builder: (context, state) {
            final id = state.uri.queryParameters['id'] ?? '';
            if (id.isEmpty) return const LandingPage();
            return ProgramDetailPage(programId: id);
          },
        ),
        GoRoute(
          path: myPurchases,
          builder: (context, state) => const MyPurchasesPage(),
        ),
        GoRoute(
          path: coaches,
          builder: (context, state) => const CoachesPage(),
        ),
        GoRoute(
          path: coachDetail,
          builder: (context, state) {
            final id = state.uri.queryParameters['id'] ?? '';
            if (id.isEmpty) return const LandingPage();
            return CoachDetailPage(coachId: id);
          },
        ),
        GoRoute(
          path: coachingSessions,
          builder: (context, state) => const CoachingSessionsPage(),
        ),
        GoRoute(
          path: myWorkoutPlan,
          builder: (context, state) => const MyWorkoutPlanPage(),
        ),
        GoRoute(
          path: freeConsultation,
          builder: (context, state) => const FreeConsultationPage(),
        ),
        GoRoute(
          path: antigravityChat,
          builder: (context, state) => const AntiGravityChatPage(),
        ),
        GoRoute(
          path: helpCenter,
          builder: (context, state) => const HelpCenterPage(),
        ),
        GoRoute(
          path: notifications,
          builder: (context, state) => const NotificationsPage(),
        ),
        GoRoute(
          path: journal,
          builder: (context, state) => const JournalPage(),
        ),
      ],
    );
  }

}

/// Converts a Stream to a Listenable for GoRouter refreshListenable
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
