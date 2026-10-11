import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_monaco/src/common/exceptions.dart';
import 'package:flutter_monaco/src/platform/platform_webview.dart';
import 'package:flutter_monaco/src/protocol/envelope.dart';

/// The single Dart-side endpoint of wire protocol v3.
///
/// Owns request correlation, lifecycle futures, and the decoded event and
/// request streams. Every command travels as a
/// `FlutterMonaco.dispatch({id, method, params})` script and resolves from
/// the matching `response` envelope posted through the JavaScript channel,
/// so behavior is identical on Android, iOS, macOS, Windows, and Web - no
/// platform ever has to decode a `runJavaScriptReturningResult` value.
class MonacoProtocol {
  /// Creates a protocol endpoint over the platform WebView.
  ///
  /// Wire the WebView's JavaScript channel to [handleChannelMessage] before
  /// loading the page.
  MonacoProtocol({required this._webView}) {
    // Guard against unhandled async errors when disposed before readiness.
    _pageReady.future.catchError(
      (_) => const MonacoHandshake(
        protocolVersion: -1,
        monacoVersion: '',
        capabilities: {},
      ),
    );
    _editorReady.future.catchError((_) {});
  }

  final PlatformWebViewController _webView;

  final Completer<MonacoHandshake> _pageReady = Completer<MonacoHandshake>();
  final Completer<void> _editorReady = Completer<void>();
  final StreamController<ProtocolEvent> _events =
      StreamController<ProtocolEvent>.broadcast();
  final StreamController<ProtocolRequest> _requests =
      StreamController<ProtocolRequest>.broadcast();
  final StreamController<MonacoPageReload> _pageReloads =
      StreamController<MonacoPageReload>.broadcast();
  Completer<void>? _reloadEditorReady;
  final Map<String, _PendingInvoke> _pending = {};
  int _invokeSeq = 0;
  int _lastEventSeq = 0;
  bool _disposed = false;

  /// Completes at `lifecycle: pageReady` with the parsed handshake.
  ///
  /// Completes with an error on protocol version skew or a fatal boot
  /// failure before the page reported in.
  Future<MonacoHandshake> get pageReady => _pageReady.future;

  /// Completes at `lifecycle: ready` (the editor exists and every command
  /// is registered). Completes with an error on `lifecycle: fatal`.
  Future<void> get editorReady => _editorReady.future;

  /// Whether the editor reported ready.
  bool get isEditorReady => _editorReady.isCompleted && _editorReadyCompletedOk;
  bool _editorReadyCompletedOk = false;

  /// Whether [dispose] ran.
  bool get isDisposed => _disposed;

  /// All decoded editor events, in arrival order.
  Stream<ProtocolEvent> get events => _events.stream;

  /// JavaScript-initiated requests awaiting a Dart answer via [respond].
  Stream<ProtocolRequest> get requests => _requests.stream;

  /// Fires when the page document loads AGAIN after the first successful
  /// handshake.
  ///
  /// This happens outside the app's control: the Flutter web engine
  /// re-inserted the editor's iframe during platform-view re-composition
  /// (re-inserting an iframe reloads its `src`), a native WebView process
  /// recovered from a crash, or the page was refreshed. The new document is
  /// a bare shell - every model, registration, and listener of the old page
  /// is gone, and commands that were in flight fail with
  /// [MonacoPageReloadedError] the moment the reload is detected.
  ///
  /// A reload whose handshake shows a protocol version skew is NOT emitted
  /// here (the page cannot be re-booted); it only fails the in-flight
  /// commands.
  Stream<MonacoPageReload> get pageReloads => _pageReloads.stream;

  /// Dispatches [method] with [params] and completes with the response
  /// value.
  ///
  /// A JavaScript `undefined` result resolves to [monacoJsUndefined]. Fails
  /// with [MonacoJavaScriptError] when the page reports an error, a
  /// [MonacoTimeoutError] when no response arrives within [timeout] (pass
  /// `null` to wait indefinitely and manage deadlines at the call site),
  /// and a [MonacoDisposedError] after [dispose].
  Future<Object?> invoke(
    String method,
    Map<String, Object?> params, {
    Duration? timeout = const Duration(seconds: 30),
  }) async {
    return await (await invokeIssued(method, params, timeout: timeout));
  }

