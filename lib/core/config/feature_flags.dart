import 'app_config.dart';

/// Feature flags for gradual rollout and A/B testing
/// Can be updated dynamically from backend
class FeatureFlags {
  static FeatureFlags? _instance;
  
  // Flag values (can be updated from remote config)
  bool _enableNewPlayer = false;
  bool _enableSocialSharing = true;
  bool _enableCommunity = false;
  bool _enableWorkoutTracking = false;
  bool _enableSleepStories = true;
  bool _enableBiometricAuth = false;
  bool _showPremiumBadge = true;
  bool _enableDarkModeOnly = true;
  int _maxFreeContent = 5;
  int _freeTrialDays = 7;
  
  /// Get the singleton instance
  static FeatureFlags get instance {
    _instance ??= FeatureFlags._();
    return _instance!;
  }
  
  FeatureFlags._();
  
  // ============================================
  // Feature Getters
  // ============================================
  
  /// New video/audio player UI
  bool get enableNewPlayer => _enableNewPlayer;
  
  /// Social sharing buttons
  bool get enableSocialSharing => _enableSocialSharing;
  
  /// Community features (comments, ratings)
  bool get enableCommunity => _enableCommunity;
  
  /// Workout/exercise tracking
  bool get enableWorkoutTracking => _enableWorkoutTracking;
  
  /// Sleep stories feature
  bool get enableSleepStories => _enableSleepStories;
  
  /// Biometric authentication (Face ID, fingerprint)
  bool get enableBiometricAuth => _enableBiometricAuth;
  
  /// Show premium badge on content
  bool get showPremiumBadge => _showPremiumBadge;
  
  /// Force dark mode only (no light mode option)
  bool get enableDarkModeOnly => _enableDarkModeOnly;
  
  /// Maximum free content items for non-premium users
  int get maxFreeContent => _maxFreeContent;
  
  /// Free trial period in days
  int get freeTrialDays => _freeTrialDays;
  
  // ============================================
  // Environment-based Flags
  // ============================================
  
  /// Show debug tools (only in dev/staging)
  bool get showDebugTools => AppConfig.instance.isDebugMode;
  
  /// Enable verbose logging
  bool get enableVerboseLogging => AppConfig.instance.isDevelopment;
  
  /// Enable analytics tracking
  bool get enableAnalytics => AppConfig.instance.enableAnalytics;
  
  /// Enable crash reporting
  bool get enableCrashReporting => AppConfig.instance.enableCrashReporting;
  
  /// Enable offline mode
  bool get enableOfflineMode => AppConfig.instance.enableOfflineMode;
  
  /// Enable push notifications
  bool get enablePushNotifications => AppConfig.instance.enablePushNotifications;
  
  // ============================================
  // Remote Config Updates
  // ============================================
  
  /// Update flags from remote config (Firebase, etc.)
  void updateFromRemote(Map<String, dynamic> config) {
    _enableNewPlayer = config['enable_new_player'] ?? _enableNewPlayer;
    _enableSocialSharing = config['enable_social_sharing'] ?? _enableSocialSharing;
    _enableCommunity = config['enable_community'] ?? _enableCommunity;
    _enableWorkoutTracking = config['enable_workout_tracking'] ?? _enableWorkoutTracking;
    _enableSleepStories = config['enable_sleep_stories'] ?? _enableSleepStories;
    _enableBiometricAuth = config['enable_biometric_auth'] ?? _enableBiometricAuth;
    _showPremiumBadge = config['show_premium_badge'] ?? _showPremiumBadge;
    _enableDarkModeOnly = config['enable_dark_mode_only'] ?? _enableDarkModeOnly;
    _maxFreeContent = config['max_free_content'] ?? _maxFreeContent;
    _freeTrialDays = config['free_trial_days'] ?? _freeTrialDays;
  }
  
  /// Check if a specific feature is enabled by key name
  bool isEnabled(String featureKey) {
    return switch (featureKey) {
      'new_player' => _enableNewPlayer,
      'social_sharing' => _enableSocialSharing,
      'community' => _enableCommunity,
      'workout_tracking' => _enableWorkoutTracking,
      'sleep_stories' => _enableSleepStories,
      'biometric_auth' => _enableBiometricAuth,
      'premium_badge' => _showPremiumBadge,
      'dark_mode_only' => _enableDarkModeOnly,
      _ => false,
    };
  }
  
  /// Get all flags as map (for debugging)
  Map<String, dynamic> toMap() {
    return {
      'enable_new_player': _enableNewPlayer,
      'enable_social_sharing': _enableSocialSharing,
      'enable_community': _enableCommunity,
      'enable_workout_tracking': _enableWorkoutTracking,
      'enable_sleep_stories': _enableSleepStories,
      'enable_biometric_auth': _enableBiometricAuth,
      'show_premium_badge': _showPremiumBadge,
      'enable_dark_mode_only': _enableDarkModeOnly,
      'max_free_content': _maxFreeContent,
      'free_trial_days': _freeTrialDays,
    };
  }
}
