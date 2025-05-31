// lib/config/app_logger.dart
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  verbose,
}

class AppLogger {
  static bool _isEnabled = true;
  static LogLevel _minLevel = LogLevel.debug;

  // Enable/disable logging
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  // Set minimum log level
  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  // Check if logging is enabled for this level
  static bool _shouldLog(LogLevel level) {
    if (!_isEnabled) return false;
    return level.index >= _minLevel.index;
  }

  // Get log level emoji for better visibility
  static String _getLevelEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.verbose:
        return '📝';
    }
  }

  // Get log level name
  static String _getLevelName(LogLevel level) {
    return level.name.toUpperCase();
  }

  // Core logging method
  static void _log(LogLevel level, String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (!_shouldLog(level)) return;

    final timestamp = DateTime.now().toIso8601String();
    final emoji = _getLevelEmoji(level);
    final levelName = _getLevelName(level);
    final tagPrefix = tag != null ? '[$tag] ' : '';

    final logMessage = '$emoji [$timestamp] $levelName: $tagPrefix$message';

    // In debug mode, use developer.log for better debugging
    if (kDebugMode) {
      developer.log(
        message,
        time: DateTime.now(),
        level: _getDeveloperLogLevel(level),
        name: tag ?? 'DebtTracker',
        error: error,
        stackTrace: stackTrace,
      );
    }

    // Always print to console for visibility
    print(logMessage);

    // Print structured data if provided
    if (data != null && data.isNotEmpty) {
      print('📊 Data: $data');
    }

    if (error != null) {
      print('💥 Error: $error');
    }

    if (stackTrace != null) {
      print('📚 Stack Trace: $stackTrace');
    }
  }

  // Convert our log level to developer log level
  static int _getDeveloperLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.verbose:
        return 400;
    }
  }

  // Public logging methods
  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace, data: data);
  }

  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace, data: data);
  }

  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace, data: data);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace, data: data);
  }

  static void verbose(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    _log(LogLevel.verbose, message, tag: tag, error: error, stackTrace: stackTrace, data: data);
  }

  // Convenience methods for common scenarios
  static void apiRequest(String method, String url, {Map<String, dynamic>? data}) {
    info('🌐 API $method: $url', tag: 'API');
    if (data != null && data.isNotEmpty) {
      debug('📤 Request Data: $data', tag: 'API');
    }
  }

  static void apiResponse(String method, String url, int statusCode, {dynamic response}) {
    if (statusCode >= 200 && statusCode < 300) {
      info('✅ API $method Response: $statusCode for $url', tag: 'API');
    } else {
      warning('⚠️ API $method Response: $statusCode for $url', tag: 'API');
    }
    if (response != null) {
      debug('📥 Response Data: $response', tag: 'API');
    }
  }

  static void apiError(String method, String url, Object error, {StackTrace? stackTrace}) {
    AppLogger.error('💥 API $method Error for $url', tag: 'API', error: error, stackTrace: stackTrace);
  }

  static void authEvent(String event, {Map<String, dynamic>? data}) {
    info('🔐 Auth Event: $event', tag: 'AUTH', data: data);
  }

  static void navigation(String from, String to) {
    info('🧭 Navigation: $from → $to', tag: 'NAVIGATION');
  }

  static void userAction(String action, {Map<String, dynamic>? context}) {
    info('👆 User Action: $action', tag: 'USER', data: context);
  }

  static void dataOperation(String operation, String type, {String? id, bool success = true, Map<String, dynamic>? data}) {
    final emoji = success ? '✅' : '❌';
    final status = success ? 'SUCCESS' : 'FAILED';
    final idInfo = id != null ? ' (ID: $id)' : '';
    info('$emoji Data $operation $type$idInfo - $status', tag: 'DATA', data: data);
  }

  static void performance(String operation, Duration duration, {Map<String, dynamic>? data}) {
    final ms = duration.inMilliseconds;
    final emoji = ms < 1000 ? '⚡' : ms < 3000 ? '🐌' : '🐢';
    info('$emoji Performance: $operation took ${ms}ms', tag: 'PERF', data: data);
  }

  // Method to log app lifecycle events
  static void lifecycle(String event, {Map<String, dynamic>? data}) {
    info('🔄 App Lifecycle: $event', tag: 'LIFECYCLE', data: data);
  }

  // Method to log cache operations
  static void cache(String operation, String key, {bool hit = false, Map<String, dynamic>? data}) {
    final emoji = hit ? '🎯' : '💾';
    info('$emoji Cache $operation: $key', tag: 'CACHE', data: data);
  }

  // Method to log validation errors
  static void validation(String field, String error, {Map<String, dynamic>? data}) {
    warning('📝 Validation Error - $field: $error', tag: 'VALIDATION', data: data);
  }

  // Method to log network connectivity
  static void network(String status, {Map<String, dynamic>? data}) {
    final emoji = status.toLowerCase().contains('connected') ? '🌐' : '📡';
    info('$emoji Network: $status', tag: 'NETWORK', data: data);
  }
}