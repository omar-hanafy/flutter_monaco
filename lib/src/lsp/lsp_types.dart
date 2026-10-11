import 'package:flutter/foundation.dart';

/// Lifecycle phase of a language server connection.
enum LspConnectionStatus {
  /// The transport is being established and the LSP `initialize` handshake
  /// is in flight. Also the state while a reconnect attempt runs.
  connecting,

  /// The handshake completed; Monaco's LSP client is live and language
  /// features are active in the editor.
  open,

  /// The connection ended - either explicitly via `disconnect()` or because
  /// the transport closed and no (further) reconnect was attempted.
  closed,

  /// The connection ended with an error and will not recover (initial
  /// connect failed after being surfaced, every reconnect attempt was
  /// exhausted, the transport reported an error, or the editor page
  /// reloaded - then [LspConnectionState.error] is a
  /// `MonacoPageReloadedError`).
  failed,
}

/// Immutable snapshot of a language server connection's state.
@immutable
class LspConnectionState {
  /// Creates a connection state snapshot.
  const LspConnectionState({
    required this.status,
    this.error,
    this.reconnectAttempt = 0,
  });

  /// The current lifecycle phase.
  final LspConnectionStatus status;

  /// The error that caused a `closed`/`failed` transition, if any.
  final Object? error;

  /// Which reconnect attempt produced this state; `0` for the initial
  /// connection.
  final int reconnectAttempt;

  /// Whether the connection is currently serving language features.
  bool get isOpen => status == LspConnectionStatus.open;

  /// Whether the connection has permanently ended.
  bool get isFinal =>
      status == LspConnectionStatus.closed ||
      status == LspConnectionStatus.failed;

  @override
  bool operator ==(Object other) {
    return other is LspConnectionState &&
        other.status == status &&
        other.error == error &&
        other.reconnectAttempt == reconnectAttempt;
  }

  @override
  int get hashCode => Object.hash(status, error, reconnectAttempt);

  @override
  String toString() =>
      'LspConnectionState(${status.name}'
      '${reconnectAttempt > 0 ? ', attempt: $reconnectAttempt' : ''}'
      '${error != null ? ', error: $error' : ''})';
}

/// Controls whether and how a language server connection reconnects after
/// its transport drops unexpectedly.
///
/// Reconnects only apply to drops that happen *after* the connection was
/// open: the initial `connectLanguageServer` call always throws on failure.
/// An explicit `disconnect()` never triggers a reconnect, and neither does
/// an editor page reload: the reload discards the in-page client, the
/// connection fails with `MonacoPageReloadedError`, and the application
/// reconnects from `MonacoController.onPageReloaded` once its documents are
/// restored.
///
/// Not supported for `LspBridgedTransport` (its message stream is single-use;
/// respawn the server and reconnect from app code instead).
@immutable
class LspReconnectPolicy {
  /// Never reconnect. Unexpected transport drops transition the connection
  /// straight to [LspConnectionStatus.closed].
  const LspReconnectPolicy.none()
    : maxAttempts = 0,
      initialDelay = Duration.zero,
      maxDelay = Duration.zero,
      backoffMultiplier = 1;

  /// Reconnect with exponential backoff: the first attempt waits
  /// [initialDelay], each subsequent attempt multiplies the wait by
  /// [backoffMultiplier] up to [maxDelay]. After [maxAttempts] consecutive
  /// failures the connection transitions to [LspConnectionStatus.failed].
  ///
  /// A successful reconnect resets the attempt counter.
  const LspReconnectPolicy.exponentialBackoff({
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.maxAttempts = 5,
    this.backoffMultiplier = 2,
  }) : assert(maxAttempts > 0, 'maxAttempts must be positive'),
       assert(backoffMultiplier >= 1, 'backoffMultiplier must be >= 1');

  /// Maximum number of consecutive reconnect attempts; `0` disables
  /// reconnecting.
  final int maxAttempts;

  /// Delay before the first reconnect attempt.
  final Duration initialDelay;

  /// Upper bound for the backoff delay.
  final Duration maxDelay;

  /// Factor applied to the delay after each failed attempt.
  final int backoffMultiplier;

  /// Whether this policy performs any reconnects.
  bool get enabled => maxAttempts > 0;

  /// The delay to wait before reconnect [attempt] (1-based).
  Duration delayFor(int attempt) {
    assert(attempt >= 1, 'attempt is 1-based');
    var delay = initialDelay;
    for (var i = 1; i < attempt; i++) {
      delay *= backoffMultiplier;
      if (delay >= maxDelay) return maxDelay;
    }
    return delay > maxDelay ? maxDelay : delay;
  }

  @override
  bool operator ==(Object other) {
    return other is LspReconnectPolicy &&
        other.maxAttempts == maxAttempts &&
        other.initialDelay == initialDelay &&
        other.maxDelay == maxDelay &&
        other.backoffMultiplier == backoffMultiplier;
  }

  @override
  int get hashCode =>
      Object.hash(maxAttempts, initialDelay, maxDelay, backoffMultiplier);

  @override
  String toString() => enabled
      ? 'LspReconnectPolicy.exponentialBackoff(maxAttempts: $maxAttempts)'
      : 'LspReconnectPolicy.none()';
}
