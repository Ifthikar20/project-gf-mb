import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:app_links/app_links.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'token_storage.dart';

/// OAuth Service for handling social login (Google, Apple)
/// Handles launching OAuth URLs and processing deep link callbacks
class OAuthService {
  static OAuthService? _instance;
  final ApiClient _api;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  
  // Callback for when OAuth completes
  Function(User user)? onAuthSuccess;
  Function(String error)? onAuthError;
  
  static OAuthService get instance {
    _instance ??= OAuthService._(ApiClient.instance);
    return _instance!;
  }
  
  OAuthService._(this._api);
  
  /// Initialize deep link listening
  /// Call this in main.dart or app initialization
  Future<void> initialize() async {
    // Handle cold start - app was launched by a link
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        await _handleIncomingLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }
    
    // Handle links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }
  
  /// Clean up resources
  void dispose() {
    _linkSubscription?.cancel();
  }
  
  /// Handle incoming deep link
  Future<void> _handleIncomingLink(Uri uri) async {
    debugPrint('📱 Received deep link: $uri');
    
    // Check if this is an auth callback
    if (uri.scheme == 'betterbliss' && uri.host == 'auth') {
      final sessionId = uri.queryParameters['session_id'];
      final error = uri.queryParameters['error'];
      
      if (error != null) {
        debugPrint('❌ OAuth error: $error');
        onAuthError?.call(error);
        return;
      }
      
      if (sessionId != null) {
        debugPrint('✅ OAuth session received');
        await _completeOAuthLogin(sessionId);
      }
    }
  }
  
  /// Complete OAuth login with session ID
  Future<void> _completeOAuthLogin(String sessionId) async {
    try {
      // Store the session token in memory
      _api.setAccessToken(sessionId);
      
      // Persist the token to secure storage
      final tokenStorage = TokenStorage.instance;
      await tokenStorage.saveAccessToken(sessionId);
      debugPrint('🔐 OAuth session saved to secure storage');
      
      // Fetch user info
      final response = await _api.get('/auth/me');
      
      if (response.data != null) {
        final user = User.fromJson(response.data);
        
        // Save user data to storage for session persistence
        await tokenStorage.saveUserData(jsonEncode(user.toJson()));
        debugPrint('✅ OAuth login complete: ${user.email}');
        
        onAuthSuccess?.call(user);
      }
    } catch (e) {
      debugPrint('❌ Failed to complete OAuth: $e');
      onAuthError?.call('Failed to complete sign in');
    }
  }

  
  /// Launch Google Sign In using native ASWebAuthenticationSession
  Future<void> signInWithGoogle() async {
    const baseUrl = 'https://api.betterandbliss.com';
    const callbackScheme = 'betterbliss';
    
    // Add prompt=select_account to force Google to show account picker every time
    final authUrl = '$baseUrl/auth/google?redirect=$callbackScheme://auth/callback&prompt=select_account';
    
    debugPrint('🔐 Launching Google OAuth (native): $authUrl');
    
    try {
      // This opens ASWebAuthenticationSession on iOS (in-app secure browser)
      // preferEphemeral: true creates isolated session (no shared cookies)
      // This ensures the account picker ALWAYS shows
      final resultUrl = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: callbackScheme,
        options: const FlutterWebAuth2Options(
          preferEphemeral: false, // Share cookies - shows account picker!
        ),
      );
      
      debugPrint('📱 OAuth callback received: $resultUrl');
      
      // Parse the callback URL
      final uri = Uri.parse(resultUrl);
      final sessionId = uri.queryParameters['session_id'];
      final error = uri.queryParameters['error'];
      
      if (error != null) {
        debugPrint('❌ OAuth error: $error');
        onAuthError?.call(error);
        return;
      }
      
      if (sessionId != null) {
        debugPrint('✅ OAuth session received');
        await _completeOAuthLogin(sessionId);
      } else {
        onAuthError?.call('No session received from sign in');
      }
    } catch (e) {
      debugPrint('❌ Google OAuth cancelled or failed: $e');
      // User likely cancelled - don't show an error for cancellation
      if (e.toString().contains('CANCELED') || e.toString().contains('cancel')) {
        debugPrint('User cancelled OAuth');
      } else {
        onAuthError?.call('Sign in was cancelled');
      }
    }
  }
  
  /// Launch Apple Sign In using native ASWebAuthenticationSession
  Future<void> signInWithApple() async {
    const baseUrl = 'https://api.betterandbliss.com';
    const callbackScheme = 'betterbliss';
    
    final authUrl = '$baseUrl/auth/apple?redirect=$callbackScheme://auth/callback';
    
    debugPrint('🔐 Launching Apple OAuth (native): $authUrl');
    
    try {
      // This opens ASWebAuthenticationSession on iOS (in-app secure browser)
      // preferEphemeral: true creates isolated session (no shared cookies)
      // This ensures the account picker ALWAYS shows
      final resultUrl = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: callbackScheme,
        options: const FlutterWebAuth2Options(
          preferEphemeral: false, // Share cookies - shows account picker!
        ),
      );
      
      debugPrint('📱 OAuth callback received: $resultUrl');
      
      // Parse the callback URL
      final uri = Uri.parse(resultUrl);
      final sessionId = uri.queryParameters['session_id'];
      final error = uri.queryParameters['error'];
      
      if (error != null) {
        debugPrint('❌ OAuth error: $error');
        onAuthError?.call(error);
        return;
      }
      
      if (sessionId != null) {
        debugPrint('✅ OAuth session received');
        await _completeOAuthLogin(sessionId);
      } else {
        onAuthError?.call('No session received from sign in');
      }
    } catch (e) {
      debugPrint('❌ Apple OAuth cancelled or failed: $e');
      // User likely cancelled - don't show an error for cancellation
      if (e.toString().contains('CANCELED') || e.toString().contains('cancel')) {
        debugPrint('User cancelled OAuth');
      } else {
        onAuthError?.call('Sign in was cancelled');
      }
    }
  }
}
