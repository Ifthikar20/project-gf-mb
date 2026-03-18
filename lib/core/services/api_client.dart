import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/environment_config.dart';
import 'app_logger.dart';

/// Singleton API client with DRF Token authentication
/// Uses `Authorization: Token <key>` header (not Bearer)
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  
  // Store DRF auth token for Authorization header
  String? _accessToken;
  
  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }
  
  ApiClient._() {
    _dio = Dio(_baseOptions);
    
    // Add auth interceptor
    _dio.interceptors.add(_authInterceptor);
    
    // Note: AppLogger handles request/response logging in the auth interceptor.
    // No extra LogInterceptor needed — it was duplicating every call.
  }
  
  /// Set access token (called after login/register/OAuth)
  void setAccessToken(String? token) {
    _accessToken = token;
    AppLogger.auth('Access token ${token != null ? "set" : "cleared"}');
  }
  
  /// Get the current access token
  String? get accessToken => _accessToken;
  
  /// Check if we have an access token
  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;
  
  BaseOptions get _baseOptions {
    final appKey = EnvironmentConfig.instance.clientId;
    return BaseOptions(
      baseUrl: EnvironmentConfig.instance.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (appKey.isNotEmpty) 'X-Client-Id': appKey,
      },
    );
  }
  
  InterceptorsWrapper get _authInterceptor => InterceptorsWrapper(
    onRequest: (options, handler) {
      // Add DRF Token auth header (not Bearer!)
      if (_accessToken != null && _accessToken!.isNotEmpty) {
        options.headers['Authorization'] = 'Token $_accessToken';
      }
      AppLogger.request(options.method, options.path);
      return handler.next(options);
    },
    onResponse: (response, handler) {
      AppLogger.response(
        response.statusCode,
        response.requestOptions.path,
        data: kDebugMode ? response.data : null,
      );
      return handler.next(response);
    },
    onError: (error, handler) async {
      final path = error.requestOptions.path;
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;

      // Compact error logging — only full detail for 500+ server errors
      if (statusCode != null && statusCode >= 500) {
        debugPrint('🔥 $statusCode $path — server error');
      } else {
        debugPrint('⛔ ${statusCode ?? '?'} $path — $responseData');
      }

      return handler.next(error);
    },
  );
  
  /// Get the Dio instance for direct use
  Dio get dio => _dio;
  
  /// Get the current base URL
  String get baseUrl => _dio.options.baseUrl;
  
  /// Test connection to API
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
  
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return _dio.patch<T>(path, data: data, options: options);
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
