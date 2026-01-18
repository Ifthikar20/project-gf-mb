import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import '../config/environment_config.dart';
import 'token_storage.dart';
import 'app_logger.dart';

/// Singleton API client with cookie-based authentication
/// Handles token refresh automatically via interceptors
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  late final CookieJar _cookieJar;
  
  // Store access token for Authorization header fallback
  String? _accessToken;
  
  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }
  
  ApiClient._() {
    _cookieJar = CookieJar();
    _dio = Dio(_baseOptions);
    
    // Add cookie manager for mobile (handles HttpOnly cookies)
    if (!kIsWeb) {
      _dio.interceptors.add(CookieManager(_cookieJar));
    }
    
    // Add auth interceptor for token refresh
    _dio.interceptors.add(_authInterceptor);
    
    // Add logging in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }
  
  /// Set access token (called after login)
  void setAccessToken(String? token) {
    _accessToken = token;
    AppLogger.auth('Access token ${token != null ? "set" : "cleared"}');
  }
  
  /// Get the current access token
  String? get accessToken => _accessToken;
  
  /// Check if we have an access token
  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;
  
  BaseOptions get _baseOptions => BaseOptions(
    baseUrl: EnvironmentConfig.instance.apiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    // Important: Allow cookies to be sent with requests

    extra: {'withCredentials': true},
  );
  
  // Flag to prevent infinite refresh loops
  bool _isRefreshing = false;
  
  InterceptorsWrapper get _authInterceptor => InterceptorsWrapper(
    onRequest: (options, handler) {
      // Add Authorization header if we have a token
      if (_accessToken != null && _accessToken!.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $_accessToken';
      }
      AppLogger.request(options.method, options.path);
      return handler.next(options);
    },
    onResponse: (response, handler) {
      AppLogger.response(
        response.statusCode,
        response.requestOptions.path,
        data: kDebugMode ? response.data : null, // Log response body in debug mode
      );
      return handler.next(response);
    },
    onError: (error, handler) async {
      final path = error.requestOptions.path;
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;
      final headers = error.response?.headers;

      // Skip refresh for auth endpoints to prevent infinite loops
      if (path.contains('/auth/')) {
        AppLogger.e(
          '❌ Auth endpoint failed: $path ($statusCode)\n'
          '📋 Response Body: $responseData\n'
          '📨 Response Headers: ${headers?.map}\n'
          '🔍 Error Type: ${error.type}\n'
          '💬 Error Message: ${error.message}',
          error: error,
        );
        return handler.reject(error);
      }
      
      // Handle 401 - try to refresh token (only if not already refreshing)
      if (error.response?.statusCode == 401 && !_isRefreshing) {
        _isRefreshing = true;
        try {
          AppLogger.auth('Attempting token refresh...');
          final refreshed = await _refreshToken();
          if (refreshed) {
            AppLogger.auth('Token refreshed, retrying request');
            // Update the request with new token
            error.requestOptions.headers['Authorization'] = 'Bearer $_accessToken';
            // Retry the original request
            final retryResponse = await _dio.fetch(error.requestOptions);
            _isRefreshing = false;
            return handler.resolve(retryResponse);
          } else {
            _isRefreshing = false;
            AppLogger.e('Token refresh returned no token');
            return handler.reject(error);
          }
        } catch (e) {
          _isRefreshing = false;
          AppLogger.e('Token refresh failed', error: e);
          return handler.reject(error);
        }
      }

      // Log all other errors with full details
      AppLogger.e(
        '❌ API Error: $path ($statusCode)\n'
        '📋 Response Body: $responseData\n'
        '🔍 Error Type: ${error.type}\n'
        '💬 Error Message: ${error.message}',
        error: error,
      );

      return handler.next(error);
    },
  );
  
  /// Refresh access token using stored refresh token
  Future<bool> _refreshToken() async {
    try {
      // Import is needed at runtime, but we'll use dynamic import pattern
      final tokenStorage = (await _getTokenStorage());
      final refreshToken = await tokenStorage.getRefreshToken();
      
      if (refreshToken == null || refreshToken.isEmpty) {
        AppLogger.w('No refresh token available');
        return false;
      }
      
      final response = await _dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      
      // Extract new access token from response
      if (response.statusCode == 200) {
        final setCookies = response.headers['set-cookie'];
        if (setCookies != null) {
          for (final cookie in setCookies) {
            if (cookie.startsWith('access_token=')) {
              final tokenStart = cookie.indexOf('=') + 1;
              final tokenEnd = cookie.indexOf(';');
              _accessToken = cookie.substring(tokenStart, tokenEnd > 0 ? tokenEnd : cookie.length);
              await tokenStorage.saveAccessToken(_accessToken!);
              AppLogger.auth('New access token saved');
              return true;
            }
          }
        }
        
        // Also check response body for token
        if (response.data['access_token'] != null) {
          _accessToken = response.data['access_token'];
          await tokenStorage.saveAccessToken(_accessToken!);
          AppLogger.auth('New access token saved from body');
          return true;
        }
      }
      
      return false;
    } catch (e) {
      AppLogger.e('Refresh token request failed', error: e);
      return false;
    }
  }
  
  // Helper to get TokenStorage (lazy import to avoid circular deps)
  dynamic _tokenStorageInstance;
  Future<dynamic> _getTokenStorage() async {
    _tokenStorageInstance ??= _createTokenStorage();
    return _tokenStorageInstance;
  }
  
  dynamic _createTokenStorage() {
    // This creates the TokenStorage instance
    return TokenStorage.instance;
  }
  
  /// Get the Dio instance for direct use
  Dio get dio => _dio;
  
  /// Get the current base URL
  String get baseUrl => _dio.options.baseUrl;
  
  /// Clear cookies (logout)
  Future<void> clearCookies() async {
    await _cookieJar.deleteAll();
  }
  
  /// Test connection to API
  /// Useful for debugging - call this to verify API is reachable
  Future<bool> testConnection() async {
    try {
      AppLogger.i('Testing connection to: ${_dio.options.baseUrl}');
      final response = await _dio.get('/health');
      AppLogger.i('API Health Check: ${response.statusCode} - ${response.data}');
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.e('API Connection Failed\nBase URL: ${_dio.options.baseUrl}\nTip: For iOS simulator, use your Mac IP instead of localhost', error: e);
      return false;
    }
  }
  
  // ============================================
  // Convenience HTTP Methods
  // ============================================
  
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }
  
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }
  
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return _dio.put<T>(path, data: data, options: options);
  }
  
  Future<Response<T>> delete<T>(
    String path, {
    Options? options,
  }) {
    return _dio.delete<T>(path, options: options);
  }
}
