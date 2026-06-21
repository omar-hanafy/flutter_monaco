import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

/// An enumeration representing the connection state of the Monaco Editor.
enum _ConnectionState {
  /// The editor is currently initializing and not yet ready for interaction.
  connecting,

  /// The editor has successfully initialized and is ready.
  ready,

  /// An error occurred during the initialization of the editor.
  error,
}

bool _pointerMayClaimKeyboard(PointerDownEvent event) {
  if (event.kind == PointerDeviceKind.mouse ||
      event.kind == PointerDeviceKind.trackpad) {
    return event.buttons == kPrimaryMouseButton;
  }
  return true;
}

bool _pointerShouldRecoverInputFocus(
  PointerDownEvent event, {
  required bool hasFlutterFocus,
  required bool monacoReportsFocused,
  TargetPlatform? platform,
}) {
  if (!_pointerMayClaimKeyboard(event)) return false;
  final targetPlatform = platform ?? defaultTargetPlatform;
  if (targetPlatform == TargetPlatform.macOS) {
    return true;
  }
  return !hasFlutterFocus || !monacoReportsFocused;
}

/// A widget that renders a Monaco Editor instance.
///
/// This widget manages the lifecycle of the underlying WebView and the [MonacoController].
/// It handles initialization, resizing, and exposes callbacks for editor events.
///
/// ### Behavior
/// * **Initialization**: Displays [loadingBuilder] (or a spinner) until the editor is ready.
/// * **Updates**: Rebuilds when [options] change, applying the new configuration dynamically.
/// * **Error Handling**: Displays [errorBuilder] (or an error message) if initialization fails.
///
/// ### Example
///
/// ```dart
/// MonacoEditor(
///   initialValue: 'print("Hello World");',
///   options: EditorOptions(
///     language: MonacoLanguage.python,
///     theme: MonacoTheme.vsDark,
///   ),
///   onContentChanged: (value) => print('New content: $value'),
/// )
/// ```
class MonacoEditor extends StatefulWidget {
  /// Creates a new [MonacoEditor] widget.
  const MonacoEditor({
    super.key,
    this.controller,
    this.controllerFactory,
    this.initialValue,
    this.options = const EditorOptions(),
    this.initialSelection,
    this.autofocus = false,
    this.customCss,
    this.allowCdnFonts = false,
    this.readyTimeout,
    this.onReady,
    this.onContentChanged,
    this.onRawContentChanged,
    this.fullTextOnFlushOnly = false,
    this.contentDebounce = const Duration(milliseconds: 120),
    this.onSelectionChanged,
    this.onFocus,
    this.onBlur,
    this.onLiveStats,
    this.loadingBuilder,
    this.errorBuilder,
    this.showStatusBar = false,
    this.statusBarBuilder,
    this.backgroundColor,
    this.interactionEnabled = true,
    this.padding,
    this.constraints,
  });

  /// The controller that manages the editor instance.
  ///
  /// If provided, you are responsible for disposing of it.
  /// If `null`, a controller is created and managed internally by this widget.
  final MonacoController? controller;

  /// Test-only hook to supply a controller factory when this widget
  /// owns the controller lifecycle.
  @visibleForTesting
  final Future<MonacoController> Function()? controllerFactory;

  /// The initial content to load into the editor.
  ///
  /// Applied only when the editor is first created. To update content dynamically,
  /// use [MonacoController.setValue].
  final String? initialValue;

  /// Configuration options for the editor (theme, language, font size, etc.).
  ///
  /// Changing this property will dynamically update the editor instance.
  final EditorOptions options;

  /// The text range to select immediately after initialization.
  final Range? initialSelection;

  /// If `true`, the editor requests focus as soon as it becomes ready.
  final bool autofocus;

  /// CSS injected into the editor's page (e.g., `@font-face` rules).
  ///
  /// Changing this property triggers a full reload of the editor.
  final String? customCss;

  /// If `true`, allows the editor to load fonts from remote URLs.
  ///
  /// **Security Note**: This enables network requests from the WebView.
  /// Changing this property triggers a full reload.
  final bool allowCdnFonts;

  /// The maximum duration to wait for the editor to initialize before showing an error.
  final Duration? readyTimeout;

  /// Callback invoked when the editor is fully initialized and ready.
  ///
  /// Provides the [MonacoController] for interaction.
  final ValueChanged<MonacoController>? onReady;

  /// Callback invoked when the text content changes.
  ///
  /// This is debounced by [contentDebounce] unless it's a "flush" event (e.g., `setValue`).
  final ValueChanged<String>? onContentChanged;

