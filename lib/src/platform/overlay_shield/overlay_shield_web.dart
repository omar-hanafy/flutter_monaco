import 'dart:js_interop';
import 'dart:ui' show Rect;
import 'dart:ui_web' as ui_web;

import 'package:flutter_monaco/src/platform/web_interaction_coordinator.dart';
import 'package:web/web.dart' as web;

/// A manually managed transparent DOM shield over a Flutter overlay region.
///
/// Deliberately NOT an [`HtmlElementView`]: routing this through Flutter's
/// platform-view system reintroduces the very ordering bug we are trying to
/// fix (two platform views fighting for hit-test priority). Instead, the
/// shield is a normal absolutely-positioned `<div>` appended to the Flutter
/// host element with `z-index: 2147483647`. Plain DOM beats platform views
/// in browser hit-testing, so the shield reliably becomes the event target
/// at the overlay's rect.
///
/// The shield does not call `stopPropagation()`. After the browser picks the
/// shield as the hit target, the event still bubbles up to Flutter's listener
/// on the host. Flutter then hit-tests the widget tree and dispatches to the
/// widget visually at that position - normally the overlay child wrapped by
/// [`MonacoOverlayBoundary`].
class MonacoOverlayDomShield {
  /// `true` on web. Callers gate construction on this flag.
  static const bool isSupported = true;

  /// Create a shield attached to the Flutter view with the given [flutterViewId].
  ///
  /// Set [_debug] to render the shield as a translucent green rectangle while
  /// developing.
  MonacoOverlayDomShield({required int flutterViewId, required this._debug})
    : _lockId = 'flutter-monaco-overlay-${_nextLockId()}' {
    _host = ui_web.views.getHostElement(flutterViewId) as web.Element?;
    _createElement();
  }

  static int _lockCounter = 0;
  static int _nextLockId() {
    _lockCounter++;
    return DateTime.now().microsecondsSinceEpoch * 1000 + _lockCounter;
  }

  final bool _debug;
  final String _lockId;

  web.Element? _host;
  web.HTMLDivElement? _element;
  Rect _rect = Rect.zero;

  bool _hovering = false;
  bool _pointerDown = false;
  bool _disposed = false;

  final List<_DomListener> _listeners = <_DomListener>[];

  /// Reposition / resize the shield to match a new overlay rect.
  ///
  /// Pass [Rect.zero] to hide the shield without disposing it. While the
  /// pointer is hovering or pressing the shield, the coordinator keeps
  /// intersecting Monaco iframes locked.
  void update(Rect rect) {
    if (_disposed) return;

    _rect = rect;
    final element = _element;
    if (element == null) return;

    if (rect.isEmpty || rect.width <= 0 || rect.height <= 0) {
      element.style.pointerEvents = 'none';
      element.style.left = '-10000px';
      element.style.top = '-10000px';
      element.style.width = '0px';
      element.style.height = '0px';
      MonacoWebInteractionCoordinator.instance.unlock(_lockId);
      return;
    }

    element.style.pointerEvents = 'auto';
    element.style.left = '${rect.left}px';
    element.style.top = '${rect.top}px';
    element.style.width = '${rect.width}px';
    element.style.height = '${rect.height}px';

    if (_hovering || _pointerDown) {
      _lockIntersectingEditors();
    }
  }

  /// Remove the shield's DOM element, release any held iframe locks, and
  /// unregister all event listeners. Safe to call multiple times.
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    MonacoWebInteractionCoordinator.instance.unlock(_lockId);

    for (final listener in _listeners) {
      listener.target.removeEventListener(listener.type, listener.callback);
    }
    _listeners.clear();

