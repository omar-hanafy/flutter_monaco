@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // `cat` echoes stdin to stdout, which makes it a perfect loopback "server"
  // for exercising framing, the transport pump, and process lifecycle.
  final hasCat = !Platform.isWindows;

  group('LspServerProcess', () {
    test('round-trips framed messages through a real process', () async {
      if (!hasCat) return markTestSkipped('requires a POSIX cat binary');
      final server = await LspServerProcess.start('cat', []);
      addTearDown(server.stop);

      final received = <Map<String, Object?>>[];
      final sub = server.transport.fromServer.listen(received.add);
      addTearDown(sub.cancel);

      server.transport.toServer({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {'processId': null},
      });
      server.transport.toServer({
        'jsonrpc': '2.0',
        'method': 'initialized',
        'params': <String, Object?>{},
      });

      await _poll(() => received.length == 2);
      expect(received[0]['method'], 'initialize');
      expect(received[1]['method'], 'initialized');
    });

    test('stop() closes stdin and reaps the process', () async {
      if (!hasCat) return markTestSkipped('requires a POSIX cat binary');
      final server = await LspServerProcess.start('cat', []);
      expect(server.isStopped, isFalse);

      final code = await server.stop();
      expect(code, 0); // cat exits cleanly on stdin EOF
      expect(server.isStopped, isTrue);

      // Idempotent.
      expect(await server.stop(), 0);
    });

    test('fromServer closes when the process exits', () async {
      if (!hasCat) return markTestSkipped('requires a POSIX cat binary');
      final server = await LspServerProcess.start('cat', []);

      final done = Completer<void>();
      server.transport.fromServer.listen((_) {}, onDone: done.complete);

      await server.stop();
      await done.future.timeout(const Duration(seconds: 5));
    });

    test('stop() escalates when the server stopped reading stdin', () async {
      if (!hasCat) return markTestSkipped('requires POSIX sleep');
      // `sleep` never reads stdin, so ~1.6 MB of framed traffic fills the
      // pipe buffer and leaves stdin.close() waiting for a flush that never
      // happens. stop() must still escalate to SIGTERM/SIGKILL.
      final server = await LspServerProcess.start('sleep', ['30']);
      addTearDown(() => Process.killPid(server.pid, ProcessSignal.sigkill));
      final payload = 'x' * 4096;
      for (var i = 0; i < 400; i++) {
        server.transport.toServer({
          'jsonrpc': '2.0',
          'method': 'textDocument/didChange',
          'params': payload,
        });
      }

      final code = await server
          .stop(
            terminateTimeout: const Duration(milliseconds: 200),
            killTimeout: const Duration(milliseconds: 200),
          )
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => fail('stop() never escalated past stdin.close()'),
          );
      expect(code, isNot(0), reason: 'the server was terminated by a signal');
      expect(await server.exitCode, code);
    });

    test('malformed UTF-8 on stderr is decoded, not thrown', () async {
      if (!hasCat) return markTestSkipped('requires a POSIX sh binary');
      final lines = <String>[];
      final uncaught = <Object>[];
      await runZonedGuarded(() async {
        final server = await LspServerProcess.start('sh', [
          '-c',
          r"printf '\377\376 code-page text\n' >&2; sleep 0.3",
        ], onStderr: lines.add);
        await server.exitCode;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await server.stop();
      }, (error, _) => uncaught.add(error));

      expect(uncaught, isEmpty);
      expect(lines, hasLength(1));
      expect(lines.single, contains('�'));
      expect(lines.single, contains('code-page text'));
    });

    test('an unexpected non-zero exit errors the message stream with the '
        'exit code and stderr tail', () async {
      if (!hasCat) return markTestSkipped('requires a POSIX sh binary');
      final server = await LspServerProcess.start('sh', [
        '-c',
        'echo "unknown option --stdoi" >&2; exit 3',
      ], onStderr: (_) {});
      addTearDown(server.stop);

      final errors = <Object>[];
      final done = Completer<void>();
      server.transport.fromServer.listen(
        (_) {},
        onError: errors.add,
        onDone: done.complete,
      );
      await done.future.timeout(const Duration(seconds: 5));

      expect(errors, [
        isA<ProcessException>()
            .having((e) => e.errorCode, 'errorCode', 3)
            .having((e) => e.executable, 'executable', 'sh')
            .having((e) => e.message, 'message', contains('exited with code 3'))
            .having(
              (e) => e.message,
              'message',
              contains('unknown option --stdoi'),
            ),
      ]);
    });

    test('a clean exit closes the message stream without an error', () async {
      if (!hasCat) return markTestSkipped('requires a POSIX sh binary');
      final server = await LspServerProcess.start('sh', ['-c', 'exit 0']);
      addTearDown(server.stop);

      final errors = <Object>[];
      final done = Completer<void>();
      server.transport.fromServer.listen(
        (_) {},
        onError: errors.add,
        onDone: done.complete,
      );
      await done.future.timeout(const Duration(seconds: 5));
      expect(errors, isEmpty);
    });

    test('start() surfaces spawn failures', () async {
      expect(
        () => LspServerProcess.start(
          'definitely-not-a-real-language-server-binary',
          [],
        ),
        throwsA(isA<ProcessException>()),
      );
    });
  });
}

Future<void> _poll(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