  /// Callback invoked for every content change signal from Monaco.
  ///
  /// The boolean argument is `true` if the change was a "flush" (full replacement).
  final ValueChanged<bool>? onRawContentChanged;

  /// If `true`, [onContentChanged] is only called for "flush" events, ignoring typing.
  final bool fullTextOnFlushOnly;

  /// The delay before [onContentChanged] is triggered after the user stops typing.
  final Duration contentDebounce;

  /// Callback invoked when the cursor selection changes.
  final ValueChanged<Range?>? onSelectionChanged;

  /// Callback invoked when the editor gains focus.
  final VoidCallback? onFocus;

  /// Callback invoked when the editor loses focus.
  final VoidCallback? onBlur;

  /// Callback for receiving real-time editor statistics (cursor position, line count).
  final ValueChanged<LiveStats>? onLiveStats;

  /// Builder for the widget displayed while the editor is initializing.
  ///
  /// Defaults to a [CircularProgressIndicator].
  final WidgetBuilder? loadingBuilder;

  /// Builder for the widget displayed if initialization fails.
  ///
  /// Defaults to an error icon and retry button.
  final Widget Function(BuildContext context, Object error, StackTrace? st)?
  errorBuilder;

  /// If `true`, displays a status bar with line/column info at the bottom.
  final bool showStatusBar;

  /// Builder for a custom status bar widget.
  final Widget Function(BuildContext context, LiveStats stats)?
  statusBarBuilder;

  /// The background color of the WebView container.
  ///
  /// Visible while the editor is loading or if the editor has padding.
  final Color? backgroundColor;

  /// Whether the editor intercepts pointer events.
  ///
  /// Set this to `false` when displaying Flutter overlays (dialogs, dropdowns)
  /// over the editor on Web to ensure the overlays receive pointer events.
  final bool interactionEnabled;

  /// Padding applied around the editor WebView.
  final EdgeInsetsGeometry? padding;

  /// Constraints applied to the editor container.
  final BoxConstraints? constraints;

  /// Creates the mutable state for this widget.
  @override
  State<MonacoEditor> createState() => _MonacoEditorState();
}

class _MonacoEditorState extends State<MonacoEditor> {
  /// The current state of the editor connection.
  _ConnectionState _connectionState = _ConnectionState.connecting;

  /// The controller for the editor. Can be external or internal.
  MonacoController? _controller;

  /// `true` if this widget is responsible for creating and disposing the controller.
  bool _ownsController = false;

  /// Holds any error that occurred during bootstrap.
  Object? _error;
  StackTrace? _stack;

  /// Subscriptions to controller events to be managed across the widget lifecycle.
  final List<StreamSubscription<dynamic>> _streamSubscriptions = [];
  StreamSubscription<bool>? _contentSub;
  VoidCallback? _statsListener;

  /// Content sequence number for race condition prevention.
  int _contentSeq = 0;

  /// Bootstrap sequence number to ignore stale async work.
  int _bootstrapSeq = 0;

  /// Timer for debouncing content changes.
  Timer? _contentDebounceTimer;

  /// FocusNode to explicitly request platform view focus for the WebView.
  final FocusNode _webFocusNode = FocusNode(debugLabel: 'MonacoWebViewFocus');

  /// Whether Monaco itself reports DOM focus, driven by the controller's
  /// focus/blur stream. On macOS this is not proof that WKWebView is still
  /// native input-ready.
  bool _monacoReportsFocused = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant MonacoEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the controller is swapped externally, we need to re-bootstrap.
    if (oldWidget.controller != widget.controller) {
      _teardown(disposeOldController: _ownsController);
      _bootstrap();
      return;
    }

    // If we OWN the controller and HTML-affecting knobs changed, rebuild.
    final htmlKnobsChanged =
        (oldWidget.customCss != widget.customCss) ||
        (oldWidget.allowCdnFonts != widget.allowCdnFonts);
    if (_ownsController && htmlKnobsChanged) {
      _teardown(disposeOldController: true);
      _bootstrap();
      return;
    }

    if (widget.interactionEnabled != oldWidget.interactionEnabled &&
        _controller != null) {
      _ignoreAsync(
        _controller!.setInteractionEnabled(widget.interactionEnabled),
      );
    }

    if (_connectionState != _ConnectionState.ready || _controller == null) {
      return;
    }

