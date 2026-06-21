import 'dart:async';
import 'dart:convert';

import 'package:convert_object/convert_object.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_monaco/src/core/monaco_bridge.dart';
import 'package:flutter_monaco/src/platform/platform_webview.dart';

/// A callback function that provides completion items for a given
/// [CompletionRequest]. It should return a [Future] that resolves to a
/// [CompletionList].
typedef CompletionProvider =
    Future<CompletionList> Function(CompletionRequest request);

/// Describes why Monaco input focus is being requested.
///
/// The distinction matters on desktop platform views: background maintenance
/// must not steal the keyboard from Flutter text inputs, while direct user
/// interaction with Monaco is an intentional keyboard handoff that may release
/// Flutter's active text input before Monaco is focused.
enum MonacoFocusIntent {
  /// Focus requested because the user directly interacted with Monaco.
  user,

  /// Focus requested by background maintenance such as route or lifecycle sync.
  maintenance,
}

/// Manages the lifecycle and interaction with a Monaco Editor instance.
///
/// The [MonacoController] bridges Dart and the underlying JavaScript editor,
/// providing methods to read/write content, manage selection, and execute commands.
///
/// ### Usage
/// * Call [create] to instantiate a controller off-widget (headless or advanced usage).
/// * Use [setValue] / [getValue] to manage content.
/// * Listen to [onContentChanged] for real-time updates.
class MonacoController {
  MonacoController._(this._bridge, this._webViewController) {
    _wireEvents();
  }

  static const String _jsEvalEnvelopeKey = '__flutterMonacoEval';
  static const String _jsEvalValueKey = 'value';
  static const String _jsEvalUndefinedKey = 'isUndefined';
  static const String _jsEvalOkKey = 'ok';
  static const String _jsEvalErrorKey = 'error';
  static const _jsUndefined = _JavaScriptUndefinedValue();

  final MonacoBridge _bridge;
  final PlatformWebViewController _webViewController;
  final Completer<void> _onReady = Completer<void>();
  bool _disposed = false;
  bool _interactionEnabled = true;

  // Event streams
  final _onContentChanged = StreamController<bool>.broadcast();
  final _onSelectionChanged = StreamController<Range?>.broadcast();
  final _onFocus = StreamController<void>.broadcast();
  final _onBlur = StreamController<void>.broadcast();

  // Decoration tracking
  List<String> _decorationIds = const [];

  // Content queuing for pre-ready calls
  String? _queuedValue;
  MonacoLanguage? _queuedLanguage;
  final List<_RegisteredCompletion> _queuedCompletionSources = [];
  final Map<String, _RegisteredCompletion> _completionSources = {};
  bool _completionListenerWired = false;

  /// Completes when the editor is fully initialized and ready to accept commands.
  Future<void> get onReady => _onReady.future;

  /// Returns `true` if the editor has finished initializing.
  bool get isReady => _onReady.isCompleted;

  /// Returns `true` if the editor currently accepts user interaction.
  bool get isInteractionEnabled => _interactionEnabled;

  /// Exposes real-time statistics (cursor position, selection, line count).
  ValueNotifier<LiveStats> get liveStats => _bridge.liveStats;

  /// Stream emitting `true` (flush) or `false` (partial) when content changes.
  Stream<bool> get onContentChanged => _onContentChanged.stream;

  /// Stream emitting the new [Range] whenever the cursor selection changes.
  Stream<Range?> get onSelectionChanged => _onSelectionChanged.stream;

  /// Stream emitting Monaco DOM focus events.
  ///
  /// This is not a native input-readiness guarantee on desktop platform views.
  Stream<void> get onFocus => _onFocus.stream;

  /// Stream emitting Monaco DOM blur events.
  Stream<void> get onBlur => _onBlur.stream;

  /// Creates and initializes a new [MonacoController].
  ///
  /// This method spins up the WebView and loads the Monaco resources.
  ///
  /// On native platforms it waits for the `onReady` signal from JavaScript
  /// before returning. On web it returns as soon as the controller is created
  /// and continues initialization in the background. Use [onReady] or
  /// [isReady] to wait for readiness on web.
  ///
  /// Throws a [TimeoutException] if the editor does not become ready within [readyTimeout] (default 20s).
  ///
  /// * [options]: Initial configuration (theme, language, etc.).
  /// * [customCss]: CSS injected into the HTML (e.g., for custom fonts).
  /// * [allowCdnFonts]: If `true`, allows loading fonts from remote URLs (enables network requests).
  static Future<MonacoController> create({
    EditorOptions? options,
    String? customCss,
    bool allowCdnFonts = false,
    Duration? readyTimeout,
  }) async {
    // Ensure Monaco assets are ready
    await MonacoAssets.ensureReady();

    // Create platform-specific WebView controller
    final webViewController = PlatformWebViewFactory.createController();

    // Create and attach bridge
    final bridge = MonacoBridge()..attachWebView(webViewController);
    MonacoController? controller;

    try {
      // Initialize WebView.
      await webViewController.initialize();
      await webViewController.enableJavaScript();
      await webViewController.addJavaScriptChannel(
        'flutterChannel',
        bridge.handleJavaScriptMessage,
      );

      // Create controller first (before loading HTML) so widget can render.
      controller = MonacoController._(bridge, webViewController);

      final readyFuture = (() async {
        try {
          await webViewController.load(
            customCss: customCss,
            allowCdnFonts: allowCdnFonts,
          );
          debugPrint(
            '[MonacoController] Loading HTML (Platform: ${kIsWeb ? 'Web' : defaultTargetPlatform.name})',
          );

          // Wait for editor ready signal with configurable timeout
          await bridge.onReady.future.timeout(
            readyTimeout ?? const Duration(seconds: 20),
            onTimeout: () => throw TimeoutException(
              'Monaco Editor did not report ready in ${readyTimeout?.inSeconds ?? 20} seconds.',
            ),
          );

          // Mark ready
          if (!controller!._onReady.isCompleted) {
            controller._onReady.complete();
          }

          // Apply initial options if provided
          if (options != null) {
            await controller.updateOptions(options);
            await controller.setThemeById(options.effectiveThemeId);
            await controller.setLanguage(options.language);
          }

          // Apply any queued content
          if (controller._queuedValue != null) {
            await controller.setValue(controller._queuedValue!);
            controller._queuedValue = null;
          }
          if (controller._queuedLanguage != null) {
            await controller.setLanguage(controller._queuedLanguage!);
            controller._queuedLanguage = null;
          }

          // Register any queued completion sources
          for (final entry in controller._queuedCompletionSources) {
            await controller._registerCompletionSourceInternal(entry);
          }
          controller._queuedCompletionSources.clear();
        } catch (e, st) {
          // Only complete _onReady with error on web, where we return the
          // controller before readyFuture completes. On native, we await
          // readyFuture and throw before returning, so no one listens to
          // _onReady - completing it with an error would be unhandled.
          if (kIsWeb &&
              controller != null &&
              !controller._onReady.isCompleted) {
            controller._onReady.completeError(e, st);
          }
          rethrow;
        }
      })();

      if (kIsWeb) {
        unawaited(readyFuture.catchError((Object _, StackTrace _) {}));
      } else {
        await readyFuture;
      }

      return controller;
    } catch (_) {
      // Clean up resources on failure
      if (controller != null) {
        controller.dispose();
      } else {
        bridge.dispose();
        webViewController.dispose();
      }
      rethrow;
    }
  }