    _element?.remove();
    _element = null;
    _host = null;
  }

  void _createElement() {
    final host = _host;
    if (host == null) return;

    final element = web.document.createElement('div') as web.HTMLDivElement;
    _element = element;

    element
      ..setAttribute('data-flutter-monaco-overlay-shield', _lockId)
      ..setAttribute('aria-hidden', 'true')
      ..setAttribute('tabindex', '-1');

    element.style.position = 'fixed';
    element.style.left = '-10000px';
    element.style.top = '-10000px';
    element.style.width = '0px';
    element.style.height = '0px';
    element.style.margin = '0';
    element.style.padding = '0';
    element.style.border = '0';
    element.style.pointerEvents = 'none';
    element.style.backgroundColor = _debug
        ? 'rgba(0, 255, 0, 0.18)'
        : 'transparent';
    element.style.outline = _debug ? '1px solid rgba(0, 128, 0, 0.7)' : 'none';

    // Max z-index so the shield beats platform-view wrappers in DOM stacking.
    element.style.zIndex = '2147483647';

    // Let Flutter own the gesture sequence.
    element.style.touchAction = 'manipulation';

    host.appendChild(element);

    _listen(element, 'pointerenter', _onPointerEnter);
    _listen(element, 'pointerleave', _onPointerLeave);
    _listen(element, 'pointerdown', _onPointerDown);
    _listen(element, 'pointermove', _onPointerMove);
    _listen(element, 'mousedown', _onMouseDown);
    _listen(element, 'touchstart', _onTouchStart);
    _listen(element, 'contextmenu', _onContextMenu);

    _listen(web.document, 'pointerup', _onGlobalPointerRelease);
    _listen(web.document, 'pointercancel', _onGlobalPointerRelease);
    _listen(web.document, 'mouseup', _onGlobalPointerRelease);
    _listen(web.document, 'touchend', _onGlobalPointerRelease);
    _listen(web.document, 'touchcancel', _onGlobalPointerRelease);
    _listen(web.document, 'visibilitychange', _onVisibilityChange);
  }

  void _listen(
    web.EventTarget target,
    String type,
    void Function(web.Event event) handler,
  ) {
    final callback = handler.toJS;
    target.addEventListener(type, callback);
    _listeners.add(_DomListener(target, type, callback));
  }

  void _onPointerEnter(web.Event event) {
    _hovering = true;
    _lockIntersectingEditors();
  }

  void _onPointerLeave(web.Event event) {
    _hovering = false;
    if (!_pointerDown) {
      MonacoWebInteractionCoordinator.instance.unlock(_lockId);
    }
  }

  void _onPointerDown(web.Event event) {
    _pointerDown = true;
    _preventBrowserDefault(event);
    _lockIntersectingEditors();
  }

  void _onPointerMove(web.Event event) {
    if (_pointerDown) {
      _preventBrowserDefault(event);
      _lockIntersectingEditors();
    }
  }

  void _onMouseDown(web.Event event) {
    _preventBrowserDefault(event);
    _lockIntersectingEditors();
  }

  void _onTouchStart(web.Event event) {
    _pointerDown = true;
    _preventBrowserDefault(event);
    _lockIntersectingEditors();
  }

  void _onContextMenu(web.Event event) {
    _preventBrowserDefault(event);
    _lockIntersectingEditors();
  }

  void _onGlobalPointerRelease(web.Event event) {
    if (!_pointerDown) return;

    _pointerDown = false;
    if (_hovering) {
      _lockIntersectingEditors();
    } else {
      MonacoWebInteractionCoordinator.instance.unlock(_lockId);
    }
  }

  void _onVisibilityChange(web.Event event) {
    _pointerDown = false;
    _hovering = false;
    MonacoWebInteractionCoordinator.instance.unlock(_lockId);
  }

  void _lockIntersectingEditors() {
    MonacoWebInteractionCoordinator.instance.lockEditorsForRect(_lockId, _rect);
  }

  void _preventBrowserDefault(web.Event event) {
    if (event.cancelable) {
      event.preventDefault();
    }

    // Deliberately do NOT call stopPropagation / stopImmediatePropagation.
    // Flutter still needs the event to bubble up so it can hit-test the
    // widget visually at the click position.
  }
}

class _DomListener {
  _DomListener(this.target, this.type, this.callback);

  final web.EventTarget target;
  final String type;
  final JSFunction callback;
}