    // If options change, apply them to the existing controller.
    if (widget.options != oldWidget.options) {
      _ignoreAsync(_controller!.updateOptions(widget.options));
      // Explicitly update theme and language as they require separate bridge calls.
      _ignoreAsync(_controller!.setThemeById(widget.options.effectiveThemeId));
      _ignoreAsync(_controller!.setLanguage(widget.options.language));
    }

    if (widget.backgroundColor != oldWidget.backgroundColor &&
        widget.backgroundColor != null) {
      _ignoreAsync(_controller!.setBackgroundColor(widget.backgroundColor!));
      _ignoreAsync(
        _controller!.setHostPageBackgroundColor(widget.backgroundColor!),
      );
    }

    // If the content change callback has been updated, we need to rewire the listener.
    if (widget.onContentChanged != oldWidget.onContentChanged) {
      _wireContentListener();
    }
  }

  /// Initializes the editor controller and sets up listeners.
  Future<void> _bootstrap() async {
    final bootstrapToken = ++_bootstrapSeq;
    setState(() {
      _connectionState = _ConnectionState.connecting;
      _error = null;
      _stack = null;
    });

    try {
      final ownsController = widget.controller == null;
      _ownsController = ownsController;
      final controller =
          widget.controller ??
          await (widget.controllerFactory?.call() ??
              MonacoController.create(
                options: widget.options,
                customCss: widget.customCss,
                allowCdnFonts: widget.allowCdnFonts,
                readyTimeout: widget.readyTimeout,
              ));

      if (!_isBootstrapCurrent(bootstrapToken)) {
        if (ownsController) {
          controller.dispose();
        }
        return;
      }

      setState(() => _controller = controller);
      _ownsController = ownsController;

      await _controller!.setInteractionEnabled(widget.interactionEnabled);
      if (!_isBootstrapCurrent(bootstrapToken)) {
        return;
      }

      // Wait for the underlying web view to be ready.
      await _controller!.onReady;
      if (!_isBootstrapCurrent(bootstrapToken)) {
        return;
      }

      // Apply initial values and settings post-readiness. Background is
      // cosmetic - the widget already paints its own container behind the
      // WebView - so a platform failure here must not abort initialization.
      // The split exists because macOS native backgrounds are unreliable;
      // both layers can fail independently.
      if (widget.backgroundColor != null) {
        try {
          await _controller!.setBackgroundColor(widget.backgroundColor!);
        } catch (e) {
          debugPrint('[MonacoEditor] setBackgroundColor failed: $e');
        }
        try {
          await _controller!.setHostPageBackgroundColor(
            widget.backgroundColor!,
          );
        } catch (e) {
          debugPrint('[MonacoEditor] setHostPageBackgroundColor failed: $e');
        }
      }
      // Ensure options are up-to-date in case they changed during bootstrap
      if (_isBootstrapCurrent(bootstrapToken)) {
        // We can't easily check if they differ from what we passed to create(),
        // so we just re-apply them to be safe. This is cheap if no changes.
        await _controller!.updateOptions(widget.options);
        await _controller!.setThemeById(widget.options.effectiveThemeId);
        await _controller!.setLanguage(widget.options.language);
      }

      if (widget.initialValue != null) {
        await _controller!.setValue(widget.initialValue!);
        if (!_isBootstrapCurrent(bootstrapToken)) {
          return;
        }
      }
      if (widget.initialSelection != null) {
        await _controller!.setSelection(widget.initialSelection!);
        if (!_isBootstrapCurrent(bootstrapToken)) {
          return;
        }
      }
      if (widget.autofocus &&
          widget.interactionEnabled &&
          !_isMobileInputPlatform()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isBootstrapCurrent(bootstrapToken)) return;
          _webFocusNode.requestFocus();
          unawaited(_controller!.ensureEditorFocus(attempts: 3));
        });
      }

      _wireListeners();

      if (_isBootstrapCurrent(bootstrapToken)) {
        setState(() => _connectionState = _ConnectionState.ready);
        widget.onReady?.call(_controller!);
      }
    } catch (e, st) {
      if (!_isBootstrapCurrent(bootstrapToken)) return;
      _teardown(disposeOldController: _ownsController);
      setState(() {
        _connectionState = _ConnectionState.error;
        _error = e;
        _stack = st;
      });
    }
  }

  bool _isBootstrapCurrent(int token) => mounted && token == _bootstrapSeq;

  bool _isMobileInputPlatform() {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Subscribes to all relevant event streams from the controller.
  void _wireListeners() {
    if (_controller == null) return;

    // Clear any existing subscriptions before wiring new ones.
    _teardownListeners();

    _wireContentListener();
    if (widget.onSelectionChanged != null) {
      final selectionSub = _controller!.onSelectionChanged.listen(
        (r) => widget.onSelectionChanged?.call(r),
      );
      _streamSubscriptions.add(selectionSub);
    }
    final focusSub = _controller!.onFocus.listen((_) {
      _monacoReportsFocused = true;
      widget.onFocus?.call();
    });
    _streamSubscriptions.add(focusSub);
    final blurSub = _controller!.onBlur.listen((_) {
      _monacoReportsFocused = false;
      widget.onBlur?.call();
    });
    _streamSubscriptions.add(blurSub);

    _statsListener = () =>
        widget.onLiveStats?.call(_controller!.liveStats.value);
    _controller!.liveStats.addListener(_statsListener!);
  }

  void _ignoreAsync(Future<void> future) {
    unawaited(
      future.catchError((e, st) {
        debugPrint('[MonacoEditor] Async update error: $e');
      }),
    );
  }

  /// Wires only the content changed listener, allowing it to be updated separately.
  void _wireContentListener() {
    // Cancel any previous content subscription first.
    _contentSub?.cancel();
    _contentSub = null;

    _contentSub = _controller!.onContentChanged.listen((isFlush) {
      // 1) Always surface raw signal if requested.
      widget.onRawContentChanged?.call(isFlush);

      // 2) Nothing else to do?
      if (widget.onContentChanged == null) return;
      if (widget.fullTextOnFlushOnly && !isFlush) return;

      // 3) Flush = immediate fetch (no debounce), else debounced.
      Future<void> pullAndEmit() async {
        final seq = ++_contentSeq;
        final text = await _controller!.getValue();
        if (!mounted || seq != _contentSeq) return; // drop stale
        widget.onContentChanged!(text);
      }

      if (isFlush) {
        _contentDebounceTimer?.cancel();
        _ignoreAsync(pullAndEmit());
        return;
      }

      _contentDebounceTimer?.cancel();
      _contentDebounceTimer = Timer(
        widget.contentDebounce,
        () => _ignoreAsync(pullAndEmit()),
      );
    });
  }

  /// Cancels all active event subscriptions.
  void _teardownListeners() {
    for (final sub in _streamSubscriptions) {
      sub.cancel();
    }
    _streamSubscriptions.clear();

    _contentSub?.cancel();
    _contentSub = null;

    _contentDebounceTimer?.cancel();
    _contentDebounceTimer = null;

    if (_controller != null && _statsListener != null) {
      _controller!.liveStats.removeListener(_statsListener!);
      _statsListener = null;
    }
  }

  /// Cleans up all resources, including listeners and the controller if owned.
  void _teardown({required bool disposeOldController}) {
    _teardownListeners();
    if (disposeOldController) {
      _controller?.dispose();
    }
    _controller = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg =
        widget.backgroundColor ??
        (theme.brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white);

    return Container(
      color: bg,
      constraints: widget.constraints,
      padding: widget.padding,
      child: _buildChild(context),
    );
  }

  /// Builds the main content based on the current connection state.
  Widget _buildChild(BuildContext context) {
    // No controller yet - show loading or error
    if (_controller == null) {
      if (_connectionState == _ConnectionState.error) {
        return widget.errorBuilder?.call(context, _error!, _stack) ??
            _DefaultError(
              error: _error!,
              onRetry: _ownsController ? _bootstrap : null,
            );
      }
      return widget.loadingBuilder?.call(context) ?? const _DefaultLoading();
    }

    // On mobile, let the WebView own the full tap-to-keyboard chain.
    // Flutter's Focus/Listener wrapper steals the gesture context, which
    // causes the OS to refuse the soft keyboard.
    final isMobileInputPlatform = _isMobileInputPlatform();

    final Widget webView;
    if (isMobileInputPlatform) {
      webView = SizedBox.expand(child: _controller!.webViewWidget);
    } else {
      webView = SizedBox.expand(
        child: Focus(
          focusNode: _webFocusNode,
          canRequestFocus: widget.interactionEnabled,
          autofocus: widget.autofocus && widget.interactionEnabled,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              return KeyEventResult.skipRemainingHandlers;
            }
            return KeyEventResult.ignored;
          },
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              if (!widget.interactionEnabled) return;
              if (!_pointerShouldRecoverInputFocus(
                event,
                hasFlutterFocus: _webFocusNode.hasFocus,
                monacoReportsFocused: _monacoReportsFocused,
              )) {
                return;
              }
              _webFocusNode.requestFocus();
              unawaited(
                _controller!.ensureEditorFocus(
                  attempts: 1,
                  intent: MonacoFocusIntent.user,
                ),
              );
            },
            child: _controller!.webViewWidget,
          ),
        ),
      );
    }

    Widget content = webView;
    if (_connectionState == _ConnectionState.connecting) {
      // Overlay the webView with a loading indicator, this ensures the
      // webView already exists and is ready to be rendered.
      content = Stack(
        children: [
          webView,
          Positioned.fill(
            child:
                widget.loadingBuilder?.call(context) ?? const _DefaultLoading(),
          ),
        ],
      );
    } else if (_connectionState == _ConnectionState.error) {
      // Overlay the webView with an error indicator, this ensures the
      // webView already exists and is ready to be rendered.
      content = Stack(
        children: [
          webView,
          Positioned.fill(
            child:
                widget.errorBuilder?.call(context, _error!, _stack) ??
                _DefaultError(
                  error: _error!,
                  onRetry: _ownsController ? _bootstrap : null,
                ),
          ),
        ],
      );
    }

    final showBar = widget.showStatusBar || widget.statusBarBuilder != null;

    if (!showBar) {
      return content;
    }

    // The status bar is built here, listening to the controller's stats.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: content),
        if (widget.statusBarBuilder != null)
          ValueListenableBuilder<LiveStats>(
            valueListenable: _controller!.liveStats,
            builder: (context, stats, _) =>
                widget.statusBarBuilder!(context, stats),
          )
        else
          _MonacoStatusBar(controller: _controller!),
      ],
    );
  }

  @override
  void dispose() {
    _webFocusNode.dispose();
    _teardown(disposeOldController: _ownsController);
    super.dispose();
  }
}

