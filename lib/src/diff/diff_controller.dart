import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_monaco/src/editor/boot_timeout.dart';
import 'package:flutter_monaco/src/platform/platform_webview.dart';
import 'package:flutter_monaco/src/protocol/envelope.dart';
import 'package:flutter_monaco/src/protocol/protocol.dart';

/// Drives a Monaco diff editor (original vs modified) in a WebView.
///
/// The page boots in diff mode (`page.boot` with `mode: 'diff'`): two
/// models inside `monaco.editor.createDiffEditor`, driven by the `diff.*`
/// command registry. The single-editor surface ([MonacoController]) does
/// not exist on a diff page - only the operations below.
///
/// ### Usage
///
/// ```dart
/// final diff = await MonacoDiffController.create(
///   original: oldSource,
///   modified: newSource,
///   language: MonacoLanguage.dart,
/// );
/// await diff.whenReady;
/// ```
///
/// Prefer the `MonacoDiffEditor` widget, which renders loading/error chrome
/// and manages this controller's lifecycle.
class MonacoDiffController {
  MonacoDiffController._(this._protocol, this._webViewController) {
    _reloadSubscription = _protocol.pageReloads.listen((reload) {
      unawaited(_recoverFromPageReload(reload));
    });
  }

  final MonacoProtocol _protocol;
  final PlatformWebViewController _webViewController;
  final Completer<void> _onReady = Completer<void>();
  bool _readyCompletedOk = false;
  bool _disposed = false;

  /// The exact `page.boot` payload of the first boot, replayed verbatim
  /// when the page document reloads (see [onPageReloaded]).
  Map<String, Object?>? _bootPayload;
  final _pageReloaded = StreamController<void>.broadcast();

  /// Page-reload recovery gate, awaited by [_ensureReady]: same contract as
  /// `MonacoController`'s. A reloaded page shell only knows `page.boot` and
  /// `page.eval` until the diff editor exists, so commands issued during
  /// recovery queue here (FIFO) instead of reaching it. A failed recovery
  /// leaves the gate failed with a [MonacoPageReloadedError] until a newer
  /// reload recovers the editor.
  Completer<void>? _recoveryGate;
  int _recoveryGeneration = 0;

  /// The boot deadline ([create]'s `readyTimeout`), which also bounds each
  /// page-reload re-boot so commands waiting on the gate cannot hang.
  Duration _readyTimeout = MonacoDefaults.readyTimeout;
  StreamSubscription<MonacoPageReload>? _reloadSubscription;

  /// Completes when the diff editor is fully initialized and ready to
  /// accept commands. Completes with the boot error if initialization
  /// fails.
  Future<void> get whenReady => _onReady.future;

  /// Returns `true` if the diff editor finished initializing successfully
  /// and is not recovering from a page reload (see [onPageReloaded]).
  bool get isReady =>
      _onReady.isCompleted && _readyCompletedOk && _recoveryGate == null;

  /// Fires after the controller recovered from a page reload.
  ///
  /// Same contract as `MonacoController.onPageReloaded`: the page document
  /// reloaded outside the app's control (Flutter web re-inserted the
  /// iframe, a WebView process recovered, or the page was refreshed), the
  /// controller re-booted the diff editor with its ORIGINAL boot payload
  /// (original/modified text, language, options, theme), and the editor
  /// accepts commands again. Content and configuration applied after
  /// [create] must be restored by the app from this stream (the
  /// `MonacoDiffEditor` widget re-applies its own texts and configuration);
  /// commands that were in flight failed with [MonacoPageReloadedError], and
  /// commands issued during the recovery wait for it and then run in issue
  /// order. A failed recovery (including a re-boot that misses [create]'s
  /// `readyTimeout`) surfaces as an error event on this stream, and
  /// waiting and later commands fail with [MonacoPageReloadedError].
  Stream<void> get onPageReloaded => _pageReloaded.stream;

