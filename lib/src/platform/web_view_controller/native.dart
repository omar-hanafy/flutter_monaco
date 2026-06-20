import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_monaco/src/platform/platform_webview.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart' as wf;
import 'package:webview_flutter_windows/webview_flutter_windows.dart' as ww;

/// Base class for native platform WebView implementations.
///
/// This abstract class provides shared functionality for native platforms
/// (Android, iOS, macOS, Windows) and uses a factory constructor to return
/// the appropriate concrete implementation based on the current OS.
///
/// ### Platform Selection
///
/// - **Windows:** Returns [WindowsWebViewController] using `webview_flutter_windows`
///   (Microsoft Edge WebView2 runtime).
/// - **Android/iOS/macOS:** Returns [FlutterWebViewController] using
///   `webview_flutter` with platform-specific WebView implementations.
///
/// ### Shared Behavior
///
/// The [_ensureHtmlFile] method is shared across all native implementations.
/// It generates platform-specific HTML (with correct paths for Monaco assets)
/// and caches it to disk for faster subsequent loads.
///
/// See also:
/// - [FlutterWebViewController] for Android/iOS/macOS implementation.
/// - [WindowsWebViewController] for Windows implementation.
/// - [MonacoAssets] for HTML generation and asset management.
abstract class WebViewController implements PlatformWebViewController {
  /// Creates the appropriate native controller for the current platform.
  ///
  /// Returns [WindowsWebViewController] on Windows, or
  /// [FlutterWebViewController] on Android, iOS, and macOS.
  factory WebViewController() {
    if (Platform.isWindows) {
      return WindowsWebViewController();
    } else {
      return FlutterWebViewController();
    }
  }

  const WebViewController._();

  @override
  Future<void> requestNativeFocus() async {
    // No-op by default. webview_flutter platforms participate in the regular
    // platform focus system; only Windows needs an explicit handoff.
  }

  /// Generates and caches the Monaco editor HTML file for native platforms.
  ///
  /// This method:
  /// 1. Computes a cache key from [customCss] and [allowCdnFonts]
  /// 2. Returns the cached file path if it already exists
  /// 3. Generates platform-specific HTML with correct asset paths
  /// 4. Writes the HTML to the cache directory
  ///
  /// **Platform differences:**
  /// - Windows uses absolute `file://` paths since HTML is loaded via URL
  /// - macOS/iOS uses relative paths since HTML is in the same directory
  ///
  /// Returns the absolute path to the generated HTML file.
  Future<String> _ensureHtmlFile({
    String? customCss,
    bool allowCdnFonts = false,
  }) async {
    final htmlFilePath = await MonacoAssets.indexHtmlPath(
      cacheKey: Object.hash(
        MonacoAssets.htmlGenerationVersion,
        customCss,
        allowCdnFonts,
      ),
    );

    // Use cache key in filename to avoid conflicts.
    final htmlFile = File(htmlFilePath);

    // Skip if file already exists (cached).
    if (htmlFile.existsSync()) {
      debugPrint('[MonacoAssets] Using cached HTML file: ${htmlFile.path}');
      return htmlFilePath;
    }

    // Generate platform-specific HTML
    String htmlContent;

    if (Platform.isWindows) {
      final targetDir = p.dirname(htmlFilePath);

      // Windows needs absolute paths since we load from file://
      final vsPath = p.join(targetDir, 'min', 'vs');
      final absoluteVsPath = Uri.file(vsPath).toString();
      htmlContent = MonacoAssets.generateIndexHtml(
        absoluteVsPath,
        isWindows: true,
        isIosOrMacOS: false,
        customCss: customCss,
        allowCdnFonts: allowCdnFonts,
      );
    } else {
      // macOS uses relative paths since HTML is in the same directory
      htmlContent = MonacoAssets.generateIndexHtml(
        p.join('min', 'vs'),
        isWindows: false,
        isIosOrMacOS: Platform.isIOS || Platform.isMacOS,
        customCss: customCss,
        allowCdnFonts: allowCdnFonts,
      );
    }

    // Write the HTML file
    await htmlFile.writeAsString(htmlContent);

    debugPrint('[MonacoAssets] HTML file created at: ${htmlFile.path}');
    return htmlFilePath;
  }
}

