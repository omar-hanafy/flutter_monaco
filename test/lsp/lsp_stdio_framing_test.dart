import 'dart:convert';

import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LspStdioMessageEncoder', () {
    test('frames a message with byte-accurate Content-Length', () {
      final bytes = LspStdioMessageEncoder.encode({'jsonrpc': '2.0', 'id': 1});
      final text = utf8.decode(bytes);
      final body = '{"jsonrpc":"2.0","id":1}';

      expect(text, 'Content-Length: ${body.length}\r\n\r\n$body');
    });

    test('uses UTF-8 byte length, not character count', () {
      final bytes = LspStdioMessageEncoder.encode({'text': 'héllo 🌍'});
      final headerEnd = utf8.decode(bytes).indexOf('\r\n\r\n');
      final header = utf8.decode(bytes.sublist(0, headerEnd));
      final declaredLength = int.parse(header.split(':')[1].trim());
      final bodyBytes = bytes.sublist(headerEnd + 4);

      expect(declaredLength, bodyBytes.length);
      expect(jsonDecode(utf8.decode(bodyBytes)), {'text': 'héllo 🌍'});
    });
  });

  group('LspStdioMessageDecoder', () {
    test('decodes a single complete frame', () {
      final decoder = LspStdioMessageDecoder();
      final messages = decoder.addBytes(
        LspStdioMessageEncoder.encode({'jsonrpc': '2.0', 'method': 'ping'}),
      );

      expect(messages, [
        {'jsonrpc': '2.0', 'method': 'ping'},
      ]);
      expect(decoder.pendingBytes, 0);
    });

    test('decodes messages split across arbitrary chunk boundaries', () {
      final decoder = LspStdioMessageDecoder();
      final frame = LspStdioMessageEncoder.encode({
        'jsonrpc': '2.0',
        'id': 42,
        'result': {'capabilities': <String, Object?>{}},
      });

      final collected = <Map<String, Object?>>[];
      // Feed one byte at a time - the cruelest possible chunking.
      for (final byte in frame) {
        collected.addAll(decoder.addBytes([byte]));
      }

      expect(collected, hasLength(1));
      expect(collected.single['id'], 42);
    });

    test('decodes multiple frames arriving in one chunk', () {
      final decoder = LspStdioMessageDecoder();
      final chunk = [
        ...LspStdioMessageEncoder.encode({'id': 1}),
        ...LspStdioMessageEncoder.encode({'id': 2}),
        ...LspStdioMessageEncoder.encode({'id': 3}),
      ];

      final messages = decoder.addBytes(chunk);
      expect(messages.map((m) => m['id']), [1, 2, 3]);
    });

    test('handles extra headers and case-insensitive Content-Length', () {
      final decoder = LspStdioMessageDecoder();
      final body = utf8.encode('{"ok":true}');
      final header = ascii.encode(
        'content-length: ${body.length}\r\n'
        'Content-Type: application/vscode-jsonrpc; charset=utf-8\r\n\r\n',
      );

      final messages = decoder.addBytes([...header, ...body]);
      expect(messages, [
        {'ok': true},
      ]);
    });

    test('decodes multi-byte UTF-8 bodies', () {
      final decoder = LspStdioMessageDecoder();
      final message = {'text': 'こんにちは 🎌', 'emoji': '🚀'};

      final result = decoder.addBytes(LspStdioMessageEncoder.encode(message));
      expect(result.single, message);
    });

    test('throws on a frame without Content-Length', () {
      final decoder = LspStdioMessageDecoder();
      expect(
        () => decoder.addBytes(
          ascii.encode('Content-Type: application/json\r\n\r\n{}'),
        ),
        throwsFormatException,
      );
    });

    test('throws on a body that is not valid JSON', () {
      final decoder = LspStdioMessageDecoder();
      expect(
        () => decoder.addBytes(ascii.encode('Content-Length: 5\r\n\r\nnope!')),
        throwsFormatException,
      );
    });

    test('skips non-object JSON frames instead of crashing', () {
      final decoder = LspStdioMessageDecoder();
      final chunk = [
        ...ascii.encode('Content-Length: 4\r\n\r\ntrue'),
        ...LspStdioMessageEncoder.encode({'id': 7}),
      ];

      final messages = decoder.addBytes(chunk);
      expect(messages, [
        {'id': 7},
      ]);
    });

    test('keeps buffering across calls until a frame completes', () {
      final decoder = LspStdioMessageDecoder();
      final frame = LspStdioMessageEncoder.encode({'id': 9});
      final split = frame.length ~/ 2;

      expect(decoder.addBytes(frame.sublist(0, split)), isEmpty);
      expect(decoder.pendingBytes, greaterThan(0));
      expect(decoder.addBytes(frame.sublist(split)).single['id'], 9);
      expect(decoder.pendingBytes, 0);
    });

    test('throws when the header never terminates within the cap', () {
      final decoder = LspStdioMessageDecoder(maxHeaderBytes: 64);

      expect(
        () => decoder.addBytes(List<int>.filled(65, 0x61)),
        throwsFormatException,
      );
    });

    test('throws on a Content-Length beyond the body cap', () {
      final decoder = LspStdioMessageDecoder(maxBodyBytes: 1024);
      final frame = utf8.encode('Content-Length: 4096\r\n\r\n');

      expect(() => decoder.addBytes(frame), throwsFormatException);
    });
  });
}
