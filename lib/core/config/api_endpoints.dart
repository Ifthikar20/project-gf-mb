import 'app_config.dart';

/// Centralized API endpoints configuration
/// All API paths are defined here for easy maintenance and consistency
/// Aligned with the betterbliss-auth Django backend
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
  // Authentication Endpoints (/auth/)
  // ============================================
  static String get authBase => '$baseUrl/auth';
  static String get login => '$authBase/login';
  static String get register => '$authBase/register';
  static String get logout => '$authBase/logout';
  static String get forgotPassword => '$authBase/forgot-password';
  static String get resetPassword => '$authBase/reset-password';
  static String get changePassword => '$authBase/change-password';
  
  // User profile (via auth)
  static String get me => '$authBase/me';
  static String get profile => '$authBase/profile';
  static String get deleteAccount => '$authBase/delete-account';
  
  // OAuth
  static String get googleAuth => '$authBase/google';
  static String get appleAuth => '$authBase/apple';
  static String get authCallback => '$authBase/callback';
  
  // ============================================
  // Content Endpoints (/api/)
  // ============================================
  static String get apiBase => '$baseUrl/api';
  
  // Content browsing & detail
  static String get contentBrowse => '$apiBase/content/browse';
  static String contentDetail(String id) => '$apiBase/content/$id';
  
  // Categories
  static String get categories => '$apiBase/categories';
  static String categoryById(String id) => '$apiBase/categories/$id';
  
  // Experts
  static String get experts => '$apiBase/experts';
  static String get expertsSearch => '$apiBase/experts/search';
  static String expertProfile(String slug) => '$apiBase/experts/$slug';
  
  // ============================================
  // Analytics / Tracking (/api/track/)
  // ============================================
  static String trackView(String id) => '$apiBase/track/view/$id';
  static String trackPlay(String id) => '$apiBase/track/play/$id';
  static String get trackSearch => '$apiBase/track/search';
  
  // ============================================
  // Personalization (/api/personalization/)
  // ============================================
  static String get personalizationBase => '$apiBase/personalization';
  static String get onboarding => '$personalizationBase/onboarding';
  static String get onboardingOptions => '$personalizationBase/onboarding/options';
  static String get preferences => '$personalizationBase/preferences';
  static String get recommendations => '$personalizationBase/recommendations';
  static String get homeFeed => '$personalizationBase/home-feed';
  
  // ============================================
  // Streaming
  // ============================================
  static String contentStream(String id) => '$baseUrl/$id/stream';
  
  // Legacy streaming (secure URLs from backend)
  static String get streamingBase => '$baseUrl/api/streaming';
  static String secureStream(String id) => '$streamingBase/content/$id/stream';
  
  // ============================================
  // Series (CMS API — used internally)
  // ============================================
  static String get cmsBase => '$baseUrl/v1/cms';
  static String get seriesBase => '$cmsBase/series';
  static String seriesById(String id) => '$seriesBase/$id';
  static String get publishedSeries => '$seriesBase?status=published';
  static String seriesForExplore() => '$seriesBase?status=published&show_on_explore=true';
  static String seriesForMeditate() => '$seriesBase?status=published&show_on_meditate=true';
  
  // ============================================
  // Wellness Goals (local — may use backend later)
  // ============================================
  static String get goalsBase => '$baseUrl/goals';
  static String get allGoals => goalsBase;
  static String goalById(String id) => '$goalsBase/$id';
  static String get goalProgress => '$goalsBase/progress';
  static String get goalStats => '$goalsBase/stats';
  
  // ============================================
  // Workouts & Calorie Tracking
  // ============================================
  static String get workoutsBase => '$baseUrl/api/workouts';
  static String get workoutTypes => '$workoutsBase/types';
  static String get bodyProfile => '$workoutsBase/body-profile';
  static String get calorieEstimate => '$workoutsBase/estimate';
  static String get logManual => '$workoutsBase/log/manual';
  static String get logAppleHealth => '$workoutsBase/log/apple-health';
  static String get logAppleHealthBatch => '$workoutsBase/log/apple-health/batch';
  static String get workoutHistory => '$workoutsBase/history';
  static String get workoutStats => '$workoutsBase/stats';
  static String get workoutGoals => '$workoutsBase/goals';
  static String get workoutGoalSet => '$workoutsBase/goals/set';
  static String workoutGoalDelete(String type) => '$workoutsBase/goals/$type';
  
  // ============================================
  // Engagement
  // ============================================
  static String get engagementBase => '$baseUrl/api/engagement';
  static String get logWatch => '$engagementBase/watch';
  static String get watchHistory => '$engagementBase/history';
  static String get streak => '$engagementBase/streak';
  static String favoriteToggle(String id) => '$engagementBase/favorite/$id';
  static String get favorites => '$engagementBase/favorites';
  
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
