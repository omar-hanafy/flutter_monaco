import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

/// A tiny, no-UI helper that reasserts Monaco focus on common desktop events.
///
/// - Calls [MonacoController.requestFocus] when the app is resumed.
/// - Optionally subscribes to the current [PageRoute] via a [RouteObserver]
///   and re-focuses when the route becomes visible again (didPopNext).
///
/// This is an optional utility for desktop apps that frequently switch routes
/// or windows. Place it near your editor once you have the controller.
class MonacoFocusGuard extends StatefulWidget {
  /// Creates a [MonacoFocusGuard] widget.
  const MonacoFocusGuard({
    super.key,
    required this.controller,
    this.routeObserver,
    this.modalRouteObserver,
    this.ensureAttempts = 3,
    this.autoDisableInteraction = true,
    this.onError,
  });

  /// The [MonacoController] for the editor that needs focus management.
  final MonacoController controller;

  /// An optional [RouteObserver] to listen for route changes.
  ///
  /// If provided, the guard will re-focus the editor when the current route
  /// becomes visible again (e.g., after a `pop`).
  final RouteObserver<PageRoute<dynamic>>? routeObserver;

  /// An optional [RouteObserver] for [ModalRoute] (dialogs, menus, popups).
  ///
  /// If set, this is preferred over [routeObserver] and allows the guard to
  /// react to popup routes like `showDialog` and `showMenu`.
  final RouteObserver<ModalRoute<dynamic>>? modalRouteObserver;

  /// The number of times to attempt to focus the editor.
  ///
  /// Defaults to 3 attempts.
  final int ensureAttempts;

  /// If `true`, automatically disables editor interaction when a new route
  /// is pushed on top and re-enables it when the current route is returned to.
  ///
  /// This is useful for ensuring Flutter dialogs and menus remain interactive
  /// over the Monaco editor on Web. Requires [modalRouteObserver] for dialogs
  /// and menus, or [routeObserver] for page routes.
  ///
  /// The guard holds a disable scope that composes like
  /// [MonacoController.runWithInteractionDisabled]: it never overwrites the
  /// interaction state the app sets through
  /// [MonacoController.setInteractionEnabled] (or
  /// `MonacoEditor.interactionEnabled`), including changes made while the
  /// route is covered.
  final bool autoDisableInteraction;

  /// Called when a focus or interaction update the guard runs in the
  /// background fails. When `null`, failures go to [FlutterError.reportError].
  ///
  /// A controller that failed to boot, was disposed, or could not recover
  /// from a page reload has no editor to focus; those cases are already
  /// reported through the controller (`whenReady`, `onPageReloaded`) and are
  /// not reported again here.
  final void Function(Object error, StackTrace stackTrace)? onError;

  @override
  State<MonacoFocusGuard> createState() => _MonacoFocusGuardState();
}

