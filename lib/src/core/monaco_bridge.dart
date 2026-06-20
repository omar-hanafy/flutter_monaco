import 'dart:async';
import 'dart:convert';

import 'package:convert_object/convert_object.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_monaco/src/models/monaco_types.dart';
import 'package:flutter_monaco/src/platform/platform_webview.dart';

/// Bidirectional communication bridge between Flutter and the Monaco Editor.
///
/// The [MonacoBridge] handles all message routing between the JavaScript Monaco
/// instance and Flutter Dart code. It:
///
/// - **Parses messages:** Decodes JSON payloads from `flutterChannel.postMessage`
/// - **Routes events:** Dispatches known events (ready, stats, errors) to handlers
/// - **Notifies listeners:** Forwards all events to registered raw listeners
/// - **Tracks state:** Manages readiness state and live statistics
///
/// ### Event Flow
///
/// ```
/// Monaco JS ─► flutterChannel.postMessage(json) ─► WebView Channel
///     ─► handleJavaScriptMessage ─► _routeEvent ─► onReady / liveStats
///                                 ─► _notifyRawListeners ─► MonacoController
/// ```
///
/// ### Known Events
///
/// - `onEditorReady`: Monaco finished initializing, completes [onReady]
/// - `stats`: Live editor statistics, updates [liveStats]
/// - `error`: JavaScript error, logged to debug console
/// - `contentChanged`, `selectionChanged`, `focus`, `blur`: Forwarded to controller
/// - `completionRequest`: Autocompletion request, handled by controller
///
/// ### Lifecycle
///
/// 1. Create bridge: `MonacoBridge()`
/// 2. Attach to WebView: `bridge.attachWebView(controller)`
/// 3. Wait for ready: `await bridge.onReady.future`
/// 4. Listen for events: `bridge.addRawListener(handler)`
/// 5. Dispose: `bridge.dispose()`
///
/// See also:
/// - [MonacoController] which orchestrates the bridge and WebView.
/// - [handleJavaScriptMessage] for the message entry point.
class MonacoBridge extends ChangeNotifier {
  /// Creates a bridge and sets up error handling for the readiness future.
  ///
  /// The constructor guards against unhandled async errors if the bridge is
  /// disposed before Monaco reports ready.
  MonacoBridge() {
    // Prevent unhandled async errors when disposed before readiness.
    onReady.future.catchError((_) {});
  }

  PlatformWebViewController? _webViewController;

  /// Completes when Monaco reports the `onEditorReady` event.
  ///
  /// Await this future before calling methods on [MonacoController] to ensure
  /// the editor is fully initialized. Completes with an error if the bridge
  /// is disposed before readiness.
  final Completer<void> onReady = Completer<void>();

  /// Real-time statistics from the editor, updated on every cursor/content change.
  ///
  /// Use this to display status bar information like line count, selection
  /// length, and cursor position. Starts with [LiveStats.defaults] until
  /// Monaco sends actual values.
  final ValueNotifier<LiveStats> liveStats = ValueNotifier(
    LiveStats.defaults(),
  );

  final List<void Function(Map<String, dynamic>)> _rawListeners = [];
  bool _disposed = false;

  /// Returns `true` if this bridge has been disposed.
  ///
  /// After disposal, all methods become no-ops and [onReady] completes
  /// with an error if not already completed.
  bool get isDisposed => _disposed;

  /// Associates this bridge with a [PlatformWebViewController].
  ///
  /// Must be called before loading Monaco HTML. The WebView's JavaScript
  /// channel should be configured to call [handleJavaScriptMessage].
  ///
  /// Throws [StateError] if called after [dispose].
  ///
  /// **Note:** Attaching a different controller replaces the previous one.
  /// This logs a warning but does not throw, allowing controller replacement
  /// for hot-reload scenarios.
  void attachWebView(PlatformWebViewController controller) {
    if (_disposed) {
      throw StateError('Cannot attach WebView to disposed bridge');
    }
    if (_webViewController != null && _webViewController != controller) {
      debugPrint(
        '[MonacoBridge] Replacing previously attached WebView controller.',
      );
    }
    _webViewController = controller;
    debugPrint('[MonacoBridge] WebView controller attached.');
  }

