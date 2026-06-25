import 'package:flutter/foundation.dart';

enum AppLogLevel { debug, info, warning, error }

/// Logger applicatif centralise.
///
/// - `debug`: uniquement en debug.
/// - `info`/`warning`/`error`: actifs en debug et release.
abstract final class AppLogger {
  static final RegExp _sensitiveInlinePattern = RegExp(
    r'\b(token|refresh[_-]?token|authorization|cookie|password|passwd|secret|api[_-]?key|email)\b\s*[:=]\s*([^\s,;]+)',
    caseSensitive: false,
  );

  static final RegExp _bearerPattern = RegExp(
    r'bearer\s+[a-z0-9\-._~+/]+=*',
    caseSensitive: false,
  );

  static void debug(String message, {String scope = 'APP'}) {
    _log(level: AppLogLevel.debug, scope: scope, message: message);
  }

  static void info(String message, {String scope = 'APP'}) {
    _log(level: AppLogLevel.info, scope: scope, message: message);
  }

  static void warning(String message, {String scope = 'APP'}) {
    _log(level: AppLogLevel.warning, scope: scope, message: message);
  }

  static void error(
    String message, {
    String scope = 'APP',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      level: AppLogLevel.error,
      scope: scope,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _log({
    required AppLogLevel level,
    required String scope,
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level == AppLogLevel.debug && !kDebugMode) return;

    final levelLabel = level.name.toUpperCase();
    final normalizedScope = scope.trim().isEmpty ? 'APP' : scope.trim();
    debugPrint('[$normalizedScope][$levelLabel] ${_sanitize(message)}');
    if (error != null) {
      debugPrint(
        '[$normalizedScope][$levelLabel] error=${_sanitize(error.toString())}',
      );
    }
    if (stackTrace != null) {
      debugPrintStack(
        label: '[$normalizedScope][$levelLabel] stacktrace',
        stackTrace: stackTrace,
      );
    }
  }

  static String _sanitize(String input) {
    var sanitized = input.replaceAllMapped(
      _sensitiveInlinePattern,
      (match) => '${match.group(1)}=<redacted>',
    );
    sanitized = sanitized.replaceAll(_bearerPattern, 'Bearer <redacted>');
    return sanitized;
  }
}