/// WebView implementation for Android, iOS, and macOS using `webview_flutter`.
///
/// This controller wraps the `webview_flutter` package to provide Monaco editor
/// hosting on mobile and desktop Apple platforms. It uses platform-specific
/// WebView implementations under the hood:
///
/// - **Android:** Android WebView
/// - **iOS:** WKWebView
/// - **macOS:** WKWebView
///
/// ### JavaScript Communication
///
/// Communication with Monaco uses `JavaScriptChannel` which creates a
/// `window.[channelName]` object in JavaScript. Messages sent via
/// `window.flutterChannel.postMessage(msg)` are received in the [onMessage]
/// callback passed to [addJavaScriptChannel].
///
/// ### File Loading
///
/// Monaco HTML is loaded from the local filesystem using [loadFile]. The HTML
/// file is generated by [_ensureHtmlFile] with platform-appropriate paths
/// for Monaco assets.
///
/// See also:
/// - [WindowsWebViewController] for Windows-specific implementation.
/// - [wf.WebViewController] for the underlying Flutter WebView controller.
class FlutterWebViewController extends WebViewController {
  /// Creates a new controller backed by `webview_flutter`.
  FlutterWebViewController() : super._() {
    _controller = wf.WebViewController();
  }

  @override
  Widget get widget => wf.WebViewWidget(controller: _controller);

  late final wf.WebViewController _controller;
  bool _disposed = false;

  /// Provides direct access to the underlying `webview_flutter` controller.
  ///
  /// Use this for advanced operations not exposed by [PlatformWebViewController],
  /// such as custom navigation delegates or platform-specific settings.
  wf.WebViewController get flutterController => _controller;

  @override
  Future<void> initialize() async {
    /// Sets the JavaScript mode for the WebView.
    await _controller.setJavaScriptMode(wf.JavaScriptMode.unrestricted);

    // Set up console logging for debugging
    await _controller.setOnConsoleMessage((message) {
      debugPrint('[Monaco Console] ${message.level.name}: ${message.message}');
    });

    /// Sets the navigation delegate for the WebView.
    _controller.setNavigationDelegate(
      wf.NavigationDelegate(
        onPageFinished: (url) {
          debugPrint('[MonacoController] WebView Page Finished: $url');
        },
        onWebResourceError: (error) {
          debugPrint(
            '[MonacoController] WebView Error: ${error.description} on ${error.url}',
          );
        },
      ),
    );
  }

  @override
  Future<void> setBackgroundColor(Color color) async {
    await _controller.setBackgroundColor(color);
  }

  @override
  Future<void> setInteractionEnabled(bool enabled) async {
    // No-op on native platforms as overlays work correctly by default.
  }

  /// Loads a Flutter asset into the WebView.
  Future<Object?> loadFlutterAsset(String asset) async {
    await _controller.loadFlutterAsset(asset);
    return null;
  }

  @override
  Future<void> enableJavaScript() async {
    await _controller.setJavaScriptMode(wf.JavaScriptMode.unrestricted);
  }

  @override
  Future<Object?> runJavaScript(String script) async {
    try {
      await _controller.runJavaScript(script);
    } catch (e) {
      debugPrint('[FlutterWebViewController] JS execution error: $e');
      rethrow;
    }
    return null;
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String script) async {
    try {
      return await _controller.runJavaScriptReturningResult(script);
    } catch (e) {
      debugPrint('[FlutterWebViewController] JS result error: $e');
      rethrow;
    }
  }

  @override
  Future<Object?> addJavaScriptChannel(
    String name,
    void Function(String) onMessage,
  ) async {
    await _controller.addJavaScriptChannel(
      name,
      onMessageReceived: (wf.JavaScriptMessage message) {
        onMessage(message.message);
      },
    );
    return null;
  }

  @override
  Future<void> load({String? customCss, bool allowCdnFonts = false}) async {
    final htmlFilePath = await _ensureHtmlFile(
      customCss: customCss,
      allowCdnFonts: allowCdnFonts,
    );
    await _controller.loadFile(htmlFilePath);
  }

  @override
  Future<Object?> removeJavaScriptChannel(String name) async {
    await _controller.removeJavaScriptChannel(name);
    return null;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
  }
}

/// WebView implementation for Windows using Microsoft Edge WebView2.
///
/// This controller wraps the `webview_flutter_windows` package to provide Monaco editor
/// hosting on Windows. It requires the WebView2 runtime, which is pre-installed
/// on Windows 11 and available as a separate download for Windows 10.
///
/// ### JavaScript Communication
///
/// Unlike `webview_flutter`, WebView2 uses `chrome.webview.postMessage` for
/// native communication. However, the Monaco HTML defines a `window.flutterChannel`
/// shim that forwards to this API, providing a consistent interface.
///
/// Messages are received via the [webMessage] stream and dispatched to all
/// registered channel handlers in [_channels].
///
/// ### Result Parsing
///
/// WebView2's `ExecuteScript` returns JSON-encoded results, which may need
/// unwrapping. Use [parseWindowsScriptResult] to normalize return values.
///
/// ### Initialization
///
/// The first call to [initialize] may take longer if WebView2 needs to
/// install its runtime. Subsequent initializations are fast.
///
/// See also:
/// - [FlutterWebViewController] for Android/iOS/macOS implementation.
/// - [ww.WebviewController] for the underlying Windows WebView controller.
/// - [parseWindowsScriptResult] for result normalization.
class WindowsWebViewController extends WebViewController {
  /// Creates a new controller backed by `webview_flutter_windows` (WebView2).
  WindowsWebViewController() : super._() {
    _controller = ww.WebviewController();
  }

