import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_monaco/src/platform/platform_webview_interface.dart';
import 'package:flutter_monaco/src/platform/web_view_controller/web_view_controller.dart'
    as base;

// Export the interface so consumers can use it
export 'platform_webview_interface.dart';

/// Factory for creating platform-specific [PlatformWebViewController] instances.
///
/// This factory abstracts away platform detection and returns the appropriate
/// WebView implementation for the current platform. Use this instead of
/// directly instantiating platform-specific controllers.
///
/// ### Example
///
/// ```dart
/// final controller = PlatformWebViewFactory.createController();
/// await controller.initialize();
/// await controller.load();
/// ```
///
/// ### Testing
///
/// Use [debugCreateOverride] to inject mock controllers in tests:
///
/// ```dart
/// PlatformWebViewFactory.debugCreateOverride = () => MockWebViewController();
/// ```
///
/// See also:
/// - [PlatformWebViewController] for the interface contract.
/// - [WebViewController] for the forwarding implementation.
class PlatformWebViewFactory {
  /// Test hook to override controller creation with a mock implementation.
  ///
  /// Set this before creating controllers in tests, and reset to `null`
  /// after each test to avoid cross-test contamination.
  @visibleForTesting
  static PlatformWebViewController Function()? debugCreateOverride;

  /// Creates a new [PlatformWebViewController] for the current platform.
  ///
  /// On native platforms, this returns a controller backed by `webview_flutter`
  /// (Android/iOS/macOS) or `webview_flutter_windows` (Windows). On web, it returns
  /// an iframe-based controller.
  ///
  /// If [debugCreateOverride] is set, returns the result of that function
  /// instead, allowing test mocking.
  static PlatformWebViewController createController() {
    final override = debugCreateOverride;
    if (override != null) {
      return override();
    }

    return WebViewController();
  }
}

/// Forwarding implementation of [PlatformWebViewController].
///
/// This class delegates all operations to the platform-specific
/// [base.WebViewController] selected at compile time via conditional exports.
/// It provides a stable API surface while allowing the underlying
/// implementation to vary by platform.
///
/// **Note:** This class is internal. Use [PlatformWebViewFactory.createController]
/// to obtain instances.
///
/// See also:
/// - [web_view_controller.dart] for the conditional export logic.
/// - [FlutterWebViewController] for Android/iOS/macOS implementation.
/// - [WindowsWebViewController] for Windows implementation.
class WebViewController implements PlatformWebViewController {
  /// Creates a controller that forwards to the platform-specific implementation.
  WebViewController() : _controller = base.WebViewController();

  final base.WebViewController _controller;

  @override
  Widget get widget => _controller.widget;

  @override
  Future<void> initialize() => _controller.initialize();

  @override
  Future<void> load({String? customCss, bool allowCdnFonts = false}) {
    return _controller.load(customCss: customCss, allowCdnFonts: allowCdnFonts);
  }

  @override
  void dispose() {
    return _controller.dispose();
  }

  @override
  Future<void> enableJavaScript() => _controller.enableJavaScript();

  @override
  Future<Object?> addJavaScriptChannel(
    String name,
    void Function(String p1) onMessage,
  ) {
    return _controller.addJavaScriptChannel(name, onMessage);
  }

  @override
  Future<Object?> removeJavaScriptChannel(String name) {
    return _controller.removeJavaScriptChannel(name);
  }

  @override
  Future<Object?> runJavaScript(String script) {
    return _controller.runJavaScript(script);
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String script) {
    return _controller.runJavaScriptReturningResult(script);
  }

  @override
  Future<void> setBackgroundColor(Color color) =>
      _controller.setBackgroundColor(color);

  @override
  Future<void> setInteractionEnabled(bool enabled) =>
      _controller.setInteractionEnabled(enabled);

  @override
  Future<void> requestNativeFocus() => _controller.requestNativeFocus();
}

/// Normalizes WebView2 `ExecuteScript` results to Dart-friendly types.
///
/// WebView2 wraps JavaScript return values in JSON encoding, which means:
/// - Strings come back double-quoted: `"hello"` instead of `hello`
/// - `null` comes back as the literal string `"null"`
/// - Objects/arrays may already be JSON strings
///
/// This function handles these cases:
/// 1. Non-string results are returned as-is
/// 2. The literal string `"null"` becomes Dart `null`
/// 3. JSON-encoded strings (`"value"`) are decoded to plain strings
/// 4. Other values are returned unchanged
///
/// ### Example
///
/// ```dart
/// // WebView2 returns: "\"hello\""
/// parseWindowsScriptResult('"hello"'); // Returns: 'hello'
///
/// // WebView2 returns: "null"
/// parseWindowsScriptResult('null'); // Returns: null
///
/// // WebView2 returns: "42"
/// parseWindowsScriptResult('42'); // Returns: '42' (still a string)
/// ```
///
/// See also:
/// - [WindowsWebViewController.runJavaScriptReturningResult] which uses this.
Object? parseWindowsScriptResult(Object? result) {
  if (result is! String) return result;

  final trimmed = result.trim();
  if (trimmed.isEmpty) return result;

  if (trimmed == 'null') return null;

  if (trimmed.length >= 2 && trimmed.startsWith('"') && trimmed.endsWith('"')) {
    try {
      return json.decode(trimmed);
    } catch (_) {
      return trimmed.substring(1, trimmed.length - 1);
    }
  }

  return result;
}