  /// Converges a freshly reloaded diff page back to a booted editor, then
  /// opens the command gate. See [onPageReloaded].
  Future<void> _recoverFromPageReload(MonacoPageReload reload) async {
    if (_disposed) return;
    final bootPayload = _bootPayload;
    if (bootPayload == null) {
      debugPrint(
        '[MonacoDiffController] Page reloaded before boot completed; '
        'leaving recovery to the boot flow.',
      );
      return;
    }
    debugPrint('[MonacoDiffController] Page reloaded; re-booting the editor.');
    final generation = ++_recoveryGeneration;
    final gate = _openRecoveryGate();
    try {
      final readyTimeout = _readyTimeout;
      await () async {
        await _protocol.invoke('page.boot', bootPayload, timeout: null);
        await reload.editorReady;
      }().timeout(
        readyTimeout,
        onTimeout: () => throw MonacoTimeoutError(
          message:
              'The reloaded Monaco diff editor did not report ready in '
              '${readyTimeout.inSeconds} seconds.',
          timeout: readyTimeout,
          operation: 'boot',
        ),
      );
      if (_disposed || generation != _recoveryGeneration) return;
      _recoveryGate = null;
      gate.complete();
      _pageReloaded.add(null);
    } on MonacoDisposedError {
      // Disposed mid-recovery; dispose settles the gate.
    } on MonacoPageReloadedError catch (e, st) {
      // Normally superseded by a newer reload whose recovery takes over the
      // gate; a skewed reload interrupts without starting a new recovery.
      await Future<void>.delayed(Duration.zero);
      if (_disposed || generation != _recoveryGeneration) return;
      _failRecovery(gate, e, st);
    } catch (e, st) {
      debugPrint('[MonacoDiffController] Page reload recovery failed: $e');
      if (_disposed || generation != _recoveryGeneration) return;
      _failRecovery(gate, e, st);
    }
  }

  Completer<void> _openRecoveryGate() {
    final current = _recoveryGate;
    if (current != null && !current.isCompleted) return current;
    final gate = Completer<void>();
    gate.future.ignore();
    _recoveryGate = gate;
    return gate;
  }

  void _failRecovery(Completer<void> gate, Object error, StackTrace st) {
    if (!gate.isCompleted) {
      gate.completeError(
        MonacoPageReloadedError(
          message:
              'The Monaco page reloaded and the diff editor could not be '
              'recovered: $error',
          operation: 'page.boot',
        ),
        st,
      );
    }
    _pageReloaded.addError(error, st);
  }

  /// The platform-specific WebView widget hosting the diff editor.
  Widget get webViewWidget => _webViewController.widget;

  /// Creates a diff controller and starts the (non-blocking) boot.
  ///
  /// Returns before the editor is ready (asset preparation and WebView
  /// setup are still awaited here); await [whenReady] for
  /// readiness. [options] configures the inner editors (fonts, minimap,
  /// ...), [diff] the diff-specific behavior (side-by-side vs inline,
  /// ...). [original]/[modified]/[language] seed the two models so the
  /// first painted frame already shows the requested diff.
  ///
  /// [readyTimeout] bounds the whole boot; it defaults to
  /// [MonacoDefaults.readyTimeout] (20s on native, 90s on web where the
  /// cold-cache first load must download the editor bundle over the
  /// network).
  static Future<MonacoDiffController> create({
    EditorOptions? options,
    MonacoDiffOptions diff = const MonacoDiffOptions(),
    String original = '',
    String modified = '',
    MonacoLanguage language = MonacoLanguage.plaintext,
    MonacoPageConfig page = const MonacoPageConfig(),
    Duration readyTimeout = MonacoDefaults.readyTimeout,
  }) async {
    await MonacoAssets.ensureReady();

    final webViewController = PlatformWebViewFactory.createController();
    final protocol = MonacoProtocol(webView: webViewController);
    MonacoDiffController? controller;

    try {
      await webViewController.initialize();
      await webViewController.enableJavaScript();
      await webViewController.addJavaScriptChannel(
        'flutterChannel',
        protocol.handleChannelMessage,
      );

      controller = MonacoDiffController._(protocol, webViewController);
      controller._startBoot(
        options: options,
        diff: diff,
        original: original,
        modified: modified,
        language: language,
        page: page,
        readyTimeout: readyTimeout,
      );
      return controller;
    } catch (_) {
      if (controller != null) {
        controller.dispose();
      } else {
        protocol.dispose();
        webViewController.dispose();
      }
      rethrow;
    }
  }

