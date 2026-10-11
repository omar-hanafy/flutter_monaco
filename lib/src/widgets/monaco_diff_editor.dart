import 'dart:async';

import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_monaco/src/widgets/monaco_status_bar.dart';
import 'package:flutter_monaco/src/widgets/scroll_handoff_driver.dart';
import 'package:material_ui/material_ui.dart';

/// A widget that renders a Monaco diff editor (original vs modified).
///
/// Mirrors `MonacoEditor`'s chrome: shows [loadingBuilder] until the diff
/// editor is ready and [errorBuilder] on boot failure. Content, language,
/// options, and diff options update live via `didUpdateWidget`. After the
/// controller recovers from a page reload (see
/// `MonacoDiffController.onPageReloaded`) the widget re-applies its current
/// texts, options, theme, diff options, and scroll handoff; a failed
/// recovery is reported to [onError].
///
/// ### Example
///
/// ```dart
/// MonacoDiffEditor(
///   original: oldSource,
///   modified: newSource,
///   language: MonacoLanguage.dart,
///   diffOptions: MonacoDiffOptions(renderSideBySide: true),
/// )
/// ```
class MonacoDiffEditor extends StatefulWidget {
  /// Creates a new [MonacoDiffEditor] widget.
  const MonacoDiffEditor({
    super.key,
    this.controller,
    this.controllerFactory,
    this.original = '',
    this.modified = '',
    this.language = MonacoLanguage.plaintext,
    this.options = const EditorOptions(),
    this.diffOptions = const MonacoDiffOptions(),
    this.page = const MonacoPageConfig(),
    this.readyTimeout = MonacoDefaults.readyTimeout,
    this.scrollHandoff = const MonacoScrollHandoff.disabled(),
    this.onReady,
    this.onError,
    this.loadingBuilder,
    this.errorBuilder,
    this.backgroundColor,
  });

  /// The controller that manages the diff editor instance.
  ///
  /// If provided, you are responsible for disposing of it. If `null`, a
  /// controller is created and managed internally by this widget.
  final MonacoDiffController? controller;

  /// Test-only hook to supply a controller factory when this widget owns
  /// the controller lifecycle.
  @visibleForTesting
  final Future<MonacoDiffController> Function()? controllerFactory;

  /// The original (left) text.
  final String original;

  /// The modified (right) text.
  final String modified;

  /// The language shared by both sides.
  final MonacoLanguage language;

  /// Editor options for the inner editor pair (fonts, minimap, ...).
  ///
  /// A null [EditorOptions.theme] follows the surrounding Flutter
  /// brightness (D27), exactly like `MonacoEditor`.
  final EditorOptions options;

  /// Diff-specific options (side-by-side vs inline, ...).
  final MonacoDiffOptions diffOptions;

  /// Page-level settings; changing this recreates the controller when the
  /// widget owns it.
  final MonacoPageConfig page;

  /// How scroll input the diff editor cannot consume is handed to the
  /// Flutter host. Defaults to [MonacoScrollHandoff.disabled].
  ///
  /// When set to [MonacoScrollHandoff.edge], wheel or trackpad input over
  /// either pane keeps scrolling the diff until it reaches its vertical
  /// scroll edge; unconsumed deltas are then forwarded to
  /// [MonacoScrollHandoff.controller] or the nearest enclosing vertical
  /// scrollable, so the surrounding page continues scrolling. Identical
  /// semantics to `MonacoEditor.scrollHandoff`.
  final MonacoScrollHandoff scrollHandoff;

  /// The maximum duration to wait for the diff editor to initialize.
  ///
  /// Defaults to [MonacoDefaults.readyTimeout]: 20s on native platforms
  /// (local assets, so expiry means a hung boot) and 90s on web, where the
  /// cold-cache first load must download the multi-megabyte editor bundle
  /// and is bound by bandwidth, not by a hang. Hard failures surface
  /// immediately regardless of this deadline.
  final Duration readyTimeout;

  /// Callback invoked when the diff editor is ready.
  final ValueChanged<MonacoDiffController>? onReady;

