import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/config/app_config.dart';
import 'core/config/environment_config.dart';
import 'core/services/analytics_service.dart';
import 'core/services/oauth_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_bloc.dart';
import 'core/navigation/app_router.dart';
import 'core/auth/auth_bloc.dart';
import 'core/services/recently_viewed_service.dart';
import 'features/wellness_goals/data/datasources/goals_local_datasource.dart';
import 'features/wellness_goals/data/repositories/goals_repository_impl.dart';
import 'features/wellness_goals/presentation/bloc/goals_bloc.dart';
import 'features/wellness_goals/presentation/bloc/goals_event.dart';
import 'features/videos/data/repositories/videos_repository.dart';
import 'features/videos/presentation/bloc/videos_bloc.dart';

import 'features/meditation/data/repositories/meditation_repository.dart';
import 'features/meditation/presentation/bloc/meditation_bloc.dart';

import 'features/wellness_goals/data/models/wellness_checkin_model.dart';
import 'features/wellness_goals/data/models/fitness_profile_model.dart';
import 'features/library/presentation/bloc/library_bloc.dart';
import 'core/services/goal_tracking_service.dart';
import 'core/services/healthkit_service.dart';
import 'features/subscription/data/services/apple_iap_service.dart';
import 'features/workouts/presentation/bloc/workout_bloc.dart';
import 'features/diet/presentation/bloc/diet_bloc.dart';
import 'features/diet/data/models/diet_models.dart';
import 'features/knowledge/presentation/bloc/knowledge_bloc.dart';
import 'features/meditation/data/models/journal_models.dart';
import 'features/advisor/presentation/bloc/advisor_bloc.dart';
import 'features/advisor/presentation/bloc/advisor_event.dart';
import 'features/explore/presentation/bloc/class_schedule_bloc.dart';
import 'features/subscription/presentation/bloc/subscription_bloc.dart';
import 'features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'features/coaching/presentation/bloc/coaching_bloc.dart';
import 'features/journal/presentation/bloc/journal_bloc.dart';
import 'features/wellness_score/presentation/bloc/wellness_score_bloc.dart';
import 'features/sleep/presentation/bloc/sleep_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cap the in-memory image cache to prevent OOM on image-heavy pages.
  // Default is unlimited — this limits to 30 images / 50 MB.
  PaintingBinding.instance.imageCache.maximumSize = 30;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;

  // Load environment variables from .env file
  await EnvironmentConfig.load();

  // Initialize app configuration (environment-aware)
  AppConfig.initialize();

  // Initialize GA4 Analytics (Measurement Protocol - no Firebase SDK needed)
  try {
    await AnalyticsService.instance.initialize();
    debugPrint(' GA4 Analytics initialized');
  } catch (e) {
    debugPrint(' GA4 init failed (analytics disabled): $e');
  }

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Register Hive adapters for wellness system
  if (!Hive.isAdapterRegistered(20)) {
    Hive.registerAdapter(WellnessCheckInModelAdapter());
  }
  if (!Hive.isAdapterRegistered(21)) {
    Hive.registerAdapter(FitnessProfileModelAdapter());
  }
  if (!Hive.isAdapterRegistered(22)) {
    Hive.registerAdapter(BodyTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(23)) {
    Hive.registerAdapter(FitnessGoalAdapter());
  }
  if (!Hive.isAdapterRegistered(24)) {
    Hive.registerAdapter(WorkoutIntensityAdapter());
  }
  // Diet models
  if (!Hive.isAdapterRegistered(30)) {
    Hive.registerAdapter(MealTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(31)) {
    Hive.registerAdapter(MealLogAdapter());
  }
  // Meditation journal
  if (!Hive.isAdapterRegistered(32)) {
    Hive.registerAdapter(MeditationJournalEntryAdapter());
  }

  // Initialize recently viewed service
  await RecentlyViewedService.instance.init();

  // Initialize OAuth deep link handling
  await OAuthService.instance.initialize();
  debugPrint(' OAuth service initialized');

  // Initialize goal tracking service with the local data source
  final goalsDataSource = GoalsLocalDataSource();
  GoalTrackingService.instance.initialize(goalsDataSource);
  
  // Track daily app usage for streak goals
  GoalTrackingService.instance.trackDailyUsage();
  debugPrint(' Goal tracking service initialized');

  // Initialize HealthKit service (loads saved preferences)
  await HealthKitService.instance.init();

  // Initialize Apple In-App Purchases
  await AppleIAPService.instance.init();
  if (HealthKitService.instance.isEnabled) {
    // Refresh cached health data on app startup
    HealthKitService.instance.refreshAndCache();
  }

  // Set system UI overlay style — force dark native chrome so the iOS
  // window is never white before Flutter's first frame renders.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Suppress noisy image HTTP exceptions (403 from CloudFront thumbnails).
  // CachedNetworkImage's errorWidget handles the fallback UI already —
  // this just prevents Flutter from logging scary red exception traces.
  final defaultOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final isImageError =
        details.library == 'image resource service';
    if (isImageError) {
      // Silently ignore — errorWidget in the UI handles this
      debugPrint(' Image load failed (suppressed): ${details.exceptionAsString().split('\n').first}');
      return;
    }
    // All other errors pass through normally
    defaultOnError?.call(details);
  };

  runApp(const WellnessApp());
}

