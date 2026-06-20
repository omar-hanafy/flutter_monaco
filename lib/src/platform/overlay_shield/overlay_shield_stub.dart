import 'dart:ui' show Rect;

/// Native and unsupported-platform no-op shield.
///
/// All methods are inert. [`MonacoOverlayBoundary`] checks [`isSupported`] and
/// avoids construction on non-web platforms, but this stub remains as a safety
/// net so accidental construction does nothing.
class MonacoOverlayDomShield {
  /// `false` on this platform - the shield is web-only.
  static const bool isSupported = false;

  /// No-op constructor. Construction is permitted so callers can share the
  /// same code path on web and native, but no DOM work happens.
  MonacoOverlayDomShield({required int flutterViewId, required bool debug});

  /// Update the shield's tracked rect. No-op on native.
  void update(Rect rect) {}

  /// Release any resources. No-op on native.
  void dispose() {}
}
