import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
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

  // Initialize app configuration (environment-aware)
  // Build with: flutter run --dart-define=ENVIRONMENT=production
  AppConfig.initialize();

  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Register adapters - note: run 'flutter packages pub run build_runner build' to generate
  // Hive.registerAdapter(GoalModelAdapter());

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
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
          debugShowCheckedModeBanner: config.isDebugMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}

