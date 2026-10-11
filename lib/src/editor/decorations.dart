import 'package:flutter_monaco/src/types/decorations.dart';

/// Internal command dispatcher a decoration set rides. Wired to the
/// controller's readiness-gated invoke.
typedef MonacoDecorationInvoke = Future<Object?> Function(
  String method,
  Map<String, Object?> params,
);

/// An independent group of editor decorations.
///
/// Created with `MonacoController.createDecorationSet`. Each set wraps one
/// Monaco `createDecorationsCollection`: [set] atomically replaces only
/// this set's decorations, so multiple features (search highlights,
/// diagnostics underlines, blame gutter, ...) can decorate the same editor
/// without clobbering each other - the 2.x global `deltaDecorations` id
/// bookkeeping is gone.
final class MonacoDecorationSet {
  /// Internal: construct via MonacoController.
  MonacoDecorationSet.internal(this._invoke, this.id);

  final MonacoDecorationInvoke _invoke;

  /// The page-side set identifier.
  final String id;

  bool _disposed = false;

  /// Whether [dispose] ran; a disposed set rejects further calls.
  bool get isDisposed => _disposed;

  /// Replaces this set's decorations with [decorations].
  Future<void> set(List<DecorationOptions> decorations) async {
    _checkNotDisposed();
    await _invoke('decorations.set', {
      'setId': id,
      'decorations': decorations.map((d) => d.toJson()).toList(),
    });
  }

  /// Removes all of this set's decorations (the set stays usable).
  Future<void> clear() async {
    _checkNotDisposed();
    await _invoke('decorations.clear', {'setId': id});
  }

  /// Removes all decorations and releases the page-side collection.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _invoke('decorations.dispose', {'setId': id});
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('MonacoDecorationSet($id) has been disposed.');
    }
  }

  @override
  String toString() => 'MonacoDecorationSet($id)';
}