  /// Runs the two-phase boot in diff mode. Failures land in [whenReady].
  void _startBoot({
    required EditorOptions? options,
    required MonacoDiffOptions diff,
    required String original,
    required String modified,
    required MonacoLanguage language,
    required MonacoPageConfig page,
    required Duration readyTimeout,
  }) {
    final bootOptions = MonacoDefaults.editorOptions.merge(options);
    final bootTheme = bootOptions.theme ?? MonacoDefaults.darkTheme;
    _readyTimeout = readyTimeout;
    _onReady.future.ignore();
    unawaited(() async {
      try {
        await () async {
          await _webViewController.load(page: page);
          await _protocol.pageReady;
          // Kept for page-reload recovery (onPageReloaded).
          final bootPayload = <String, Object?>{
            'mode': 'diff',
            'options': bootOptions.toMonacoOptions(),
            'diffOptions': diff.toMonacoOptions(),
            'original': original,
            'modified': modified,
            'language': language.id,
            'theme': bootTheme.id,
          };
          _bootPayload = bootPayload;
          try {
            await _protocol.invoke('page.boot', bootPayload, timeout: null);
          } on MonacoPageReloadedError {
            // The page reloaded before answering. Page-reload recovery
            // re-boots the new page with this payload, and that page's
            // ready lifecycle completes editorReady below; a fatal or
            // skewed reload fails it instead.
          }
          await _protocol.editorReady;
        }().timeout(
          readyTimeout,
          onTimeout: () => throw MonacoTimeoutError(
            message: monacoBootTimeoutMessage(
              subject: 'Monaco diff editor',
              timeout: readyTimeout,
            ),
            timeout: readyTimeout,
            operation: 'boot',
          ),
        );
        if (!_onReady.isCompleted) {
          _readyCompletedOk = true;
          _onReady.complete();
        }
      } catch (e, st) {
        if (!_onReady.isCompleted) {
          _onReady.completeError(e, st);
        }
      }
    }());
  }

  /// Create a diff controller for tests without touching assets or
  /// platform views.
  ///
  /// When [runBoot] is true, the REAL boot pipeline runs against the fake
  /// WebView instead ([markReady] is ignored): `load()` is expected to emit
  /// `pageReady`, `page.boot` carries the boot arguments, and readiness
  /// follows the fake's `ready` lifecycle. Use this to exercise flows that
  /// depend on boot state, like page-reload recovery.
  @visibleForTesting
  static Future<MonacoDiffController> createForTesting({
    required PlatformWebViewController webViewController,
    bool markReady = true,
    String channelName = 'flutterChannel',
    bool runBoot = false,
    EditorOptions? bootOptions,
    MonacoDiffOptions bootDiffOptions = const MonacoDiffOptions(),
    String bootOriginal = '',
    String bootModified = '',
    MonacoLanguage bootLanguage = MonacoLanguage.plaintext,
    Duration readyTimeout = const Duration(seconds: 20),
  }) async {
    final protocol = MonacoProtocol(webView: webViewController);

    await webViewController.initialize();
    await webViewController.enableJavaScript();
    await webViewController.addJavaScriptChannel(
      channelName,
      protocol.handleChannelMessage,
    );

    final controller = MonacoDiffController._(protocol, webViewController);
    if (runBoot) {
      controller._startBoot(
        options: bootOptions,
        diff: bootDiffOptions,
        original: bootOriginal,
        modified: bootModified,
        language: bootLanguage,
        page: const MonacoPageConfig(),
        readyTimeout: readyTimeout,
      );
    } else if (markReady) {
      controller.completeReadyForTesting();
    }
    return controller;
  }