class _MonacoFocusGuardState extends State<MonacoFocusGuard>
    with WidgetsBindingObserver, RouteAware {
  PageRoute<dynamic>? _route;
  RouteObserver<PageRoute<dynamic>>? _routeObserver;
  ModalRoute<dynamic>? _modalRoute;
  RouteObserver<ModalRoute<dynamic>>? _modalRouteObserver;

  /// Whether another route currently covers this guard's route.
  bool _covered = false;

  /// Releases the guard's interaction disable scope; null while none is
  /// held.
  Completer<void>? _disableScope;

  /// Completes once the held scope exited and the controller applied the
  /// resulting interaction state.
  Future<void>? _disableScopeExit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRouteSubscriptions();
    if (widget.autoDisableInteraction &&
        widget.modalRouteObserver == null &&
        widget.routeObserver == null) {
      debugPrint(
        '⚠️ [MonacoFocusGuard] autoDisableInteraction is enabled but no route observer was provided. '
        'Pass a MonacoRouteObserver to handle web overlays automatically.',
      );
    }
  }

  @override
  void didUpdateWidget(covariant MonacoFocusGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.modalRouteObserver != oldWidget.modalRouteObserver ||
        widget.routeObserver != oldWidget.routeObserver) {
      _syncRouteSubscriptions();
      if (widget.modalRouteObserver == null && widget.routeObserver == null) {
        // Nothing can report the covering route's pop any more.
        _covered = false;
      }
    }
    if (widget.controller != oldWidget.controller ||
        widget.autoDisableInteraction != oldWidget.autoDisableInteraction ||
        !_covered) {
      // The scope belongs to the controller it was opened on.
      _releaseDisableScope();
    }
    if (_covered && widget.autoDisableInteraction) {
      _holdDisableScope();
    }
  }

  /// (Re)subscribes to the configured observer for the current route.
  void _syncRouteSubscriptions() {
    if (widget.modalRouteObserver != _modalRouteObserver) {
      if (_modalRouteObserver != null && _modalRoute != null) {
        _modalRouteObserver!.unsubscribe(this);
      }
      _modalRouteObserver = widget.modalRouteObserver;
      _modalRoute = null;
    }
    if (widget.routeObserver != _routeObserver) {
      if (_routeObserver != null && _route != null) {
        _routeObserver!.unsubscribe(this);
      }
      _routeObserver = widget.routeObserver;
      _route = null;
    }

    if (_modalRouteObserver != null) {
      final route = ModalRoute.of(context);
      if (route != null && route != _modalRoute) {
        if (_modalRoute != null) {
          _modalRouteObserver!.unsubscribe(this);
        }
        _modalRoute = route;
        _modalRouteObserver!.subscribe(this, route);
      }
      return;
    }

    if (_routeObserver != null) {
      final route = ModalRoute.of(context);
      if (route is PageRoute<dynamic> && route != _route) {
        if (_route != null) {
          _routeObserver!.unsubscribe(this);
        }
        _route = route;
        _routeObserver!.subscribe(this, route);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_routeObserver != null && _route != null) {
      _routeObserver!.unsubscribe(this);
    }
    if (_modalRouteObserver != null && _modalRoute != null) {
      _modalRouteObserver!.unsubscribe(this);
    }
    _releaseDisableScope();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _requestFocus();
    }
  }

  @override
  void didPushNext() {
    _covered = true;
    if (widget.autoDisableInteraction) {
      _holdDisableScope();
    }
  }

  @override
  void didPopNext() {
    _covered = false;
    final scopeExit = _releaseDisableScope();
    if (scopeExit == null) {
      _requestFocus();
      return;
    }
    // Focus requests are dropped while interaction is disabled, so focus
    // only once the controller re-applied the app's interaction state.
    unawaited(
      scopeExit.then((_) {
        if (mounted && !_covered) _requestFocus();
      }),
    );
  }

  /// Disables interaction for as long as the guard holds the scope. Like
  /// [MonacoController.runWithInteractionDisabled] (which implements it),
  /// it composes with the app's own interaction state instead of
  /// snapshotting and restoring it.
  void _holdDisableScope() {
    if (_disableScope != null) return;
    final scope = Completer<void>();
    _disableScope = scope;
    _disableScopeExit = _runInBackground(
      widget.controller,
      widget.controller.runWithInteractionDisabled(() => scope.future),
    );
  }

  /// Exits the held scope (if any); the returned future completes once the
  /// controller applied the resulting interaction state.
  Future<void>? _releaseDisableScope() {
    final scope = _disableScope;
    final exit = _disableScopeExit;
    _disableScope = null;
    _disableScopeExit = null;
    if (scope == null) return null;
    if (!scope.isCompleted) scope.complete();
    return exit;
  }

  void _requestFocus() {
    unawaited(
      _runInBackground(
        widget.controller,
        widget.controller.requestFocus(attempts: widget.ensureAttempts),
      ),
    );
  }

  /// Nobody awaits the guard's work, so its failures are routed here
  /// instead of escaping as uncaught zone errors. The returned future never
  /// fails.
  Future<void> _runInBackground(
    MonacoController controller,
    Future<void> work,
  ) {
    return work.catchError((Object error, StackTrace stackTrace) {
      // No editor to act on: the controller already reports why through
      // whenReady / onPageReloaded.
      if (error is MonacoDisposedError || !controller.isReady) return;
      final handler = widget.onError;
      if (mounted && handler != null) {
        handler(error, stackTrace);
        return;
      }
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'flutter_monaco',
          context: ErrorDescription('while running a MonacoFocusGuard update'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