  @override
  Widget get widget => ww.Webview(_controller);

  late final ww.WebviewController _controller;
  final Map<String, void Function(String)> _channels = {};
  StreamSubscription<dynamic>? _webMessageSubscription;
  bool _isInitialized = false;
  bool _disposed = false;

  /// Provides direct access to the underlying `webview_flutter_windows` controller.
  ///
  /// Use this for advanced operations not exposed by [PlatformWebViewController],
  /// such as custom popup policies or DevTools access.
  ww.WebviewController get windowsController => _controller;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('[WindowsWebViewController] Initializing WebView2...');
    await _controller.initialize();
    _isInitialized = true;

    // Set up default configuration
    await _controller.setBackgroundColor(const Color(0xFF1E1E1E));
    await _controller.setPopupWindowPolicy(ww.WebviewPopupWindowPolicy.deny);

    // Set up message handler BEFORE adding any channels
    _setupWebMessageHandler();

    debugPrint('[WindowsWebViewController] WebView2 initialized successfully');
  }

  void _setupWebMessageHandler() {
    _webMessageSubscription?.cancel();

    _webMessageSubscription = _controller.webMessage.listen((
      dynamic rawMessage,
    ) {
      if (kDebugMode) {
        debugPrint(
          '[WindowsWebViewController] Raw message: $rawMessage (${rawMessage.runtimeType})',
        );
      }

      try {
        String messageStr;

        if (rawMessage is String) {
          messageStr = rawMessage;
        } else if (rawMessage is Map) {
          messageStr = json.encode(rawMessage);
        } else {
          messageStr = rawMessage.toString();
        }

        _channels.forEach((channelName, handler) {
          if (kDebugMode) {
            debugPrint(
              '[WindowsWebViewController] Forwarding to channel: $channelName',
            );
          }
          handler(messageStr);
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[WindowsWebViewController] Error handling message: $e');
        }
      }
    });
  }

  /// Loads the given HTML string into the WebView.
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {
    debugPrint(
      '[WindowsWebViewController] Loading HTML string (length: ${html.length})',
    );
    await _controller.loadStringContent(html);
  }

  @override
  Future<void> load({String? customCss, bool allowCdnFonts = false}) async {
    final htmlFilePath = await _ensureHtmlFile(
      customCss: customCss,
      allowCdnFonts: allowCdnFonts,
    );
    await _controller.loadUrl(Uri.file(htmlFilePath).toString());
  }

  @override
  Future<void> setBackgroundColor(Color color) async {
    await _controller.setBackgroundColor(color);
  }

  @override
  Future<void> setInteractionEnabled(bool enabled) async {
    // No-op on Windows as WebView2 respects Flutter's overlay stacking.
  }

  @override
  Future<void> requestNativeFocus() async {
    if (!_isInitialized || _disposed) return;
    // Moves real Win32 keyboard focus to the WebView2 control so that
    // subsequent in-page focus calls (and typing) actually work.
    await _controller.focus();
  }

  @override
  Future<void> enableJavaScript() async {}

  @override
  Future<Object?> runJavaScript(String script) async {
    try {
      return await _controller.executeScript(script);
    } catch (e) {
      debugPrint('[WindowsWebViewController] JS execution error: $e');
      rethrow;
    }
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String script) async {
    try {
      final result = await _controller.executeScript(script);
      return parseWindowsScriptResult(result);
    } catch (e) {
      debugPrint('[WindowsWebViewController] JS result error: $e');
      rethrow;
    }
  }

  @override
  Future<Object?> addJavaScriptChannel(
    String name,
    void Function(String) onMessage,
  ) async {
    debugPrint(
      '[WindowsWebViewController] Registering handler for channel: $name',
    );

    // Store the handler - HTML already defines window.flutterChannel
    _channels[name] = onMessage;

    // No need to inject JavaScript - the HTML already has the channel defined
    return null;
  }

  @override
  Future<Object?> removeJavaScriptChannel(String name) async {
    _channels.remove(name);
    return null; // No-op in JS; HTML owns flutterChannel
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    debugPrint('[WindowsWebViewController] Disposing...');
    _webMessageSubscription?.cancel();
    _channels.clear();
    if (_isInitialized) {
      _controller.dispose();
    }
  }
}
