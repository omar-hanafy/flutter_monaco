import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bridge_sources.dart';
import '../helpers/generate_index_html.dart';

void main() {
  group('LSP bridge assets', () {
    test(
      'bundled Monaco version is 0.57.0 (monaco.lsp first shipped in 0.55)',
      () {
        expect(MonacoAssets.monacoVersion, '0.57.0');
      },
    );

    test('generated html references the LSP bridge script', () {
      final html = generateIndexHtml('min/vs');
      expect(html, contains('lsp.js'));
    });

    test('installs the flutterMonaco.lsp namespace', () {
      final lsp = bridgeSource('lsp.js');

      expect(lsp, contains('window.flutterMonaco.lsp'));
      expect(lsp, contains('deliverServerMessage'));
      expect(lsp, contains('disconnectAll'));
      expect(lsp, contains('monaco.lsp.MonacoLspClient'));
      expect(lsp, contains('monaco.lsp.WebSocketTransport.connectTo'));
    });

    test('acknowledges optional server refresh requests', () {
      final lsp = bridgeSource('lsp.js');

      // Monaco (0.55 through 0.57) answers these with method-not-found, which kills
      // servers like pyright via an unhandled rejection; the bridge must
      // register benign handlers instead.
      expect(lsp, contains('workspace/diagnostic/refresh'));
      expect(lsp, contains('workspace/semanticTokens/refresh'));
      expect(lsp, contains('workspace/codeLens/refresh'));
      expect(lsp, contains('registerBenignRefreshHandlers'));
    });

    test('installs the protocol v3 dispatcher', () {
      final core = bridgeSource('core.js');

      expect(core, contains('window.FlutterMonaco'));
      expect(core, contains('PROTOCOL_VERSION = 3'));
      expect(core, contains('dispatch:'));
      expect(core, contains("kind: 'response'"));
    });

    test('registers the lsp commands on the v3 wire', () {
      final lsp = bridgeSource('lsp.js');

      for (final method in [
        'lsp.connect',
        'lsp.disconnect',
        'lsp.disconnectAll',
        'lsp.deliverServerMessage',
        'lsp.sendRequest',
        'lsp.sendNotification',
        'lsp.listConnections',
      ]) {
        expect(
          lsp,
          contains("FM.register('$method'"),
          reason: 'missing v3 registration for $method',
        );
      }
    });

    test('prefers monaco.json with a legacy namespace fallback', () {
      final api = bridgeSource('editor-api.js');

      expect(api, contains("typeof monaco.json !== 'undefined'"));
      expect(api, contains('monaco.languages && monaco.languages.json'));
    });

    test('default CSP stays locked down', () {
      final html = generateIndexHtml('min/vs');

      expect(html, contains("connect-src 'self' blob:;"));
      expect(html, isNot(contains('ws://')));
    });

    test('allowedConnectSources extends connect-src only', () {
      final html = generateIndexHtml(
        'min/vs',
        allowedConnectSources: ['ws://127.0.0.1:3000', 'wss://lsp.example.com'],
      );

      expect(
        html,
        contains(
          "connect-src 'self' blob: ws://127.0.0.1:3000 wss://lsp.example.com;",
        ),
      );
      // The other directives must not gain the new sources.
      expect(html, isNot(contains("script-src 'self' file: ws://")));
    });

    test('rejects CSP source expressions that could inject directives', () {
      for (final malicious in [
        "ws://x; script-src 'unsafe-eval'",
        'ws://x"',
        "ws://x'",
        'ws://a b',
        'ws://x<script>',
      ]) {
        expect(
          () => generateIndexHtml('min/vs', allowedConnectSources: [malicious]),
          throwsArgumentError,
          reason: 'should reject: $malicious',
        );
      }
    });

    test('ignores blank entries in allowedConnectSources', () {
      final html = generateIndexHtml(
        'min/vs',
        allowedConnectSources: ['', '  '],
      );
      expect(html, contains("connect-src 'self' blob:;"));
    });
  });
}
