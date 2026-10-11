import 'dart:ui' show Offset, Rect;
import 'dart:ui_web' as ui_web;

import 'package:flutter_monaco/src/platform/web_interaction_coordinator.dart';
import 'package:web/web.dart' as web;

/// Moves the host element of the Flutter view [viewId] by [by] CSS pixels
/// inside the page, like an app embedded into a larger page (element
/// embedding / multi-view). Returns a callback restoring the old position.
void Function() shiftFlutterViewHost(int viewId, Offset by) {
  final host = ui_web.views.getHostElement(viewId)! as web.HTMLElement;
  final previousLeft = host.style.marginLeft;
  final previousTop = host.style.marginTop;
  host.style.marginLeft = '${by.dx}px';
  host.style.marginTop = '${by.dy}px';
  return () {
    host.style.marginLeft = previousLeft;
    host.style.marginTop = previousTop;
  };
}

/// Where the Flutter view [viewId]'s logical origin lies in the browser
/// viewport.
Offset flutterViewViewportOrigin(int viewId) {
  final host = ui_web.views.getHostElement(viewId)! as web.Element;
  final view = host.querySelector('flutter-view') ?? host;
  final rect = view.getBoundingClientRect();
  return Offset(rect.left, rect.top);
}

List<web.Element> _shieldElements() {
  final shields = web.document.querySelectorAll(
    '[data-flutter-monaco-overlay-shield]',
  );
  return [
    for (var i = 0; i < shields.length; i++) shields.item(i)! as web.Element,
  ];
}

/// The viewport rects of every overlay shield element in the page.
List<Rect> overlayShieldViewportRects() {
  return [
    for (final shield in _shieldElements())
      () {
        final rect = shield.getBoundingClientRect();
        return Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height);
      }(),
  ];
}

/// Places a stand-in editor iframe at [viewportRect] and registers it with
/// the web interaction coordinator, like a mounted Monaco editor. Returns a
/// reader for its `pointer-events` style and a cleanup callback.
({String Function() pointerEvents, void Function() remove}) addProbeEditor(
  String id,
  Rect viewportRect,
) {
  final iframe = web.HTMLIFrameElement()
    ..id = id
    ..style.position = 'fixed'
    ..style.left = '${viewportRect.left}px'
    ..style.top = '${viewportRect.top}px'
    ..style.width = '${viewportRect.width}px'
    ..style.height = '${viewportRect.height}px'
    ..style.border = '0';
  web.document.body!.appendChild(iframe);
  MonacoWebInteractionCoordinator.instance.registerEditor(id, iframe);
  return (
    pointerEvents: () => iframe.style.pointerEvents,
    remove: () {
      MonacoWebInteractionCoordinator.instance.unregisterEditor(id);
      iframe.remove();
    },
  );
}

/// Dispatches `pointerenter` on every overlay shield, as when the mouse
/// moves over the protected overlay.
void hoverOverlayShields() {
  for (final shield in _shieldElements()) {
    shield.dispatchEvent(web.PointerEvent('pointerenter'));
  }
}