  /// Create a controller for tests without touching assets or platform views.
  @visibleForTesting
  static Future<MonacoController> createForTesting({
    required PlatformWebViewController webViewController,
    MonacoBridge? bridge,
    bool markReady = true,
    String channelName = 'flutterChannel',
  }) async {
    final wiredBridge = bridge ?? MonacoBridge();
    wiredBridge.attachWebView(webViewController);

    await webViewController.initialize();
    await webViewController.enableJavaScript();
    await webViewController.addJavaScriptChannel(
      channelName,
      wiredBridge.handleJavaScriptMessage,
    );

    final controller = MonacoController._(wiredBridge, webViewController);
    if (markReady && !controller._onReady.isCompleted) {
      controller._onReady.complete();
    }
    if (markReady && !wiredBridge.onReady.isCompleted) {
      wiredBridge.onReady.complete();
    }
    return controller;
  }

  /// Manually complete the ready signal for tests.
  @visibleForTesting
  void completeReadyForTesting() {
    if (!_onReady.isCompleted) {
      _onReady.complete();
    }
  }

  /// Get the platform-specific WebView widget
  Widget get webViewWidget => _webViewController.widget;

  /// Ensure the editor is ready before executing commands
  Future<void> _ensureReady() async {
    if (!_onReady.isCompleted) {
      await _onReady.future;
    }
  }

  /// Switches the editor's syntax highlighting language.
  ///
  /// If the editor is not yet ready, the language is queued and applied upon initialization.
  Future<void> setLanguage(MonacoLanguage language) async {
    if (!_onReady.isCompleted) {
      _queuedLanguage = language;
      if (kIsWeb) return;
      await _ensureReady();
      if (_queuedLanguage == language) {
        // Only use queued value if it hasn't been overwritten
        _queuedLanguage = null;
      } else {
        return; // A newer language was queued, skip this one
      }
    }
    await _invokeMonacoCommand('setLanguage', [language.id]);
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
    await _invokeMonacoCommand('setJsonDiagnosticsOptions', [
      diagnostics.toJson(),
    ]);
  }

  /// Changes the editor's color theme.
  ///
  /// Waits for the editor to be ready before applying.
  Future<void> setTheme(MonacoTheme theme) async {
    await setThemeById(theme.id);
  }

  /// Changes the editor's color theme using a raw Monaco theme identifier.
  ///
  /// Accepts both built-in Monaco theme ids and custom theme ids previously
  /// registered with [defineTheme] or [defineThemeFromJson]. Throws an
  /// [ArgumentError] when [themeId] is empty so callers don't silently
  /// activate Monaco's empty-string fallback.
  Future<void> setThemeById(String themeId) async {
    if (themeId.trim().isEmpty) {
      throw ArgumentError.value(
        themeId,
        'themeId',
        'themeId must be a non-empty string',
      );
    }
    await _invokeMonacoCommand('setTheme', [themeId]);
  }

  /// Returns the Monaco theme id currently active in the editor.
  ///
  /// Reads the live value from Monaco's runtime rather than caching what
  /// Dart most recently sent. Returns `null` when Monaco can't report a
  /// theme (e.g. on engine versions that don't expose `editor.getTheme()`)
  /// or when the bridge call fails - this method follows the same
  /// fallback-on-failure contract as [getValue] / [getLineCount].
  Future<String?> getThemeId() async {
    try {
      final result = await _invokeMonacoCommand('getTheme', []);
      return result is String && result.isNotEmpty ? result : null;
    } catch (_) {
      return null;
    }
  }

  /// Registers or replaces a custom Monaco theme.
  ///
  /// After registration, activate the theme by calling
  /// [setThemeById]([MonacoThemeDefinition.id]) or setting
  /// [EditorOptions.themeId].
  ///
  /// Use [defineThemeFromJson] when the theme data only exists in raw
  /// Monaco-shaped JSON.
  Future<void> defineTheme(MonacoThemeDefinition theme) async {
    await defineThemeFromJson(theme.id, theme.toMonacoThemeData());
  }