  /// Callback invoked when a background diff operation fails. When `null`,
  /// failures go to [FlutterError.reportError].
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// Builder for the widget displayed while the diff editor initializes.
  final WidgetBuilder? loadingBuilder;

  /// Builder for the widget displayed if initialization fails.
  final Widget Function(BuildContext context, Object error, StackTrace? st)?
  errorBuilder;

  /// Background color painted behind the WebView.
  final Color? backgroundColor;

  @override
  State<MonacoDiffEditor> createState() => _MonacoDiffEditorState();
}

enum _DiffConnectionState { connecting, ready, error }

class _MonacoDiffEditorState extends State<MonacoDiffEditor> {
  MonacoDiffController? _controller;
  bool _ownsController = false;
  _DiffConnectionState _connectionState = _DiffConnectionState.connecting;
  Object? _error;
  StackTrace? _stack;
  int _bootstrapSeq = 0;
  MonacoTheme? _appliedResolvedTheme;
  bool _bootstrappedOnce = false;

  /// Applies forwarded scroll deltas to the configured Flutter target
  /// (shared with `MonacoEditor`).
  late final ScrollHandoffDriver _scrollHandoffDriver = ScrollHandoffDriver(
    config: () => widget.scrollHandoff,
    context: () => context,
    isMounted: () => mounted,
  );
  StreamSubscription<MonacoScrollHandoffDetails>? _scrollHandoffSub;
  StreamSubscription<void>? _pageReloadSub;

  /// The handoff sources and boundary policy last pushed to the diff page,
  /// so config rebuilds only produce bridge traffic when the effective
  /// configuration changes.
  bool _syncedWheelSource = false;
  bool _syncedTouchSource = false;
  MonacoScrollBoundaryPolicy _syncedPolicy =
      MonacoScrollBoundaryPolicy.newGestureOnly;

