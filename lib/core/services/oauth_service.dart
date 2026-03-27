import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:app_links/app_links.dart';
import '../config/environment_config.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'token_storage.dart';

/// OAuth Service for handling social login (Google, Apple)
/// Deep link callback now returns `token` (DRF Token) instead of `session_id`
class OAuthService {
  static OAuthService? _instance;
  final ApiClient _api;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  
  // Callback for when OAuth completes
  Function(User user)? onAuthSuccess;
  Function(String error)? onAuthError;

  // CSRF protection: pending state nonce for CSRF validation
  String? _pendingState;
  
  static OAuthService get instance {
    _instance ??= OAuthService._(ApiClient.instance);
    return _instance!;
  }
  
  OAuthService._(this._api);
  
  /// Initialize deep link listening
  Future<void> initialize() async {
    // Handle cold start — app was launched by a link
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
    debugPrint(' Received deep link: $uri');
    
    // Check if this is an auth callback
    if (uri.scheme == 'betterbliss' && uri.host == 'auth') {
      final token = uri.queryParameters['token'];
      final error = uri.queryParameters['error'];
      
      if (error != null) {
        debugPrint(' OAuth error: $error');
        onAuthError?.call(error);
        return;
      }
      
      if (token != null) {
        debugPrint(' OAuth token received');
        await _completeOAuthLogin(token);
      }
    }
  }
  
  /// Complete OAuth login with DRF token
  Future<void> _completeOAuthLogin(String token) async {
    try {
      // Store the DRF token
      _api.setAccessToken(token);
      
      final tokenStorage = TokenStorage.instance;
      await tokenStorage.saveAccessToken(token);
      debugPrint(' OAuth DRF token saved');
      
      // Fetch user info from /auth/me
      final response = await _api.get('/auth/me');
      
      if (response.data != null) {
        final userData = response.data['user'] ?? response.data;
        final user = User.fromJson(userData);
        
        // Save user data for session persistence
        await tokenStorage.saveUserData(jsonEncode(user.toJson()));
        debugPrint(' OAuth login complete: ${user.email}');
        
        onAuthSuccess?.call(user);
      }
    } catch (e) {
      debugPrint(' Failed to complete OAuth: $e');
      onAuthError?.call('Failed to complete sign in');
    }
  }

  /// Get the API base URL from environment config
  String get _baseUrl => EnvironmentConfig.instance.apiBaseUrl;
  
  /// Launch Google Sign In
  Future<void> signInWithGoogle() async {
    const callbackScheme = 'betterbliss';

    // Generate state nonce for CSRF protection
    final stateBytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final state = base64Url.encode(stateBytes);
    _pendingState = state;

    final authUrl = '$_baseUrl/auth/google?redirect=$callbackScheme://auth/callback&prompt=select_account&state=$state';

    debugPrint('[OAuth] Launching Google OAuth');

    try {
      final resultUrl = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: callbackScheme,
        options: const FlutterWebAuth2Options(
          preferEphemeral: false,
        ),
      );

      debugPrint('[OAuth] Callback received successfully');

      // Validate state nonce to prevent CSRF
      final callbackState = Uri.parse(resultUrl).queryParameters['state'];
      if (callbackState != _pendingState) {
        _pendingState = null;
        throw Exception('OAuth state mismatch — possible CSRF attack');
      }
      _pendingState = null;

      final uri = Uri.parse(resultUrl);
      final returnedState = uri.queryParameters['state'];
      final token = uri.queryParameters['token'];
      final error = uri.queryParameters['error'];

      // Validate CSRF state (FIX 6)
      if (returnedState != _pendingState) {
        _pendingState = null;
        onAuthError?.call('OAuth state mismatch — possible CSRF attack');
        return;
      }
      _pendingState = null;

      if (error != null) {
        debugPrint(' OAuth error: $error');
        onAuthError?.call(error);
        return;
      }

      if (token != null) {
        debugPrint(' OAuth token received');
        await _completeOAuthLogin(token);
      } else {
        onAuthError?.call('No token received from sign in');
      }
    } catch (e) {
      _pendingState = null;
      debugPrint(' Google OAuth cancelled or failed: $e');
      if (e.toString().contains('CANCELED') || e.toString().contains('cancel')) {
        debugPrint('User cancelled OAuth');
      } else {
        onAuthError?.call('Sign in was cancelled');
      }
    }
  }
  
  /// Launch Apple Sign In
  Future<void> signInWithApple() async {
    const callbackScheme = 'betterbliss';

    // Generate state nonce for CSRF protection
    final stateBytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final state = base64Url.encode(stateBytes);
    _pendingState = state;

    final authUrl = '$_baseUrl/auth/apple?redirect=$callbackScheme://auth/callback&state=$state';

    debugPrint('[OAuth] Launching Apple OAuth');

    try {
      final resultUrl = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: callbackScheme,
        options: const FlutterWebAuth2Options(
          preferEphemeral: false,
        ),
      );

      debugPrint('[OAuth] Callback received successfully');

      // Validate state nonce to prevent CSRF
      final callbackState = Uri.parse(resultUrl).queryParameters['state'];
      if (callbackState != _pendingState) {
        _pendingState = null;
        throw Exception('OAuth state mismatch — possible CSRF attack');
      }
      _pendingState = null;

      final uri = Uri.parse(resultUrl);
      final returnedState = uri.queryParameters['state'];
      final token = uri.queryParameters['token'];
      final error = uri.queryParameters['error'];

      // Validate CSRF state (FIX 6)
      if (returnedState != _pendingState) {
        _pendingState = null;
        onAuthError?.call('OAuth state mismatch — possible CSRF attack');
        return;
      }
      _pendingState = null;

      if (error != null) {
        debugPrint(' OAuth error: $error');
        onAuthError?.call(error);
        return;
      }

      if (token != null) {
        debugPrint(' OAuth token received');
        await _completeOAuthLogin(token);
      } else {
        onAuthError?.call('No token received from sign in');
      }
    } catch (e) {
      _pendingState = null;
      debugPrint(' Apple OAuth cancelled or failed: $e');
      if (e.toString().contains('CANCELED') || e.toString().contains('cancel')) {
        debugPrint('User cancelled OAuth');
      } else {
        onAuthError?.call('Sign in was cancelled');
      }
    }
  }
}
