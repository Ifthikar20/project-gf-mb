import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'analytics_service.dart';
import 'recently_viewed_service.dart';
import 'token_storage.dart';
import 'streaming_service.dart';

/// User model from the BetterBliss Auth API
class User {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String role;
  final String subscriptionTier;
  final String status;
  final bool shareFoodDataWithCoach;
  final String? createdAt;
  final String? updatedAt;
  final bool? onboardingCompleted;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.role,
    required this.subscriptionTier,
    this.status = 'active',
    this.shareFoodDataWithCoach = false,
    this.createdAt,
    this.updatedAt,
    this.onboardingCompleted,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'] ?? json['name'],
      avatarUrl: json['avatar_url'],
      role: json['role'] ?? 'free_user',
      subscriptionTier: json['subscription_tier'] ?? 'free',
      status: json['status'] ?? 'active',
      shareFoodDataWithCoach: json['share_food_data_with_coach'] ?? false,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'role': role,
    'subscription_tier': subscriptionTier,
    'status': status,
    'share_food_data_with_coach': shareFoodDataWithCoach,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  User copyWith({bool? shareFoodDataWithCoach, bool? onboardingCompleted}) => User(
    id: id,
    email: email,
    displayName: displayName,
    avatarUrl: avatarUrl,
    role: role,
    subscriptionTier: subscriptionTier,
    status: status,
    shareFoodDataWithCoach: shareFoodDataWithCoach ?? this.shareFoodDataWithCoach,
    createdAt: createdAt,
    updatedAt: updatedAt,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
  );

  /// Legacy getter for backward compatibility
  String? get name => displayName;

  bool get isPremium => subscriptionTier == 'premium';
  bool get isBasic => subscriptionTier == 'basic';
  bool get isFree => subscriptionTier == 'free';
  bool get isActive => status == 'active';
}