  /// The texts/language last pushed to (or booted into) the controller, so
  /// prop changes that land during the connecting window are re-applied at
  /// ready instead of being dropped. Null = never pushed by this widget.
  String? _appliedOriginal;
  String? _appliedModified;
  MonacoLanguage? _appliedLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // First bootstrap runs here (not initState): resolving a null theme
    // reads Theme.of(context). See MonacoEditor for the same pattern.
    if (!_bootstrappedOnce) {
      _bootstrappedOnce = true;
      _bootstrap();
      return;
    }
    // D27: a null options.theme follows the ambient brightness.
    if (widget.options.theme != null) return;
    if (_connectionState != _DiffConnectionState.ready || _controller == null) {
      return;
    }
    final resolved = _resolveTheme();
    if (resolved == _appliedResolvedTheme) return;
    _appliedResolvedTheme = resolved;
    _ignoreAsync(_controller!.setTheme(resolved));
  }

  @override
  void didUpdateWidget(covariant MonacoDiffEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      _teardown(disposeOldController: _ownsController);
      _bootstrap();
      return;
    }

    if (_ownsController && oldWidget.page != widget.page) {
      _teardown(disposeOldController: true);
      _bootstrap();
      return;
    }

    if (widget.scrollHandoff != oldWidget.scrollHandoff) {
      // Identity compare is enough: the sync method dedupes against the
      // last pushed source flags, so rebuilds with equivalent configs are
      // free.
      _syncScrollHandoffSources();
    }

    if (_connectionState != _DiffConnectionState.ready || _controller == null) {
      return;
    }

    if (widget.original != oldWidget.original ||
        widget.modified != oldWidget.modified ||
        widget.language != oldWidget.language) {
      _syncTexts();
    }

    if (widget.options != oldWidget.options) {
      _ignoreAsync(_controller!.updateOptions(widget.options));
      if (widget.options.theme != oldWidget.options.theme) {
        final resolvedTheme = _resolveTheme();
        _appliedResolvedTheme = resolvedTheme;
        _ignoreAsync(_controller!.setTheme(resolvedTheme));
      }
    }

    if (widget.diffOptions != oldWidget.diffOptions) {
      _ignoreAsync(_controller!.updateDiffOptions(widget.diffOptions));
    }
  }

  /// Resolves the effective theme: an explicit options theme always wins;
  /// a null theme follows the surrounding Flutter brightness (D27).
  MonacoTheme _resolveTheme() {
    final explicit = widget.options.theme;
    if (explicit != null) return explicit;
    final brightness = mounted ? Theme.of(context).brightness : Brightness.dark;
    return brightness == Brightness.dark
        ? MonacoDefaults.darkTheme
        : MonacoDefaults.lightTheme;
  }

  bool _isBootstrapCurrent(int token) => token == _bootstrapSeq && mounted;

  Future<void> _bootstrap() async {
    // A retry after a failed owned boot must not orphan the previous
    // controller (its platform WebView and protocol, with the in-flight
    // page.boot, would leak once per retry).
    if (_controller != null) {
      _teardown(disposeOldController: _ownsController);
    }

    final bootstrapToken = ++_bootstrapSeq;
    setState(() {
      _connectionState = _DiffConnectionState.connecting;
      _error = null;
      _stack = null;
    });

    try {
      final ownsController = widget.controller == null;
      _ownsController = ownsController;
      final usedInternalCreate =
          widget.controller == null && widget.controllerFactory == null;
      final bootTheme = _resolveTheme();
      _appliedResolvedTheme = bootTheme;
      final bootOriginal = widget.original;
      final bootModified = widget.modified;
      final bootLanguage = widget.language;
      // Snapshot the configuration the boot applies; the widget may rebuild
      // with different values while boot is in flight (didUpdateWidget
      // drops changes during `connecting`), so readiness reconciles against
      // these below.
      final bootOptions = widget.options;
      final bootDiffOptions = widget.diffOptions;
      final controller =
          widget.controller ??
          await (widget.controllerFactory?.call() ??
              MonacoDiffController.create(
                options: widget.options.copyWith(theme: bootTheme),
                diff: widget.diffOptions,
                original: bootOriginal,
                modified: bootModified,
                language: bootLanguage,
                page: widget.page,
                readyTimeout: widget.readyTimeout,
              ));
      if (usedInternalCreate) {
        _appliedOriginal = bootOriginal;
        _appliedModified = bootModified;
        _appliedLanguage = bootLanguage;
      }

      if (!_isBootstrapCurrent(bootstrapToken)) {
        if (ownsController) {
          controller.dispose();
        }
        return;
      }

      setState(() => _controller = controller);
      _ownsController = ownsController;

      await _controller!.whenReady;
      if (!_isBootstrapCurrent(bootstrapToken)) {
        return;
      }

      // Externally supplied controllers booted with their own texts and
      // options; apply this widget's configuration post-readiness. Texts
      // are only pushed when the widget actually carries content -
      // otherwise the defaults ('' vs '') would wipe the diff an external
      // controller booted with.
      var appliedOptions = bootOptions;
      var appliedDiffOptions = bootDiffOptions;
      if (!usedInternalCreate) {
        appliedOptions = widget.options;
        appliedDiffOptions = widget.diffOptions;
        await _controller!.updateOptions(appliedOptions);
        await _controller!.updateDiffOptions(appliedDiffOptions);
        final resolvedTheme = _resolveTheme();
        _appliedResolvedTheme = resolvedTheme;
        await _controller!.setTheme(resolvedTheme);
        if (widget.original.isNotEmpty || widget.modified.isNotEmpty) {
          await _controller!.setTexts(
            original: widget.original,
            modified: widget.modified,
            language: widget.language,
          );
          _appliedOriginal = widget.original;
          _appliedModified = widget.modified;
          _appliedLanguage = widget.language;
        }
        if (!_isBootstrapCurrent(bootstrapToken)) {
          return;
        }
      }

      // Option/diff-option/theme props may have changed while the boot was
      // in flight (didUpdateWidget cannot see them during `connecting`);
      // apply the delta before reporting ready. Texts are reconciled by
      // _syncTexts below.
      if (widget.options != appliedOptions) {
        await _controller!.updateOptions(widget.options);
      }
      if (widget.diffOptions != appliedDiffOptions) {
        await _controller!.updateDiffOptions(widget.diffOptions);
      }
      final reconciledTheme = _resolveTheme();
      if (reconciledTheme != _appliedResolvedTheme) {
        _appliedResolvedTheme = reconciledTheme;
        await _controller!.setTheme(reconciledTheme);
      }
      if (!_isBootstrapCurrent(bootstrapToken)) {
        return;
      }

      _wireScrollHandoff();
      _wirePageReload();
      _syncScrollHandoffSources();

      setState(() => _connectionState = _DiffConnectionState.ready);
      // Content props may have changed while the boot was in flight;
      // re-apply the delta now that didUpdateWidget can no longer see it.
      _syncTexts();
      _invokeOnReady();
    } catch (e, st) {
      if (!_isBootstrapCurrent(bootstrapToken)) return;
      // Boot failures render the error surface; onError is informed when
      // set, but there is no FlutterError fallback - the failure is
      // already visible. An owned controller is disposed here (matching
      // MonacoEditor) instead of leaking its WebView until retry/dispose.
      widget.onError?.call(e, st);
      _teardown(disposeOldController: _ownsController);
      setState(() {
        _connectionState = _DiffConnectionState.error;
        _error = e;
        _stack = st;
      });
    }
  }

  /// An application onReady exception is not an editor boot failure: report
  /// it through FlutterError and leave the healthy diff editor alone.
  void _invokeOnReady() {
    final callback = widget.onReady;
    if (callback == null) return;
    try {
      callback(_controller!);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'flutter_monaco',
          context: ErrorDescription('while calling MonacoDiffEditor.onReady'),
        ),
      );
    }
  }

  /// Pushes the widget's texts/language when they differ from what was
  /// last applied. Never pushes the widget's empty defaults over an
  /// external controller's booted content (applied == null and both sides
  /// empty means this widget never carried content).
  void _syncTexts() {
    if (_controller == null) return;
    if (_appliedOriginal == widget.original &&
        _appliedModified == widget.modified &&
        _appliedLanguage == widget.language) {
      return;
    }
    if (_appliedOriginal == null &&
        widget.original.isEmpty &&
        widget.modified.isEmpty) {
      return;
    }
    _appliedOriginal = widget.original;
    _appliedModified = widget.modified;
    _appliedLanguage = widget.language;
    _ignoreAsync(
      _controller!.setTexts(
        original: widget.original,
        modified: widget.modified,
        language: widget.language,
      ),
    );
  }

  /// Subscribes the shared driver to the controller's handoff stream.
  void _wireScrollHandoff() {
    _scrollHandoffSub?.cancel();
    _scrollHandoffSub = _controller!.onScrollHandoff.listen(
      _scrollHandoffDriver.handle,
    );
  }

  /// Re-applies this widget's configuration whenever the controller
  /// recovers from a page reload; recovery failures route to onError.
  void _wirePageReload() {
    _pageReloadSub?.cancel();
    _pageReloadSub = _controller!.onPageReloaded.listen(
      (_) => _reapplyAfterPageReload(),
      onError: _reportAsyncError,
    );
  }

  /// The re-booted page carries the controller's BOOT-time payload (texts,
  /// options, theme) and no scroll handoff listeners, so every applied
  /// snapshot this widget dedupes against describes the old page. Reset
  /// them and push the widget's current configuration.
  void _reapplyAfterPageReload() {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final resolvedTheme = _resolveTheme();
    _appliedResolvedTheme = resolvedTheme;
    _ignoreAsync(() async {
      await controller.updateOptions(widget.options);
      await controller.updateDiffOptions(widget.diffOptions);
      await controller.setTheme(resolvedTheme);
    }());
    if (_appliedOriginal != null) {
      // This widget owned the texts on the old page: the reload reverted
      // them to the boot texts, so push them again even if unchanged.
      _appliedOriginal = widget.original;
      _appliedModified = widget.modified;
      _appliedLanguage = widget.language;
      _ignoreAsync(
        controller.setTexts(
          original: widget.original,
          modified: widget.modified,
          language: widget.language,
        ),
      );
    } else {
      _syncTexts();
    }
    _syncedWheelSource = false;
    _syncedTouchSource = false;
    _syncedPolicy = MonacoScrollBoundaryPolicy.newGestureOnly;
    _syncScrollHandoffSources();
  }

  /// Pushes the desired handoff sources and boundary policy to the diff
  /// page when they differ from what was last pushed. A disabled config
  /// therefore produces no bridge traffic at all.
  void _syncScrollHandoffSources() {
    final controller = _controller;
    if (controller == null) return;
    final wheel = widget.scrollHandoff.wheelSourceEnabled;
    final touch = widget.scrollHandoff.touchSourceEnabled;
    final policy = widget.scrollHandoff.policy;
    if (wheel == _syncedWheelSource &&
        touch == _syncedTouchSource &&
        policy == _syncedPolicy) {
      return;
    }
    _syncedWheelSource = wheel;
    _syncedTouchSource = touch;
    _syncedPolicy = policy;
    _ignoreAsync(
      controller.setScrollHandoffSources(
        wheel: wheel,
        touch: touch,
        policy: policy,
      ),
    );
  }

  void _ignoreAsync(Future<void> future) {
    unawaited(
      future.catchError((Object e, StackTrace st) {
        _reportAsyncError(e, st);
      }),
    );
  }

  void _reportAsyncError(Object error, StackTrace stackTrace) {
    final handler = widget.onError;
    if (handler != null) {
      handler(error, stackTrace);
      return;
    }
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'flutter_monaco',
        context: ErrorDescription('while running a MonacoDiffEditor update'),
      ),
    );
  }

  void _teardown({required bool disposeOldController}) {
    _scrollHandoffSub?.cancel();
    _scrollHandoffSub = null;
    _pageReloadSub?.cancel();
    _pageReloadSub = null;
    final controller = _controller;
    if (controller != null &&
        !disposeOldController &&
        (_syncedWheelSource || _syncedTouchSource)) {
      // The external controller outlives this widget: stop the page from
      // posting handoff events nobody consumes.
      _ignoreAsync(controller.setScrollHandoffSources());
    }
    _syncedWheelSource = false;
    _syncedTouchSource = false;
    _syncedPolicy = MonacoScrollBoundaryPolicy.newGestureOnly;
    _scrollHandoffDriver.clearPending();
    if (disposeOldController) {
      controller?.dispose();
    }
    _controller = null;
    _appliedResolvedTheme = null;
    _appliedOriginal = null;
    _appliedModified = null;
    _appliedLanguage = null;
  }

  @override
  void dispose() {
    _teardown(disposeOldController: _ownsController);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg =
        widget.backgroundColor ??
        (theme.brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white);

    return ColoredBox(color: bg, child: _buildChild(context));
  }

  Widget _buildChild(BuildContext context) {
    // No controller yet: plain loading/error chrome.
    if (_controller == null) {
      if (_connectionState == _DiffConnectionState.error) {
        return widget.errorBuilder?.call(context, _error!, _stack) ??
            MonacoDefaultError(
              error: _error!,
              onRetry: _ownsController ? _bootstrap : null,
            );
      }
      return widget.loadingBuilder?.call(context) ??
          const MonacoDefaultLoading();
    }

    // The WebView must be IN the tree while the page boots: on web the
    // iframe only attaches (and can load Monaco) once its platform view
    // renders. Loading/error states overlay it instead of replacing it,
    // exactly like MonacoEditor.
    final webView = SizedBox.expand(child: _controller!.webViewWidget);
    return switch (_connectionState) {
      _DiffConnectionState.ready => webView,
      _DiffConnectionState.connecting => Stack(
        children: [
          webView,
          Positioned.fill(
            child:
                widget.loadingBuilder?.call(context) ??
                const MonacoDefaultLoading(),
          ),
        ],
      ),
      _DiffConnectionState.error => Stack(
        children: [
          webView,
          Positioned.fill(
            child:
                widget.errorBuilder?.call(context, _error!, _stack) ??
                MonacoDefaultError(
                  error: _error!,
                  onRetry: _ownsController ? _bootstrap : null,
                ),
          ),
        ],
      ),
    };
  }
}
