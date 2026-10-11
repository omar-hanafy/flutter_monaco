import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_monaco/src/editor/focus_coordinator.dart';
import 'package:flutter_monaco/src/lsp/lsp_connection.dart';
import 'package:flutter_monaco/src/platform/platform_webview.dart';
import 'package:flutter_monaco/src/protocol/envelope.dart';
import 'package:flutter_monaco/src/protocol/protocol.dart';

/// Manages the lifecycle and interaction with a Monaco Editor instance.
///
/// The [MonacoController] bridges Dart and the underlying JavaScript editor,
/// providing methods to read/write content, manage selection, and execute commands.
///
/// ### Usage
/// * Call [create] to instantiate a controller off-widget (headless or advanced usage).
/// * Use `controller.document.setText` / `getText` to manage content.
/// * Listen to [onContentChanged] for real-time updates.
class MonacoController {
  MonacoController._(this._protocol, this._webViewController) {
    _wireEvents();
    _wireRequests();
    _wireReloadRecovery();
    _lspManager = MonacoLspManager(protocol: _protocol);
  }

  final MonacoProtocol _protocol;
  final PlatformWebViewController _webViewController;
  final Completer<void> _onReady = Completer<void>();
  late final MonacoLspManager _lspManager;
  bool _disposed = false;

  /// The exact `page.boot` payload of the first boot, replayed verbatim
  /// when the page document reloads (see [onPageReloaded]). Null until
  /// [_startBoot] runs.
  Map<String, Object?>? _bootPayload;

  /// Page-reload recovery gate, awaited by [_ensureReady].
  ///
  /// Non-null from the moment a reload is picked up until the re-boot and
  /// the registration replay finished. A reloaded page shell only knows
  /// `page.boot` and `page.eval` until its editor exists, so commands issued
  /// in that window queue here (FIFO, like pre-ready commands) instead of
  /// reaching a page that would answer "Unknown method". Recovery itself
  /// talks to the protocol directly and is never gated. A failed recovery
  /// leaves the gate completed with a [MonacoPageReloadedError] so later
  /// commands fail the same way until a newer reload recovers the editor.
  Completer<void>? _recoveryGate;

  /// Incremented per recovery attempt; a superseded attempt never settles
  /// the gate that the newest attempt now owns.
  int _recoveryGeneration = 0;

  /// The EFFECTIVE interaction state ([_baseInteractionEnabled] with no
  /// active [runWithInteractionDisabled] scopes).
  bool _interactionEnabled = true;

  /// The state the app last requested through [setInteractionEnabled].
  bool _baseInteractionEnabled = true;

  /// Active [runWithInteractionDisabled] scopes; interaction re-enables
  /// only when the LAST overlapping scope exits.
  int _interactionBlocks = 0;

  /// Real-time statistics from the editor, updated on every cursor/content
  /// change via the `stats` protocol event.
  final ValueNotifier<MonacoLiveStats> _liveStats = ValueNotifier(
    const MonacoLiveStats(),
  );

  // Decoded editor events (sealed MonacoEvent union).
  final _events = StreamController<MonacoEvent>.broadcast();
  StreamSubscription<ProtocolEvent>? _eventSubscription;

  // Page-reload recovery (see onPageReloaded).
  final _pageReloaded = StreamController<void>.broadcast();
  StreamSubscription<MonacoPageReload>? _reloadSubscription;

  late final MonacoFocusCoordinator _focus = MonacoFocusCoordinator(
    webView: _webViewController,
    ensureReady: _ensureReady,
    invoke: (method, params) => _protocol.invoke(method, params),
    isInteractionEnabled: () => _interactionEnabled,
  );

  /// The active-tracking document handle: every call targets whatever
  /// model is currently attached to the editor. See [MonacoDocument].
  late final MonacoDocument document = MonacoDocument.internal(_invoke, null);

  /// Live completion registrations, keyed by provider id. Each entry keeps
  /// its `completions.register` params so recovery from a page reload can
  /// re-register it on the fresh page.
  final Map<String, _CompletionRegistrationState> _completionSources = {};

  /// Live Dart-defined actions, keyed by action id. Each entry keeps its
  /// `actions.register` descriptor for page-reload replay.
  final Map<String, _ActionRegistrationState> _customActions = {};
  StreamSubscription<ProtocolRequest>? _requestSubscription;
  int _registrationSeq = 0;
  MonacoCapabilities? _capabilities;

  /// Completes when the editor is fully initialized and ready to accept
  /// commands. Completes with the boot error if initialization fails
  /// (asset load, page load, protocol handshake, or editor creation).
  ///
  /// [create] returns before the editor is ready; await this future (or
  /// use the `MonacoEditor` widget, which renders loading/error chrome) for
  /// readiness.
  Future<void> get whenReady => _onReady.future;

  /// Returns `true` if the editor has finished initializing successfully
  /// and is not recovering from a page reload (see [onPageReloaded]).
  bool get isReady =>
      _onReady.isCompleted && _readyCompletedOk && _recoveryGate == null;
  bool _readyCompletedOk = false;

  /// What the loaded page can do, from the protocol handshake.
  ///
  /// Throws [StateError] before [whenReady] completes.
  MonacoCapabilities get capabilities {
    final capabilities = _capabilities;
    if (capabilities == null) {
      throw StateError(
        'capabilities is only available after whenReady completes.',
      );
    }
    return capabilities;
  }

  /// Returns `true` if the editor currently accepts user interaction.
  bool get isInteractionEnabled => _interactionEnabled;

  /// Real-time statistics (cursor position, selection, line count).
  ValueListenable<MonacoLiveStats> get stats => _liveStats;

  /// Every decoded editor event, in arrival order.
  ///
  /// The union is sealed for exhaustive switching; unknown events surface
  /// as [MonacoUnknownEvent]. Prefer the typed convenience streams below
  /// for single-concern listeners.
  Stream<MonacoEvent> get events => _events.stream;

  /// Content changes ([MonacoContentChanged]: flush flag, deltas or a
  /// truncation marker).
  Stream<MonacoContentChanged> get onContentChanged =>
      events.where((e) => e is MonacoContentChanged).cast();

  /// The new primary [Range] (or `null`) whenever the selection changes.
  Stream<Range?> get onSelectionChanged => events
      .where((e) => e is MonacoSelectionChanged)
      .map((e) => (e as MonacoSelectionChanged).selection);

  /// Monaco DOM focus transitions (`true` = focused).
  ///
  /// This is not a native input-readiness guarantee on desktop platform
  /// views; see [hasNativeInputFocus] for the authoritative signal.
  Stream<bool> get onFocusChanged => events
      .where((e) => e is MonacoFocusChanged)
      .map((e) => (e as MonacoFocusChanged).focused);

