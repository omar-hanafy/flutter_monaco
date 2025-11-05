import 'dart:async';

/// Unified interface for all platform WebView implementations
abstract class PlatformWebViewController {
  /// Execute JavaScript code without expecting a return value
  Future<Object?> runJavaScript(String script);

  /// Execute JavaScript and return the result
  Future<Object?> runJavaScriptReturningResult(String script);

  /// Add a JavaScript channel for communication between JS and Flutter
  Future<Object?> addJavaScriptChannel(
    String name,
    void Function(String) onMessage,
  );

  /// Remove a JavaScript channel
  Future<Object?> removeJavaScriptChannel(String name);

  /// Clean up resources
  void dispose();
}
