import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// User model from API
class User {
  final String id;
  final String email;
  final String? name;
  final String role;
  final String subscriptionTier;
  final List<String> permissions;
  
  User({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    required this.subscriptionTier,
    this.permissions = const [],
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['cognito_sub'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? json['display_name'],
      role: json['role'] ?? 'free_user',
      subscriptionTier: json['subscription_tier'] ?? 'free',
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role,
    'subscription_tier': subscriptionTier,
    'permissions': permissions,
  };
  
  bool get isPremium => subscriptionTier == 'premium';
  bool get isBasic => subscriptionTier == 'basic';
  bool get isFree => subscriptionTier == 'free';
}

/// Authentication service
/// Handles login, register, logout, and user management
/// Persists tokens securely for staying logged in
class AuthService {
  static AuthService? _instance;
  final ApiClient _api;
  final TokenStorage _tokenStorage = TokenStorage.instance;
  
  User? _currentUser;
  
  static AuthService get instance {
    _instance ??= AuthService._(ApiClient.instance);
    return _instance!;
  }
  
  AuthService._(this._api);
  
  /// Current logged-in user (null if not authenticated)
  User? get currentUser => _currentUser;
  
  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;
  
  /// Check if user has premium access
  bool get hasPremium => _currentUser?.isPremium ?? false;
  
  // ============================================
  // Authentication Methods
  // ============================================
  
  /// Register a new user
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _api.post('/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
      });

      if (response.data['success'] == true) {
        _currentUser = User.fromJson(response.data['user']);
        return _currentUser!;
      } else {
        throw AuthException(
          response.data['message'] ?? 'Registration failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw AuthException(
        e.response?.data?['message'] ?? 'Registration failed',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      throw AuthException('Registration failed', originalError: e);
    }
  }
  
  /// Login with email and password
  /// Persists tokens for staying logged in
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.data['success'] == true) {
        _currentUser = User.fromJson(response.data['user']);

        // Extract and save tokens from Set-Cookie header
        final setCookies = response.headers['set-cookie'];
        String? accessToken;
        String? refreshToken;

        if (setCookies != null) {
          for (final cookie in setCookies) {
            if (cookie.startsWith('access_token=')) {
              final tokenStart = cookie.indexOf('=') + 1;
              final tokenEnd = cookie.indexOf(';');
              accessToken = cookie.substring(tokenStart, tokenEnd > 0 ? tokenEnd : cookie.length);
            } else if (cookie.startsWith('refresh_token=')) {
              final tokenStart = cookie.indexOf('=') + 1;
              final tokenEnd = cookie.indexOf(';');
              refreshToken = cookie.substring(tokenStart, tokenEnd > 0 ? tokenEnd : cookie.length);
            }
          }
        }

        // Set token in API client for immediate use
        if (accessToken != null) {
          _api.setAccessToken(accessToken);
          debugPrint('🔑 Access token extracted from cookie');

          // Persist tokens for app restart
          await _tokenStorage.saveAccessToken(accessToken);
          if (refreshToken != null) {
            await _tokenStorage.saveRefreshToken(refreshToken);
          }
          // Save user data for offline display
          await _tokenStorage.saveUserData(jsonEncode(_currentUser!.toJson()));
        }

        debugPrint('✅ Logged in as: ${_currentUser!.email}');
        return _currentUser!;
      } else {
        throw AuthException(
          response.data['message'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw AuthException(
        e.response?.data?['message'] ?? 'Login failed',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      throw AuthException('Login failed', originalError: e);
    }
  }
  
  /// Logout current user and clear stored tokens
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (e) {
      debugPrint('Logout API error: $e');
    } finally {
      _currentUser = null;
      _api.setAccessToken(null);
      await _tokenStorage.clearAll(); // Clear persisted tokens
      await _api.clearCookies();
    }
  }
  
  /// Get current user from server
  Future<User?> getCurrentUser() async {
    try {
      final response = await _api.get('/auth/me');
      
      if (response.data != null) {
        _currentUser = User.fromJson(response.data);
        return _currentUser;
      }
      return null;
    } catch (e) {
      debugPrint('Get current user failed: $e');
      _currentUser = null;
      return null;
    }
  }
  
  /// Try to restore session from stored tokens
  /// Called on app start to keep user logged in
  Future<User?> tryRestoreSession() async {
    try {
      // Check if we have stored credentials
      final hasCredentials = await _tokenStorage.hasStoredCredentials();
      if (!hasCredentials) {
        debugPrint('📱 No stored credentials found');
        return null;
      }
      
      // Restore access token
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        _api.setAccessToken(accessToken);
        debugPrint('🔑 Access token restored from storage');
        
        // Try to restore user data from storage first (for offline display)
        final userJson = await _tokenStorage.getUserData();
        if (userJson != null) {
          _currentUser = User.fromJson(jsonDecode(userJson));
          debugPrint('👤 User data restored: ${_currentUser!.email}');
        }
        
        // Optionally verify with server (but don't fail if offline)
        try {
          final user = await getCurrentUser();
          if (user != null) {
            debugPrint('✅ Session verified with server');
            return user;
          }
        } catch (e) {
          debugPrint('⚠️ Server verification failed, using cached user: $e');
        }
        
        // Return cached user if server check failed (offline mode)
        return _currentUser;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Session restore failed: $e');
      // Clear potentially corrupted data
      await _tokenStorage.clearAll();
      return null;
    }
  }
  
  /// Request password reset
  Future<void> forgotPassword(String email) async {
    await _api.post('/auth/forgot-password', data: {
      'email': email,
    });
  }
  
  /// Reset password with code
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _api.post('/auth/reset-password', data: {
      'email': email,
      'confirmation_code': code,
      'new_password': newPassword,
    });
  }
  
  /// Check if user can access content tier
  bool canAccessTier(String contentTier) {
    if (_currentUser == null) {
      return contentTier == 'free';
    }
    
    const tierOrder = ['free', 'basic', 'premium'];
    final userTierIndex = tierOrder.indexOf(_currentUser!.subscriptionTier);
    final contentTierIndex = tierOrder.indexOf(contentTier);
    
    return userTierIndex >= contentTierIndex;
  }
}

/// Auth exception with optional status code for better error handling
class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final Object? originalError;

  AuthException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => message;
}