// -----------------------------------------------------------------------------
// DEFAULT UI COMPONENTS
// -----------------------------------------------------------------------------

/// The default status bar, optimized to only rebuild when stats change.
class _MonacoStatusBar extends StatelessWidget {
  const _MonacoStatusBar({required this.controller});

  final MonacoController controller;

  @override
  Widget build(BuildContext context) {
    final theme = MonacoEditorTheme.of(context);
    final style =
        theme.statusBarTextStyle ??
        Theme.of(context).textTheme.bodySmall ??
        const TextStyle(fontSize: 12);

    return ValueListenableBuilder<LiveStats>(
      valueListenable: controller.liveStats,
      builder: (context, stats, _) {
        final entries = [
          if (stats.cursorPosition != null) 'Ln ${stats.cursorPosition!.label}',
          'Ch ${stats.charCount.value}',
          if (stats.selectedLines.value > 0)
            'Sel Ln ${stats.selectedLines.value}',
          if (stats.selectedCharacters.value > 0)
            'Sel Ch ${stats.selectedCharacters.value}',
          if (stats.language != null) stats.language!,
        ].where((s) => s.isNotEmpty).toList();

        return Container(
          padding:
              theme.statusBarPadding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: theme.statusBarBackgroundColor,
            border: Border(
              top: BorderSide(
                color:
                    theme.statusBarBorderColor ??
                    Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: theme.statusBarSpacing ?? 16,
            runSpacing: 4,
            children: [for (final entry in entries) Text(entry, style: style)],
          ),
        );
      },
    );
  }
}

class _DefaultLoading extends StatelessWidget {
  const _DefaultLoading();

  @override
  Widget build(BuildContext context) {
    final theme = MonacoEditorTheme.of(context);
    return ColoredBox(
      color: theme.loadingBackgroundColor ?? Colors.transparent,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: theme.loadingIndicatorColor,
          ),
        ),
      ),
    );
  }
}

class _DefaultError extends StatelessWidget {
  const _DefaultError({required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final materialTheme = Theme.of(context);
    final theme = MonacoEditorTheme.of(context);
    final titleStyle =
        theme.errorTitleStyle ?? materialTheme.textTheme.titleMedium;
    final style = theme.errorMessageStyle ?? materialTheme.textTheme.bodyMedium;

    return ColoredBox(
      color: theme.errorBackgroundColor ?? Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.errorIconColor ?? materialTheme.colorScheme.error,
                size: 36,
              ),
              const SizedBox(height: 16),
              Text('Failed to Initialize Editor', style: titleStyle),
              const SizedBox(height: 8),
              Text('$error', textAlign: TextAlign.center, style: style),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: theme.retryButtonStyle,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