class WellnessApp extends StatelessWidget {
  const WellnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.instance;
    
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => GoalsRepositoryImpl(
            localDataSource: GoalsLocalDataSource(),
          ),
        ),
        RepositoryProvider(
          create: (context) => VideosRepository(),
        ),
        RepositoryProvider(
          create: (context) => MeditationRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          // Theme BLoC (handles vintage/classic dark mode switching)
          BlocProvider(
            create: (context) => ThemeBloc()..add(LoadTheme()),
          ),
          // Auth BLoC (check if user is logged in)
          BlocProvider(
            create: (context) => AuthBloc()..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (context) => GoalsBloc(
              repository: context.read<GoalsRepositoryImpl>(),
            )..add(LoadGoals()),
          ),
          BlocProvider(
            create: (context) => VideosBloc(
              repository: context.read<VideosRepository>(),
            ), // Data loaded on-demand in VideosPage/ExplorePage
          ),
          BlocProvider(
            create: (context) => MeditationBloc(
              repository: context.read<MeditationRepository>(),
            ), // Data loaded on-demand in MeditationPage/ExplorePage
          ),
          BlocProvider(
            create: (context) => LibraryBloc(),
          ),
          BlocProvider(
            create: (context) => WorkoutBloc(),
          ),
          BlocProvider(
            create: (context) => DietBloc(),
          ),
          BlocProvider(
            create: (context) => KnowledgeBloc(),
          ),
          BlocProvider(
            create: (context) => AdvisorBloc()..add(LoadSuggestions()),
          ),
          BlocProvider(
            create: (context) => ClassScheduleBloc(
              videosBloc: context.read<VideosBloc>(),
            ),
          ),
          BlocProvider(
            create: (context) => SubscriptionBloc()..add(LoadSubscriptionStatus()),
          ),
          BlocProvider(
            create: (context) => MarketplaceBloc(),
          ),
          BlocProvider(
            create: (context) => CoachingBloc(),
          ),
          BlocProvider(
            create: (context) => JournalBloc(),
          ),
          BlocProvider(
            create: (context) => WellnessScoreBloc(),
          ),
          BlocProvider(
            create: (context) => SleepBloc(),
          ),
        ],
        // Use Builder to access AuthBloc and create auth-aware router.
        // IMPORTANT: Router must be created ONCE outside BlocBuilder to avoid
        // recreating it on every theme change (which resets all navigation state).
        child: Builder(
          builder: (context) {
            final authBloc = context.read<AuthBloc>();
            final router = AppRouter.createRouter(authBloc);
            
            return BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, themeState) {
                return MaterialApp.router(
                  title: config.appName,
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeState.isLight ? ThemeMode.light : ThemeMode.dark,
                  routerConfig: router,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
