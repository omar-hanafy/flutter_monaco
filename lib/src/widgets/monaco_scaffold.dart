import 'package:flutter/material.dart';
import 'package:flutter_monaco/src/widgets/monaco_overlay_boundary.dart';

/// Drop-in [`Scaffold`] replacement that automatically protects common
/// static overlay slots from iframe-backed Monaco editors on Web.
///
/// On web, each of the `floatingActionButton`, `drawer`, `endDrawer`,
/// `bottomSheet`, `bottomNavigationBar`, and `persistentFooterButtons`
/// slots is wrapped in [`MonacoOverlayBoundary`] so pointer events land on
/// Flutter widgets instead of the editor iframe underneath. The `appBar`
/// is left alone by default (AppBars typically sit above the editor in the
/// layout, not over it); enable [`shieldAppBar`] for translucent /
/// `extendBodyBehindAppBar` layouts.
///
/// `MonacoScaffold` does NOT replace [`MonacoFocusGuard`]. Route overlays
/// (dialogs, popup menus, dropdown menus, modal bottom sheets) should still
/// be handled by [`MonacoFocusGuard`] + [`MonacoRouteObserver`].
///
/// On native platforms, all overlay boundaries are no-op pass-throughs.
class MonacoScaffold extends StatelessWidget {
  /// Construct a Monaco-aware [Scaffold]. Every parameter except the three
  /// at the end (`shieldStaticOverlays`, `shieldAppBar`, `overlayDebug`)
  /// behaves identically to the corresponding [Scaffold] parameter.
  const MonacoScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.persistentFooterAlignment = AlignmentDirectional.centerEnd,
    this.drawer,
    this.onDrawerChanged,
    this.endDrawer,
    this.onEndDrawerChanged,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerScrimColor,
    this.drawerEdgeDragWidth,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.restorationId,
    this.shieldStaticOverlays = true,
    this.shieldAppBar = false,
    this.overlayDebug = false,
  });

  /// See [Scaffold.appBar].
  final PreferredSizeWidget? appBar;

  /// See [Scaffold.body].
  final Widget? body;

  /// See [Scaffold.floatingActionButton].
  final Widget? floatingActionButton;

  /// See [Scaffold.floatingActionButtonLocation].
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// See [Scaffold.floatingActionButtonAnimator].
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;

  /// See [Scaffold.persistentFooterButtons].
  final List<Widget>? persistentFooterButtons;

  /// See [Scaffold.persistentFooterAlignment].
  final AlignmentDirectional persistentFooterAlignment;

  /// See [Scaffold.drawer].
  final Widget? drawer;

  /// See [Scaffold.onDrawerChanged].
  final DrawerCallback? onDrawerChanged;

  /// See [Scaffold.endDrawer].
  final Widget? endDrawer;

  /// See [Scaffold.onEndDrawerChanged].
  final DrawerCallback? onEndDrawerChanged;

  /// See [Scaffold.bottomNavigationBar].
  final Widget? bottomNavigationBar;

  /// See [Scaffold.bottomSheet].
  final Widget? bottomSheet;

  /// See [Scaffold.backgroundColor].
  final Color? backgroundColor;

  /// See [Scaffold.resizeToAvoidBottomInset].
  final bool? resizeToAvoidBottomInset;

  /// See [Scaffold.extendBody].
  final bool extendBody;

  /// See [Scaffold.extendBodyBehindAppBar].
  final bool extendBodyBehindAppBar;

  /// See [Scaffold.drawerScrimColor].
  final Color? drawerScrimColor;

  /// See [Scaffold.drawerEdgeDragWidth].
  final double? drawerEdgeDragWidth;

  /// See [Scaffold.drawerEnableOpenDragGesture].
  final bool drawerEnableOpenDragGesture;

  /// See [Scaffold.endDrawerEnableOpenDragGesture].
  final bool endDrawerEnableOpenDragGesture;

  /// See [Scaffold.restorationId].
  final String? restorationId;

  /// When false, this behaves like a plain Scaffold (no shielding).
  final bool shieldStaticOverlays;

  /// AppBars usually sit above the editor in the layout. Enable this for
  /// translucent AppBars or `extendBodyBehindAppBar: true` layouts where the
  /// AppBar visually overlaps the editor.
  final bool shieldAppBar;

  /// Shows the web shield rectangles in translucent green for debugging.
  final bool overlayDebug;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shieldAppBar ? _shieldPreferredSize(appBar) : appBar,
      body: body,
      floatingActionButton: _shield(floatingActionButton),
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      persistentFooterButtons: persistentFooterButtons
          ?.map((button) => _shield(button)!)
          .toList(),
      persistentFooterAlignment: persistentFooterAlignment,
      drawer: _shield(drawer),
      onDrawerChanged: onDrawerChanged,
      endDrawer: _shield(endDrawer),
      onEndDrawerChanged: onEndDrawerChanged,
      bottomNavigationBar: _shield(bottomNavigationBar),
      bottomSheet: _shield(bottomSheet),
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawerScrimColor: drawerScrimColor,
      drawerEdgeDragWidth: drawerEdgeDragWidth,
      drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
      endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
      restorationId: restorationId,
    );
  }

  Widget? _shield(Widget? child) {
    if (child == null) return null;
    if (!shieldStaticOverlays) return child;

    return MonacoOverlayBoundary(debug: overlayDebug, child: child);
  }

  PreferredSizeWidget? _shieldPreferredSize(PreferredSizeWidget? child) {
    if (child == null) return null;
    if (!shieldStaticOverlays) return child;

    return _PreferredMonacoOverlayBoundary(debug: overlayDebug, child: child);
  }
}

class _PreferredMonacoOverlayBoundary extends StatelessWidget
    implements PreferredSizeWidget {
  const _PreferredMonacoOverlayBoundary({
    required this.child,
    required this.debug,
  });

  final PreferredSizeWidget child;
  final bool debug;

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) {
    return MonacoOverlayBoundary(debug: debug, child: child);
  }
}