  /// Manually complete the ready signal for tests.
  @visibleForTesting
  void completeReadyForTesting() {
    _protocol.handleChannelMessage(
      jsonEncode({
        'v': kMonacoProtocolVersion,
        'kind': 'lifecycle',
        'name': 'pageReady',
        'protocolVersion': kMonacoProtocolVersion,
        'monacoVersion': 'test',
        'capabilities': <String>[],
      }),
    );
    _protocol.handleChannelMessage(
      jsonEncode({
        'v': kMonacoProtocolVersion,
        'kind': 'lifecycle',
        'name': 'ready',
      }),
    );
    _readyCompletedOk = true;
    if (!_onReady.isCompleted) {
      _onReady.complete();
    }
  }

  /// Manually fail the ready signal for tests (mirrors a boot failure).
  @visibleForTesting
  void failReadyForTesting(Object error, [StackTrace? stackTrace]) {
    _onReady.future.ignore();
    if (!_onReady.isCompleted) {
      _onReady.completeError(error, stackTrace ?? StackTrace.current);
    }
  }

  /// Awaits the readiness future unconditionally: a completer that failed is
  /// still `isCompleted`, so an isCompleted fast path would let commands skip
  /// the boot error and enter the protocol of a dead page. Every command
  /// after a failed boot must keep rethrowing the ORIGINAL boot error.
  ///
  /// After readiness, a page-reload recovery in progress holds the command
  /// until the re-booted diff editor accepts commands again.
  Future<void> _ensureReady() async {
    if (_disposed) {
      throw const MonacoDisposedError(
        message: 'MonacoDiffController has been disposed.',
      );
    }
    await _onReady.future;
    for (var gate = _recoveryGate; gate != null; gate = _recoveryGate) {
      await gate.future;
    }
    if (_disposed) {
      throw const MonacoDisposedError(
        message: 'MonacoDiffController has been disposed.',
      );
    }
  }

  Future<Object?> _invoke(String method, Map<String, Object?> params) async {
    await _ensureReady();
    final result = await _protocol.invoke(method, params);
    return identical(result, monacoJsUndefined) ? null : result;
  }

  /// Replaces both sides of the diff (and optionally the shared language).
  Future<void> setTexts({
    required String original,
    required String modified,
    MonacoLanguage? language,
  }) async {
    await _invoke('diff.setTexts', {
      'original': original,
      'modified': modified,
      if (language != null) 'language': language.id,
    });
  }

  /// Returns the current text of the modified (right/editable) side.
  Future<String> getModifiedText() async {
    final state = await _invoke('diff.getState', {});
    if (state is Map && state['modifiedText'] is String) {
      return state['modifiedText'] as String;
    }
    throw const MonacoProtocolError(
      message: 'diff.getState returned no modifiedText',
      operation: 'diff.getState',
    );
  }

  /// The number of changed line blocks Monaco currently reports.
  ///
  /// `0` always means a genuinely computed "no changes" result. When Monaco
  /// has not finished computing the diff within the bridge's grace window
  /// (throttled or offscreen views), this throws a [MonacoTimeoutError]
  /// instead of silently reporting zero; retry once the view is visible.
  Future<int> getLineChangeCount() async {
    final state = await _invoke('diff.getState', {});
    if (state is! Map) {
      throw MonacoProtocolError(
        message:
            'diff.getState returned no state map, got ${state.runtimeType}',
        operation: 'diff.getState',
      );
    }
    final count = state['lineChangeCount'];
    if (count is num) return count.toInt();
    throw const MonacoTimeoutError(
      message:
          'Monaco has not finished computing the diff; 0 would be '
          'indistinguishable from a real "no changes" result. Retry once '
          'the diff view is visible.',
      timeout: Duration(seconds: 3),
      operation: 'diff.getState',
    );
  }

