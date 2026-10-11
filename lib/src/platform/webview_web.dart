import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_monaco/src/assets/html_builder.dart';
import 'package:flutter_monaco/src/assets/monaco_assets.dart';
import 'package:flutter_monaco/src/common/exceptions.dart';
import 'package:flutter_monaco/src/common/monaco_page_config.dart';
import 'package:flutter_monaco/src/platform/platform_webview.dart';
import 'package:flutter_monaco/src/platform/web_asset_resolver.dart';
import 'package:flutter_monaco/src/platform/web_interaction_coordinator.dart';
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
    '$monacoAssetBaseDir/min/vs',
  );
  return resolveWebAssetUrl(web.document.baseURI, assetUrl);
}

/// Resolves the bundled bridge JavaScript directory URL on Flutter Web.
///
/// Same resolution rules as [_monacoVsAssetUrl]: the bridge files are plain
/// Flutter assets served from the host origin, so `script-src 'self'` admits
/// them and the blob-URL iframe (which inherits the creator's origin) can
/// load them via `<script src>`.
String _monacoBridgeAssetUrl() {
  final assetUrl = ui_web.assetManager.getAssetUrl(
    '$monacoAssetBaseDir/bridge',
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
/// `file://` or asset paths. The blob URL stays alive for as long as the
/// iframe exists (released on [dispose] or when a retry replaces it): the
/// Flutter web engine can detach and re-insert the iframe's DOM node at any
/// time after creation (platform-view re-composition around tab and route
/// churn), and re-inserting an iframe reloads its `src` from scratch. A
/// revoked blob would make that reload render Chromium's ERR_FILE_NOT_FOUND
/// page inside the editor. The reload itself is recovered by
/// `MonacoController` re-booting the fresh page shell (see
/// `MonacoProtocol.pageReloads`).
///
/// ### Widget Attachment
///
/// The iframe only loads while it is attached to the parent document, and
/// it is only attached while [widget] is mounted and painted (that is when
/// the engine composites the platform view slot). Boot therefore requires
/// the app to keep the widget in the tree - painted underneath any loading
/// chrome - from `load()` onward. A ready timeout with the iframe still
/// detached fails fast with a [StateError] naming this requirement instead
/// of retrying.
///
/// ### Focus Handling
///
/// Web focus is tricky because the iframe is a separate browsing context.
/// When Monaco reports focus events, this controller unfocuses Flutter
/// widgets. Desktop web also reasserts Monaco focus while mobile web avoids
/// amplifying accidental focus during scroll gestures.
///
/// The reverse handoff is explicit: [releaseNativeFocus] (also run by
/// [setInteractionEnabled] `false`) blurs Monaco inside the iframe AND
/// returns the parent document's focus to the Flutter view host, so Flutter
/// overlays receive keyboard events (Escape, Tab, typing) without needing a
/// first click. While the iframe element is the parent document's
/// activeElement, no key event can reach Flutter at all.
///
/// See also:
/// - `buildMonacoIndexHtml` (html_builder.dart) for HTML generation with
///   web-specific worker shims.
/// - `webview_native.dart` and `webview_windows.dart` for the native
///   platform implementations.
class WebViewController implements PlatformWebViewController {
  /// Monotonic per-controller counter mixed into [_viewId].
  ///
  /// A purely clock-derived id collides when several editors initialize in
  /// the same millisecond (one widget build creating multiple editors): the
  /// platform view registry rejects the duplicate factory, every
  /// HtmlElementView resolves to the first iframe, and the other editors
  /// never become ready.
  static int _instanceCounter = 0;

  final Map<String, void Function(String)> _channels = {};
  bool _disposed = false;
  bool _interactionEnabled = true;

  Completer<void> _readyCompleter = Completer<void>();
  bool _isReady = false;

  web.HTMLIFrameElement? _iframe;
  JSFunction? _messageHandler;
  String? _viewId;
  late final String _messageToken;

  /// The blob URL currently assigned to the iframe's `src`.
  ///
  /// Held (not revoked at ready) because the engine may re-insert the
  /// iframe later and the browser then re-fetches this URL; see the class
  /// docs. Released only through [_replaceActiveBlobUrl].
  String? _activeBlobUrl;

  /// Revokes the previous blob URL (if any) and records [next] as current.
  ///
  /// The single revoke site in this controller: a retry replaces the failed
  /// attempt's URL, and [dispose] passes `null` after the iframe is gone.
  void _replaceActiveBlobUrl(String? next) {
    final previous = _activeBlobUrl;
    if (previous != null) {
      web.URL.revokeObjectURL(previous);
    }
    _activeBlobUrl = next;
  }

  final _widgetKey = GlobalKey();
  Widget? _cachedWidget;

  @override
  Widget get widget =>
      _cachedWidget ??= HtmlElementView(key: _widgetKey, viewType: _viewId!);

  @override
  Future<void> initialize() async {
    final instanceId = ++_instanceCounter;
    _viewId =
        'monaco-iframe-$instanceId-${DateTime.now().millisecondsSinceEpoch}';
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
    final isStatsMessage = json?['kind'] == 'event' && json?['name'] == 'stats';
    if (!isStatsMessage) {
      debugPrint('[WebViewController] Received iframe message: $message');
    }

    // Lifecycle: the protocol v3 'pageReady' envelope marks the page shell
    // alive (scripts loaded, protocol available) - that is what load()
    // waits for; the editor itself is created later by page.boot. The
    // legacy {event: 'error'} shape still comes from the inline
    // loader-failure handler in the HTML head (which runs before core.js).
    final lifecycleName = (json != null && json['kind'] == 'lifecycle')
        ? json['name']
        : null;
    if (message == 'ready' || lifecycleName == 'pageReady') {
      _isReady = true;
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
      debugPrint('[WebViewController] Monaco page shell ready!');
    } else if (!_isReady &&
        (lifecycleName == 'fatal' || json?['event'] == 'error')) {
      final errorMessage =
          ((json?['error'] as Map<String, dynamic>?)?['message'] ??
                  json?['message'] ??
                  'Unknown Monaco load error')
              .toString();
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.completeError(StateError(errorMessage));
      }
    }

    // When Monaco reports focus, unfocus Flutter widgets.
    // This is gated by _interactionEnabled to avoid focus stealing when interaction is disabled.
    final focusData =
        (json != null &&
            json['kind'] == 'event' &&
            json['name'] == 'focusChanged')
        ? json['data']
        : null;
    if (_interactionEnabled &&
        focusData is Map &&
        focusData['focused'] == true) {
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
      // A pointer-inert editor must not keep the keyboard either: hand
      // document focus back to Flutter so overlays receive key events
      // (Escape closes a dialog, Tab traverses it) without a first click.
      await releaseNativeFocus();
    }
  }

  @override
  Future<NativeFocusResult> requestNativeFocus() async {
    // No-op on web; iframe focus is handled by the in-page focus helpers.
    return NativeFocusResult.unsupported;
  }

  @override
  Future<bool?> hasNativeInputFocus() async => null;

  @override
  Future<void> releaseNativeFocus() async {
    // Web's "native focus" (layer 2 of the focus model) is the browser's
    // document focus. While the parent document's activeElement is the
    // editor iframe, every key event dispatches inside the iframe's
    // document; Flutter's keyboard listeners live on the Flutter view host
    // in the parent document and receive nothing. Blurring inside the
    // iframe alone is not enough - keys keep draining into the iframe's
    // body. The handoff is two-sided, mirroring the desktop
    // implementations: blur Monaco's textarea INSIDE the iframe, then move
    // the parent document's focus onto the Flutter view host so keys flow
    // to Flutter again.
    _blurInsideIframe();
    if (_iframeHoldsDocumentFocus) {
      _focusFlutterHost();
    }
  }

  /// Whether the parent document currently routes keyboard input into the
  /// editor's iframe. Compared by element id (set in [initialize]) because
  /// JS-interop reference equality is compiler-dependent.
  bool get _iframeHoldsDocumentFocus {
    final viewId = _viewId;
    if (viewId == null) return false;
    final active = web.document.activeElement;
    return active != null && active.tagName == 'IFRAME' && active.id == viewId;
  }

  void _blurInsideIframe() {
    // Best-effort: blur Monaco's textarea so the editor stops handling keys
    // and its caret stops blinking while it is interaction-disabled.
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

  /// Moves the parent document's focus from the editor iframe onto the
  /// Flutter view host element, so the framework's key listeners receive
  /// events again.
  void _focusFlutterHost() {
    final iframe = _iframe;
    if (iframe == null) return;
    try {
      // closest() keeps this correct under multi-view embeddings: focus the
      // <flutter-view> THIS editor lives in, not the first one on the page.
      final host = iframe.closest('flutter-view');
      if (host == null || !host.isA<web.HTMLElement>()) {
        // Unknown host DOM (engine change / exotic embedding): at least pull
        // focus off the iframe so keys stop draining into an inert editor.
        iframe.blur();
        return;
      }
      final hostElement = host as web.HTMLElement;
      if (!hostElement.hasAttribute('tabindex')) {
        // Programmatic focus() requires focusability; -1 keeps the host out
        // of the user's Tab order.
        hostElement.tabIndex = -1;
      }
      hostElement.focus(web.FocusOptions(preventScroll: true));
    } catch (_) {}
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

  /// The error a [load] interrupted by [dispose] ends with.
  static const _disposedDuringLoad = MonacoDisposedError(
    message: 'WebViewController disposed while the Monaco page was loading.',
    operation: 'load',
  );

  @override
  Future<void> load({MonacoPageConfig page = const MonacoPageConfig()}) async {
    debugPrint('[WebViewController] Loading Monaco in iframe');
    if (_disposed) throw _disposedDuringLoad;
    await _waitForIframeAttachment();

    final vsPath = _monacoVsAssetUrl();

    Object? lastError;
    const maxLoadAttempts = 2;
    for (var attempt = 1; attempt <= maxLoadAttempts; attempt++) {
      // Every await below can span a dispose: bail out before creating a
      // blob URL that dispose (which already ran) would never revoke.
      if (_disposed) throw _disposedDuringLoad;
      _isReady = false;
      _readyCompleter = Completer<void>();

      final html = buildMonacoIndexHtml(
        vsPath: vsPath,
        bridgeBase: _monacoBridgeAssetUrl(),
        monacoVersion: MonacoAssets.monacoVersion,
        isWeb: true,
        messageToken: _messageToken,
        customCss: page.customCss,
        allowCdnFonts: page.allowCdnFonts,
        allowedConnectSources: page.allowedConnectSources,
      );

      final blobUrl = web.URL.createObjectURL(
        web.Blob([html.toJS].toJS, web.BlobPropertyBag(type: 'text/html')),
      );
      _replaceActiveBlobUrl(blobUrl);

      try {
        _iframe!.src = blobUrl;
        await _ensureReady();
        // The blob URL intentionally stays alive (see _activeBlobUrl): an
        // engine-driven iframe re-insertion reloads `src`, which must still
        // resolve.
        return;
      } catch (e) {
        if (_disposed) throw _disposedDuringLoad;
        // A ready timeout while the iframe is outside the DOM is not a
        // transient load failure: a detached iframe never loads its src at
        // all, so retrying would only burn another silent 20s. This is a
        // usage error - readiness is being awaited while nothing put the
        // platform view on screen - and must surface as one.
        if (e is TimeoutException && !(_iframe?.isConnected ?? false)) {
          throw StateError(
            'Monaco iframe is not attached to the DOM, so the editor page '
            'can never load. On web, whenReady only completes while the '
            "controller's webViewWidget is mounted and painted: keep the "
            'widget in the tree underneath your loading UI (an opaque Stack '
            'overlay, as the MonacoEditor widget does) instead of inserting '
            'it after readiness, and do not hide it with Offstage or '
            'Visibility(visible: false).',
          );
        }
        lastError = e;
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
    for (var i = 0; i < maxFrames && !iframe.isConnected && !_disposed; i++) {
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
    // A load() waiting for the page shell must end now, not at its timeout.
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.future.ignore();
      _readyCompleter.completeError(_disposedDuringLoad);
    }
    _detachParentBindings();
    _iframe?.remove();
    _iframe = null;
    _replaceActiveBlobUrl(null);
  }

  /// Removing the iframe element discards its browsing context WITHOUT
  /// firing `pagehide`, so listeners the embedded document registered on
  /// the parent's `visualViewport`/window (the mobile-web viewport-fit of
  /// issue #11) would stay attached to the host page and keep the dead
  /// document - and its whole Monaco instance - rooted until the next
  /// parent viewport event evicts them. Detach them eagerly so a disposed
  /// editor is collectable immediately.
  void _detachParentBindings() {
    try {
      _iframe?.contentWindow?.callMethod(
        'eval'.toJS,
        'window.__flutterMonacoDetachParentBindings && window.__flutterMonacoDetachParentBindings();'
            .toJS,
      );
    } catch (_) {}
  }
}
