import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/config/app_config.dart';
import 'core/config/environment_config.dart';
import 'core/services/analytics_service.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'core/auth/auth_bloc.dart';
import 'core/services/recently_viewed_service.dart';
import 'features/wellness_goals/data/datasources/goals_local_datasource.dart';
import 'features/wellness_goals/data/repositories/goals_repository_impl.dart';
import 'features/wellness_goals/presentation/bloc/goals_bloc.dart';
import 'features/wellness_goals/presentation/bloc/goals_event.dart';
import 'features/videos/data/repositories/videos_repository.dart';
import 'features/videos/presentation/bloc/videos_bloc.dart';
import 'features/videos/presentation/bloc/videos_event.dart';
import 'features/meditation/data/repositories/meditation_repository.dart';
import 'features/meditation/presentation/bloc/meditation_bloc.dart';
import 'features/meditation/presentation/bloc/meditation_event.dart';
import 'features/library/presentation/bloc/library_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await EnvironmentConfig.load();

  // Initialize app configuration (environment-aware)
  AppConfig.initialize();

  // Initialize GA4 Analytics (Measurement Protocol - no Firebase SDK needed)
  try {
    await AnalyticsService.instance.initialize();
    debugPrint('✅ GA4 Analytics initialized');
  } catch (e) {
    debugPrint('⚠️ GA4 init failed (analytics disabled): $e');
  }

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize recently viewed service
  await RecentlyViewedService.instance.init();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

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
            )..add(const LoadVideos()),
          ),
          BlocProvider(
            create: (context) => MeditationBloc(
              repository: context.read<MeditationRepository>(),
            )..add(LoadMeditationAudios()),
          ),
          BlocProvider(
            create: (context) => LibraryBloc(),
          ),
        ],
        child: MaterialApp.router(
          title: config.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