  /// Like [invoke], but splits issuing from awaiting: the outer future
  /// completes once the dispatch script was handed to the WebView, yielding
  /// the response future.
  ///
  /// Callers that must order a follow-up script after the dispatch script
  /// but before the response (the LSP bridged-transport pump: connect must
  /// be issued before the first deliverServerMessage) await the outer
  /// future, run their scripts, then await the inner one.
  Future<Future<Object?>> invokeIssued(
    String method,
    Map<String, Object?> params, {
    Duration? timeout = const Duration(seconds: 30),
  }) async {
    if (_disposed) {
      throw MonacoDisposedError(
        message: 'MonacoProtocol has been disposed.',
        operation: method,
      );
    }

    final id = 'r${++_invokeSeq}';
    final pending = _PendingInvoke(method: method);
    _pending[id] = pending;

    // Build the response future (including its timeout wrapper) BEFORE
    // issuing the script, and mark it ignored: an error response or a
    // dispose-time completeError can land while the issuing runJavaScript is
    // still being awaited, i.e. before the caller has attached a listener,
    // which would otherwise surface as an unhandled async error. Awaiters
    // that attach later still receive the result.
    final responseFuture = timeout == null
        ? pending.completer.future
        : pending.completer.future.timeout(
            timeout,
            onTimeout: () {
              _pending.remove(id);
              throw MonacoTimeoutError(
                message:
                    'Monaco command "$method" received no response in '
                    '${timeout.inSeconds}s.',
                timeout: timeout,
                operation: method,
              );
            },
          );
    responseFuture.ignore();

    final script =
        'window.FlutterMonaco && window.FlutterMonaco.dispatch({ '
        '"id": ${_jsJson(id)}, '
        '"method": ${_jsJson(method)}, '
        '"params": ${_jsJson(params)} })';
    try {
      await _webView.runJavaScript(script);
    } catch (e) {
      _pending.remove(id);
      final error = MonacoJavaScriptError(
        operation: method,
        message: 'Failed to issue dispatch: $e',
        details: e,
      );
      // Settle the response future too: it already exists (with its timeout
      // timer) and would otherwise sit pending for the full timeout window.
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(error);
      }
      throw error;
    }

