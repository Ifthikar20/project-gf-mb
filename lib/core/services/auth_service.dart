import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
    debugPrint('\n' + '='*80);
    debugPrint('📝 [AUTH SERVICE] Starting registration flow');
    debugPrint('📧 Email: $email');
    debugPrint('👤 Full Name: $fullName');
    debugPrint('📍 Location: AuthService.register()');
    debugPrint('='*80);
    
    try {
      debugPrint('\n📤 [STEP 1/4] Sending POST request to /auth/register');
      final response = await _api.post('/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
      });
      
      debugPrint('\n✅ [STEP 2/4] Received response from server');
      debugPrint('📊 Status Code: ${response.statusCode}');
      debugPrint('📋 Response Data: ${response.data}');
      
      if (response.data['success'] == true) {
        debugPrint('\n✅ [STEP 3/4] Registration successful, parsing user data');
        _currentUser = User.fromJson(response.data['user']);
        debugPrint('👤 User ID: ${_currentUser!.id}');
        debugPrint('📧 User Email: ${_currentUser!.email}');
        debugPrint('🎭 User Role: ${_currentUser!.role}');
        debugPrint('💎 Subscription: ${_currentUser!.subscriptionTier}');
        
        // Extract and save session_id from Set-Cookie header if present
        debugPrint('\n🔍 [STEP 4/4] Checking for session_id cookie');
        final setCookies = response.headers['set-cookie'];
        String? sessionId;
        
        if (setCookies != null) {
          for (final cookie in setCookies) {
            if (cookie.startsWith('session_id=')) {
              final tokenStart = cookie.indexOf('=') + 1;
              final tokenEnd = cookie.indexOf(';');
              sessionId = cookie.substring(tokenStart, tokenEnd > 0 ? tokenEnd : cookie.length);
              debugPrint('🔑 Found session_id from registration');
            }
          }
        }
        
        // Save session and user data
        if (sessionId != null) {
          await _tokenStorage.saveAccessToken(sessionId);
          debugPrint('✅ Session ID saved to secure storage');
        }
        await _tokenStorage.saveUserData(jsonEncode(_currentUser!.toJson()));
        debugPrint('✅ User data saved to secure storage');
        
        debugPrint('\n' + '='*80);
        debugPrint('🎉 [AUTH SERVICE] Registration completed successfully');
        debugPrint('👤 Registered as: ${_currentUser!.email}');
        debugPrint('='*80 + '\n');
        
        return _currentUser!;
      } else {
        debugPrint('\n❌ [ERROR] Server returned success=false');
        debugPrint('📋 Response: ${response.data}');
        final errorMsg = response.data['message'] ?? 'Registration failed';
        throw AuthException(errorMsg);
      }
    } on DioException catch (e) {
      debugPrint('\n' + '='*80);
      debugPrint('❌ [AUTH SERVICE] Registration failed with DioException');
      debugPrint('📍 Location: AuthService.register() - catch block');
      debugPrint('🔍 Status Code: ${e.response?.statusCode}');
      debugPrint('� Response Data: ${e.response?.data}');
      debugPrint('='*80 + '\n');
      
      // Use helper to extract structured error (handles 429 rate limits too)
      throw extractAuthError(e, fallbackMessage: 'Registration failed');
    } catch (e) {
      debugPrint('\n' + '='*80);
      debugPrint('❌ [AUTH SERVICE] Registration failed with error');
      debugPrint('�📍 Location: AuthService.register() - catch block');
      debugPrint('🔍 Error Type: ${e.runtimeType}');
      debugPrint('💬 Error Message: $e');
      debugPrint('='*80 + '\n');
      if (e is AuthException || e is RateLimitException) rethrow;
      throw AuthException('Registration failed: $e');
    }
  }
  
  /// Login with email and password
  /// Persists tokens for staying logged in
  Future<User> login({
    required String email,
    required String password,
  }) async {
    debugPrint('\n' + '='*80);
    debugPrint('🔐 [AUTH SERVICE] Starting login flow');
    debugPrint('📧 Email: $email');
    debugPrint('📍 Location: AuthService.login()');
    debugPrint('='*80);
    
    try {
      debugPrint('\n📤 [STEP 1/5] Sending POST request to /auth/login');
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      debugPrint('\n✅ [STEP 2/5] Received response from server');
      debugPrint('📊 Status Code: ${response.statusCode}');
      debugPrint('📋 Response Data: ${response.data}');
      debugPrint('📨 Response Headers: ${response.headers.map}');
      
      if (response.data['success'] == true) {
        debugPrint('\n✅ [STEP 3/5] Login successful, parsing user data');
        _currentUser = User.fromJson(response.data['user']);
        debugPrint('👤 User ID: ${_currentUser!.id}');
        debugPrint('📧 User Email: ${_currentUser!.email}');
        debugPrint('🎭 User Role: ${_currentUser!.role}');
        debugPrint('💎 Subscription: ${_currentUser!.subscriptionTier}');
        
        // Extract and save session_id from Set-Cookie header
        // Note: Backend uses session_id cookie for authentication (HttpOnly, Secure)
        debugPrint('\n🔍 [STEP 4/5] Extracting session_id from Set-Cookie headers');
        final setCookies = response.headers['set-cookie'];
        String? sessionId;
        
        if (setCookies != null) {
          debugPrint('📦 Found ${setCookies.length} Set-Cookie header(s)');
          for (final cookie in setCookies) {
            debugPrint('🍪 Cookie: ${cookie.substring(0, cookie.length > 50 ? 50 : cookie.length)}...');
            if (cookie.startsWith('session_id=')) {
              final tokenStart = cookie.indexOf('=') + 1;
              final tokenEnd = cookie.indexOf(';');
              sessionId = cookie.substring(tokenStart, tokenEnd > 0 ? tokenEnd : cookie.length);
              debugPrint('🔑 Found session_id: ${sessionId.substring(0, sessionId.length > 20 ? 20 : sessionId.length)}...');
            }
          }
        } else {
          debugPrint('⚠️  No Set-Cookie headers found in response');
        }
        
        // Save session and user data
        debugPrint('\n💾 [STEP 5/5] Saving session and user data to storage');
        
        // The session_id cookie is HttpOnly and will be automatically sent by Dio's cookie jar
        // We still save it to our token storage as a backup and for session validation
        if (sessionId != null) {
          await _tokenStorage.saveAccessToken(sessionId);
          debugPrint('✅ Session ID saved to secure storage');
        } else {
          debugPrint('ℹ️  Session ID is managed via HttpOnly cookie (handled by cookie jar)');
        }
        
        // Save user data for offline display and session persistence
        await _tokenStorage.saveUserData(jsonEncode(_currentUser!.toJson()));
        debugPrint('✅ User data saved to secure storage');
        
        debugPrint('\n' + '='*80);
        debugPrint('🎉 [AUTH SERVICE] Login completed successfully');
        debugPrint('👤 Logged in as: ${_currentUser!.email}');
        debugPrint('='*80 + '\n');
        return _currentUser!;
      } else {
        debugPrint('\n❌ [ERROR] Server returned success=false');
        debugPrint('📋 Response: ${response.data}');
        final errorMsg = response.data['message'] ?? 'Login failed';
        throw AuthException(errorMsg);
      }
    } on DioException catch (e) {
      debugPrint('\n' + '='*80);
      debugPrint('❌ [AUTH SERVICE] Login failed with DioException');
      debugPrint('📍 Location: AuthService.login() - catch block');
      debugPrint('🔍 Status Code: ${e.response?.statusCode}');
      debugPrint('� Response Data: ${e.response?.data}');
      debugPrint('='*80 + '\n');
      
      // Use helper to extract structured error (handles 429 rate limits too)
      throw extractAuthError(e, fallbackMessage: 'Login failed');
    } catch (e) {
      debugPrint('\n' + '='*80);
      debugPrint('❌ [AUTH SERVICE] Login failed with error');
      debugPrint('�📍 Location: AuthService.login() - catch block');
      debugPrint('🔍 Error Type: ${e.runtimeType}');
      debugPrint('💬 Error Message: $e');
      debugPrint('='*80 + '\n');
      if (e is AuthException || e is RateLimitException) rethrow;
      throw AuthException('Login failed: $e');
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
  
  /// Request password reset - sends 6-digit code to email
  /// Always succeeds from API perspective (security: don't reveal if email exists)
  Future<void> forgotPassword(String email) async {
    debugPrint('\n' + '='*80);
    debugPrint('📧 [AUTH SERVICE] Requesting password reset');
    debugPrint('📧 Email: $email');
    debugPrint('='*80);
    
    try {
      await _api.post('/auth/forgot-password', data: {
        'email': email,
      });
      debugPrint('✅ Password reset code sent (if account exists)');
    } on DioException catch (e) {
      debugPrint('⚠️ Forgot password request: ${e.response?.data}');
      // Don't throw - API always returns success for security
    } catch (e) {
      debugPrint('⚠️ Forgot password error: $e');
      // Don't throw - always show success message to user
    }
  }
  
  /// Reset password with 6-digit verification code
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    debugPrint('\n' + '='*80);
    debugPrint('🔐 [AUTH SERVICE] Resetting password with code');
    debugPrint('📧 Email: $email');
    debugPrint('🔢 Code: ${code.substring(0, 2)}****');
    debugPrint('='*80);
    
    try {
      final response = await _api.post('/auth/reset-password', data: {
        'email': email,
        'confirmation_code': code,
        'new_password': newPassword,
      });
      
      debugPrint('✅ Password reset successful');
      debugPrint('📋 Response: ${response.data}');
    } on DioException catch (e) {
      debugPrint('❌ Password reset failed: ${e.response?.statusCode}');
      debugPrint('📋 Response: ${e.response?.data}');
      
      final responseData = e.response?.data;
      String errorMsg = 'Password reset failed';
      if (responseData is Map) {
        errorMsg = responseData['detail'] ?? responseData['message'] ?? errorMsg;
      }
      throw AuthException(errorMsg);
    } catch (e) {
      debugPrint('❌ Password reset error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Password reset failed: $e');
    }
  }
  
  /// Change password while logged in (requires current password)
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    debugPrint('\n' + '='*80);
    debugPrint('🔑 [AUTH SERVICE] Changing password');
    debugPrint('='*80);
    
    try {
      final response = await _api.post('/auth/change-password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      
      debugPrint('✅ Password changed successfully');
      debugPrint('📋 Response: ${response.data}');
    } on DioException catch (e) {
      debugPrint('❌ Password change failed: ${e.response?.statusCode}');
      debugPrint('📋 Response: ${e.response?.data}');
      
      final responseData = e.response?.data;
      String errorMsg = 'Password change failed';
      if (responseData is Map) {
        errorMsg = responseData['detail'] ?? responseData['message'] ?? errorMsg;
      }
      throw AuthException(errorMsg);
    } catch (e) {
      debugPrint('❌ Password change error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Password change failed: $e');
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
}

/// Auth exception with optional error code for structured handling
class AuthException implements Exception {
  final String message;
  final String? code;  // e.g., 'INVALID_RESET_CODE', 'EMAIL_NOT_FOUND'
  final String? hint;  // Additional help text from backend
  
  AuthException(this.message, {this.code, this.hint});
  
  @override
  String toString() => message;
  
  /// Check if this is a specific error type
  bool isCode(String errorCode) => code == errorCode;
}

/// Rate limit exception for HTTP 429 responses
class RateLimitException implements Exception {
  final int retryAfterSeconds;
  final String message;
  
  RateLimitException({this.retryAfterSeconds = 60, String? message})
      : message = message ?? 'Too many attempts. Please try again in ${retryAfterSeconds}s.';
  
  @override
  String toString() => message;
}

/// Helper to extract structured error from API response
/// Supports both legacy format: {"detail": "..."}
/// And new structured format: {"error": {"code": "...", "message": "...", "hint": "..."}}
AuthException extractAuthError(DioException e, {String fallbackMessage = 'Operation failed'}) {
  final statusCode = e.response?.statusCode;
  final responseData = e.response?.data;
  
  // Handle rate limiting (429)
  if (statusCode == 429) {
    final retryAfter = int.tryParse(
      e.response?.headers.value('Retry-After') ?? '60'
    ) ?? 60;
    throw RateLimitException(retryAfterSeconds: retryAfter);
  }
  
  if (responseData is Map) {
    // New structured error format: {"error": {"code": "...", "message": "..."}}
    if (responseData['error'] is Map) {
      final error = responseData['error'] as Map;
      return AuthException(
        error['message'] ?? fallbackMessage,
        code: error['code'],
        hint: error['hint'],
      );
    }
    
    // Legacy format: {"detail": "..."} or {"message": "..."}
    final errorMsg = responseData['detail'] ?? responseData['message'] ?? fallbackMessage;
    return AuthException(errorMsg);
  }
  
  return AuthException(fallbackMessage);
}