  /// Scroll deltas the editor could not consume.
  ///
  /// Events only arrive after a source was enabled with
  /// [setScrollHandoffSources] (the `MonacoEditor.scrollHandoff`
  /// configuration does this automatically). Malformed bridge payloads are
  /// dropped silently. See [MonacoScrollHandoffDetails] for the delta
  /// conventions.
  Stream<MonacoScrollHandoffDetails> get onScrollHandoff => events
      .where((e) => e is MonacoScrollHandoffEvent)
      .map((e) => (e as MonacoScrollHandoffEvent).details);

  /// Fires after the controller recovered from a page reload.
  ///
  /// The page document can reload outside the app's control: the Flutter
  /// web engine detaches and re-inserts the editor's iframe during
  /// platform-view re-composition (tab and route churn) and re-inserting an
  /// iframe reloads it, a native WebView process can recover from a crash,
  /// or the page can be refreshed. The reloaded document is a bare shell -
  /// everything page-side is discarded.
  ///
  /// The controller recovers on its own before this fires: it re-boots the
  /// editor with the ORIGINAL boot payload (options, text, language, theme
  /// as passed to [create]), waits for readiness, and re-registers every
  /// live [registerCompletions] provider and [addAction] action, so their
  /// registration handles stay valid. By the time an event arrives here the
  /// editor accepts commands again.
  ///
  /// What the controller cannot restore is state it never owned - listen to
  /// this stream to restore it:
  ///
  /// * Document content and models: text reverts to the boot text; models
  ///   opened with [openDocument] are gone (their pinned handles now throw
  ///   [MonacoJavaScriptError]) - re-open and re-activate them.
  /// * Post-boot configuration: [updateOptions], [setTheme], [defineTheme],
  ///   [setScrollHandoffSources], markers, decorations, and view states.
  /// * LSP connections: they died with the page - disconnect and reconnect.
  ///
  /// Commands that were in flight when the page reloaded fail with
  /// [MonacoPageReloadedError]; retry them from here. Commands issued while
  /// the controller recovers wait for the recovery (in issue order) and then
  /// run against the re-booted editor. If the re-boot itself fails, the
  /// failure is delivered as an error event on this stream, the editor stays
  /// unusable, and waiting and later commands fail with
  /// [MonacoPageReloadedError].
  Stream<void> get onPageReloaded => _pageReloaded.stream;

  /// Creates a new [MonacoController] and boots the editor.
  ///
  /// Returns before the editor is ready: asset preparation and WebView
  /// setup are awaited here, then the page load + boot continue in the
  /// background. Await [whenReady] before
  /// issuing commands directly, or hand the controller to the `MonacoEditor`
  /// widget, which renders loading and error chrome. Boot failures complete
  /// [whenReady] with the error.
  ///
  /// The editor is born configured: [options], [initialText], the language,
  /// and the theme travel in the `page.boot` command and apply before the
  /// first frame paints - there is no default-theme flash and no
  /// post-ready re-apply.
  ///
  /// * [options]: Initial configuration (theme, language, fonts, ...).
  /// * [initialText]: Initial document contents (never written to disk; it
  ///   travels over the protocol).
  /// * [page]: Page-level settings (custom CSS, CSP opt-ins). See
  ///   [MonacoPageConfig]; changing these requires a new controller.
  /// * [readyTimeout]: Upper bound for the whole boot (asset extraction
  ///   excluded); on expiry [whenReady] completes with a
  ///   [MonacoTimeoutError]. Defaults to [MonacoDefaults.readyTimeout]
  ///   (20s on native, 90s on web where the cold-cache first load must
  ///   download the editor bundle over the network).
  ///
  /// On web the boot can only complete while [webViewWidget] is mounted and
  /// painted (the editor iframe loads only inside the document): keep the
  /// widget in the tree underneath your loading UI rather than inserting it
  /// once [whenReady] completes. See [webViewWidget].
  static Future<MonacoController> create({
    EditorOptions? options,
    String? initialText,
    MonacoPageConfig page = const MonacoPageConfig(),
    Duration readyTimeout = MonacoDefaults.readyTimeout,
  }) async {
    // Ensure Monaco assets are ready
    await MonacoAssets.ensureReady();

    // Create platform-specific WebView controller
    final webViewController = PlatformWebViewFactory.createController();
    final protocol = MonacoProtocol(webView: webViewController);
    MonacoController? controller;

    try {
      // Initialize WebView.
      await webViewController.initialize();
      await webViewController.enableJavaScript();
      await webViewController.addJavaScriptChannel(
        'flutterChannel',
        protocol.handleChannelMessage,
      );

      // Create controller first (before loading HTML) so widget can render.
      controller = MonacoController._(protocol, webViewController);
      controller._startBoot(
        options: options,
        initialText: initialText,
        page: page,
        readyTimeout: readyTimeout,
      );
      return controller;
    } catch (_) {
      // Clean up resources on failure
      if (controller != null) {
        controller.dispose();
      } else {
        protocol.dispose();
        webViewController.dispose();
      }
      rethrow;
    }
  }