  /// Registers or replaces a Monaco theme from raw Monaco-shaped JSON.
  ///
  /// This is an escape hatch for Monaco theme fields not yet modeled by
  /// [MonacoThemeDefinition]. Prefer [defineTheme] for type safety. Throws
  /// an [ArgumentError] when [id] is empty.
  ///
  /// [data] must follow Monaco's `IStandaloneThemeData` shape.
  Future<void> defineThemeFromJson(String id, Map<String, Object?> data) async {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(
        id,
        'id',
        'theme id must be a non-empty string',
      );
    }
    await _invokeMonacoCommand('defineTheme', [id, data]);
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
    await _invokeMonacoCommand('setHostPageBackground', [_cssRgba(color)]);
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
    _interactionEnabled = enabled;
    await _webViewController.setInteractionEnabled(enabled);
  }

  /// Runs [action] with editor interaction temporarily disabled, restoring the
  /// previous state in a `finally` block.
  ///
  /// Useful for transient Flutter overlays that are NOT pushed as routes (so
  /// [`MonacoFocusGuard`] cannot detect them) and that are NOT static enough
  /// to wrap in a [`MonacoOverlayBoundary`] - typically `ScaffoldMessenger`
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

    final wasEnabled = _interactionEnabled;
    if (wasEnabled) {
      await setInteractionEnabled(false);
    }

    try {
      return await Future<T>.value(action());
    } finally {
      if (wasEnabled && !_disposed) {
        await setInteractionEnabled(true);
      }
    }
  }

  /// Updates the editor configuration options.
  ///
  /// Only the fields present in [options] will be updated; others remain unchanged.
  Future<void> updateOptions(EditorOptions options) async {
    await _invokeMonacoCommand('updateOptions', [options.toMonacoOptions()]);
  }

  /// Registers a dynamic completion provider for the given [languages].
  ///
  /// The [provider] callback is invoked whenever the user requests completions (e.g., Ctrl+Space).
  ///
  /// * [id]: Optional unique identifier. If omitted, one is generated.
  /// * [triggerCharacters]: Characters that automatically trigger the completion (e.g., `.` or `@`).
  ///
  /// Returns the [id] of the registered provider.
  Future<String> registerCompletionSource({
    String? id,
    required List<String> languages,
    List<String> triggerCharacters = const [],
    required CompletionProvider provider,
  }) async {
    if (languages.isEmpty) {
      throw ArgumentError.value(languages, 'languages', 'Cannot be empty');
    }
    if (id != null && _completionSources.containsKey(id)) {
      throw ArgumentError.value(id, 'id', 'Completion source already exists');
    }

    final providerId =
        id ??
        'flutter_${DateTime.now().millisecondsSinceEpoch}_${_completionSources.length}';
    final entry = _RegisteredCompletion(
      id: providerId,
      languages: List<String>.from(languages),
      triggerCharacters: List<String>.from(triggerCharacters),
      provider: provider,
    );
    _completionSources[providerId] = entry;

    if (!_onReady.isCompleted) {
      // Queue for registration when ready - don't block widget rendering
      _queuedCompletionSources.add(entry);
      return providerId;
    }

    await _registerCompletionSourceInternal(entry);
    return providerId;
  }

  Future<void> _registerCompletionSourceInternal(
    _RegisteredCompletion entry,
  ) async {
    final payload = jsonEncode({
      'id': entry.id,
      'languages': entry.languages,
      'triggerCharacters': entry.triggerCharacters,
    });

    try {
      await _webViewController.runJavaScript(
        'flutterMonaco.registerCompletionSource($payload)',
      );
    } catch (e) {
      _completionSources.remove(entry.id);
      rethrow;
    }

    _wireCompletionListenerOnce();
  }

  /// Registers a static list of completion items.
  ///
  /// Useful for simple keyword lists or fixed snippets.
  Future<String> registerStaticCompletions({
    String? id,
    required List<String> languages,
    List<String> triggerCharacters = const [],
    required List<CompletionItem> items,
    bool isIncomplete = false,
  }) {
    return registerCompletionSource(
      id: id,
      languages: languages,
      triggerCharacters: triggerCharacters,
      provider: (_) async =>
          CompletionList(suggestions: items, isIncomplete: isIncomplete),
    );
  }

  /// Unregisters a previously registered completion source.
  Future<void> unregisterCompletionSource(String id) async {
    _completionSources.remove(id);
    // Also remove from queue if it was pending registration
    _queuedCompletionSources.removeWhere((e) => e.id == id);

    if (!_onReady.isCompleted) {
      // Not registered on JS side yet, just return
      return;
    }
    await _webViewController.runJavaScript(
      'flutterMonaco.unregisterCompletionSource(${jsonEncode(id)})',
    );
  }

  /// Execute an editor action
  Future<void> executeAction(String actionId, [dynamic args]) async {
    await _invokeMonacoCommand('executeAction', [actionId, args]);
  }

  /// Whether a Flutter text input (TextField, CupertinoTextField,
  /// SelectableText, ...) currently owns Flutter's primary focus.
  ///
  /// Focus nudges must never steal the keyboard from one: on Windows,
  /// [PlatformWebViewController.requestNativeFocus] moves real Win32
  /// keyboard focus to the WebView, which would make typing land in the
  /// editor instead of, say, a dialog's TextField.
  static bool _flutterTextInputHasFocus() {
    final BuildContext? context;
    try {
      context = FocusManager.instance.primaryFocus?.context;
    } catch (_) {
      // MonacoController also runs headless (no widget binding, e.g. plain
      // Dart tests); without a binding there is no Flutter focus to steal.
      return false;
    }
    if (context == null) return false;
    // Every Flutter text input attaches its focus node inside an
    // EditableText, so it is found as an ancestor state.
    return context.findAncestorStateOfType<EditableTextState>() != null;
  }

  static bool _shouldRespectFlutterTextInput(MonacoFocusIntent intent) {
    return intent == MonacoFocusIntent.maintenance;
  }

  static bool _shouldReplayInputFocus(MonacoFocusIntent intent) {
    return !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.macOS &&
        intent == MonacoFocusIntent.user;
  }

  static bool _shouldReleaseFlutterTextInput(MonacoFocusIntent intent) {
    if (kIsWeb || intent != MonacoFocusIntent.user) return false;
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  static Future<void> _releaseFlutterTextInputForUserFocus() async {
    if (_flutterTextInputHasFocus()) {
      try {
        FocusManager.instance.primaryFocus?.unfocus();
      } catch (_) {}
    }
    try {
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    } catch (_) {}
    await Future<void>.delayed(Duration.zero);
  }

  static String _forceFocusScript(MonacoFocusIntent intent) {
    final replayArg = _shouldReplayInputFocus(intent)
        ? '({ replayInputFocus: true })'
        : '()';
    return 'window.flutterMonaco && window.flutterMonaco.forceFocus && '
        'window.flutterMonaco.forceFocus$replayArg';
  }

  /// Requests focus for the editor widget.
  ///
  /// Uses a robust method that waits for visibility and layout before attempting focus.
  /// On Android and iOS, the OS soft keyboard may only appear after a user tap
  /// inside the editor.
  ///
  /// This is cooperative: it does nothing while a Flutter text input owns
  /// the primary focus, so programmatic calls cannot steal the keyboard from
  /// a focused TextField (e.g. in a dialog). For direct pointer interaction,
  /// use [ensureEditorFocus] with [MonacoFocusIntent.user].
  Future<void> focus() async {
    if (!_interactionEnabled) return;
    await _ensureReady();
    if (_flutterTextInputHasFocus()) return;
    // On Windows, WebView2 must hold real Win32 keyboard focus before the
    // in-page focus below has any effect. No-op on other platforms.
    await _webViewController.requestNativeFocus();
    // Use robust in-page helper (waits for visibility, layouts, focuses textarea)
    await _webViewController.runJavaScript(
      _forceFocusScript(MonacoFocusIntent.maintenance),
    );
  }

  /// Attempts to focus the editor multiple times to handle race conditions during layout transitions.
  ///
  /// [attempts] defaults to 3, with [interval] of 24ms.
  ///
  /// Like [focus], this defaults to cooperative background maintenance:
  /// attempts made while a Flutter text input owns the primary focus are
  /// skipped, so refocus nudges after content updates, route pops, or app
  /// resume cannot steal the keyboard from a focused TextField.
  ///
  /// Pass [MonacoFocusIntent.user] only from direct user interaction with the
  /// editor, such as a primary pointer down inside the Monaco view. On desktop
  /// that intent first releases Flutter's text-input channel so a stale
  /// TextField/dialog client cannot keep swallowing native input. On macOS it
  /// also replays the in-page focus path because WKWebView native input
  /// readiness can become stale while Monaco still reports DOM focus.
  Future<void> ensureEditorFocus({
    int attempts = 3,
    Duration interval = const Duration(milliseconds: 24),
    MonacoFocusIntent intent = MonacoFocusIntent.maintenance,
  }) async {
    if (!_interactionEnabled) return;
    await _ensureReady();

    var nativeFocusRequested = false;

    // On mobile, multiple async focus() calls interrupt the IME lifecycle.
    final isMobileNative =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final effectiveAttempts = isMobileNative ? 1 : attempts;
    if (effectiveAttempts <= 0) return;

    if (_shouldReleaseFlutterTextInput(intent)) {
      await _releaseFlutterTextInputForUserFocus();
    }

    for (var i = 0; i < effectiveAttempts; i++) {
      // Re-evaluated per attempt: a text input losing focus mid-loop (e.g.
      // a closing dialog) lets the remaining attempts proceed.
      if (!_shouldRespectFlutterTextInput(intent) ||
          !_flutterTextInputHasFocus()) {
        if (!nativeFocusRequested) {
          // On Windows, hand real Win32 keyboard focus to WebView2 first;
          // the JS focus below cannot take effect without it.
          await _webViewController.requestNativeFocus();
          nativeFocusRequested = true;
        }
        try {
          await _webViewController.runJavaScript(_forceFocusScript(intent));
        } catch (_) {}
      }
      if (i + 1 < effectiveAttempts) {
        await Future<void>.delayed(interval);
      }
    }
  }

  /// Forces the Monaco editor to re-measure its container and update its layout.
  ///
  /// Call this if the widget size changes but the editor does not update automatically.
  Future<void> layout() async {
    await _ensureReady();
    await _webViewController.runJavaScript(
      'window.flutterMonaco && window.flutterMonaco.layout && window.flutterMonaco.layout()',
    );
  }

  /// Scrolls the editor to the very top (line 1, column 1).
  Future<void> scrollToTop() async {
    await _ensureReady();
    await _webViewController.runJavaScript('''
      if (window.editor) {
        window.editor.setScrollPosition({ scrollTop: 0, scrollLeft: 0 });
        window.editor.setPosition({ lineNumber: 1, column: 1 });
        window.editor.revealLineInCenterIfOutsideViewport(1);
      }
    ''');
  }

  /// Scrolls the editor to the last line.
  Future<void> scrollToBottom() async {
    await _ensureReady();
    await _webViewController.runJavaScript('''
      if (window.editor && window.editor.getModel()) {
        const lineCount = window.editor.getModel().getLineCount();
        window.editor.revealLineInCenterIfOutsideViewport(lineCount);
        window.editor.setPosition({ lineNumber: lineCount, column: 1 });
      }
    ''');
  }

  /// Format the document
  Future<void> format() => executeAction(MonacoAction.formatDocument);

  /// Open find dialog
  Future<void> find() => executeAction(MonacoAction.find);

  /// Open replace dialog
  Future<void> replace() => executeAction(MonacoAction.startFindReplaceAction);

  /// Toggle word wrap
  Future<void> toggleWordWrap() => executeAction(MonacoAction.toggleWordWrap);

  /// Select all content
  Future<void> selectAll() => executeAction(MonacoAction.selectAll);

  /// Undo last action
  Future<void> undo() => executeAction(MonacoAction.undo);

  /// Redo last undone action
  Future<void> redo() => executeAction(MonacoAction.redo);

  /// Cut selected text
  Future<void> cut() => executeAction(MonacoAction.clipboardCutAction);

  /// Copy selected text
  Future<void> copy() => executeAction(MonacoAction.clipboardCopyAction);

  /// Paste from clipboard
  Future<void> paste() => executeAction(MonacoAction.clipboardPasteAction);

  /// Fold all foldable regions in the current model.
  Future<void> foldAll() => executeAction(MonacoAction.foldAll);

  /// Unfold all foldable regions in the current model.
  Future<void> unfoldAll() => executeAction(MonacoAction.unfoldAll);

  /// Toggle line comments on the current selection.
  Future<void> toggleLineComment() => executeAction(MonacoAction.commentLine);

  /// Indent the current selection or active line.
  Future<void> indentLines() => executeAction(MonacoAction.indentLines);

  /// Outdent the current selection or active line.
  Future<void> outdentLines() => executeAction(MonacoAction.outdentLines);

  // --- EVENT HANDLING ---

  /// Wire up event listeners with improved conversion
  void _wireEvents() {
    _bridge.addRawListener((Map<String, dynamic> json) {
      // Use safer conversion methods with fallbacks
      final event = json.tryGetString(
        'event',
        alternativeKeys: ['eventType', 'type'],
        defaultValue: 'unknown',
      );

      switch (event) {
        case 'contentChanged':
          // Use tryGetBool with default value
          _onContentChanged.add(
            json.tryGetBool(
                  'isFlush',
                  alternativeKeys: ['flush', 'fullChange'],
                  defaultValue: false,
                ) ??
                false,
          );
          break;
        case 'selectionChanged':
          // Use factory constructor for cleaner conversion
          final selectionMap = json.tryGetMap<String, dynamic>(
            'selection',
            alternativeKeys: ['sel', 'range'],
          );
          final selection = selectionMap != null
              ? Range.fromJson(selectionMap)
              : null;
          _onSelectionChanged.add(selection);
          break;
        case 'focus':
          _onFocus.add(null);
          break;
        case 'blur':
          _onBlur.add(null);
          break;
        default:
          break;
      }
    });
  }

  void _wireCompletionListenerOnce() {
    if (_completionListenerWired) return;
    _completionListenerWired = true;

    _bridge.addRawListener((Map<String, dynamic> json) {
      if (json.tryGetString('event') != 'completionRequest') return;

      unawaited(() async {
        try {
          await _ensureReady();
          final request = CompletionRequest.fromJson(json);
          final registered = _completionSources[request.providerId];
          const emptySuggestions = {'suggestions': <Map<String, dynamic>>[]};

          Future<void> respond(Map<String, dynamic> payload) {
            return _webViewController.runJavaScript(
              'flutterMonaco.complete(${jsonEncode(request.requestId)}, ${jsonEncode(payload)})',
            );
          }

          if (registered == null) {
            await respond(emptySuggestions);
            return;
          }

          try {
            final result = await registered.provider(request);
            await respond(result.toJson());
          } catch (e) {
            debugPrint('[MonacoController] completion provider failed: $e');
            await respond(emptySuggestions);
          }
        } catch (e) {
          debugPrint('[MonacoController] completion respond failed: $e');
        }
      }());
    });
  }

  /// Helper method to safely execute JavaScript and convert the result
  Future<T?> _executeJavaScript<T>(
    String script, {
    T? defaultValue,
    bool jsonAware = true,
  }) async {
    try {
      await _ensureReady();
      final raw = await _webViewController.runJavaScriptReturningResult(script);

      // Windows WebView2 might auto-decode JSON, handle both cases
      // Only decode if jsonAware is true (for API calls that return JSON)
      final result =
          (jsonAware &&
              raw is String &&
              (raw.startsWith('{') || raw.startsWith('[')))
          ? (raw.tryDecode() ?? raw)
          : raw;

      // Use tryToType for all type conversions
      return tryConvertToType<T>(result) ?? defaultValue;
    } catch (e) {
      debugPrint('[MonacoController] JavaScript execution error: $e');
      return defaultValue;
    }
  }

  /// Helper to safely parse JSON results with enhanced conversion
  Future<T?> _executeJavaScriptWithJson<T>(
    String script, {
    T? defaultValue,
    T Function(Map<String, dynamic>)? parser,
  }) async {
    try {
      await _ensureReady();
      final raw = await _webViewController.runJavaScriptReturningResult(script);

      // Handle Windows auto-decode: raw might already be a Map/List
      final obj = raw is String ? (raw.tryDecode() ?? raw) : raw;

      // Try to convert to Map
      final json = tryConvertToMap<String, dynamic>(obj);
      if (json == null || json.isEmpty) return defaultValue;

      // Use parser if provided, otherwise try direct conversion
      return parser?.call(json) ?? tryConvertToType<T>(json) ?? defaultValue;
    } catch (e) {
      debugPrint('[MonacoController] JSON parsing error: $e');
      return defaultValue;
    }
  }

  String _wrapJavaScriptEvaluationExpression(String expression) {
    final envelopeKey = jsonEncode(_jsEvalEnvelopeKey);
    final valueKey = jsonEncode(_jsEvalValueKey);
    final undefinedKey = jsonEncode(_jsEvalUndefinedKey);

    return '''
      (function() {
        const value = ($expression);

        if (typeof value === 'undefined') {
          return JSON.stringify({
            $envelopeKey: true,
            $undefinedKey: true,
            $valueKey: null
          });
        }

        return JSON.stringify({
          $envelopeKey: true,
          $undefinedKey: false,
          $valueKey: value
        });
      })()
    ''';
  }

  Object? _decodeJavaScriptEvaluationResult(Object? raw) {
    Object? current = raw;

    for (var i = 0; i < 3; i++) {
      if (current is! String) break;

      final trimmed = current.trim();
      if (trimmed.isEmpty) return null;

      try {
        current = jsonDecode(trimmed);
      } catch (_) {
        break;
      }
    }

    final envelope = tryConvertToMap<String, dynamic>(current);
    if (envelope == null || envelope[_jsEvalEnvelopeKey] != true) {
      return current;
    }

    if (envelope[_jsEvalUndefinedKey] == true) {
      return _jsUndefined;
    }

    return envelope.containsKey(_jsEvalValueKey)
        ? envelope[_jsEvalValueKey]
        : null;
  }

  /// Decodes a raw `runJavaScriptReturningResult` payload into the
  /// `flutterMonacoInvoke` envelope shape, applying the same triple-decode
  /// loop the evaluation helper uses.
  ///
  /// Returns the parsed envelope map, or `null` if the payload could not be
  /// resolved to one. Callers treat a missing envelope as a bridge failure.
  Map<String, dynamic>? _decodeInvokeEnvelope(Object? raw) {
    Object? current = raw;

    for (var i = 0; i < 3; i++) {
      if (current is! String) break;
      final trimmed = current.trim();
      if (trimmed.isEmpty) return null;
      try {
        current = jsonDecode(trimmed);
      } catch (_) {
        break;
      }
    }

    final envelope = tryConvertToMap<String, dynamic>(current);
    if (envelope == null || envelope[_jsEvalEnvelopeKey] != true) {
      return null;
    }
    return envelope;
  }

  /// Invokes a typed Monaco bridge command and returns the helper's value.
  ///
  /// The JavaScript side dispatches the call through `window.flutterMonacoInvoke`
  /// which wraps the helper in a try/catch and returns a result envelope.
  /// Success envelopes (`ok: true`) yield the helper's value (or `null` when
  /// the helper returned `undefined`). Failure envelopes (`ok: false`) raise
  /// [MonacoJavaScriptException] tagged with [method] so callers can react to
  /// or rethrow the failure.
  ///
  /// This is the canonical path for mutating commands. Read methods with
  /// documented fallbacks should catch [MonacoJavaScriptException] at the
  /// Dart layer and return their default value to preserve the public API
  /// contract.
  Future<Object?> _invokeMonacoCommand(
    String method,
    List<Object?> args,
  ) async {
    await _ensureReady();

    final script =
        'JSON.stringify(window.flutterMonacoInvoke(${jsonEncode(method)}, ${jsonEncode(args)}))';
    final raw = await _webViewController.runJavaScriptReturningResult(script);
    final envelope = _decodeInvokeEnvelope(raw);

    if (envelope == null) {
      throw MonacoJavaScriptException(
        operation: method,
        message: 'Invalid Monaco bridge envelope: $raw',
        details: raw,
      );
    }

    if (envelope[_jsEvalOkKey] == true) {
      if (envelope[_jsEvalUndefinedKey] == true) return null;
      return envelope.containsKey(_jsEvalValueKey)
          ? envelope[_jsEvalValueKey]
          : null;
    }

    final error = tryConvertToMap<String, dynamic>(envelope[_jsEvalErrorKey]);
    throw MonacoJavaScriptException.fromJson(
      error ?? <String, dynamic>{'message': 'Unknown Monaco bridge error'},
      operation: method,
    );
  }

  // --- CONTENT AND SELECTION ---

  /// Retrieves the current text content of the editor.
  ///
  /// Returns [defaultValue] if the operation fails or returns null.
  Future<String> getValue({String defaultValue = ''}) async {
    try {
      final result = await _invokeMonacoCommand('getValue', []);
      return result is String ? result : defaultValue;
    } catch (_) {
      // Documented fallback contract: reads with defaultValue never propagate
      // bridge errors. Use [evaluateJavaScript] or [_invokeMonacoCommand]
      // directly if strict failure visibility is required.
      return defaultValue;
    }
  }

  /// Replaces the entire content of the editor.
  ///
  /// If the editor is not yet ready, the value is queued and applied immediately
  /// after initialization.
  Future<void> setValue(String value) async {
    if (!_onReady.isCompleted) {
      _queuedValue = value;
      if (kIsWeb) return;
      await _ensureReady();
      if (_queuedValue == value) {
        // Only use queued value if it hasn't been overwritten
        _queuedValue = null;
      } else {
        return; // A newer value was queued, skip this one
      }
    }
    await _invokeMonacoCommand('setValue', [value]);
  }

  /// Retrieves the current primary selection range.
  ///
  /// Returns `null` if no selection exists or the editor is not ready.
  Future<Range?> getSelection() async {
    return _executeJavaScriptWithJson<Range>(
      'JSON.stringify(flutterMonaco.getSelection())',
      parser: Range.fromJson,
    );
  }

  /// Selects the specified [range] in the editor.
  Future<void> setSelection(Range range) async {
    await _invokeMonacoCommand('setSelection', [range.toJson()]);
  }

  // --- NAVIGATION ---

  /// Reveal a line in the editor with validation
  Future<void> revealLine(int line, {bool center = false}) async {
    await _ensureReady();
    // Validate line number
    final lineCount = await getLineCount();
    if (lineCount < 1) return;
    final int validLine = line.clamp(1, lineCount);

    await _webViewController.runJavaScript(
      'flutterMonaco.revealLine($validLine, $center)',
    );
  }

  /// Reveal a range in the editor
  Future<void> revealRange(Range range, {bool center = false}) async {
    await _ensureReady();
    await _webViewController.runJavaScript(
      'flutterMonaco.revealRange(${jsonEncode(range.toJson())}, $center)',
    );
  }

  /// Reveal multiple lines in the editor
  Future<void> revealLines(
    int startLine,
    int endLine, {
    bool center = false,
  }) async {
    final range = Range.lines(startLine, endLine);
    await revealRange(range, center: center);
  }

  /// Reveal a position in the editor
  Future<void> revealPosition(Position position, {bool center = false}) async {
    final range = Range.fromPositions(position, position);
    await revealRange(range, center: center);
  }

  // --- LINE OPERATIONS ---

  /// Get the total line count with enhanced conversion
  Future<int> getLineCount({int defaultValue = 0}) async {
    try {
      final result = await _invokeMonacoCommand('getLineCount', []);
      if (result is int) return result;
      if (result is num) return result.toInt();
      return defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  /// Get the content of a specific line with validation
  Future<String> getLineContent(int line, {String defaultValue = ''}) async {
    // Validate line number
    final lineCount = await getLineCount();
    if (line < 1 || line > lineCount) return defaultValue;

    try {
      final result = await _invokeMonacoCommand('getLineContent', [line]);
      return result is String ? result : defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  /// Get multiple lines content at once
  Future<List<String>> getLinesContent(
    List<int> lines, {
    String lineDefaultValue = '',
  }) async {
    final results = <String>[];
    if (lines.isEmpty) return results;

    final lineCount = await getLineCount();
    for (final line in lines) {
      if (line < 1 || line > lineCount) {
        results.add(lineDefaultValue);
        continue;
      }
      try {
        final result = await _invokeMonacoCommand('getLineContent', [line]);
        results.add(result is String ? result : lineDefaultValue);
      } catch (_) {
        results.add(lineDefaultValue);
      }
    }
    return results;
  }

  // --- EDITS ---

  /// Applies a list of edit operations to the document.
  ///
  /// This is the most efficient way to make multiple changes at once.
  Future<void> applyEdits(List<EditOperation> edits) async {
    if (edits.isEmpty) return;
    await _invokeMonacoCommand('applyEdits', [
      edits.map((e) => e.toJson()).toList(),
    ]);
  }

  /// Inserts [text] at the specified [position].
  Future<void> insertText(Position position, String text) async {
    final edit = EditOperation.insert(position: position, text: text);
    await applyEdits([edit]);
  }

  /// Deletes the text within the specified [range].
  Future<void> deleteRange(Range range) async {
    final edit = EditOperation.delete(range: range);
    await applyEdits([edit]);
  }

  /// Replaces the text within [range] with [text].
  Future<void> replaceRange(Range range, String text) async {
    final edit = EditOperation(range: range, text: text);
    await applyEdits([edit]);
  }

  /// Deletes the specified [line] (1-based index).
  Future<void> deleteLine(int line) async {
    final range = Range.lines(line, line);
    await deleteRange(range);
  }

  // --- DECORATIONS ---

  /// Sets the decorations (highlights, glyphs, etc.) in the editor.
  ///
  /// Replaces any previously set decorations tracked by this controller.
  /// Returns the IDs of the newly created decorations.
  Future<List<String>> setDecorations(
    List<DecorationOptions> decorations,
  ) async {
    final raw = await _invokeMonacoCommand('deltaDecorations', [
      _decorationIds,
      decorations.map((d) => d.toJson()).toList(),
    ]);
    if (raw is! List) {
      throw MonacoJavaScriptException(
        operation: 'deltaDecorations',
        message: 'Expected deltaDecorations to return a list of IDs.',
        details: raw,
      );
    }

    return _decorationIds = raw
        .map((e) => e.toString())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Adds inline style decorations (e.g., text color, background) to specific [ranges].
  ///
  /// [className] should be a CSS class available in the WebView (injected via `customCss`).
  Future<List<String>> addInlineDecorations(
    List<Range> ranges,
    String className, {
    String? hoverMessage,
  }) async {
    final decorations = ranges
        .map(
          (range) => DecorationOptions.inlineClass(
            range: range,
            className: className,
            hoverMessage: hoverMessage,
          ),
        )
        .toList();

    return setDecorations(decorations);
  }

  /// Adds decorations to entire lines (e.g., for breakpoints or diffs).
  Future<List<String>> addLineDecorations(
    List<int> lines,
    String className, {
    bool isWholeLine = true,
  }) async {
    final decorations = lines
        .map(
          (line) => DecorationOptions.line(
            range: Range.singleLine(line),
            className: className,
            isWholeLine: isWholeLine,
          ),
        )
        .toList();

    return setDecorations(decorations);
  }

  /// Removes all decorations set by this controller.
  Future<void> clearDecorations() => setDecorations(const []);

  // --- MARKERS (DIAGNOSTICS) ---

  /// Sets the diagnostics (errors, warnings, hints) for the editor.
  ///
  /// [owner] is a string identifier for the source of these markers.
  Future<void> setMarkers(
    List<MarkerData> markers, {
    String owner = 'flutter',
  }) async {
    await _invokeMonacoCommand('setModelMarkers', [
      owner,
      markers.map((m) => m.toJson()).toList(),
    ]);
  }

  /// Convenience method to set error markers.
  Future<void> setErrorMarkers(
    List<MarkerData> errors, {
    String owner = 'flutter-errors',
  }) async {
    await setMarkers(errors, owner: owner);
  }

  /// Convenience method to set warning markers.
  Future<void> setWarningMarkers(
    List<MarkerData> warnings, {
    String owner = 'flutter-warnings',
  }) async {
    await setMarkers(warnings, owner: owner);
  }

  /// Clears all markers for the specified [owner].
  Future<void> clearMarkers({String owner = 'flutter'}) async {
    await setMarkers([], owner: owner);
  }

  /// Clears all markers from common owners ('flutter', 'flutter-errors', 'flutter-warnings').
  Future<void> clearAllMarkers() async {
    await Future.wait([
      clearMarkers(owner: 'flutter'),
      clearMarkers(owner: 'flutter-errors'),
      clearMarkers(owner: 'flutter-warnings'),
    ]);
  }

  // --- FIND AND REPLACE ---

  /// Find matches in the document with enhanced parsing
  Future<List<FindMatch>> findMatches(
    String query, {
    FindOptions options = const FindOptions(),
    int limit = 1000,
  }) async {
    // Don't use JSON.stringify - return array directly
    final matches = await _executeJavaScript<List<dynamic>>(
      'flutterMonaco.findMatches(${jsonEncode(query)}, ${jsonEncode(options.toJson())}, $limit)',
      defaultValue: const [],
    );

    if (matches == null || matches.isEmpty) return [];

    return matches
        .map((match) => tryConvertToMap<String, dynamic>(match))
        .where((map) => map != null)
        .map((map) => FindMatch.fromJson(map!))
        .toList();
  }

  /// Replace all matches in the document
  Future<int> replaceMatches(
    String query,
    String replacement, {
    FindOptions options = const FindOptions(),
    int defaultCount = 0,
  }) async {
    return await _executeJavaScript<int>(
          'flutterMonaco.replaceMatches(${jsonEncode(query)}, ${jsonEncode(replacement)}, ${jsonEncode(options.toJson())})',
          defaultValue: defaultCount,
        ) ??
        defaultCount;
  }

  // --- VIEW STATE ---

  /// Save the current view state with enhanced conversion
  Future<Map<String, dynamic>> saveViewState() async {
    final result = await _executeJavaScriptWithJson<Map<String, dynamic>>(
      'JSON.stringify(flutterMonaco.saveViewState())',
    );
    return result ?? {};
  }

  /// Restore a previously saved view state
  Future<void> restoreViewState(Map<String, dynamic> state) async {
    if (state.isEmpty) return;
    await _ensureReady();

    await _webViewController.runJavaScript(
      'flutterMonaco.restoreViewState(${jsonEncode(state)})',
    );
  }

  // --- MULTI-MODEL ---

  /// Create a new model with enhanced URI handling
  Future<Uri> createModel(
    String value, {
    String language = 'plaintext',
    Uri? uri,
    Uri? defaultUri,
  }) async {
    final script =
        '''
      flutterMonaco.createModel(
        ${jsonEncode(value)}, 
        ${jsonEncode(language)}, 
        ${uri != null ? jsonEncode(uri.toString()) : 'null'}
      )
    ''';

    final result = await _executeJavaScript<String>(script);

    // Enhanced URI conversion with fallback
    final createdUri = result != null ? tryConvertToUri(result) : null;
    if (createdUri != null) {
      return createdUri;
    }
    if (defaultUri != null) {
      return defaultUri;
    }
    throw StateError('flutterMonaco.createModel returned invalid uri: $result');
  }

  /// Set the active model
  Future<void> setModel(Uri uri) async {
    await _ensureReady();
    await _webViewController.runJavaScript(
      'flutterMonaco.setModel(${jsonEncode(uri.toString())})',
    );
  }

  /// Dispose a model
  Future<void> disposeModel(Uri uri) async {
    await _ensureReady();
    await _webViewController.runJavaScript(
      'flutterMonaco.disposeModel(${jsonEncode(uri.toString())})',
    );
  }

  /// List all models with enhanced conversion
  Future<List<Uri>> listModels() async {
    // Don't use JSON.stringify - return array directly
    final list = await _executeJavaScript<List<dynamic>>(
      'flutterMonaco.listModels()',
      defaultValue: const [],
    );

    if (list == null || list.isEmpty) return [];

    // Convert each item to URI and filter out nulls
    return list
        .map(tryConvertToUri)
        .where((uri) => uri != null)
        .cast<Uri>()
        .toList();
  }

  // --- ADDITIONAL HELPER METHODS ---

  /// Get editor statistics from bridge's live stream
  LiveStats getStatistics() {
    // Use the bridge's liveStats which is already updated via events
    return _bridge.liveStats.value;
  }

  /// Check if the editor has unsaved changes
  Future<bool> hasUnsavedChanges() async {
    return await _executeJavaScript<bool>(
          'flutterMonaco.hasUnsavedChanges()',
          defaultValue: false,
        ) ??
        false;
  }

  /// Mark the current content as saved (baseline for dirty tracking)
  Future<void> markSaved() async {
    await _ensureReady();
    await _webViewController.runJavaScript('flutterMonaco.markSaved()');
  }

  /// Get cursor position with enhanced conversion
  Future<Position?> getCursorPosition() async {
    return _executeJavaScriptWithJson<Position>(
      'JSON.stringify(flutterMonaco.getCursorPosition())',
      parser: Position.fromJson,
    );
  }

  /// Set cursor position
  Future<void> setCursorPosition(Position position) async {
    await _invokeMonacoCommand('setCursorPosition', [
      position.line,
      position.column,
    ]);
  }

  /// Set cursor position from zero-based coordinates
  Future<void> setCursorPositionZeroBased(int line, int column) async {
    final position = Position.fromZeroBased(line, column);
    await setCursorPosition(position);
  }

  /// Get word at position
  Future<String?> getWordAtPosition(Position position) async {
    return _executeJavaScript<String>(
      'flutterMonaco.getWordAtPosition(${position.line}, ${position.column})',
      jsonAware: false, // Don't decode - this is plain text content
    );
  }

  // --- BATCH OPERATIONS ---

  /// Execute multiple operations in batch
  Future<void> executeBatch(List<Future<void> Function()> operations) async {
    for (final operation in operations) {
      await operation();
    }
  }

  /// Get multiple editor properties at once
  Future<EditorState> getEditorState() async {
    final content = await getValue();
    final selection = await getSelection();
    final cursorPosition = await getCursorPosition();
    final lineCount = await getLineCount();
    final hasChanges = await hasUnsavedChanges();
    final stats = getStatistics(); // Now synchronous

    return EditorState(
      content: content,
      selection: selection,
      cursorPosition: cursorPosition,
      lineCount: lineCount,
      hasUnsavedChanges: hasChanges,
      language: stats.language,
      theme: null,
      // Would need a separate API call to get theme
      stats: stats,
    );
  }

  // --- JAVASCRIPT ESCAPE HATCH ---

  /// Executes arbitrary JavaScript in the editor WebView.
  ///
  /// This is an advanced escape hatch for scenarios not covered by the typed
  /// Dart API. Prefer typed [MonacoController] methods such as [setValue],
  /// [getSelection], [setMarkers], and [executeAction] when they cover your
  /// use case.
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
  /// platforms.
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
  /// Returns [defaultValue] when the expression returns `undefined`, when the
  /// decoded value is `null`, or when the value cannot be converted to [T].
  ///
  /// JavaScript execution errors are allowed to propagate. This keeps raw
  /// JavaScript integrations easier to debug.
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

    final wrapped = _wrapJavaScriptEvaluationExpression(expression);
    final raw = await _webViewController.runJavaScriptReturningResult(wrapped);
    final decoded = _decodeJavaScriptEvaluationResult(raw);

    if (decoded == _jsUndefined || decoded == null) {
      return defaultValue;
    }

    return tryConvertToType<T>(decoded) ?? defaultValue;
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
    _onContentChanged.close();
    _onSelectionChanged.close();
    _onFocus.close();
    _onBlur.close();
    _bridge.dispose();
    _webViewController.dispose();
  }
}

class _RegisteredCompletion {
  _RegisteredCompletion({
    required this.id,
    required this.languages,
    required this.triggerCharacters,
    required this.provider,
  });

  final String id;
  final List<String> languages;
  final List<String> triggerCharacters;
  final CompletionProvider provider;
}

class _JavaScriptUndefinedValue {
  const _JavaScriptUndefinedValue();
}
