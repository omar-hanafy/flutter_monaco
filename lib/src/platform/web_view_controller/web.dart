import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_monaco/src/core/monaco_assets.dart';
import 'package:flutter_monaco/src/platform/platform_webview.dart';
import 'package:flutter_monaco/src/platform/web_interaction_coordinator.dart';
import 'package:flutter_monaco/src/platform/web_view_controller/web_asset_resolver.dart';
import 'package:web/web.dart' as web;

/// Resolves the bundled Monaco `vs/` directory URL on Flutter Web.
///
/// Monaco's files are ordinary Flutter assets, so the URL comes from Flutter's
/// own resolver (`ui_web.assetManager`) - the single source of truth that
/// already honors `<base href>`, a CDN `assetBase`, a custom `assetsDir`, and
/// URL-encoding. The resolver may return a `<base href>`-relative URL, so it is
/// absolutized against `web.document.baseURI` - the page's `<base href>`, which
/// (unlike the raw page URL) excludes the active single-page route under path
/// URL strategy, so the path stays correct and still resolves inside the
/// blob-URL iframe that hosts Monaco (see issue #14).
String _monacoVsAssetUrl() {
  final assetUrl = ui_web.assetManager.getAssetUrl(
    '${MonacoAssets.assetBaseDir}/min/vs',
  );
  return resolveWebAssetUrl(web.document.baseURI, assetUrl);
}

/// WebView implementation for Flutter Web using an iframe.
///
/// On web platforms, native WebViews aren't available, so Monaco is hosted
/// in an iframe element. This approach provides:
///
/// - **Isolation:** Monaco runs in a separate browsing context
/// - **Security:** Content-Security-Policy can be applied per-iframe
/// - **Compatibility:** Works across all modern browsers
///
/// ### Communication
///
/// The iframe communicates with Flutter via `postMessage`:
/// - **Monaco to Flutter:** `window.parent.postMessage(msg, '*')`
/// - **Flutter to Monaco:** `iframe.contentWindow.eval(script)`
///
/// The HTML defines `window.flutterChannel.postMessage` which calls
/// `window.parent.postMessage`, maintaining API consistency with native.
///
/// ### HTML Loading
///
/// Monaco HTML is generated as a blob URL to avoid CORS issues with
/// `file://` or asset paths. The blob URL is revoked after Monaco
/// reports ready to free memory.
///
/// ### Focus Handling
///
/// Web focus is tricky because the iframe is a separate browsing context.
/// When Monaco reports focus events, this controller unfocuses Flutter
/// widgets. Desktop web also reasserts Monaco focus while mobile web avoids
/// amplifying accidental focus during scroll gestures.
///
/// See also:
/// - [MonacoAssets.generateIndexHtml] for HTML generation with web-specific
///   worker shims.
/// - [native.dart] for native platform implementations.
class WebViewController implements PlatformWebViewController {
  final Map<String, void Function(String)> _channels = {};
  bool _disposed = false;
  bool _interactionEnabled = true;

  Completer<void> _readyCompleter = Completer<void>();
  bool _isReady = false;

  web.HTMLIFrameElement? _iframe;
  JSFunction? _messageHandler;
  String? _viewId;
  late final String _messageToken;

  final _widgetKey = GlobalKey();
  Widget? _cachedWidget;

  @override
  Widget get widget =>
      _cachedWidget ??= HtmlElementView(key: _widgetKey, viewType: _viewId!);

