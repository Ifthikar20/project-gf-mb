import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
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

  
  /// Launch Google Sign In
  Future<void> signInWithGoogle() async {
    const baseUrl = 'https://api.betterandbliss.com';
    const redirectUri = 'betterbliss://auth/callback';
    
    final url = Uri.parse('$baseUrl/auth/google?redirect=$redirectUri');
    
    debugPrint('🔐 Launching Google OAuth: $url');
    
    try {
      // Check if we can launch the URL
      final canLaunch = await canLaunchUrl(url);
      debugPrint('📱 Can launch URL: $canLaunch');
      
      if (!canLaunch) {
        debugPrint('❌ Cannot launch URL - check LSApplicationQueriesSchemes in Info.plist');
        onAuthError?.call('Cannot open browser for sign in');
        return;
      }
      
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      
      debugPrint('📱 URL launch result: $launched');
      
      if (!launched) {
        onAuthError?.call('Could not launch browser for sign in');
      }
    } catch (e) {
      debugPrint('❌ Failed to launch Google OAuth: $e');
      onAuthError?.call('Failed to launch sign in: $e');
    }
  }
  
  /// Launch Apple Sign In
  Future<void> signInWithApple() async {
    const baseUrl = 'https://api.betterandbliss.com';
    const redirectUri = 'betterbliss://auth/callback';
    
    final url = Uri.parse('$baseUrl/auth/apple?redirect=$redirectUri');
    
    debugPrint('🔐 Launching Apple OAuth: $url');
    
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        onAuthError?.call('Could not launch browser for sign in');
      }
    } catch (e) {
      debugPrint('❌ Failed to launch Apple OAuth: $e');
      onAuthError?.call('Failed to launch sign in');
    }
  }
}