/// Authentication service for DRF TokenAuthentication
/// Handles login, register, logout, profile, and password management
/// Token is returned in JSON response body and stored securely
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
  /// Backend returns token in response body — NOT in cookies
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    debugPrint('[AUTH SERVICE] Register initiated');

    try {
      final response = await _api.post('/auth/register', data: {
        'email': email,
        'password': password,
        'display_name': fullName,
      });
      
      if (response.data['success'] == true) {
        // Extract DRF token from response body
        final token = response.data['token'] as String?;
        if (token != null) {
          _api.setAccessToken(token);
          await _tokenStorage.saveAccessToken(token);
          debugPrint(' DRF token saved');
        }

        // Parse user data with onboarding status from API
        final onboardingCompleted = response.data['onboarding_completed'] as bool?;
        _currentUser = User.fromJson(response.data['user']).copyWith(
          onboardingCompleted: onboardingCompleted,
        );
        await _tokenStorage.saveUserData(jsonEncode(_currentUser!.toJson()));

        debugPrint(' Registered as: ${_currentUser!.email}');
        return _currentUser!;
      } else {
        throw AuthException(response.data['message'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      throw _extractError(e, fallback: 'Registration failed');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Registration failed: $e');
    }
  }
  
  /// Login with email and password
  /// Backend returns token in response body — NOT in cookies
  Future<User> login({
    required String email,
    required String password,
  }) async {
    debugPrint('[AUTH SERVICE] Login initiated');

    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      if (response.data['success'] == true) {
        // Extract DRF token from response body
        final token = response.data['token'] as String?;
        if (token != null) {
          _api.setAccessToken(token);
          await _tokenStorage.saveAccessToken(token);
          debugPrint(' DRF token saved');
        }

        // Parse user data with onboarding status from API
        final onboardingCompleted = response.data['onboarding_completed'] as bool?;
        _currentUser = User.fromJson(response.data['user']).copyWith(
          onboardingCompleted: onboardingCompleted,
        );
        await _tokenStorage.saveUserData(jsonEncode(_currentUser!.toJson()));

        debugPrint(' Logged in as: ${_currentUser!.email}');
        return _currentUser!;
      } else {
        throw AuthException(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw _extractError(e, fallback: 'Login failed');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Login failed: $e');
    }
  }
  
  /// Logout current user — deletes token server-side
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (e) {
      debugPrint('Logout API error: $e');
    } finally {
      _currentUser = null;
      _api.setAccessToken(null);
      await _tokenStorage.clearAll();

      // Clear cross-account data to prevent leaking data between users
      await RecentlyViewedService.instance.clearAll();
      AnalyticsService.instance.setUserId(null);

      // Clear streaming URL cache
      try {
        StreamingService.instance.clearCache();
        debugPrint(' Streaming URL cache cleared on logout');
      } catch (e) {
        debugPrint(' Could not clear streaming cache: $e');
      }
    }
  }
  
  /// Get current user from server
  /// Backend returns {success: true, user: {...}}
  Future<User?> getCurrentUser() async {
    try {
      final response = await _api.get('/auth/me');
      
      if (response.data != null) {
        // Backend wraps user in {success, user} envelope
        final userData = response.data['user'] ?? response.data;
        _currentUser = User.fromJson(userData);
        return _currentUser;
      }
      return null;
    } catch (e) {
      debugPrint('Get current user failed: $e');
      _currentUser = null;
      return null;
    }
  }
  
  /// Try to restore session from stored token
  /// If token is expired (7 days), returns null and clears storage
  Future<User?> tryRestoreSession() async {
    try {
      final hasCredentials = await _tokenStorage.hasStoredCredentials();
      if (!hasCredentials) {
        debugPrint(' No stored credentials found');
        return null;
      }
      
      // Restore access token
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        _api.setAccessToken(accessToken);
        debugPrint(' Access token restored from storage');
        
        // Restore cached user data for offline display
        final userJson = await _tokenStorage.getUserData();
        if (userJson != null) {
          _currentUser = User.fromJson(jsonDecode(userJson));
          debugPrint(' User data restored: ${_currentUser!.email}');
        }
        
        // Verify with server
        try {
          final user = await getCurrentUser();
          if (user != null) {
            debugPrint(' Session verified with server');
            // Record successful verification time for offline grace period
            await _tokenStorage.write(
              key: 'last_server_verified_at',
              value: DateTime.now().toIso8601String(),
            );
            return user;
          }
        } on DioException catch (e) {
          final status = e.response?.statusCode;
          if (status == 401 || status == 403) {
            // Token expired or forbidden — clear everything
            debugPrint('⏰ Token invalid ($status), clearing session');
            _currentUser = null;
            _api.setAccessToken(null);
            await _tokenStorage.clearAll();
            return null;
          }
          // Network error — allow offline access with 24h grace period
          final lastVerified = await _tokenStorage.read(key: 'last_server_verified_at');
          if (lastVerified != null) {
            final lastVerifiedTime = DateTime.parse(lastVerified);
            final hoursSince = DateTime.now().difference(lastVerifiedTime).inHours;
            if (hoursSince > 24) {
              debugPrint('[Auth] Offline grace period expired — forcing re-authentication');
              await logout();
              return null;
            }
          }
          debugPrint('[Auth] Server verification failed (network), using cached session');
        }
      }
      
      return null;
    } catch (e) {
      debugPrint(' Session restore failed: $e');
      await _tokenStorage.clearAll();
      return null;
    }
  }
  
  /// Update user profile (display name, avatar)
  Future<User> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final response = await _api.patch('/auth/profile', data: {
        if (displayName != null) 'display_name': displayName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      });
      
      final userData = response.data['user'] ?? response.data;
      _currentUser = User.fromJson(userData);
      await _tokenStorage.saveUserData(jsonEncode(_currentUser!.toJson()));
      
      debugPrint(' Profile updated');
      return _currentUser!;
    } on DioException catch (e) {
      throw _extractError(e, fallback: 'Profile update failed');
    }
  }
  
  /// Request password reset — sends email
  /// Always succeeds from API perspective (security: don't reveal if email exists)
  Future<void> forgotPassword(String email) async {
    debugPrint(' [AUTH SERVICE] Requesting password reset for: $email');
    
    try {
      await _api.post('/auth/forgot-password', data: {
        'email': email,
      });
      debugPrint(' Password reset requested');
    } catch (e) {
      debugPrint(' Forgot password request: $e');
      // Don't throw — always show success message to user
    }
  }
  
  /// Reset password with verification
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    debugPrint(' [AUTH SERVICE] Resetting password');
    
    try {
      await _api.post('/auth/reset-password', data: {
        'reset_token': token,
        'new_password': newPassword,
      });
      debugPrint(' Password reset successful');
    } on DioException catch (e) {
      throw _extractError(e, fallback: 'Password reset failed');
    }
  }
  
  /// Change password while logged in
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    debugPrint(' [AUTH SERVICE] Changing password');
    
    try {
      await _api.post('/auth/change-password', data: {
        'current_password': oldPassword,
        'new_password': newPassword,
      });
      debugPrint(' Password changed successfully');
    } on DioException catch (e) {
      throw _extractError(e, fallback: 'Password change failed');
    }
  }
  
  /// Soft-delete the user account
  Future<void> deleteAccount() async {
    debugPrint(' [AUTH SERVICE] Deleting account');
    
    try {
      await _api.delete('/auth/delete-account');
      debugPrint(' Account deleted');
    } on DioException catch (e) {
      throw _extractError(e, fallback: 'Account deletion failed');
    } finally {
      _currentUser = null;
      _api.setAccessToken(null);
      await _tokenStorage.clearAll();
    }
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
  
  // ============================================
  // Private: Error Extraction
  // ============================================
  
  /// Extract structured error from DioException
  /// Supports: {error: {code, message, hint}} and legacy {detail}
  AuthException _extractError(DioException e, {String fallback = 'Operation failed'}) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;
    
    // Handle rate limiting
    if (statusCode == 429) {
      return AuthException(
        'Too many attempts. Please wait a minute.',
        statusCode: 429,
        code: 'TOO_MANY_ATTEMPTS',
      );
    }
    
    if (responseData is Map) {
      // New structured format: {error: {code, message, hint}}
      if (responseData['error'] is Map) {
        final error = responseData['error'] as Map;
        return AuthException(
          error['message'] ?? fallback,
          statusCode: statusCode,
          code: error['code'],
          hint: error['hint'],
        );
      }
      
      // Legacy format: {detail} or {message}
      final errorMsg = responseData['detail'] ?? responseData['message'] ?? fallback;
      return AuthException(errorMsg, statusCode: statusCode);
    }
    
    return AuthException(fallback, statusCode: statusCode);
  }
}

