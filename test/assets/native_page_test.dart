import 'dart:convert';

import 'package:flutter_monaco/src/assets/native_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/csp.dart';

void main() {
  group('monacoBridgeFingerprint', () {
    final base = {
      'core.js': utf8.encode('core'),
      'boot.js': utf8.encode('boot'),
    };

    test('is stable and order-independent', () {
      expect(
        monacoBridgeFingerprint(base),
        monacoBridgeFingerprint({
          'boot.js': utf8.encode('boot'),
          'core.js': utf8.encode('core'),
        }),
      );
    });

    test('changes with any file, name or presence', () {
      final fingerprint = monacoBridgeFingerprint(base);
      for (final changed in <Map<String, List<int>?>>[
        {...base, 'core.js': utf8.encode('core2')},
        {...base, 'core.js': null},
        {'core.js': utf8.encode('core'), 'lsp.js': utf8.encode('boot')},
        {...base, 'lsp.js': utf8.encode('')},
      ]) {
        expect(monacoBridgeFingerprint(changed), isNot(fingerprint));
      }
    });
  });

  group('buildVirtualHostMonacoPage', () {
    test('encodes path segments and fingerprints the page', () {
      final page = buildVirtualHostMonacoPage(
        versionDirectory: 'monaco-0.57.0',
        htmlFileName: 'monaco_abc.html',
        monacoVersion: '0.57.0',
        bridgeVersion: 'b1',
      );
      final url = Uri.parse(page.url);
      expect(url.scheme, 'https');
      expect(url.host, monacoVirtualHostName);
      expect(url.path, '/monaco-0.57.0/monaco_abc.html');
      expect(url.queryParameters['v'], matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(
        scriptUrlsIn(page.html),
        contains(
          'https://flutter-monaco.example/monaco-0.57.0/bridge/boot.js?v=b1',
        ),
      );

      final other = buildVirtualHostMonacoPage(
        versionDirectory: 'monaco-0.57.0',
        htmlFileName: 'monaco_abc.html',
        monacoVersion: '0.57.0',
        bridgeVersion: 'b2',
      );
      expect(other.url, isNot(page.url));
    });
  });

  group('connectSourcesNeedInsecurePage', () {
    test('insecure endpoints off loopback need a non-secure page', () {
      for (final sources in [
        ['ws://192.168.1.5:3000'],
        ['http://lsp.example.com/schema'],
        ['wss://ok.example', 'WS://LAN-HOST:9000'],
        ['ws:'],
        ['http:'],
        ['ws://*:3000'],
        // `connect-src *` admitted ws: to any host from the 3.x file: page.
        ['*'],
      ]) {
        expect(
          connectSourcesNeedInsecurePage(sources),
          isTrue,
          reason: '$sources',
        );
      }
    });

    test('secure and loopback endpoints work from an https page', () {
      for (final sources in [
        <String>[],
        ['wss://lsp.example.com', 'https://schemas.example'],
        ['ws://127.0.0.1:3000', 'ws://localhost:3000', 'ws://[::1]:3000'],
        ['ws://dev.localhost:8080', 'http://127.0.0.2/x'],
        ['wss:', 'https:', 'lsp.example.com', '*.example.com'],
      ]) {
        expect(
          connectSourcesNeedInsecurePage(sources),
          isFalse,
          reason: '$sources',
        );
      }
    });
  });

  group('buildFileMonacoPage', () {
    test('Android and Apple pages reference assets relative to the page', () {
      final page = buildFileMonacoPage(
        htmlFilePath: '/data/app/monaco-0.57.0/monaco_abc.html',
        monacoVersion: '0.57.0',
        isIosOrMacOS: true,
      );
      final scripts = scriptUrlsIn(page.html);
      expect(scripts, contains('min/vs/loader.js'));
      expect(scripts, contains('bridge/boot.js'));
      expect(page.html, contains('__FM_WORKERS'));
      expect(page.html, contains('platform: "apple"'));
      expect(page.url, 'file:///data/app/monaco-0.57.0/monaco_abc.html');
    });
  });
}
