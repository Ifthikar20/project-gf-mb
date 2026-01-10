import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Secure environment variable loader
/// Uses flutter_dotenv for .env file loading
/// NEVER hardcode secrets - always use this class
class EnvironmentConfig {
  static EnvironmentConfig? _instance;
  static bool _isLoaded = false;
  
  static EnvironmentConfig get instance {
    if (!_isLoaded) {
      throw StateError(
        'EnvironmentConfig not initialized. Call EnvironmentConfig.load() in main.dart'
      );
    }
    _instance ??= EnvironmentConfig._();
    return _instance!;
  }
  
  EnvironmentConfig._();
  
  /// Load environment variables from .env file
  /// Call this in main() before runApp()
  static Future<void> load({String fileName = '.env'}) async {
    try {
      await dotenv.load(fileName: fileName);
      _isLoaded = true;
      debugPrint('✅ Environment loaded from $fileName');
    } catch (e) {
      debugPrint('⚠️ Failed to load .env file: $e');
      // In production, you might want to throw or use defaults
      _isLoaded = true; // Allow app to continue with defaults
    }
  }
  
  // ============================================
  // API Configuration
  // ============================================
  
  /// Get API base URL
  String get apiBaseUrl => _get('API_BASE_URL', 'https://api-dev.betterandbliss.app');
  
  /// Get CDN base URL
  String get cdnBaseUrl => _get('CDN_BASE_URL', 'https://cdn-dev.betterandbliss.app');
  
  /// Get API key (NEVER expose in logs)
  String get apiKey => _getSecret('API_KEY');
  
  /// Get Firebase API key
  String get firebaseApiKey => _getSecret('FIREBASE_API_KEY');
  
  // ============================================
  // Feature Flags
  // ============================================
  
  /// Check if analytics is enabled
  bool get enableAnalytics => _getBool('ENABLE_ANALYTICS', false);
  
  /// Check if crash reporting is enabled
  bool get enableCrashReporting => _getBool('ENABLE_CRASH_REPORTING', false);
  
  /// Check if API encryption is enabled
  bool get enableApiEncryption => _getBool('ENABLE_API_ENCRYPTION', false);
  
  // ============================================
  // AWS Cognito Configuration
  // ============================================
  
  /// Cognito domain (e.g., https://your-app.auth.us-east-1.amazoncognito.com)
  String get cognitoDomain => _get('COGNITO_DOMAIN', '');
  
  /// Cognito client ID
  String get cognitoClientId => _get('COGNITO_CLIENT_ID', '');
  
  /// Cognito region
  String get cognitoRegion => _get('COGNITO_REGION', 'us-east-1');
  
  /// Cognito redirect URI for OAuth
  String get cognitoRedirectUri => _get('COGNITO_REDIRECT_URI', 'betterbliss://callback');
  
  /// Check if Cognito is configured
  bool get hasCognitoConfig => cognitoDomain.isNotEmpty && cognitoClientId.isNotEmpty;
  
  // ============================================
  // CloudFront CDN Configuration
  // ============================================
  
  /// CloudFront CDN URL for streaming content (e.g., https://d1234567890.cloudfront.net)
  String get cloudfrontUrl => _get('CLOUDFRONT_URL', '');
  
  /// Check if CloudFront is configured
  bool get hasCloudFrontConfig => cloudfrontUrl.isNotEmpty;
  
  // ============================================
  // Analytics (GA4 Measurement Protocol)
  // ============================================
  
  /// Google Analytics 4 Measurement ID (e.g., G-5TF9JXPNJW)
  String get gaMeasurementId => _get('GA_MEASUREMENT_ID', '');
  
  /// GA4 API Secret (from GA4 Admin > Data Streams > Measurement Protocol)
  String get gaApiSecret => _getSecret('GA_API_SECRET');
  
  /// Check if GA4 is enabled
  bool get gaEnabled => _getBool('GA_ENABLED', true);
  
  /// Check if GA4 is properly configured
  bool get hasGAConfig => gaMeasurementId.isNotEmpty && gaApiSecret.isNotEmpty;
  
  // ============================================
  // Certificate Pinning
  // ============================================
  
  /// Get certificate hash for pinning
  String get certHash1 => _get('API_CERT_HASH_1', '');
  String get certHash2 => _get('API_CERT_HASH_2', '');
  
  /// Get all certificate hashes as list
  List<String> get certificateHashes {
    final hashes = <String>[];
    if (certHash1.isNotEmpty) hashes.add(certHash1);
    if (certHash2.isNotEmpty) hashes.add(certHash2);
    return hashes;
  }
  
  // ============================================
  // Private helpers
  // ============================================
  
  /// Get environment variable with default
  String _get(String key, String defaultValue) {
    // First check dotenv
    final dotenvValue = dotenv.env[key];
    if (dotenvValue != null && dotenvValue.isNotEmpty) {
      return dotenvValue;
    }
    
    // Fallback to default
    return defaultValue;
  }
  
  /// Get boolean environment variable
  bool _getBool(String key, bool defaultValue) {
    final value = _get(key, defaultValue.toString()).toLowerCase();
    return value == 'true' || value == '1' || value == 'yes';
  }
  
  /// Get secret (masked in logs)
  String _getSecret(String key) {
    final value = dotenv.env[key] ?? '';
    if (kDebugMode && value.isNotEmpty) {
      final masked = value.length > 3 ? '${value.substring(0, 3)}***' : '***';
      debugPrint('🔑 $key: $masked');
    }
    return value;
  }
  
  /// Check if running in production
  bool get isProduction {
    final env = _get('ENVIRONMENT', 'development');
    return env == 'production';
  }
  
  /// Check if running in debug/development
  bool get isDevelopment => !isProduction;
}