    return responseFuture;
  }

  /// Answers a [ProtocolRequest] received on [requests].
  ///
  /// Pass either [value] (success) or [error] (failure). Responding to an
  /// id the page already cancelled is a silent no-op on the JS side.
  Future<void> respond(String requestId, {Object? value, Object? error}) async {
    if (_disposed) return;
    final payload = error == null
        ? {'id': requestId, 'ok': true, 'value': value}
        : {
            'id': requestId,
            'ok': false,
            'error': {'message': error.toString()},
          };
    await _webView.runJavaScript(
      'window.FlutterMonaco && window.FlutterMonaco.respond(${_jsJson(payload)})',
    );
  }

  /// Entry point for every message posted through the JavaScript channel.
  void handleChannelMessage(String message) {
    if (_disposed) return;

    final envelope = EnvelopeMessage.decode(message);
    if (envelope == null) {
      // Not a v3 envelope: the web platform layer's plain 'ready' string or
      // the legacy loader-error post. Platform code handles those; here they
      // are noise.
      return;
    }

    switch (envelope) {
      case LifecycleEnvelope(:final name, :final json):
        _handleLifecycle(name, json);
      case ResponseEnvelope():
        _handleResponse(envelope);
      case EventEnvelope(:final event):
        _checkEventSeq(event);
        _events.add(event);
      case RequestEnvelope(:final request):
        _requests.add(request);
      case LogEnvelope(:final level, :final message):
        debugPrint('[Monaco JS:$level] $message');
      case UnknownEnvelope(:final kind):
        debugPrint('[MonacoProtocol] Unknown envelope kind: $kind');
    }
  }

  void _handleLifecycle(String name, Map<String, Object?> json) {
    switch (name) {
      case 'pageReady':
        final handshake = MonacoHandshake.fromEnvelope(json);
        final isReload = _pageReady.isCompleted;
        if (isReload) {
          // The document loaded again: the old page's state (models,
          // registrations, response routing) is gone, so nothing still in
          // flight can ever be answered. Event sequence numbering restarts
          // with the new page.
          _failPendingForReload();
          _lastEventSeq = 0;
          // The previous reload's editor died with its document too: a
          // recovery still waiting for it must fail instead of waiting for a
          // `ready` that page can no longer post (a skewed page is never
          // booted, so nothing else would ever settle it).
          final previousReloadReady = _reloadEditorReady;
          _reloadEditorReady = null;
          if (previousReloadReady != null && !previousReloadReady.isCompleted) {
            previousReloadReady.completeError(
              const MonacoPageReloadedError(
                message:
                    'The Monaco page reloaded again before the re-booted '
                    'editor reported ready.',
                operation: 'page.boot',
              ),
            );
          }
        }
        if (handshake.protocolVersion != kMonacoProtocolVersion) {
          final error = MonacoProtocolError(
            operation: 'handshake',
            message:
                'Protocol version skew: page speaks '
                'v${handshake.protocolVersion}, Dart speaks '
                'v$kMonacoProtocolVersion. Generated page and package code '
                'are out of sync.',
          );
          if (!_pageReady.isCompleted) _pageReady.completeError(error);
          if (!_editorReady.isCompleted) _editorReady.completeError(error);
          if (isReload) {
            // A skewed page cannot be re-booted; don't announce a
            // recoverable reload.
            debugPrint('[MonacoProtocol] Reloaded page has ${error.message}');
          }
          return;
        }
        if (isReload) {
          final editorReadyAgain = Completer<void>();
          editorReadyAgain.future.ignore();
          _reloadEditorReady = editorReadyAgain;
          _pageReloads.add(
            MonacoPageReload._(
              handshake: handshake,
              editorReady: editorReadyAgain.future,
            ),
          );
          return;
        }
        _pageReady.complete(handshake);
      case 'ready':
        _editorReadyCompletedOk = true;
        if (!_editorReady.isCompleted) _editorReady.complete();
        final reloadReady = _reloadEditorReady;
        if (reloadReady != null && !reloadReady.isCompleted) {
          reloadReady.complete();
        }
      case 'fatal':
        final errorJson = json['error'];
        final error = MonacoJavaScriptError.fromJson(
          errorJson is Map<String, dynamic>
              ? errorJson
              : <String, dynamic>{'message': 'Fatal Monaco boot failure'},
          operation: 'boot',
        );
        if (!_pageReady.isCompleted) _pageReady.completeError(error);
        if (!_editorReady.isCompleted) _editorReady.completeError(error);
        final reloadReady = _reloadEditorReady;
        if (reloadReady != null && !reloadReady.isCompleted) {
          reloadReady.completeError(error);
        }
      default:
        debugPrint('[MonacoProtocol] Unknown lifecycle stage: $name');
    }
  }

  /// Fails every in-flight invoke with [MonacoPageReloadedError]: their
  /// responses died with the old page document.
  void _failPendingForReload() {
    for (final pending in List.of(_pending.values)) {
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(
          MonacoPageReloadedError(
            message:
                'The Monaco page reloaded while the command was in flight. '
                'Retry after the editor recovers '
                '(MonacoController.onPageReloaded).',
            operation: pending.method,
          ),
        );
      }
    }
    _pending.clear();
  }

  void _handleResponse(ResponseEnvelope envelope) {
    final pending = _pending.remove(envelope.id);
    if (pending == null) {
      // Timed-out or disposed invoke; a late response is a no-op.
      return;
    }
    if (envelope.ok) {
      pending.completer.complete(
        envelope.isUndefined ? monacoJsUndefined : envelope.value,
      );
    } else {
      pending.completer.completeError(
        MonacoJavaScriptError.fromJson(
          envelope.error?.cast<String, dynamic>() ??
              <String, dynamic>{'message': 'Unknown Monaco bridge error'},
          operation: pending.method,
        ),
      );
    }
  }

  void _checkEventSeq(ProtocolEvent event) {
    final seq = event.seq;
    if (seq == null) return;
    assert(() {
      if (seq <= _lastEventSeq) {
        debugPrint(
          '[MonacoProtocol] Event sequence regression: got $seq after '
          '$_lastEventSeq (${event.name}). Messages were dropped or '
          'reordered.',
        );
      }
      return true;
    }(), 'debug-only event sequence check');
    if (seq > _lastEventSeq) _lastEventSeq = seq;
  }

  /// Fails every pending invoke and closes the streams.
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    for (final pending in List.of(_pending.values)) {
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(
          MonacoDisposedError(
            message: 'MonacoProtocol disposed while the command was pending.',
            operation: pending.method,
          ),
        );
      }
    }
    _pending.clear();

    if (!_pageReady.isCompleted) {
      _pageReady.completeError(
        const MonacoDisposedError(
          message: 'MonacoProtocol disposed before the page became ready.',
        ),
      );
    }
    if (!_editorReady.isCompleted) {
      _editorReady.completeError(
        const MonacoDisposedError(
          message: 'MonacoProtocol disposed before the editor became ready.',
        ),
      );
    }
    final reloadReady = _reloadEditorReady;
    if (reloadReady != null && !reloadReady.isCompleted) {
      reloadReady.completeError(
        const MonacoDisposedError(
          message:
              'MonacoProtocol disposed while a page reload was '
              'being recovered.',
        ),
      );
    }
    _events.close();
    _requests.close();
    _pageReloads.close();
  }

  /// JSON-encodes [value] for safe embedding inside a JavaScript source
  /// string.
  ///
  /// U+2028/U+2029 are valid JSON but terminate JavaScript string literals;
  /// escaping them keeps `runJavaScript(dispatch(...))` payloads intact.
  /// (Same treatment the 2.3.0 LSP manager applied.)
  static String _jsJson(Object? value) {
    return jsonEncode(value)
        .replaceAll('\u2028', r'\u2028')
        .replaceAll('\u2029', r'\u2029');
  }
}

class _PendingInvoke {
  _PendingInvoke({required this.method});

  final String method;
  final Completer<Object?> completer = Completer<Object?>();
}

/// One page-reload occurrence delivered on [MonacoProtocol.pageReloads].
///
/// Carries the fresh page's [handshake] and an [editorReady] future that
/// tracks the RELOADED page's editor: after re-dispatching `page.boot`,
/// await [editorReady] before issuing editor commands. It completes at the
/// next `lifecycle: ready` and fails at the next `lifecycle: fatal` (or on
/// dispose).
final class MonacoPageReload {
  MonacoPageReload._({required this.handshake, required this.editorReady});

  /// The handshake the reloaded page shell reported.
  final MonacoHandshake handshake;

  /// Completes when the reloaded page's editor exists and every command is
  /// registered.
  final Future<void> editorReady;
}
