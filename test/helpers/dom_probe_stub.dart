import 'dart:ui' show Offset, Rect;

Never _webOnly() =>
    throw UnsupportedError('DOM probes require a web test platform.');

/// Web-only; see `dom_probe_web.dart`.
void Function() shiftFlutterViewHost(int viewId, Offset by) => _webOnly();

/// Web-only; see `dom_probe_web.dart`.
Offset flutterViewViewportOrigin(int viewId) => _webOnly();

/// Web-only; see `dom_probe_web.dart`.
List<Rect> overlayShieldViewportRects() => _webOnly();

/// Web-only; see `dom_probe_web.dart`.
({String Function() pointerEvents, void Function() remove}) addProbeEditor(
  String id,
  Rect viewportRect,
) => _webOnly();

/// Web-only; see `dom_probe_web.dart`.
void hoverOverlayShields() => _webOnly();
