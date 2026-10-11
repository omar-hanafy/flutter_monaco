import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_monaco/src/lsp/lsp_stdio_framing.dart';
import 'package:flutter_monaco/src/lsp/lsp_transport.dart';

/// Spawns and manages a stdio language server process, exposing it as an
/// [LspBridgedTransport].
///
/// This is the recommended way to run a local language server on desktop:
/// no network port, no proxy, and no Content-Security-Policy changes -
/// JSON-RPC messages are framed onto the process's stdin/stdout and relayed
/// through the Flutter bridge.
///
/// ```dart
/// final server = await LspServerProcess.start(
///   'pyright-langserver', ['--stdio'],
/// );
/// final connection = await controller.connectLanguageServer(
///   id: 'pyright',
///   transport: server.transport,
/// );
/// // ... later:
/// await connection.disconnect(); // stops the process via transport.onClose
/// ```
///
/// ### Lifecycle
///
/// - The server's stdout is decoded with LSP `Content-Length` framing and
///   streamed to the editor; stderr lines go to the `onStderr` callback of
///   [start] (default: `debugPrint`).
/// - When the connection is disconnected or the controller is disposed, the
///   transport's `onClose` runs [stop] automatically.
/// - If the process dies on its own, the message stream ends and the
///   connection ends: a clean exit (code 0) transitions it to `closed`; any
///   other exit code first emits a [ProcessException] (its `errorCode` is the
///   exit code and its message carries the last stderr lines), so the
///   connection becomes `failed` with that error. When this happens during
///   the LSP `initialize` handshake, `connectLanguageServer` throws that
///   [ProcessException] right away instead of waiting for its timeout.
///   Observe `LanguageServerConnection.whenClosed` or [exitCode] to react
///   (e.g. respawn and reconnect).
/// - stderr is decoded as UTF-8 leniently: malformed bytes (for example
///   code-page output) become U+FFFD.
///
/// ### Platform support
///
/// Desktop (macOS, Windows, Linux hosts running Flutter desktop apps that
/// embed this package's editor on a supported platform). On Android and iOS
/// spawning arbitrary executables is generally impossible; on the web this
/// class is a stub that throws [UnsupportedError].
///
/// **macOS App Sandbox:** a sandboxed app cannot spawn external binaries -
/// `start` fails with `ProcessException: Operation not permitted`. Either
/// disable `com.apple.security.app-sandbox` in your entitlements (fine for
/// apps distributed outside the App Store) or bundle the server inside the
/// app with inherit entitlements.
class LspServerProcess {
  LspServerProcess._(
    this._process, {
    required this._executable,
    required List<String> arguments,
    required void Function(String line) onStderr,
  }) : _arguments = List.unmodifiable(arguments) {
    // A dead process makes stdin writes fail asynchronously; observing the
    // future keeps that from surfacing as an unhandled async error during
    // hot-reload-heavy dev loops.
    unawaited(_process.stdin.done.then((_) {}, onError: (_) {}));

    _stdoutSubscription = _process.stdout.listen(
      (chunk) {
        try {
          for (final message in _decoder.addBytes(chunk)) {
            if (!_fromServer.isClosed) _fromServer.add(message);
          }
        } catch (error, stackTrace) {
          if (!_fromServer.isClosed) _fromServer.addError(error, stackTrace);
        }
      },
      onDone: () => unawaited(_handleStdoutDone()),
      onError: (Object error, StackTrace stackTrace) {
        if (!_fromServer.isClosed) _fromServer.addError(error, stackTrace);
      },
      cancelOnError: false,
    );

    // Servers print whatever their platform encoding produces (a Windows
    // server may emit code-page text), so decode leniently: a malformed
    // byte becomes U+FFFD instead of an uncaught FormatException.
    _stderrSubscription = _process.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(
          (line) {
            _recordStderr(line);
            try {
              onStderr(line);
            } catch (error) {
              debugPrint('[LspServerProcess] onStderr threw: $error');
            }
          },
          onError: (Object error) {
            debugPrint(
              '[LspServerProcess] Failed to read server stderr: $error',
            );
          },
          onDone: () {
            if (!_stderrDone.isCompleted) _stderrDone.complete();
          },
        );

    transport = LspBridgedTransport(
      fromServer: _fromServer.stream,
      toServer: _write,
      onClose: () => stop(),
    );
  }

