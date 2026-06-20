import 'package:flutter/widgets.dart';
import 'package:flutter_monaco/src/platform/platform_webview.dart';

/// Fallback stub implementation for unsupported platforms.
///
/// This class exists to satisfy the type system when compiling for platforms
/// where neither `dart:io` nor `dart:js_interop` is available. All methods
/// throw [UnsupportedError] to provide clear failure messages.
///
/// **When this is used:**
/// - Platforms without WebView support (e.g., some embedded systems)
/// - Compilation targets not covered by the conditional exports
///
/// If you encounter errors from this stub, verify that:
/// 1. You're running on a supported platform (Android, iOS, macOS, Windows, Web)
/// 2. The `webview_flutter` or `webview_flutter_windows` dependencies are properly configured
///
/// See also:
/// - [web_view_controller.dart] for the conditional export logic.
/// - [native.dart] for Android/iOS/macOS/Windows implementations.
/// - [web.dart] for the web implementation.
class WebViewController implements PlatformWebViewController {
  @override
  Widget get widget =>
      throw UnsupportedError('WebView not supported on this platform');

  @override
  Future<void> initialize() {
    throw UnsupportedError('WebView not supported on this platform');
  }

  @override
  Future<void> enableJavaScript() {
    throw UnsupportedError('WebView not supported on this platform');
  }

  @override
  Future<Object?> runJavaScript(String script) {
    throw UnsupportedError('WebView not supported on this platform');
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String script) {
    throw UnsupportedError('WebView not supported on this platform');
  }

  @override
  Future<Object?> addJavaScriptChannel(
    String name,
    void Function(String) onMessage,
  ) {
    throw UnsupportedError('WebView not supported on this platform');
  }

  @override
  Future<Object?> removeJavaScriptChannel(String name) {
    throw UnsupportedError('WebView not supported on this platform');
  }

  @override
  Future<void> setBackgroundColor(Color color) {
    throw UnsupportedError('WebView not supported on this platform');
  }

  @override
  Future<void> setInteractionEnabled(bool enabled) {
    throw UnsupportedError('WebView not supported on this platform');
  }

  @override
  Future<void> requestNativeFocus() {
    throw UnsupportedError('WebView not supported on this platform');
  }

  @override
  void dispose() {
    throw UnsupportedError('WebView not supported on this platform');
  }

  @override
  Future<void> load({String? customCss, bool allowCdnFonts = false}) {
    throw UnsupportedError('WebView not supported on this platform');
  }
}
