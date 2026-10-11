import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_monaco/src/assets/html_builder.dart';
import 'package:flutter_monaco/src/assets/monaco_assets.dart';
import 'package:flutter_monaco/src/platform/platform_webview.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart' as wf;
import 'package:webview_flutter_windows/webview_flutter_windows.dart' as ww;

part 'webview_windows.dart';

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
  Future<NativeFocusResult> requestNativeFocus() async {
    // No-op by default: Android and iOS WebViews participate in the regular
    // platform focus system. Windows (WebView2 Win32 focus) and macOS
    // (WKWebView first responder, via the flutter_monaco native plugin)
    // override this with a real handoff.
    return NativeFocusResult.unsupported;
  }

  @override
  Future<bool?> hasNativeInputFocus() async => null;

  @override
  Future<void> releaseNativeFocus() async {}

  /// Generates the Monaco editor HTML file for native platforms.
  ///
  /// The file is rewritten on every load: it is KB-sized, and always
  /// rewriting makes stale-page bugs structurally impossible (the 2.x
  /// exists-check fast path required a manual cache-bust constant). The
  /// [customCss]/[allowCdnFonts]/[allowedConnectSources] tuple still keys the
  /// file name so differently configured editors in one app do not clobber
  /// each other's page while running.
  ///
  /// **Platform differences:**
  /// - Windows uses absolute `file://` paths since HTML is loaded via URL
  /// - macOS/iOS/Android use relative paths since HTML sits next to the
  ///   extracted assets
  ///
  /// Returns the absolute path to the generated HTML file.
  Future<String> _ensureHtmlFile(MonacoPageConfig page) async {
    final htmlFilePath = await monacoIndexHtmlPath(
      cacheKey: page.stableCacheKey(),
    );

    final htmlFile = File(htmlFilePath);

    // Generate platform-specific HTML
    String htmlContent;

    if (Platform.isWindows) {
      final targetDir = p.dirname(htmlFilePath);

      // Windows needs absolute paths since we load from file://
      final vsPath = p.join(targetDir, 'min', 'vs');
      final absoluteVsPath = Uri.file(vsPath).toString();
      final bridgeBase = Uri.file(p.join(targetDir, 'bridge')).toString();
      htmlContent = buildMonacoIndexHtml(
        vsPath: absoluteVsPath,
        bridgeBase: bridgeBase,
        monacoVersion: MonacoAssets.monacoVersion,
        isWindows: true,
        customCss: page.customCss,
        allowCdnFonts: page.allowCdnFonts,
        allowedConnectSources: page.allowedConnectSources,
      );
    } else {
      // macOS uses relative paths since HTML is in the same directory
      htmlContent = buildMonacoIndexHtml(
        vsPath: p.join('min', 'vs'),
        bridgeBase: 'bridge',
        monacoVersion: MonacoAssets.monacoVersion,
        isIosOrMacOS: Platform.isIOS || Platform.isMacOS,
        customCss: page.customCss,
        allowCdnFonts: page.allowCdnFonts,
        allowedConnectSources: page.allowedConnectSources,
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
  Widget get widget {
    final webView = wf.WebViewWidget(controller: _controller);
    if (Platform.isMacOS) {
      // Anchor the WebView's render box so the macOS native focus channel
      // can locate THIS WKWebView in the window (apps may host several).
      return KeyedSubtree(key: _macosViewAnchorKey, child: webView);
    }
    return webView;
  }

  late final wf.WebViewController _controller;
  bool _disposed = false;

  /// Provides direct access to the underlying `webview_flutter` controller.
  ///
  /// Use this for advanced operations not exposed by [PlatformWebViewController],
  /// such as custom navigation delegates or platform-specific settings.
  wf.WebViewController get flutterController => _controller;

  /// Method channel to the `flutter_monaco` macOS plugin, which performs the
  /// NSWindow first-responder handoff that `webview_flutter_wkwebview` does
  /// not implement (it has no responder management at all - verified against
  /// 3.26.0 sources).
  @visibleForTesting
  static const MethodChannel macosNativeFocusChannel = MethodChannel(
    'flutter_monaco/native_focus',
  );

  final GlobalKey _macosViewAnchorKey = GlobalKey(
    debugLabel: 'MonacoMacosWebViewAnchor',
  );

  /// The WebView's current bounds in Flutter logical coordinates (which equal
  /// AppKit points on macOS), relative to the Flutter view's top-left origin.
  /// Null when the widget is not attached to the tree.
  Map<String, double>? _macosWebViewRectArgs() {
    final renderObject = _macosViewAnchorKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return <String, double>{
      'x': topLeft.dx,
      'y': topLeft.dy,
      'width': renderObject.size.width,
      'height': renderObject.size.height,
    };
  }

  @override
  Future<NativeFocusResult> requestNativeFocus() async {
    if (_disposed) return NativeFocusResult.failed;
    if (!Platform.isMacOS) {
      // Android and iOS WebViews take native focus from the user gesture
      // itself; there is no handoff to perform.
      return NativeFocusResult.unsupported;
    }
    try {
      final status = await macosNativeFocusChannel.invokeMethod<String>(
        'focusWebView',
        _macosWebViewRectArgs(),
      );
      return switch (status) {
        'granted' => NativeFocusResult.granted,
        'already-owned' => NativeFocusResult.alreadyOwned,
        _ => NativeFocusResult.failed,
      };
    } on MissingPluginException {
      // Native side not registered (widget tests, headless, or an embedding
      // that never ran plugin registration). Callers fall back to the
      // in-page focus replay path.
      return NativeFocusResult.unsupported;
    } catch (e) {
      debugPrint('[FlutterWebViewController] macOS focus handoff failed: $e');
      return NativeFocusResult.failed;
    }
  }

  @override
  Future<bool?> hasNativeInputFocus() async {
    if (_disposed || !Platform.isMacOS) return null;
    try {
      return await macosNativeFocusChannel.invokeMethod<bool>(
        'hasNativeFocus',
        _macosWebViewRectArgs(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> releaseNativeFocus() async {
    if (_disposed || !Platform.isMacOS) return;
    try {
      await macosNativeFocusChannel.invokeMethod<void>('releaseWebViewFocus');
    } catch (_) {
      // Best-effort: without the native plugin there is nothing to release.
    }
  }

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
  Future<void> load({MonacoPageConfig page = const MonacoPageConfig()}) async {
    final htmlFilePath = await _ensureHtmlFile(page);
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
