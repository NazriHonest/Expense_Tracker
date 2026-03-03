import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Global error types
enum ErrorType { network, authentication, validation, database, unknown }

/// Error event for tracking
class ErrorEvent {
  final ErrorType type;
  final String message;
  final String? stackTrace;
  final DateTime timestamp;
  final String? context;

  ErrorEvent({
    required this.type,
    required this.message,
    this.stackTrace,
    this.context,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return '[$type] $message${context != null ? ' (Context: $context)' : ''}';
  }
}

/// Global error handler service
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final List<ErrorEvent> _errorHistory = [];
  final StreamController<ErrorEvent> _errorController =
      StreamController<ErrorEvent>.broadcast();
  final int _maxHistorySize = 50;

  Stream<ErrorEvent> get errorStream => _errorController.stream;
  List<ErrorEvent> get errorHistory => List.unmodifiable(_errorHistory);

  /// Initialize global error handlers
  void initialize() {
    // Flutter error handler
    FlutterError.onError = (details) {
      handleError(
        details.exceptionAsString(),
        type: ErrorType.unknown,
        context: 'Flutter Error',
        stackTrace: details.stack?.toString(),
      );
    };

    // Platform dispatcher error handler
    PlatformDispatcher.instance.onError = (error, stack) {
      handleError(
        error.toString(),
        type: ErrorType.unknown,
        context: 'Platform Error',
        stackTrace: stack.toString(),
      );
      return true; // Continue execution
    };

    debugPrint('🛡️ ErrorHandler initialized');
  }

  /// Handle error with context
  void handleError(
    String message, {
    ErrorType type = ErrorType.unknown,
    String? context,
    String? stackTrace,
    bool logToConsole = true,
  }) {
    final event = ErrorEvent(
      type: type,
      message: message,
      stackTrace: stackTrace,
      context: context,
    );

    // Add to history
    _errorHistory.add(event);
    if (_errorHistory.length > _maxHistorySize) {
      _errorHistory.removeAt(0);
    }

    // Emit to stream
    _errorController.add(event);

    // Log to console
    if (logToConsole) {
      _logError(event);
    }
  }

  /// Handle Dio/network errors
  void handleNetworkError(dynamic error, {String? context}) {
    String message = 'Network error occurred';

    if (error.toString().contains('SocketException') ||
        error.toString().contains('Network')) {
      message = 'No internet connection. Please check your network.';
      handleError(message, type: ErrorType.network, context: context);
    } else if (error.toString().contains('timeout')) {
      message = 'Request timed out. Please try again.';
      handleError(message, type: ErrorType.network, context: context);
    } else {
      handleError(error.toString(), type: ErrorType.network, context: context);
    }
  }

  /// Handle authentication errors
  void handleAuthError(String message, {String? context}) {
    handleError(message, type: ErrorType.authentication, context: context);
  }

  /// Handle validation errors
  void handleValidationError(String message, {String? context}) {
    handleError(message, type: ErrorType.validation, context: context);
  }

  /// Handle database errors
  void handleDatabaseError(String message, {String? context}) {
    handleError(message, type: ErrorType.database, context: context);
  }

  /// Log error to console
  void _logError(ErrorEvent event) {
    final emoji = _getErrorEmoji(event.type);
    debugPrint('$emoji ${event.toString()}');
    if (event.stackTrace != null && kDebugMode) {
      debugPrint('📋 Stack trace:\n${event.stackTrace}');
    }
  }

  String _getErrorEmoji(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return '📡';
      case ErrorType.authentication:
        return '🔐';
      case ErrorType.validation:
        return '⚠️';
      case ErrorType.database:
        return '💾';
      case ErrorType.unknown:
        return '❌';
    }
  }

  /// Get user-friendly error message
  static String getFriendlyMessage(ErrorType type, String message) {
    switch (type) {
      case ErrorType.network:
        return 'Unable to connect to server. Please check your internet connection.';
      case ErrorType.authentication:
        return 'Authentication failed. Please log in again.';
      case ErrorType.validation:
        return message; // Already user-friendly
      case ErrorType.database:
        return 'Failed to save data. Please try again.';
      case ErrorType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }

  /// Get color for error type
  static Color getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.authentication:
        return Colors.red;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.database:
        return Colors.brown;
      case ErrorType.unknown:
        return Colors.grey;
    }
  }

  /// Clear error history
  void clearHistory() {
    _errorHistory.clear();
    debugPrint('🗑️ Error history cleared');
  }

  /// Get error count by type
  Map<ErrorType, int> getErrorCounts() {
    final counts = <ErrorType, int>{};
    for (final event in _errorHistory) {
      counts[event.type] = (counts[event.type] ?? 0) + 1;
    }
    return counts;
  }

  /// Dispose resources
  void dispose() {
    _errorController.close();
  }
}

/// Extension for async operations with error handling
extension AsyncErrorHandling<T> on Future<T> {
  Future<T> handleErrors({
    Function(String error)? onError,
    ErrorType type = ErrorType.unknown,
    String? context,
  }) async {
    try {
      return await this;
    } catch (e) {
      ErrorHandler().handleError(e.toString(), type: type, context: context);
      if (onError != null) {
        onError(e.toString());
      }
      rethrow;
    }
  }
}
