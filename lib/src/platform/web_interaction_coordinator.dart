import 'dart:ui' show Rect;

import 'package:web/web.dart' as web;

/// Web-only coordinator for Monaco iframe pointer-event state.
///
/// Each registered iframe has a `baseEnabled` flag (controlled by
/// [`MonacoController.setInteractionEnabled`]) and a set of overlay locks
/// owned by [`MonacoOverlayBoundary`] instances. The iframe is interactive
/// only when both conditions hold:
///
/// ```
/// baseEnabled == true && locks.isEmpty
/// ```
///
/// This composes cleanly with [`MonacoFocusGuard`] (which manages the base
/// state for route overlays) and the new static-overlay shields. Releasing
/// a static overlay lock does not re-enable an iframe that a route observer
/// has disabled.
class MonacoWebInteractionCoordinator {
  MonacoWebInteractionCoordinator._();

  /// Process-wide singleton. The web platform controller registers each
  /// Monaco iframe here, and [`MonacoOverlayBoundary`] adds and removes
  /// pointer-event locks.
  static final MonacoWebInteractionCoordinator instance =
      MonacoWebInteractionCoordinator._();

  final Map<String, _EditorEntry> _editors = <String, _EditorEntry>{};
  final Map<String, Set<String>> _lockOwners = <String, Set<String>>{};

  /// Register or re-register an editor's iframe. Preserves any existing base
  /// state and locks if the same id is re-registered (defensive against hot
  /// reload).
  void registerEditor(String id, web.HTMLIFrameElement iframe) {
    final previous = _editors[id];

    _editors[id] = _EditorEntry(
      id: id,
      iframe: iframe,
      baseEnabled: previous?.baseEnabled ?? true,
      locks: previous?.locks ?? <String>{},
    );

    _apply(_editors[id]!);
  }

  /// Remove an editor and any locks pointing at it.
  void unregisterEditor(String id) {
    _editors.remove(id);

    for (final owner in List<String>.from(_lockOwners.keys)) {
      final lockedEditors = _lockOwners[owner]!;
      lockedEditors.remove(id);
      if (lockedEditors.isEmpty) {
        _lockOwners.remove(owner);
      }
    }
  }

  /// Sets the base interactive state for an editor. Called by
  /// [`MonacoController.setInteractionEnabled`].
  void setBaseEnabled(String id, bool enabled) {
    final entry = _editors[id];
    if (entry == null) return;

    entry.baseEnabled = enabled;
    _apply(entry);
  }

  /// Locks every iframe whose DOM rect intersects [rect]. Lock ownership is
  /// keyed by [owner]; calling this again with the same owner replaces the
  /// previous set of locked editors (so a moving overlay tracks correctly).
  void lockEditorsForRect(String owner, Rect rect) {
    if (rect.isEmpty || rect.width <= 0 || rect.height <= 0) {
      unlock(owner);
      return;
    }

    final nextEditors = <String>{};

    for (final entry in _editors.values) {
      if (!entry.iframe.isConnected) continue;

      final editorRect = _rectForElement(entry.iframe);
      if (editorRect.overlaps(rect)) {
        nextEditors.add(entry.id);
      }
    }

    final previousEditors = _lockOwners[owner] ?? <String>{};

    for (final id in previousEditors.difference(nextEditors)) {
      final entry = _editors[id];
      if (entry == null) continue;

      entry.locks.remove(owner);
      _apply(entry);
    }

    for (final id in nextEditors.difference(previousEditors)) {
      final entry = _editors[id];
      if (entry == null) continue;

      entry.locks.add(owner);
      _apply(entry);
    }

    if (nextEditors.isEmpty) {
      _lockOwners.remove(owner);
    } else {
      _lockOwners[owner] = nextEditors;
    }
  }

  /// Release any locks held by [owner].
  void unlock(String owner) {
    final editorIds = _lockOwners.remove(owner);
    if (editorIds == null) return;

    for (final id in editorIds) {
      final entry = _editors[id];
      if (entry == null) continue;

      entry.locks.remove(owner);
      _apply(entry);
    }
  }

  /// Release every overlay lock (does not touch base state).
  void releaseAllOverlayLocks() {
    for (final owner in List<String>.from(_lockOwners.keys)) {
      unlock(owner);
    }
  }

  Rect _rectForElement(web.Element element) {
    final rect = element.getBoundingClientRect();
    return Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height);
  }

  void _apply(_EditorEntry entry) {
    entry.iframe.style.pointerEvents = entry.baseEnabled && entry.locks.isEmpty
        ? 'auto'
        : 'none';
  }
}

class _EditorEntry {
  _EditorEntry({
    required this.id,
    required this.iframe,
    required this.baseEnabled,
    required this.locks,
  });

  final String id;
  final web.HTMLIFrameElement iframe;
  bool baseEnabled;
  final Set<String> locks;
}