  @override
  Future<void> initialize() async {
    _viewId = 'monaco-iframe-${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('[WebViewController] Initializing iframe approach');
    _messageToken = 'monaco-${DateTime.now().microsecondsSinceEpoch}-$_viewId';

    // Create iframe for Monaco.
    _iframe = web.HTMLIFrameElement()
      ..id = _viewId!
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      // Iframes are inline by default; the baseline gap can overflow the
      // host page by a few pixels, giving mobile Safari something to pan.
      ..style.display = 'block'
      // Touch pans and overscroll that start over the editor must never
      // chain into the host page (issue #11). The embedded document declares
      // the same policy; this covers the frame boundary itself.
      ..style.touchAction = 'none'
      ..style.overscrollBehavior = 'none'
      ..allow = 'clipboard-read; clipboard-write';

    MonacoWebInteractionCoordinator.instance.registerEditor(_viewId!, _iframe!);
    _applyInteractionEnabled();

    // Register the view factory.
    ui_web.platformViewRegistry.registerViewFactory(_viewId!, (_) => _iframe!);

    // Listen for messages from the iframe.
    final handler = _handleIframeMessage.toJS;
    _messageHandler = handler;
    web.window.addEventListener('message', handler);

    debugPrint('[WebViewController] View factory registered with ID: $_viewId');
  }

  void _handleIframeMessage(web.MessageEvent event) {
    // Only accept messages from our iframe
    if (_iframe?.contentWindow != event.source) return;

    final data = event.data;
    String message;
    Map<String, dynamic>? json;

    try {
      // Try to convert as string first
      message = (data as JSString).toDart;
    } catch (_) {
      // If not a string, try to convert as object
      try {
        message = jsonEncode((data as JSObject).dartify());
      } catch (_) {
        message = data.toString();
      }
    }

    if (message.startsWith('{')) {
      try {
        final decoded = jsonDecode(message);
        if (decoded is Map<String, dynamic>) {
          json = decoded;
        }
      } catch (_) {}
    }

    if (json != null) {
      final token = json['_flutterToken'];
      if (token != _messageToken) return;
    } else if (message != 'ready') {
      return;
    }

    // Only log non-stats messages to reduce noise (stats fire on every keystroke/selection)
    final isStatsMessage =
        message.contains('"event":"stats"') ||
        message.contains('"event": "stats"');
    if (!isStatsMessage) {
      debugPrint('[WebViewController] Received iframe message: $message');
    }

    // Check if this is the ready event
    final eventName = json?['event'];
    if (message == 'ready' || eventName == 'onEditorReady') {
      _isReady = true;
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
      debugPrint('[WebViewController] Monaco ready!');
    } else if (eventName == 'error' && !_isReady) {
      final errorMessage = json?['message'] ?? 'Unknown Monaco load error';
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.completeError(StateError(errorMessage.toString()));
      }
    }

    // When Monaco reports focus, unfocus Flutter widgets.
    // This is gated by _interactionEnabled to avoid focus stealing when interaction is disabled.
    if (_interactionEnabled &&
        (message.contains('"event":"focus"') ||
            message.contains('"event": "focus"'))) {
      // Unfocus any Flutter widget
      FocusManager.instance.primaryFocus?.unfocus();
      if (!_isMobileInputPlatform()) {
        _iframe?.contentWindow?.callMethod(
          'eval'.toJS,
          'window.flutterMonaco && window.flutterMonaco.forceFocus()'.toJS,
        );
      }
    }