  /// Runs the two-phase boot: load page, await pageReady, dispatch
  /// page.boot, await editor ready. Uniform on all platforms; failures land
  /// in [whenReady].
  void _startBoot({
    required EditorOptions? options,
    required String? initialText,
    required MonacoPageConfig page,
    required Duration readyTimeout,
  }) {
    // Curated defaults under the caller's sparse options (caller wins).
    // A null theme falls back to the dark default here; the MonacoEditor
    // widget resolves it from the surrounding Flutter brightness instead.
    final bootOptions = MonacoDefaults.editorOptions.merge(options);
    final bootLanguage = bootOptions.language ?? MonacoDefaults.language;
    final bootTheme = bootOptions.theme ?? MonacoDefaults.darkTheme;
    // Boot failures must reach callers through [whenReady] (and the commands
    // gated on it), never as an unhandled zone error when nobody awaits it.
    _onReady.future.ignore();
    unawaited(() async {
      try {
        await () async {
          await _webViewController.load(page: page);
          debugPrint(
            '[MonacoController] Page loading (Platform: '
            '${kIsWeb ? 'Web' : defaultTargetPlatform.name})',
          );

          final handshake = await _protocol.pageReady;
          _capabilities = MonacoCapabilities.fromHandshake(handshake);

          // Boot the editor with the merged initial state; the response
          // acknowledges acceptance, the ready lifecycle follows creation.
          // The payload is kept for page-reload recovery (onPageReloaded).
          final bootPayload = <String, Object?>{
            'options': bootOptions.toMonacoOptions(),
            'text': initialText ?? '',
            'language': bootLanguage.id,
            'theme': bootTheme.id,
            'scrollHandoff': const {'wheel': false, 'touch': false},
          };
          _bootPayload = bootPayload;
          await _protocol.invoke('page.boot', bootPayload, timeout: null);

          await _protocol.editorReady;
        }().timeout(
          readyTimeout,
          onTimeout: () => throw MonacoTimeoutError(
            message:
                'Monaco Editor did not report ready in '
                '${readyTimeout.inSeconds} seconds.'
                '${kIsWeb ? ' On web the first load downloads the editor '
                          'bundle; a slow connection can exceed this deadline. '
                          'Retrying resumes from the browser cache.' : ''}',
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

  /// Create a controller for tests without touching assets or platform views.
  ///
  /// When [markReady] is true, synthetic `pageReady` and `ready` lifecycle
  /// envelopes are pushed through the real protocol decode path so the
  /// controller behaves exactly as it does against a live page.
  ///
  /// When [runBoot] is true, the REAL boot pipeline runs against the fake
  /// WebView instead ([markReady] is ignored): `load()` is expected to emit
  /// `pageReady`, `page.boot` carries [bootOptions] and [bootInitialText],
  /// and readiness follows the fake's `ready` lifecycle. Use this to
  /// exercise flows that depend on boot state, like page-reload recovery.
  /// [readyTimeout] bounds that boot like [create]'s.
  @visibleForTesting
  static Future<MonacoController> createForTesting({
    required PlatformWebViewController webViewController,
    bool markReady = true,
    String channelName = 'flutterChannel',
    bool runBoot = false,
    EditorOptions? bootOptions,
    String? bootInitialText,
    Duration readyTimeout = const Duration(seconds: 20),
  }) async {
    final protocol = MonacoProtocol(webView: webViewController);

    await webViewController.initialize();
    await webViewController.enableJavaScript();
    await webViewController.addJavaScriptChannel(
      channelName,
      protocol.handleChannelMessage,
    );

    final controller = MonacoController._(protocol, webViewController);
    if (runBoot) {
      controller._startBoot(
        options: bootOptions,
        initialText: bootInitialText,
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
        'capabilities': ['lsp', 'diff'],
      }),
    );
    // The boot chain normally captures the handshake; mirror it here so
    // `capabilities` works exactly like it does against a live page.
    _capabilities ??= const MonacoCapabilities(
      monacoVersion: 'test',
      protocolVersion: kMonacoProtocolVersion,
      lsp: true,
      diff: true,
      raw: {'lsp', 'diff'},
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

  /// Get the platform-specific WebView widget.
  ///
  /// On web, the editor iframe only loads while this widget is mounted and
  /// painted, so [whenReady] can only complete if the app keeps it in the
  /// tree - painted underneath any loading chrome (an opaque Stack overlay,
  /// as the `MonacoEditor` widget does) - from creation onward. Inserting
  /// it only after readiness, or hiding it with `Offstage` /
  /// `Visibility(visible: false)`, deadlocks the boot; the web load then
  /// fails fast with a [StateError] naming this requirement. Native
  /// WebViews load while detached, so this only constrains web.
  Widget get webViewWidget => _webViewController.widget;

  /// Ensure the editor is ready before executing commands.
  ///
  /// Awaits the readiness future unconditionally: a completer that failed is
  /// still `isCompleted`, so an isCompleted fast path would let commands skip
  /// the boot error and enter the protocol of a dead page. Every command
  /// after a failed boot must keep rethrowing the ORIGINAL boot error.
  ///
  /// After readiness, a page-reload recovery in progress ([_recoveryGate])
  /// holds the command until the re-booted editor accepts commands again.
  Future<void> _ensureReady() async {
    if (_disposed) {
      throw const MonacoDisposedError(
        message: 'MonacoController has been disposed.',
      );
    }
    await _onReady.future;
    // Loop: a newer reload can open a fresh gate while this one settles.
    for (var gate = _recoveryGate; gate != null; gate = _recoveryGate) {
      await gate.future;
    }
    if (_disposed) {
      throw const MonacoDisposedError(
        message: 'MonacoController has been disposed.',
      );
    }
  }

  /// Dispatches a protocol command after readiness; maps a JavaScript
  /// `undefined` result to `null`.
  Future<Object?> _invoke(String method, Map<String, Object?> params) async {
    await _ensureReady();
    final result = await _protocol.invoke(method, params);
    return identical(result, monacoJsUndefined) ? null : result;
  }

  /// Configures Monaco's built-in JSON diagnostics and schema validation.
  ///
  /// This applies globally to all JSON models in the editor, not just the
  /// active one. Call it once after the editor is ready (the method
  /// internally awaits readiness). Calling it again replaces the previous
  /// configuration entirely.
  ///
  /// See [JsonDiagnosticsOptions] for available settings and defaults.
  Future<void> setJsonDiagnostics(JsonDiagnosticsOptions diagnostics) async {
    await _invoke('json.configureDiagnostics', {
      'options': diagnostics.toJson(),
    });
  }

  /// Changes the editor's color theme.
  ///
  /// Accepts both built-in themes ([MonacoTheme.vsDark], ...) and custom
  /// ids previously registered with [defineTheme]:
  /// `setTheme(MonacoTheme('app-dark'))`. Throws an [ArgumentError] when
  /// the id is empty so callers don't silently activate Monaco's
  /// empty-string fallback. Waits for the editor to be ready.
  Future<void> setTheme(MonacoTheme theme) async {
    if (theme.id.trim().isEmpty) {
      throw ArgumentError.value(
        theme.id,
        'theme',
        'theme id must be a non-empty string',
      );
    }
    await _invoke('editor.setTheme', {'theme': theme.id});
  }

  /// Returns the theme currently active in the editor.
  ///
  /// Reads the live value from Monaco's runtime rather than caching what
  /// Dart most recently sent. Returns `null` when Monaco can't report a
  /// theme (e.g. on engine versions that don't expose `editor.getTheme()`).
  /// Bridge failures throw a [MonacoException].
  Future<MonacoTheme?> getTheme() async {
    final result = await _invoke('editor.getTheme', {});
    return result is String && result.isNotEmpty ? MonacoTheme(result) : null;
  }

  /// Registers or replaces a custom Monaco theme.
  ///
  /// After registration, activate the theme with
  /// `setTheme(MonacoTheme(theme.id))` or by setting
  /// [EditorOptions.theme]. For theme data that only exists as raw
  /// Monaco-shaped JSON, build the definition with
  /// [MonacoThemeDefinition.fromMonacoThemeData]. Throws an
  /// [ArgumentError] when the id is empty.
  Future<void> defineTheme(MonacoThemeDefinition theme) async {
    if (theme.id.trim().isEmpty) {
      throw ArgumentError.value(
        theme.id,
        'theme',
        'theme id must be a non-empty string',
      );
    }
    await _invoke('editor.defineTheme', {
      'id': theme.id,
      'data': theme.toMonacoThemeData(),
    });
  }

  /// Sets the background color of the native WebView container.
  ///
  /// This targets the platform-side WebView surface only - it does NOT
  /// change Monaco's HTML host page or Monaco's own `editor.background`
  /// theme token. On macOS, native WebView background updates may be
  /// unreliable; prefer [setHostPageBackgroundColor] there or register a
  /// custom `MonacoThemeDefinition` with the desired `editor.background`.
  Future<void> setBackgroundColor(Color color) async {
    await _webViewController.setBackgroundColor(color);
  }

  /// Sets the background color of Monaco's HTML host page.
  ///
  /// Writes a CSS color to `html`, `body`, and the Monaco container element
  /// via the JS bridge. This is the most reliable surface to recolor when
  /// the native WebView's background isn't honored (notably macOS platform
  /// views). To change Monaco's own editor surface, register a
  /// [MonacoThemeDefinition] with an `editor.background` color instead -
  /// this method does not affect Monaco's internal theme tokens.
  Future<void> setHostPageBackgroundColor(Color color) async {
    await _invoke('page.setBackground', {'color': _cssRgba(color)});
  }

  /// Converts a Flutter [Color] to a CSS `rgba(...)` string.
  String _cssRgba(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    return 'rgba($r, $g, $b, ${color.a})';
  }

  /// Toggles whether the editor intercepts pointer events.
  ///
  /// On Web, this is used to allow Flutter overlays (like dialogs) to receive
  /// pointer events even when they overlap the editor. When disabled, the
  /// editor will not respond to mouse or touch events.
  ///
  /// On native platforms, this may be a no-op as overlays work correctly by default.
  Future<void> setInteractionEnabled(bool enabled) async {
    // No need to wait for ready, can be set immediately
    if (_disposed) return;
    _baseInteractionEnabled = enabled;
    await _applyEffectiveInteraction();
  }

  /// Pushes `base && no active disable scopes` to the platform view, so a
  /// [setInteractionEnabled] call during a [runWithInteractionDisabled] run
  /// composes instead of being clobbered by the run's exit.
  Future<void> _applyEffectiveInteraction() async {
    final effective = _baseInteractionEnabled && _interactionBlocks == 0;
    _interactionEnabled = effective;
    await _webViewController.setInteractionEnabled(effective);
  }

  /// Runs [action] with editor interaction temporarily disabled, restoring the
  /// previous state in a `finally` block.
  ///
  /// Useful for transient Flutter overlays that are NOT pushed as routes (so
  /// `MonacoFocusGuard` cannot detect them) and that are NOT static enough
  /// to wrap in a `MonacoOverlayBoundary` - typically `ScaffoldMessenger`
  /// snackbars with action buttons, toasts, or imperative `Overlay.insert`
  /// entries shown for a known duration.
  ///
  /// On native platforms `setInteractionEnabled` is a no-op, so this is a
  /// thin wrapper around the [action] there.
  ///
  /// Example:
  /// ```dart
  /// await controller.runWithInteractionDisabled(() async {
  ///   ScaffoldMessenger.of(context).showSnackBar(
  ///     SnackBar(
  ///       content: const Text('Saved'),
  ///       action: SnackBarAction(label: 'Undo', onPressed: undo),
  ///     ),
  ///   );
  ///   await Future<void>.delayed(const Duration(seconds: 4));
  /// });
  /// ```
  Future<T> runWithInteractionDisabled<T>(FutureOr<T> Function() action) async {
    if (_disposed) {
      return await Future<T>.value(action());
    }

    // Ref-counted, not snapshot/restore: overlapping runs (two toasts, a
    // snackbar racing a dialog) keep interaction disabled until the LAST
    // scope exits, and an external setInteractionEnabled during the run
    // updates the base state instead of being overwritten on exit.
    _interactionBlocks++;
    await _applyEffectiveInteraction();
    try {
      return await Future<T>.value(action());
    } finally {
      _interactionBlocks--;
      if (!_disposed) {
        await _applyEffectiveInteraction();
      }
    }
  }

  /// Updates the editor configuration options.
  ///
  /// Only the fields present in [options] will be updated; others remain unchanged.
  Future<void> updateOptions(EditorOptions options) async {
    await _invoke('editor.updateOptions', {
      'options': options.toMonacoOptions(),
    });
  }

  /// Registers a dynamic completion provider for the given [languages].
  ///
  /// The [provider] callback is invoked whenever the user requests
  /// completions (e.g., Ctrl+Space). Provider errors are logged and answered
  /// with an empty suggestion list; they never crash the editor.
  ///
  /// * [id]: Optional unique identifier. If omitted, one is generated.
  /// * [triggerCharacters]: Characters that automatically trigger the
  ///   completion (e.g., `.` or `@`).
  ///
  /// Returns a [MonacoCompletionRegistration]; call its `dispose` to remove
  /// the provider.
  Future<MonacoCompletionRegistration> registerCompletions({
    String? id,
    required List<MonacoLanguage> languages,
    List<String> triggerCharacters = const [],
    required CompletionProvider provider,
  }) async {
    if (languages.isEmpty) {
      throw ArgumentError.value(languages, 'languages', 'Cannot be empty');
    }
    if (id != null && _completionSources.containsKey(id)) {
      throw ArgumentError.value(id, 'id', 'Completion source already exists');
    }

    final providerId = id ?? 'flutter_${++_registrationSeq}';
    final registration = _CompletionRegistrationState(
      provider: provider,
      params: {
        'id': providerId,
        'languages': [for (final language in languages) language.id],
        'triggerCharacters': List<String>.from(triggerCharacters),
      },
    );
    _completionSources[providerId] = registration;
    try {
      await _invoke('completions.register', registration.params);
    } catch (e) {
      _completionSources.remove(providerId);
      rethrow;
    }
    return MonacoCompletionRegistration.internal(
      id: providerId,
      unregister: () => _unregisterCompletions(providerId),
    );
  }

  /// Registers a static list of completion items.
  ///
  /// Useful for simple keyword lists or fixed snippets.
  Future<MonacoCompletionRegistration> registerStaticCompletions({
    String? id,
    required List<MonacoLanguage> languages,
    List<String> triggerCharacters = const [],
    required List<CompletionItem> items,
    bool isIncomplete = false,
  }) {
    return registerCompletions(
      id: id,
      languages: languages,
      triggerCharacters: triggerCharacters,
      provider: (_) async =>
          CompletionList(suggestions: items, isIncomplete: isIncomplete),
    );
  }

  Future<void> _unregisterCompletions(String id) async {
    _completionSources.remove(id);
    if (_disposed) return;
    await _invoke('completions.unregister', {'id': id});
  }

  /// Runs a Monaco editor action, e.g.
  /// `executeAction(MonacoAction.formatDocument)`. Custom command ids run
  /// via `MonacoAction('my.command')`.
  Future<void> executeAction(MonacoAction action, {Object? args}) async {
    await _invoke('editor.executeAction', {
      'actionId': action.id,
      'args': args,
    });
  }

  /// Registers a Dart-defined editor action (D16).
  ///
  /// The action shows up in the command palette under
  /// [MonacoActionDescriptor.label], binds the descriptor's keybindings
  /// (e.g. Cmd/Ctrl+S save hooks), and optionally appears in the context
  /// menu. Each invocation calls [run] on the Dart side; errors thrown by
  /// [run] are logged in the page console and never crash the editor.
  ///
  /// Returns a [MonacoActionRegistration]; call its `dispose` to remove the
  /// action again. Registering a second action with the same id throws an
  /// [ArgumentError].
  Future<MonacoActionRegistration> addAction(
    MonacoActionDescriptor descriptor,
    Future<void> Function() run,
  ) async {
    final actionId = descriptor.id.id;
    if (_customActions.containsKey(actionId)) {
      throw ArgumentError.value(
        descriptor,
        'descriptor',
        'Action "$actionId" is already registered',
      );
    }
    final registration = _ActionRegistrationState(
      run: run,
      descriptor: descriptor.toJson(),
    );
    _customActions[actionId] = registration;
    try {
      await _invoke('actions.register', registration.descriptor);
    } catch (e) {
      _customActions.remove(actionId);
      rethrow;
    }
    return MonacoActionRegistration.internal(
      id: descriptor.id,
      unregister: () => _removeAction(actionId),
    );
  }

  Future<void> _removeAction(String actionId) async {
    _customActions.remove(actionId);
    if (_disposed) return;
    await _invoke('actions.unregister', {'id': actionId});
  }

  /// Requests editor focus, retrying to ride out layout transitions.
  ///
  /// Cooperative by default: background [MonacoFocusIntent.maintenance]
  /// calls never steal the keyboard from a focused Flutter text input.
  /// Pass [MonacoFocusIntent.user] only from direct pointer interaction
  /// with the editor. See [MonacoFocusCoordinator.requestFocus] for the
  /// full platform decision table.
  Future<void> requestFocus({
    MonacoFocusIntent intent = MonacoFocusIntent.maintenance,
    int attempts = 3,
    Duration interval = const Duration(milliseconds: 24),
  }) {
    return _focus.requestFocus(
      intent: intent,
      attempts: attempts,
      interval: interval,
    );
  }

  /// Whether the native layer currently routes keyboard input to the
  /// editor's WebView.
  ///
  /// `true`/`false` where the platform can answer authoritatively (macOS
  /// first responder, Windows WebView2); `null` where it cannot (Android,
  /// iOS, Web, headless tests). This is the real desktop input-readiness
  /// signal - [onFocusChanged] only reports Monaco's DOM focus.
  Future<bool?> hasNativeInputFocus() => _focus.hasNativeInputFocus();

  /// Hands native keyboard focus back to the Flutter view if the editor's
  /// WebView currently holds it. No-op elsewhere.
  Future<void> releaseNativeFocus() => _focus.releaseNativeFocus();

  /// Forces the Monaco editor to re-measure its container and update its layout.
  ///
  /// Call this if the widget size changes but the editor does not update automatically.
  Future<void> layout() async {
    await _invoke('editor.layout', {});
  }

  /// Scrolls the editor to the very top (line 1, column 1).
  Future<void> scrollToTop() async {
    await _invoke('editor.scrollToEdge', {'edge': 'top'});
  }

  /// Scrolls the editor to the last line.
  Future<void> scrollToBottom() async {
    await _invoke('editor.scrollToEdge', {'edge': 'bottom'});
  }

  /// Enables or disables edge scroll handoff sources inside the editor page.
  ///
  /// When a source is enabled, the page installs the matching DOM listeners
  /// and posts `scrollHandoff` events (surfaced through [onScrollHandoff])
  /// for scroll gestures the editor cannot consume, arbitrated by [policy]
  /// (the momentum-absorbing [MonacoScrollBoundaryPolicy.newGestureOnly] by
  /// default). Changing the policy cancels any handoff gesture in flight.
  /// Disabling a source removes its listeners again, so both sources
  /// disabled restores the exact pre-feature behavior. Waits for the editor
  /// to be ready.
  ///
  /// `MonacoEditor` calls this automatically from its `scrollHandoff`
  /// configuration; call it directly only for headless or custom-widget
  /// integrations that consume [onScrollHandoff] themselves.
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

  // --- EVENT HANDLING ---

  /// Wire up protocol event listeners.
  void _wireEvents() {
    _eventSubscription = _protocol.events.listen((event) {
      // Stats feed the ValueListenable, not the public event union.
      if (event.name == 'stats') {
        try {
          _liveStats.value = MonacoLiveStats.fromJson(
            Map<String, dynamic>.from(event.data),
          );
        } catch (e) {
          debugPrint('[MonacoController] Failed to parse stats: $e');
        }
        return;
      }
      // LSP internals are consumed by the LSP manager, not surfaced here.
      if (event.name == 'lspStatus' || event.name == 'lspMessage') {
        return;
      }
      _events.add(MonacoEvent.fromProtocolEvent(event));
    });
  }

  /// Wire up the JS-initiated request channel (6.5): completion providers
  /// and Dart-defined action callbacks.
  void _wireRequests() {
    _requestSubscription = _protocol.requests.listen((request) {
      unawaited(_handleRequest(request));
    });
  }

  /// Wire up page-reload recovery (see [onPageReloaded]).
  void _wireReloadRecovery() {
    _reloadSubscription = _protocol.pageReloads.listen((reload) {
      unawaited(_recoverFromPageReload(reload));
    });
  }

  /// Converges a freshly reloaded page back to a booted, usable editor.
  ///
  /// Replays the original boot payload, awaits the reloaded page's ready
  /// lifecycle, re-registers Dart-side completion providers and custom
  /// actions, then opens the command gate and announces the recovery on
  /// [onPageReloaded]. A newer reload arriving mid-recovery fails this
  /// attempt's commands with [MonacoPageReloadedError] and runs its own
  /// recovery, which takes over the gate; a genuine boot failure fails the
  /// gate with [MonacoPageReloadedError] and is surfaced as an error on
  /// [onPageReloaded].
  Future<void> _recoverFromPageReload(MonacoPageReload reload) async {
    if (_disposed) return;
    final bootPayload = _bootPayload;
    if (bootPayload == null) {
      // Reload before the first boot dispatched anything: there is nothing
      // to replay, and the original boot flow still owns readiness.
      debugPrint(
        '[MonacoController] Page reloaded before boot completed; '
        'leaving recovery to the boot flow.',
      );
      return;
    }
    debugPrint('[MonacoController] Page reloaded; re-booting the editor.');
    final generation = ++_recoveryGeneration;
    final gate = _openRecoveryGate();
    try {
      _capabilities = MonacoCapabilities.fromHandshake(reload.handshake);
      await _protocol.invoke('page.boot', bootPayload, timeout: null);
      await reload.editorReady;
      await _replayRegistrations();
      if (_disposed || generation != _recoveryGeneration) return;
      _recoveryGate = null;
      gate.complete();
      _pageReloaded.add(null);
    } on MonacoDisposedError {
      // Disposed mid-recovery; dispose settles the gate.
    } on MonacoPageReloadedError catch (e, st) {
      // Normally superseded by an even newer reload whose recovery takes
      // over the gate. A reloaded page that cannot be re-booted (protocol
      // skew) interrupts this attempt without starting a new one; let the
      // newer recovery (if any) register before deciding.
      await Future<void>.delayed(Duration.zero);
      if (_disposed || generation != _recoveryGeneration) return;
      _failRecovery(gate, e, st);
    } catch (e, st) {
      debugPrint('[MonacoController] Page reload recovery failed: $e');
      if (_disposed || generation != _recoveryGeneration) return;
      _failRecovery(gate, e, st);
    }
  }

  /// Returns the pending recovery gate, opening a new one when the page was
  /// healthy or the previous recovery failed.
  Completer<void> _openRecoveryGate() {
    final current = _recoveryGate;
    if (current != null && !current.isCompleted) return current;
    final gate = Completer<void>();
    // Settled with an error when recovery fails or the controller is
    // disposed, possibly while no command waits on it.
    gate.future.ignore();
    _recoveryGate = gate;
    return gate;
  }

  /// Fails waiting and later commands with [MonacoPageReloadedError] and
  /// reports [error] on [onPageReloaded]. The failed gate stays in place
  /// until a newer reload recovers the editor.
  void _failRecovery(Completer<void> gate, Object error, StackTrace st) {
    if (!gate.isCompleted) {
      gate.completeError(
        MonacoPageReloadedError(
          message:
              'The Monaco page reloaded and the editor could not be '
              'recovered: $error',
          operation: 'page.boot',
        ),
        st,
      );
    }
    _pageReloaded.addError(error, st);
  }

  /// Re-registers every live completion provider and custom action on the
  /// reloaded page, keeping existing registration handles valid.
  Future<void> _replayRegistrations() async {
    for (final entry in List.of(_completionSources.entries)) {
      // Skip registrations disposed while recovery was in flight.
      if (!identical(_completionSources[entry.key], entry.value)) continue;
      await _protocol.invoke('completions.register', entry.value.params);
    }
    for (final entry in List.of(_customActions.entries)) {
      if (!identical(_customActions[entry.key], entry.value)) continue;
      await _protocol.invoke('actions.register', entry.value.descriptor);
    }
  }

  Future<void> _handleRequest(ProtocolRequest request) async {
    try {
      switch (request.name) {
        case 'completion':
          await _handleCompletionRequest(request);
        case 'action':
          await _handleActionRequest(request);
        default:
          await _protocol.respond(
            request.id,
            error: 'Unknown request: ${request.name}',
          );
      }
    } catch (e) {
      // Failing to answer (e.g. the page went away mid-request) is not an
      // editor error; the JS side treats a missing answer as cancellation.
      debugPrint('[MonacoController] request "${request.name}" failed: $e');
    }
  }

  Future<void> _handleCompletionRequest(ProtocolRequest request) async {
    const emptySuggestions = {'suggestions': <Object?>[]};

    CompletionRequest completionRequest;
    try {
      completionRequest = CompletionRequest.fromJson(
        Map<String, dynamic>.from(request.data),
      );
    } on FormatException catch (e) {
      debugPrint('[MonacoController] malformed completion request: $e');
      await _protocol.respond(request.id, value: emptySuggestions);
      return;
    }

    final provider = _completionSources[completionRequest.providerId]?.provider;
    if (provider == null) {
      await _protocol.respond(request.id, value: emptySuggestions);
      return;
    }

    Map<String, dynamic> payload;
    try {
      payload = (await provider(completionRequest)).toJson();
    } catch (e) {
      debugPrint('[MonacoController] completion provider failed: $e');
      payload = Map<String, dynamic>.from(emptySuggestions);
    }
    await _protocol.respond(request.id, value: payload);
  }

  Future<void> _handleActionRequest(ProtocolRequest request) async {
    final actionId = request.data['actionId'];
    final run = actionId is String ? _customActions[actionId]?.run : null;
    if (run == null) {
      await _protocol.respond(request.id, error: 'Unknown action: $actionId');
      return;
    }
    try {
      await run();
    } catch (e) {
      await _protocol.respond(
        request.id,
        error: 'Action "$actionId" failed: $e',
      );
      return;
    }
    await _protocol.respond(request.id, value: const <String, Object?>{});
  }

  // --- SELECTION AND NAVIGATION ---

  /// Retrieves the current primary selection range.
  ///
  /// Returns `null` when the editor reports no selection. Bridge failures
  /// throw a [MonacoException].
  Future<Range?> getSelection() async {
    final result = await _invoke('editor.getSelection', {});
    return result is Map
        ? Range.fromJson(Map<String, dynamic>.from(result))
        : null;
  }

  /// Selects the specified [range] in the editor.
  Future<void> setSelection(Range range) async {
    await _invoke('editor.setSelection', {'range': range.toJson()});
  }

  // --- NAVIGATION ---

  /// Reveal a line in the editor with validation
  Future<void> revealLine(int line, {bool center = false}) async {
    await revealRange(Range.lines(line, line), center: center);
  }

  /// Reveal a range in the editor
  Future<void> revealRange(Range range, {bool center = false}) async {
    await _invoke('editor.reveal', {'range': range.toJson(), 'center': center});
  }

  /// Reveal a position in the editor
  Future<void> revealPosition(Position position, {bool center = false}) async {
    final range = Range.fromPositions(position, position);
    await revealRange(range, center: center);
  }

  // --- DECORATIONS ---

  /// Creates an independent decoration set.
  ///
  /// Each set wraps one Monaco decorations collection: setting it replaces
  /// only that set's decorations, so multiple features can decorate the
  /// editor without clobbering each other. Dispose the set to remove its
  /// decorations and release the page-side collection.
  Future<MonacoDecorationSet> createDecorationSet() async {
    final result = await _invoke('decorations.create', {});
    if (result is String && result.isNotEmpty) {
      return MonacoDecorationSet.internal(_invoke, result);
    }
    throw MonacoProtocolError(
      operation: 'decorations.create',
      message: 'Expected a decoration set id, got ${result.runtimeType}.',
    );
  }

  // --- VIEW STATE ---

  /// Captures the current view state (cursor, scroll, folding) as an
  /// opaque, persistable [MonacoViewState].
  ///
  /// Returns an empty state when the editor has no model to capture.
  /// Throws a [MonacoException] on failure.
  Future<MonacoViewState> captureViewState() async {
    final result = await _invoke('editor.captureViewState', {});
    return MonacoViewState.fromJson(
      result is Map ? Map<String, Object?>.from(result) : const {},
    );
  }

  /// Restores a previously captured view state.
  Future<void> restoreViewState(MonacoViewState state) async {
    if (state.isEmpty) return;
    await _invoke('editor.restoreViewState', {'state': state.toJson()});
  }

  // --- DOCUMENTS ---

  /// Opens a new document (Monaco model) and returns a pinned handle.
  ///
  /// Give language servers stable, file-like URIs (`file:///...`) so they
  /// can associate diagnostics and cross-file features correctly. Opening
  /// a document does not activate it; call [activateDocument].
  Future<MonacoDocument> openDocument({
    required String text,
    MonacoLanguage language = MonacoLanguage.plaintext,
    Uri? uri,
  }) async {
    final result = await _invoke('docs.open', {
      'text': text,
      'language': language.id,
      'uri': uri?.toString(),
    });
    final createdUri = result is String ? Uri.tryParse(result) : null;
    if (createdUri == null) {
      throw MonacoProtocolError(
        operation: 'docs.open',
        message: 'Expected a model URI string, got: $result',
      );
    }
    return MonacoDocument.internal(_invoke, createdUri);
  }

  /// Attaches [document] to the editor (making it the active model).
  ///
  /// Throws [ArgumentError] for the active-tracking handle (it has no URI
  /// to activate).
  Future<void> activateDocument(MonacoDocument document) async {
    final uri = document.uri;
    if (uri == null) {
      throw ArgumentError.value(
        document,
        'document',
        'The active-tracking handle is already active; pass a pinned '
            'handle from openDocument/documentByUri/listDocuments.',
      );
    }
    await _invoke('docs.activate', {'uri': uri.toString()});
  }

  /// Pinned handles for every open document.
  Future<List<MonacoDocument>> listDocuments() async {
    final list = await _invoke('docs.list', {});
    if (list is! List) {
      throw MonacoProtocolError(
        operation: 'docs.list',
        message: 'Expected a list of model URIs, got ${list.runtimeType}.',
      );
    }
    return list
        .map((e) => Uri.tryParse(e.toString()))
        .whereType<Uri>()
        .map((uri) => MonacoDocument.internal(_invoke, uri))
        .toList();
  }

  /// A pinned handle for [uri] without a bridge round trip.
  ///
  /// The handle is constructed locally; calls through it throw a
  /// [MonacoJavaScriptError] if no document with that URI is open.
  MonacoDocument documentByUri(Uri uri) =>
      MonacoDocument.internal(_invoke, uri);

  /// Returns the current cursor position.
  ///
  /// Returns `null` when the editor reports no cursor. Throws a
  /// [MonacoException] on bridge failure.
  Future<Position?> getCursorPosition() async {
    final result = await _invoke('editor.getCursor', {});
    return result is Map
        ? Position.fromJson(Map<String, dynamic>.from(result))
        : null;
  }

  /// Set cursor position
  Future<void> setCursorPosition(Position position) async {
    await _invoke('editor.setCursor', {
      'position': {'lineNumber': position.line, 'column': position.column},
    });
  }

  /// Returns a full editor snapshot in ONE bridge round trip
  /// (`editor.getState`).
  Future<EditorState> getEditorState() async {
    final result = await _invoke('editor.getState', {});
    if (result is! Map) {
      throw MonacoProtocolError(
        operation: 'editor.getState',
        message: 'Expected a state map, got ${result.runtimeType}.',
      );
    }
    return EditorState.fromJson(Map<String, dynamic>.from(result));
  }

  // --- LANGUAGE SERVER PROTOCOL ---

  /// Connects the editor to a language server and returns a handle to the
  /// live connection.
  ///
  /// Monaco's built-in LSP client (Monaco 0.55+) registers every language
  /// feature the server advertises - completions, hover, go-to-definition,
  /// references, rename, formatting, code actions, folding, inlay hints,
  /// semantic tokens, and diagnostics - directly inside the editor. After
  /// this call resolves, the editor "just works"; nothing needs to be
  /// mirrored into Dart.
  ///
  /// The call waits for editor readiness, establishes the [transport], and
  /// resolves only after the LSP `initialize` handshake completes. On
  /// failure (unreachable server, CSP-blocked WebSocket, handshake timeout)
  /// it throws and no connection is registered.
  ///
  /// * [id]: Unique identifier for this connection within the controller.
  ///   Reusing an id that is still connected throws a [StateError].
  /// * [transport]: Where the server lives - [LspWebSocketTransport],
  ///   [LspBridgedTransport] (see [LspServerProcess] for local stdio servers
  ///   on desktop), or [LspCustomTransport].
  /// * [reconnectPolicy]: Optional automatic reconnect for unexpected
  ///   transport drops after the connection was open. Defaults to no
  ///   reconnecting. Not supported for bridged transports.
  /// * [initializationTimeout]: Upper bound for transport setup plus the
  ///   `initialize` handshake, per attempt.
  ///
  /// ### Model URIs matter
  ///
  /// Language servers key their state on document URIs. Create models with
  /// stable, file-like URIs ([openDocument] with a `file:///...` uri) so the
  /// server can associate diagnostics and cross-file features correctly.
  ///
  /// ### Scoping and multiple servers
  ///
  /// Monaco's LSP client synchronizes **all** models to the server and
  /// scopes feature providers by the server's advertised
  /// `documentSelector`s. Servers that advertise capabilities without a
  /// selector are registered for every language. Multiple concurrent
  /// connections are allowed, but note that LSP diagnostics from all
  /// connections share the Monaco marker owner `'lsp'` - prefer one server
  /// per editor unless your servers publish diagnostics for disjoint files.
  ///
  /// ### Example (WebSocket)
  ///
  /// ```dart
  /// final controller = await MonacoController.create(
  ///   page: const MonacoPageConfig(
  ///     allowedConnectSources: ['ws://127.0.0.1:3000'],
  ///   ),
  /// );
  /// final connection = await controller.connectLanguageServer(
  ///   id: 'pyright',
  ///   transport: LspWebSocketTransport(
  ///     url: Uri.parse('ws://127.0.0.1:3000/python'),
  ///   ),
  /// );
  /// connection.stateChanges.listen(print);
  /// ```
  Future<LanguageServerConnection> connectLanguageServer({
    required String id,
    required LspTransport transport,
    LspReconnectPolicy reconnectPolicy = const LspReconnectPolicy.none(),
    Duration initializationTimeout = const Duration(seconds: 30),
  }) async {
    await _ensureReady();
    return _lspManager.connect(
      id: id,
      transport: transport,
      reconnectPolicy: reconnectPolicy,
      initializationTimeout: initializationTimeout,
    );
  }

  /// Disconnects the language server connection registered under [id].
  ///
  /// No-op when the id is unknown or already closed. Equivalent to calling
  /// `disconnect()` on the [LanguageServerConnection] handle.
  Future<void> disconnectLanguageServer(String id) {
    return _lspManager.disconnect(id);
  }

  /// The language server connections that have not permanently closed.
  List<LanguageServerConnection> get languageServerConnections =>
      _lspManager.connections;

  /// The active language server connection registered under [id], or `null`.
  LanguageServerConnection? languageServerConnection(String id) =>
      _lspManager.connection(id);

  // --- JAVASCRIPT ESCAPE HATCH ---

  /// Executes arbitrary JavaScript in the editor WebView.
  ///
  /// This is an advanced escape hatch for scenarios not covered by the typed
  /// Dart API. Prefer the typed surface - [document] methods such as
  /// `setText`/`setMarkers`, [getSelection], and [executeAction] - when it
  /// covers your use case.
  ///
  /// Useful for configuring Monaco language services, such as JSON schemas or
  /// TypeScript options, or for calling Monaco APIs not yet wrapped by this
  /// package.
  ///
  /// Loading third-party plugin scripts at runtime requires bundling those
  /// scripts with your app and respecting the editor page's
  /// Content-Security-Policy. The default CSP does not allow remote script
  /// origins.
  ///
  /// Waits for the editor to be ready before executing.
  ///
  /// ## Security
  ///
  /// Do not interpolate untrusted or user-provided values directly into
  /// [script]. This is raw JavaScript execution and string concatenation can
  /// create a script-injection vulnerability. Use `jsonEncode` for dynamic
  /// values:
  ///
  /// ```dart
  /// // Bad if userInput is attacker-controlled.
  /// await controller.runJavaScript('window.setName("$userInput")');
  ///
  /// // Good: jsonEncode creates a safe JavaScript literal.
  /// await controller.runJavaScript(
  ///   'window.setName(${jsonEncode(userInput)})',
  /// );
  /// ```
  ///
  /// See also:
  /// - [evaluateJavaScript] for typed, cross-platform result normalization.
  /// - [runJavaScriptReturningResultRaw] for raw platform return values.
  Future<void> runJavaScript(String script) async {
    await _ensureReady();
    await _webViewController.runJavaScript(script);
  }

  /// Evaluates a JavaScript expression and returns a Dart value of type [T].
  ///
  /// This is the recommended way to read values from the editor's JavaScript
  /// context. It normalizes platform differences so numeric, boolean, string,
  /// list, map, and null values behave consistently across supported
  /// platforms (the expression rides the `page.eval` protocol command).
  ///
  /// [expression] must be a JavaScript expression. For multi-statement logic,
  /// pass an IIFE expression:
  ///
  /// ```dart
  /// final count = await controller.evaluateJavaScript<int>(
  ///   '(() => { const editors = monaco.editor.getEditors(); return editors.length; })()',
  /// );
  /// ```
  ///
  /// Returns [defaultValue] (default `null`) when the expression returns
  /// `undefined` or `null`. Numbers convert between `int` and `double`, and
  /// numbers and booleans convert to `String`. Throws a
  /// [MonacoProtocolError] when the value cannot be converted to [T] (for
  /// example an object or array requested as `String`; return
  /// `JSON.stringify(...)` from the expression for its JSON text);
  /// JavaScript execution errors propagate as [MonacoJavaScriptError].
  ///
  /// ## Security
  ///
  /// Same caveat as [runJavaScript]: do not interpolate untrusted input into
  /// [expression]. Use `jsonEncode` for dynamic values.
  ///
  /// ## JSON compatibility
  ///
  /// The returned JavaScript value must be JSON-serializable. Values such as
  /// functions, symbols, BigInts, DOM nodes, and circular objects are not
  /// supported by this typed evaluator. Use [runJavaScriptReturningResultRaw]
  /// if you need raw platform behavior.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final editorCount = await controller.evaluateJavaScript<int>(
  ///   'monaco.editor.getEditors().length',
  /// );
  /// ```
  Future<T?> evaluateJavaScript<T>(String expression, {T? defaultValue}) async {
    await _ensureReady();
    final result = await _protocol.invoke('page.eval', {
      'expression': expression,
    });
    if (identical(result, monacoJsUndefined) || result == null) {
      return defaultValue;
    }
    if (result is T) return result as T;
    // Number normalization: platforms and JSON round-trips blur int/double.
    if (T == int && result is num) return result.toInt() as T;
    if (T == double && result is num) return result.toDouble() as T;
    // Scalars only: a map or list has no faithful string form here
    // (Dart's toString is not JSON), so it is a conversion failure.
    if (T == String && (result is num || result is bool)) {
      return result.toString() as T;
    }
    throw MonacoProtocolError(
      operation: 'page.eval',
      message:
          'Expression result of type ${result.runtimeType} cannot be '
          'converted to $T.',
    );
  }

  /// Executes JavaScript and returns the platform-native result.
  ///
  /// Advanced use only. Return types vary by platform:
  ///
  /// - iOS, macOS, and Web usually return native Dart values.
  /// - Android may return JSON-encoded strings.
  /// - Windows WebView2 may return strings where numeric and boolean literals
  ///   remain strings.
  ///
  /// Prefer [evaluateJavaScript] for cross-platform consistency. Use this
  /// method only when you specifically need the raw platform return shape, for
  /// example for debugging or advanced WebView interop.
  ///
  /// Waits for the editor to be ready before executing.
  ///
  /// ## Security
  ///
  /// Same caveat as [runJavaScript].
  Future<Object?> runJavaScriptReturningResultRaw(String script) async {
    await _ensureReady();
    return _webViewController.runJavaScriptReturningResult(script);
  }

  // --- HELPERS ---
  /// Dispose the controller and clean up resources
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
          message: 'MonacoController disposed before the editor became ready.',
        ),
      );
    }
    // Commands waiting for a page-reload recovery must not wait forever.
    final gate = _recoveryGate;
    if (gate != null && !gate.isCompleted) {
      gate.completeError(
        const MonacoDisposedError(
          message: 'MonacoController disposed while recovering a page reload.',
        ),
      );
    }
    // LSP connections must come down before the WebView: closing them fires
    // bridged-transport onClose callbacks (e.g. killing server processes)
    // and finalizes connection state streams.
    _lspManager.dispose();
    _eventSubscription?.cancel();
    _requestSubscription?.cancel();
    _reloadSubscription?.cancel();
    _completionSources.clear();
    _customActions.clear();
    _events.close();
    _pageReloaded.close();
    _liveStats.dispose();
    _protocol.dispose();
    _webViewController.dispose();
  }
}

/// Replay state for one live completion registration: the Dart [provider]
/// answering requests, and the `completions.register` [params] re-sent when
/// a page reload discards the page-side registration.
class _CompletionRegistrationState {
  _CompletionRegistrationState({required this.provider, required this.params});

  final CompletionProvider provider;
  final Map<String, Object?> params;
}

/// Replay state for one live Dart-defined action: the [run] callback, and
/// the `actions.register` [descriptor] re-sent after a page reload.
class _ActionRegistrationState {
  _ActionRegistrationState({required this.run, required this.descriptor});

  final Future<void> Function() run;
  final Map<String, Object?> descriptor;
}