  /// Starts `executable` with [arguments] and wires its stdio for LSP.
  ///
  /// Parameters mirror `Process.start`. Throws a [ProcessException] when the
  /// executable cannot be spawned.
  static Future<LspServerProcess> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    void Function(String line)? onStderr,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
    );
    return LspServerProcess._(
      process,
      executable: executable,
      arguments: arguments,
      onStderr:
          onStderr ?? ((line) => debugPrint('[LSP $executable stderr] $line')),
    );
  }

  /// How many trailing stderr lines an unexpected-exit error carries.
  static const int _stderrTailLines = 20;

  /// Upper bound for the stderr tail, in UTF-16 code units.
  static const int _stderrTailChars = 4000;

  /// How long to wait for the exit code once stdout closed on its own.
  static const Duration _exitCodeGrace = Duration(seconds: 2);

  /// How long to let stderr drain after the process exited.
  static const Duration _stderrGrace = Duration(milliseconds: 250);

  final Process _process;
  final String _executable;
  final List<String> _arguments;
  final List<String> _stderrTail = <String>[];
  final Completer<void> _stderrDone = Completer<void>();
  final LspStdioMessageDecoder _decoder = LspStdioMessageDecoder();
  final StreamController<Map<String, Object?>> _fromServer =
      StreamController<Map<String, Object?>>();
  late final StreamSubscription<List<int>> _stdoutSubscription;
  late final StreamSubscription<String> _stderrSubscription;
  bool _stopped = false;

  /// The transport to pass to `MonacoController.connectLanguageServer`.
  ///
  /// Single-use: one transport connects one editor once. To reconnect after
  /// a crash, start a new [LspServerProcess].
  late final LspBridgedTransport transport;

  /// The underlying process, for advanced integrations.
  Process get process => _process;

  /// The process id.
  int get pid => _process.pid;

  /// Completes with the server's exit code once it terminates.
  Future<int> get exitCode => _process.exitCode;

  /// Whether [stop] has been called.
  bool get isStopped => _stopped;

  void _write(Map<String, Object?> message) {
    if (_stopped) return;
    try {
      _process.stdin.add(LspStdioMessageEncoder.encode(message));
    } catch (error) {
      debugPrint('[LspServerProcess] Failed to write to server stdin: $error');
    }
  }

  /// Stops the language server, escalating gracefully:
  ///
  /// 1. Close stdin (most stdio servers exit on EOF) and wait
  ///    [terminateTimeout] for the process to exit.
  /// 2. Send SIGTERM and wait [killTimeout].
  /// 3. Send SIGKILL and wait for exit.
  ///
  /// Closing stdin is not awaited on its own: a server that stopped reading
  /// leaves buffered writes unflushed forever, and the escalation must still
  /// run. The returned future therefore always completes, after roughly
  /// [terminateTimeout] + [killTimeout] at most for an unresponsive server.
  ///
  /// Returns the process exit code. Safe to call multiple times.
  Future<int> stop({
    Duration terminateTimeout = const Duration(seconds: 3),
    Duration killTimeout = const Duration(seconds: 2),
  }) async {
    if (_stopped) return _process.exitCode;
    _stopped = true;

    // Start the EOF but do not wait for the flush; the timed exit wait
    // below covers both a draining and a stuck server.
    try {
      unawaited(_process.stdin.close().then((_) {}, onError: (_) {}));
    } catch (_) {}

    var code = await _waitForExit(terminateTimeout);
    if (code == null) {
      _process.kill();
      code = await _waitForExit(killTimeout);
    }
    if (code == null) {
      _process.kill(ProcessSignal.sigkill);
      code = await _process.exitCode;
    }

    await _stdoutSubscription.cancel();
    await _stderrSubscription.cancel();
    if (!_fromServer.isClosed) {
      unawaited(_fromServer.close());
    }
    return code;
  }

  /// Stdout ended without [stop]: the server exited (or closed its output).
  ///
  /// A non-zero exit is surfaced as a [ProcessException] on the message
  /// stream - carrying the exit code and the stderr tail - so a connection
  /// fails with the real cause (for example a server started with wrong
  /// arguments). A clean exit just closes the stream.
  Future<void> _handleStdoutDone() async {
    if (!_stopped) {
      int? code;
      try {
        code = await _process.exitCode.timeout(_exitCodeGrace);
      } on TimeoutException {
        // Stdout closed but the process lives on; report a plain close.
      }
      if (code != null && code != 0 && !_stopped) {
        try {
          await _stderrDone.future.timeout(_stderrGrace);
        } on TimeoutException {
          // A grandchild may hold stderr open; use what arrived.
        }
        if (!_fromServer.isClosed) {
          _fromServer.addError(
            ProcessException(
              _executable,
              _arguments,
              _unexpectedExitMessage(code),
              code,
            ),
          );
        }
      }
    }
    if (!_fromServer.isClosed) unawaited(_fromServer.close());
  }

  String _unexpectedExitMessage(int code) {
    final buffer = StringBuffer(
      'Language server process exited with code $code before it was stopped.',
    );
    if (_stderrTail.isNotEmpty) {
      buffer
        ..write(' Last stderr output:\n')
        ..write(_stderrTail.join('\n'));
    }
    return buffer.toString();
  }

  void _recordStderr(String line) {
    _stderrTail.add(
      line.length > _stderrTailChars
          ? line.substring(line.length - _stderrTailChars)
          : line,
    );
    var total = _stderrTail.fold<int>(0, (sum, l) => sum + l.length);
    while (_stderrTail.length > _stderrTailLines ||
        (_stderrTail.length > 1 && total > _stderrTailChars)) {
      total -= _stderrTail.removeAt(0).length;
    }
  }

  Future<int?> _waitForExit(Duration timeout) {
    return _process.exitCode
        .then<int?>((code) => code)
        .timeout(timeout, onTimeout: () => null);
  }
}
