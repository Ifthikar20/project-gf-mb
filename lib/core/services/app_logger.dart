import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logger for the app with pretty console output
/// 
/// Usage:
/// ```dart
/// AppLogger.d("Debug message");
/// AppLogger.i("Info message");
/// AppLogger.w("Warning message");
/// AppLogger.e("Error message", error: error, stackTrace: stackTrace);
/// ```
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,        // Number of method calls to show
      errorMethodCount: 8,   // Number of method calls for errors
      lineLength: 120,       // Width of log output
      colors: true,          // Colorful log messages
      printEmojis: true,     // Print emojis for log levels
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kDebugMode ? Level.trace : Level.warning, // Only show warnings+ in release
  );

  /// Log a trace message (most verbose)
  static void t(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// Log a debug message
  static void d(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log an info message
  static void i(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log a warning message
  static void w(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log an error message
  static void e(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log a fatal/critical error
  static void f(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  // ============================================
  // Convenience methods for API/Network logging
  // ============================================

  /// Log an outgoing API request
  static void request(String method, String path, {dynamic data}) {
    _logger.i('📤 $method $path${data != null ? '\n$data' : ''}');
  }

  /// Log an incoming API response
  static void response(int? statusCode, String path, {dynamic data}) {
    _logger.i('📥 $statusCode $path${data != null ? '\n$data' : ''}');
  }

  /// Log an API error
  static void apiError(String path, {int? statusCode, Object? error}) {
    _logger.e('❌ API Error: $path (${statusCode ?? 'unknown'})', error: error);
  }

  /// Log authentication events
  static void auth(String message) {
    _logger.i('🔐 $message');
  }

  /// Log navigation events  
  static void nav(String message) {
    _logger.d('🧭 $message');
  }
}