/// Auth exception
class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final String? hint;
  
  AuthException(this.message, {this.statusCode, this.code, this.hint});
  
  @override
  String toString() => message;
}

/// Rate limit exception
class RateLimitException implements Exception {
  final int retryAfterSeconds;
  RateLimitException({required this.retryAfterSeconds});
  
  @override
  String toString() => 'Rate limited. Please try again in $retryAfterSeconds seconds.';
}

/// Helper to extract structured error from API response (for use outside AuthService)
AuthException extractAuthError(DioException e, {String fallbackMessage = 'Operation failed'}) {
  final statusCode = e.response?.statusCode;
  final responseData = e.response?.data;
  
  if (statusCode == 429) {
    final retryAfter = int.tryParse(
      e.response?.headers.value('Retry-After') ?? '60'
    ) ?? 60;
    throw RateLimitException(retryAfterSeconds: retryAfter);
  }
  
  if (responseData is Map) {
    if (responseData['error'] is Map) {
      final error = responseData['error'] as Map;
      return AuthException(
        error['message'] ?? fallbackMessage,
        code: error['code'],
        hint: error['hint'],
      );
    }
    
    final errorMsg = responseData['detail'] ?? responseData['message'] ?? fallbackMessage;
    return AuthException(errorMsg);
  }
  
  return AuthException(fallbackMessage);
}