  /// Applies sparse editor options (fonts, minimap, ...) to the diff pair.
  Future<void> updateOptions(EditorOptions options) async {
    await _invoke('diff.updateOptions', {'options': options.toMonacoOptions()});
  }

  /// Applies sparse diff-specific options (side-by-side vs inline, ...).
  Future<void> updateDiffOptions(MonacoDiffOptions options) async {
    await _invoke('diff.updateOptions', {'options': options.toMonacoOptions()});
  }

  /// Switches the (global) editor theme.
  Future<void> setTheme(MonacoTheme theme) async {
    await _invoke('diff.updateOptions', {
      'options': {'theme': theme.id},
    });
  }

  /// Scrolls to and highlights the next change.
  Future<void> revealNextChange() async {
    await _invoke('diff.revealNextChange', {});
  }

  /// Scrolls to and highlights the previous change.
  Future<void> revealPreviousChange() async {
    await _invoke('diff.revealPreviousChange', {});
  }

  /// Unconsumed scroll intents reported by the diff page (edge scroll
  /// handoff). Emits only while a source is enabled through
  /// [setScrollHandoffSources]; malformed payloads are dropped silently.
  ///
  /// The vertical scroll master is the modified editor (both panes are
  /// height-aligned), and the wheel region covers both panes. See
  /// [MonacoScrollHandoffDetails] for the delta conventions.
  Stream<MonacoScrollHandoffDetails> get onScrollHandoff => _protocol.events
      .where((event) => event.name == 'scrollHandoff')
      .map(
        (event) => MonacoScrollHandoffDetails.tryParse(
          Map<String, dynamic>.from(event.data),
        ),
      )
      .where((details) => details != null)
      .cast<MonacoScrollHandoffDetails>();

  /// Enables or disables edge scroll handoff sources inside the diff page.
  ///
  /// Identical contract to `MonacoController.setScrollHandoffSources`: an
  /// enabled source installs the matching DOM listeners and posts
  /// `scrollHandoff` events (surfaced through [onScrollHandoff]) for scroll
  /// gestures the diff editor cannot consume, arbitrated by [policy] (the
  /// momentum-absorbing [MonacoScrollBoundaryPolicy.newGestureOnly] by
  /// default); disabling removes the listeners again. `MonacoDiffEditor`
  /// calls this automatically from its `scrollHandoff` configuration.
  Future<void> setScrollHandoffSources({
    bool wheel = false,
    bool touch = false,
    MonacoScrollBoundaryPolicy policy =
        MonacoScrollBoundaryPolicy.newGestureOnly,
  }) async {
    await _invoke('page.setScrollHandoff', {
      'wheel': wheel,
      'touch': touch,
      'policy': policy.name,
    });
  }

  /// Releases the WebView and fails all in-flight commands.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    // Settle readiness now: the boot may be parked in a page load that only
    // gives up at its deadline (web waits for the iframe to attach), and
    // whenReady and every command queued behind it must not wait that long.
    if (!_onReady.isCompleted) {
      _onReady.future.ignore();
      _onReady.completeError(
        const MonacoDisposedError(
          message:
              'MonacoDiffController disposed before the editor became ready.',
        ),
      );
    }
    final gate = _recoveryGate;
    if (gate != null && !gate.isCompleted) {
      gate.completeError(
        const MonacoDisposedError(
          message:
              'MonacoDiffController disposed while recovering a page reload.',
        ),
      );
    }
    _reloadSubscription?.cancel();
    _pageReloaded.close();
    _protocol.dispose();
    _webViewController.dispose();
  }
}
