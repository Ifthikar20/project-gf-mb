import 'app_config.dart';

/// Centralized API endpoints configuration
/// All API paths are defined here for easy maintenance and consistency
class ApiEndpoints {
  static final AppConfig _config = AppConfig.instance;
  
  // Base URLs
  static String get baseUrl => _config.apiBaseUrl;
  static String get cdnUrl => _config.cdnBaseUrl;
  static String get r2Url => _config.r2BaseUrl;
  
  // ============================================
  // R2 Video Assets (Background Videos)
  // ============================================
  static String get landingVideo => '$r2Url/main-video.mp4';
  static String get sunsetWavesVideo => '$r2Url/sunset-waves.mp4';
  static String get bannerVideo => '$r2Url/banner-video-1.mp4';
  
  // ============================================
  // Authentication Endpoints
  // ============================================
  static String get authBase => '$baseUrl/auth';
  static String get login => '$authBase/login';
  static String get register => '$authBase/register';
  static String get logout => '$authBase/logout';
  static String get refreshToken => '$authBase/refresh';
  static String get forgotPassword => '$authBase/forgot-password';
  static String get resetPassword => '$authBase/reset-password';
  static String get verifyEmail => '$authBase/verify-email';
  
  // ============================================
  // User Endpoints
  // ============================================
  static String get usersBase => '$baseUrl/users';
  static String get profile => '$usersBase/me';
  static String get updateProfile => '$usersBase/me';
  static String get deleteAccount => '$usersBase/me';
  static String userById(String id) => '$usersBase/$id';
  
  // ============================================
  // Content Endpoints
  // ============================================
  static String get contentBase => '$baseUrl/content';
  
  // Videos
  static String get videos => '$contentBase/videos';
  static String videoById(String id) => '$videos/$id';
  static String videoStream(String id) => '$cdnUrl/videos/$id/stream.m3u8';
  static String videoThumbnail(String id) => '$cdnUrl/videos/$id/thumbnail.jpg';
  
  // Meditations / Audio
  static String get meditations => '$contentBase/meditations';
  static String meditationById(String id) => '$meditations/$id';
  static String audioById(String id) => '$contentBase/audio/$id';
  
  // Audio Content Browse
  static String get audioBrowse => '$baseUrl/content/browse?content_type=audio';
  
  // Streaming Endpoints (secure URLs from backend)
  static String get streamingBase => '$baseUrl/api/streaming';
  static String contentStream(String id) => '$streamingBase/content/$id/stream';
  
  // Categories
  static String get categories => '$baseUrl/categories';
  static String categoryById(String id) => '$categories/$id';
  
  // ============================================
  // Library / Saved Items
  // ============================================
  static String get libraryBase => '$baseUrl/library';
  static String get savedItems => '$libraryBase/items';
  static String savedItem(String id) => '$savedItems/$id';
  static String get favorites => '$libraryBase/favorites';
  static String get history => '$libraryBase/history';
  static String get downloads => '$libraryBase/downloads';
  
  // ============================================
  // Series (CMS API)
  // ============================================
  static String get cmsBase => '$baseUrl/v1/cms';
  static String get seriesBase => '$cmsBase/series';
  static String seriesById(String id) => '$seriesBase/$id';
  
  /// Get published series for browse pages
  /// Supports: show_on_explore=true, show_on_meditate=true
  static String get publishedSeries => '$seriesBase?status=published';
  static String seriesForExplore() => '$seriesBase?status=published&show_on_explore=true';
  static String seriesForMeditate() => '$seriesBase?status=published&show_on_meditate=true';
  
  // ============================================
  // Wellness Goals
  // ============================================
  static String get goalsBase => '$baseUrl/goals';
  static String get allGoals => goalsBase;
  static String goalById(String id) => '$goalsBase/$id';
  static String get goalProgress => '$goalsBase/progress';
  static String get goalStats => '$goalsBase/stats';
  
  // ============================================
  // Subscriptions / Premium
  // ============================================
  static String get subscriptionBase => '$baseUrl/subscriptions';
  static String get currentSubscription => '$subscriptionBase/current';
  static String get subscriptionPlans => '$subscriptionBase/plans';
  static String get createSubscription => '$subscriptionBase/create';
  static String get cancelSubscription => '$subscriptionBase/cancel';
  static String get restorePurchases => '$subscriptionBase/restore';
  
  // ============================================
  // Search
  // ============================================
  static String get searchBase => '$baseUrl/search';
  static String search(String query) => '$searchBase?q=${Uri.encodeComponent(query)}';
  static String get searchSuggestions => '$searchBase/suggestions';
  
  // ============================================
  // Analytics / Tracking
  // ============================================
  static String get analyticsBase => '$baseUrl/analytics';
  static String get trackEvent => '$analyticsBase/event';
  static String get trackSession => '$analyticsBase/session';
  
  // ============================================
  // Notifications
  // ============================================
  static String get notificationsBase => '$baseUrl/notifications';
  static String get registerDevice => '$notificationsBase/register';
  static String get unregisterDevice => '$notificationsBase/unregister';
  static String get notificationPreferences => '$notificationsBase/preferences';
  
  // ============================================
  // Utility
  // ============================================
  static String get healthCheck => '$baseUrl/health';
  static String get appConfig => '$baseUrl/config';
  static String get featureFlags => '$baseUrl/features';
  
  // ============================================
  // CDN / Media Helpers
  // ============================================
  
  /// Get optimized image URL with size parameters
  static String optimizedImage(String path, {int width = 400, int quality = 80}) {
    return '$cdnUrl/$path?w=$width&q=$quality&auto=format';
  }
  
  /// Get video thumbnail at specific time
  static String videoThumbnailAt(String id, {int seconds = 0}) {
    return '$cdnUrl/videos/$id/thumbnail.jpg?t=$seconds';
  }
}