  /// Entry point for all messages from the Monaco JavaScript context.
  ///
  /// This method accepts various input types and normalizes them to JSON:
  /// - `String`: Parsed as JSON directly
  /// - `Map` or `List`: Encoded to JSON string first
  /// - Other: Converted via `toString()`
  ///
  /// After normalization, the message is:
  /// 1. Parsed to a `Map<String, dynamic>`
  /// 2. Routed based on the `event` field
  /// 3. Forwarded to all registered raw listeners
  ///
  /// **Log messages:** Strings starting with `log:` are printed to debug
  /// console and not processed further.
  ///
  /// This method is safe to call after [dispose] - it becomes a no-op.
  void handleJavaScriptMessage(dynamic message) {
    if (_disposed) return;

    final String msg;
    if (message is String) {
      msg = message;
    } else if (message is Map || message is List) {
      msg = jsonEncode(message);
    } else if (message != null) {
      msg = message.toString();
    } else {
      msg = '';
    }
    _handleJavaScriptMessage(msg);
  }

  /// Registers a listener that receives all parsed JavaScript events.
  ///
  /// Use this to:
  /// - Handle events not covered by [MonacoController]'s typed streams
  /// - Debug communication issues by logging all events
  /// - Implement custom Monaco integrations
  ///
  /// The listener receives the full parsed JSON map including the `event`
  /// field. Listeners are called synchronously in registration order.
  ///
  /// **Error handling:** Exceptions in listeners are caught and logged to
  /// prevent one faulty listener from breaking others.
  ///
  /// Remove listeners with [removeRawListener] to prevent memory leaks.
  void addRawListener(void Function(Map<String, dynamic>) listener) {
    if (_disposed) return;
    _rawListeners.add(listener);
  }

  /// Removes a previously registered raw listener.
  void removeRawListener(void Function(Map<String, dynamic>) listener) {
    _rawListeners.remove(listener);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    debugPrint('[MonacoBridge] Disposing bridge.');
    if (!onReady.isCompleted) {
      onReady.completeError(
        StateError('Bridge disposed before the editor became ready.'),
      );
    }
    _rawListeners.clear();
    liveStats.dispose();
    _webViewController = null;
    super.dispose();
  }

  void _handleJavaScriptMessage(String message) {
    if (_disposed) return;

    if (message.startsWith('log:')) {
      debugPrint('[Monaco JS] ${message.substring(4)}');
      return;
    }

    Map<String, dynamic> json;
    try {
      json = Convert.toMap(message);
    } catch (e) {
      debugPrint('[MonacoBridge] Failed to parse message: $message');
      return;
    }

    _routeEvent(json);
    _notifyRawListeners(json);
  }

  void _routeEvent(Map<String, dynamic> json) {
    final event = json['event'];
    if (event == null) {
      debugPrint('[MonacoBridge] Message missing event field');
      return;
    }

    switch (event) {
      case 'onEditorReady':
        if (!onReady.isCompleted) {
          debugPrint('[MonacoBridge] ✅ "onEditorReady" event received.');
          onReady.complete();
        }
        break;

      case 'stats':
        try {
          liveStats.value = LiveStats.fromJson(json);
        } catch (e) {
          debugPrint('[MonacoBridge] Failed to parse stats: $e');
        }
        break;

      case 'error':
        final message = json['message'] ?? 'Unknown error';
        debugPrint('❌ [Monaco JS Error] $message');
        break;

      case 'contentChanged':
      case 'selectionChanged':
      case 'focus':
      case 'blur':
      case 'completionRequest':
        // Handled by controller's raw listener
        break;

      default:
        debugPrint('[MonacoBridge] Unhandled JS event type: "$event"');
    }
  }

  void _notifyRawListeners(Map<String, dynamic> json) {
    if (_disposed) return;

    // Create a copy to avoid concurrent modification
    final listeners = List<void Function(Map<String, dynamic>)>.of(
      _rawListeners,
    );
    for (final listener in listeners) {
      try {
        listener(json);
      } catch (e, st) {
        debugPrint('[MonacoBridge] Error in raw listener: $e\n$st');
      }
    }
  }
}