    // Forward to all channels
    for (final handler in _channels.values) {
      handler(message);
    }
  }

  Future<void> _ensureReady() async {
    if (!_isReady) {
      await _readyCompleter.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('Monaco editor failed to initialize');
        },
      );
    }
  }

  bool _isMobileInputPlatform() {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Future<void> setBackgroundColor(Color color) async {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    _iframe?.style.backgroundColor = 'rgba($r, $g, $b, ${color.a})';
  }

  void _applyInteractionEnabled() {
    final iframe = _iframe;
    if (iframe == null) return;
    final viewId = _viewId;
    if (viewId == null) {
      iframe.style.pointerEvents = _interactionEnabled ? 'auto' : 'none';
      return;
    }
    MonacoWebInteractionCoordinator.instance.setBaseEnabled(
      viewId,
      _interactionEnabled,
    );
  }

  @override
  Future<void> setInteractionEnabled(bool enabled) async {
    if (_disposed) return;
    _interactionEnabled = enabled;
    _applyInteractionEnabled();

    if (!enabled) {
      // Best-effort: blur Monaco's textarea so keyboard input doesn't keep going to the editor.
      try {
        _iframe?.contentWindow?.callMethod(
          'eval'.toJS,
          '''
            (function() {
              try {
                var ta = document.querySelector('textarea.inputarea');
                if (ta && ta.blur) ta.blur();
                var ae = document.activeElement;
                if (ae && ae.blur) ae.blur();
              } catch (e) {}
            })();
          '''
              .toJS,
        );
      } catch (_) {}
    }
  }

  @override
  Future<void> requestNativeFocus() async {
    // No-op on web; iframe focus is handled by the in-page focus helpers.
  }

  @override
  Future<void> enableJavaScript() async {}

  @override
  Future<Object?> runJavaScript(String script) async {
    if (_disposed) return null;

    try {
      _iframe?.contentWindow?.callMethod('eval'.toJS, script.toJS);
      return null;
    } catch (e) {
      debugPrint('[WebViewController] JS execution error: $e');
      rethrow;
    }
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String script) async {
    if (_disposed) return null;

    try {
      final result = _iframe?.contentWindow?.callMethod(
        'eval'.toJS,
        script.toJS,
      );
      return result?.dartify();
    } catch (e) {
      debugPrint('[WebViewController] JS result error: $e');
      rethrow;
    }
  }

  @override
  Future<Object?> addJavaScriptChannel(
    String name,
    void Function(String) onMessage,
  ) async {
    debugPrint('[WebViewController] Adding JS channel: $name');
    _channels[name] = onMessage;
    return null;
  }

  @override
  Future<Object?> removeJavaScriptChannel(String name) async {
    _channels.remove(name);
    return null;
  }

  @override
  Future<void> load({String? customCss, bool allowCdnFonts = false}) async {
    debugPrint('[WebViewController] Loading Monaco in iframe');
    await _waitForIframeAttachment();

    final vsPath = _monacoVsAssetUrl();

    Object? lastError;
    const maxLoadAttempts = 2;
    for (var attempt = 1; attempt <= maxLoadAttempts; attempt++) {
      _isReady = false;
      _readyCompleter = Completer<void>();

      final html = MonacoAssets.generateIndexHtml(
        vsPath,
        isWindows: false,
        isIosOrMacOS: false,
        isWeb: true,
        messageToken: _messageToken,
        customCss: customCss,
        allowCdnFonts: allowCdnFonts,
      );

      final blobUrl = web.URL.createObjectURL(
        web.Blob([html.toJS].toJS, web.BlobPropertyBag(type: 'text/html')),
      );

      try {
        _iframe!.src = blobUrl;
        await _ensureReady();
        web.URL.revokeObjectURL(blobUrl);
        return;
      } catch (e) {
        lastError = e;
        web.URL.revokeObjectURL(blobUrl);
        if (attempt == maxLoadAttempts) {
          rethrow;
        }
        debugPrint(
          '[WebViewController] Monaco load attempt $attempt failed, retrying: $e',
        );
        _iframe?.src = 'about:blank';
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }

    throw StateError('Monaco iframe failed to load: $lastError');
  }

  Future<void> _waitForIframeAttachment() async {
    final iframe = _iframe;
    if (iframe == null || iframe.isConnected) return;

    const maxFrames = 120;
    for (var i = 0; i < maxFrames && !iframe.isConnected; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    debugPrint('[WebViewController] Disposing...');
    final viewId = _viewId;
    if (viewId != null) {
      MonacoWebInteractionCoordinator.instance.unregisterEditor(viewId);
    }
    if (_messageHandler != null) {
      web.window.removeEventListener('message', _messageHandler!);
      _messageHandler = null;
    }
    _channels.clear();
    _cachedWidget = null;
    _iframe?.remove();
    _iframe = null;
  }
}
