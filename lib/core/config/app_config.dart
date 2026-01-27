/// Environment configuration for the app
enum Environment {
  development,
  staging,
  production,
}

/// App configuration that is loaded at startup
/// Access via AppConfig.instance after calling AppConfig.initialize()
class AppConfig {
  static AppConfig? _instance;
  
  /// Get the singleton instance
  static AppConfig get instance {
    if (_instance == null) {
      throw StateError(
        'AppConfig not initialized. Call AppConfig.initialize() in main.dart'
      );
    }
    return _instance!;
  }
  
  /// Check if initialized
  static bool get isInitialized => _instance != null;
  
  // Environment
  final Environment environment;
  
  // API Configuration
  final String apiBaseUrl;
  final String cdnBaseUrl;
  final String r2BaseUrl; // Cloudflare R2 for video assets
  final Duration apiTimeout;
  final int maxRetries;
  
  // Feature Flags
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final bool enableOfflineMode;
  final bool enablePushNotifications;
  
  // App Settings
  final String appName;
  final String appVersion;
  final int buildNumber;
  
  // Cache Settings
  final Duration imageCacheDuration;
  final int maxCachedImages;
  final Duration contentCacheDuration;
  
  // Media Settings
  final int videoQualityDefault; // 720, 1080, etc.
  final bool autoPlayVideos;
  final bool streamOverCellular;
  
  // Pagination
  final int defaultPageSize;
  final int maxPageSize;
  
  // Private constructor
  AppConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.cdnBaseUrl,
    required this.r2BaseUrl,
    required this.apiTimeout,
    required this.maxRetries,
    required this.enableAnalytics,
    required this.enableCrashReporting,
    required this.enableOfflineMode,
    required this.enablePushNotifications,
    required this.appName,
    required this.appVersion,
    required this.buildNumber,
    required this.imageCacheDuration,
    required this.maxCachedImages,
    required this.contentCacheDuration,
    required this.videoQualityDefault,
    required this.autoPlayVideos,
    required this.streamOverCellular,
    required this.defaultPageSize,
    required this.maxPageSize,
  });
  
  /// Initialize app configuration
  /// Call this in main.dart before runApp()
  static void initialize({Environment? environment}) {
    // Determine environment from build config or parameter
    final env = environment ?? _getEnvironmentFromBuild();
    
    _instance = switch (env) {
      Environment.development => AppConfig._development(),
      Environment.staging => AppConfig._staging(),
      Environment.production => AppConfig._production(),
    };
  }
  
  /// Get environment from Dart defines (set during build)
  static Environment _getEnvironmentFromBuild() {
    const envString = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    return switch (envString) {
      'production' => Environment.production,
      'staging' => Environment.staging,
      _ => Environment.development,
    };
  }
  
  // Development configuration
  factory AppConfig._development() {
    return AppConfig._(
      environment: Environment.development,
      apiBaseUrl: 'https://api-dev.betterandbliss.app',
      cdnBaseUrl: 'https://cdn-dev.betterandbliss.app',
      r2BaseUrl: 'https://pub-aab30380758e431a9c177896a92abeca.r2.dev',
      apiTimeout: const Duration(seconds: 30),
      maxRetries: 3,
      enableAnalytics: false,
      enableCrashReporting: false,
      enableOfflineMode: true,
      enablePushNotifications: false,
      appName: 'Better & Bliss (Dev)',
      appVersion: '1.0.0',
      buildNumber: 1,
      imageCacheDuration: const Duration(hours: 1),
      maxCachedImages: 50,
      contentCacheDuration: const Duration(minutes: 5),
      videoQualityDefault: 480,
      autoPlayVideos: true,
      streamOverCellular: true,
      defaultPageSize: 10,
      maxPageSize: 50,
    );
  }
  
  // Staging configuration
  factory AppConfig._staging() {
    return AppConfig._(
      environment: Environment.staging,
      apiBaseUrl: 'https://api-staging.betterandbliss.app',
      cdnBaseUrl: 'https://cdn-staging.betterandbliss.app',
      r2BaseUrl: 'https://pub-aab30380758e431a9c177896a92abeca.r2.dev',
      apiTimeout: const Duration(seconds: 20),
      maxRetries: 2,
      enableAnalytics: true,
      enableCrashReporting: true,
      enableOfflineMode: true,
      enablePushNotifications: true,
      appName: 'Better & Bliss (Staging)',
      appVersion: '1.0.0',
      buildNumber: 1,
      imageCacheDuration: const Duration(hours: 6),
      maxCachedImages: 100,
      contentCacheDuration: const Duration(minutes: 15),
      videoQualityDefault: 720,
      autoPlayVideos: true,
      streamOverCellular: false,
      defaultPageSize: 20,
      maxPageSize: 50,
    );
  }
  
  // Production configuration
  factory AppConfig._production() {
    return AppConfig._(
      environment: Environment.production,
      apiBaseUrl: 'https://api.betterandbliss.app',
      cdnBaseUrl: 'https://cdn.betterandbliss.app',
      r2BaseUrl: 'https://pub-aab30380758e431a9c177896a92abeca.r2.dev',
      apiTimeout: const Duration(seconds: 15),
      maxRetries: 2,
      enableAnalytics: true,
      enableCrashReporting: true,
      enableOfflineMode: true,
      enablePushNotifications: true,
      appName: 'Better & Bliss',
      appVersion: '1.0.0',
      buildNumber: 1,
      imageCacheDuration: const Duration(days: 7),
      maxCachedImages: 200,
      contentCacheDuration: const Duration(hours: 1),
      videoQualityDefault: 1080,
      autoPlayVideos: true,
      streamOverCellular: false,
      defaultPageSize: 20,
      maxPageSize: 100,
    );
  }
  
  // Convenience getters
  bool get isDevelopment => environment == Environment.development;
  bool get isStaging => environment == Environment.staging;
  bool get isProduction => environment == Environment.production;
  bool get isDebugMode => isDevelopment || isStaging;
}
