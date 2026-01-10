import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for authentication tokens
/// Persists tokens between app restarts
class TokenStorage {
  static TokenStorage? _instance;
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // Storage keys
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userDataKey = 'user_data';
  
  static TokenStorage get instance {
    _instance ??= TokenStorage._();
    return _instance!;
  }
  
  TokenStorage._();
  
  // ============================================
  // Access Token
  // ============================================
  
  /// Save access token securely
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
    debugPrint('🔐 Access token saved to secure storage');
  }
  
  /// Get stored access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }
  
  /// Delete access token
  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }
  
  // ============================================
  // Refresh Token
  // ============================================
  
  /// Save refresh token securely
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
    debugPrint('🔐 Refresh token saved to secure storage');
  }
  
  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }
  
  /// Delete refresh token
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }
  
  // ============================================
  // User Data (for offline display)
  // ============================================
  
  /// Save user data as JSON string
  Future<void> saveUserData(String userJson) async {
    await _storage.write(key: _userDataKey, value: userJson);
  }
  
  /// Get stored user data
  Future<String?> getUserData() async {
    return await _storage.read(key: _userDataKey);
  }
  
  /// Delete user data
  Future<void> deleteUserData() async {
    await _storage.delete(key: _userDataKey);
  }
  
  // ============================================
  // Utility Methods
  // ============================================
  
  /// Clear all stored auth data (on logout)
  Future<void> clearAll() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userDataKey);
    debugPrint('🔐 All tokens cleared from secure storage');
  }
  
  /// Check if we have stored credentials
  Future<bool> hasStoredCredentials() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}
