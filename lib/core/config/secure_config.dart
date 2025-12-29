import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for sensitive data like API keys, tokens, and secrets
/// Uses platform-specific secure storage (Keychain on iOS, Keystore on Android)
class SecureConfig {
  static SecureConfig? _instance;
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  
  // Storage keys
  static const String _keyApiKey = 'api_key';
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyEncryptionKey = 'encryption_key';
  static const String _keyFirebaseToken = 'firebase_token';
  
  /// Get the singleton instance
  static SecureConfig get instance {
    _instance ??= SecureConfig._();
    return _instance!;
  }
  
  SecureConfig._();
  
  // ============================================
  // API Key Management
  // ============================================
  
  /// Get API key (set during build via environment)
  Future<String?> getApiKey() async {
    // First try to get from secure storage (for dynamic updates)
    final storedKey = await _storage.read(key: _keyApiKey);
    if (storedKey != null) return storedKey;
    
    // Fall back to build-time environment variable
    const buildKey = String.fromEnvironment('API_KEY');
    return buildKey.isNotEmpty ? buildKey : null;
  }
  
  /// Set API key (for dynamic updates from backend)
  Future<void> setApiKey(String key) async {
    await _storage.write(key: _keyApiKey, value: key);
  }
  
  // ============================================
  // Authentication Tokens
  // ============================================
  
  /// Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }
  
  /// Set access token
  Future<void> setAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }
  
  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }
  
  /// Set refresh token
  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }
  
  /// Store both tokens at once
  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      setAccessToken(accessToken),
      setRefreshToken(refreshToken),
    ]);
  }
  
  /// Clear all auth tokens (logout)
  Future<void> clearAuthTokens() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
    ]);
  }
  
  /// Check if user is authenticated
  Future<bool> get isAuthenticated async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
  
  // ============================================
  // User Data
  // ============================================
  
  /// Get stored user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }
  
  /// Store user ID
  Future<void> setUserId(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
  }
  
  // ============================================
  // Encryption Key (for Hive)
  // ============================================
  
  /// Get or generate encryption key for local database
  Future<List<int>> getEncryptionKey() async {
    final storedKey = await _storage.read(key: _keyEncryptionKey);
    
    if (storedKey != null) {
      // Decode stored key
      return storedKey.codeUnits;
    }
    
    // Generate new key (32 bytes for AES-256)
    final newKey = List<int>.generate(32, (i) => DateTime.now().microsecondsSinceEpoch % 256);
    await _storage.write(key: _keyEncryptionKey, value: String.fromCharCodes(newKey));
    return newKey;
  }
  
  // ============================================
  // Firebase/Push Notifications
  // ============================================
  
  /// Get FCM token
  Future<String?> getFirebaseToken() async {
    return await _storage.read(key: _keyFirebaseToken);
  }
  
  /// Store FCM token
  Future<void> setFirebaseToken(String token) async {
    await _storage.write(key: _keyFirebaseToken, value: token);
  }
  
  // ============================================
  // Utility Methods
  // ============================================
  
  /// Clear all secure storage (full logout/reset)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
  
  /// Check if a key exists
  Future<bool> hasKey(String key) async {
    final value = await _storage.read(key: key);
    return value != null;
  }
  
  /// Store arbitrary secure value
  Future<void> setSecureValue(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  /// Get arbitrary secure value
  Future<String?> getSecureValue(String key) async {
    return await _storage.read(key: key);
  }
  
  /// Delete arbitrary secure value
  Future<void> deleteSecureValue(String key) async {
    await _storage.delete(key: key);
  }
}
