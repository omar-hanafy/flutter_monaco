import 'dart:async';

import 'package:flutter_monaco/src/types/completion.dart';

/// A callback that provides completion items for a given
/// [CompletionRequest]. It should return a [Future] that resolves to a
/// [CompletionList].
typedef CompletionProvider = Future<CompletionList> Function(
  CompletionRequest request,
);

/// Handle for a completion provider registered through
/// `MonacoController.registerCompletions` or `registerStaticCompletions`.
///
/// Call [dispose] to remove the provider from the editor. Disposing more
/// than once is a no-op.
final class MonacoCompletionRegistration {
  /// Internal constructor; obtain instances from
  /// `MonacoController.registerCompletions`.
  MonacoCompletionRegistration.internal({
    required this.id,
    required this._unregister,
  });

  /// The provider id (also visible as [CompletionRequest.providerId]).
  final String id;

  final Future<void> Function() _unregister;
  bool _disposed = false;

  /// Whether [dispose] has been called.
  bool get isDisposed => _disposed;

  /// Removes the provider from the editor. Safe to call more than once.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _unregister();
  }
}
