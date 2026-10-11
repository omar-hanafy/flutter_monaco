import 'dart:convert';

import 'package:flutter_monaco/src/assets/html_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/csp.dart';

String _build({
  String? customCss,
  String? messageToken,
  bool isWeb = false,
  String vsPath = 'monaco/min/vs',
  String bridgeBase = 'bridge',
}) {
  return buildMonacoIndexHtml(
    vsPath: vsPath,
    bridgeBase: bridgeBase,
    monacoVersion: '0.57.0',
    isWeb: isWeb,
    messageToken: messageToken,
    customCss: customCss,
  );
}

void main() {
  group('buildMonacoIndexHtml', () {
    test('customCss cannot break out of its style element', () {
      final html = _build(
        customCss: '.a { color: red } </style><script>alert(1)</script>',
      );

      // The literal close sequence must not survive inside the custom
      // block: an early "</style" would end the element and promote the
      // rest to markup (script injection). An escaped form must remain.
      expect(html, isNot(contains('</style><script>')));
      expect(html, isNot(contains('alert(1)</script>')));
      expect(html, contains(r'<\/style><script>alert(1)<\/script>'));
    });

    test('ordinary customCss passes through', () {
      final html = _build(customCss: '.margin { color: rgb(1, 2, 3); }');
      expect(html, contains('.margin { color: rgb(1, 2, 3); }'));
    });

    group('page CSP', () {
      // The page is served from a blob: URL on web, and Firefox does not
      // resolve 'self' to the creating document's origin there - every
      // same-origin fetch (loader.js, the bridge, editor.main.css, the
      // workers) is blocked while Chrome allows it. These tests hold the
      // page to the invariant that removes the whole class: the policy must
      // admit what the page fetches WITHOUT relying on 'self'.
      const vsOrigin = 'https://app.example';
      const bridgeOrigin = 'https://bridge.example';

      String buildWeb() => _build(
        isWeb: true,
        vsPath: '$vsOrigin/assets/monaco/min/vs',
        bridgeBase: '$bridgeOrigin/assets/monaco/bridge',
      );

      test('every fetch directive admits the Monaco origin without self', () {
        final csp = PageCsp.fromHtml(buildWeb());
        // A representative subresource: the page hands Monaco a base path
        // and the bundle fetches scripts, stylesheets and workers beneath
        // it, so the whole origin has to be admitted everywhere.
        const asset = '$vsOrigin/assets/monaco/min/vs/editor/editor.main.js';

        expect(csp.fetchDirectives, isNotEmpty);
        for (final directive in csp.fetchDirectives) {
          expect(
            csp.admitsWithoutSelf(directive, asset),
            isTrue,
            reason: '$directive does not admit $asset',
          );
        }
      });

      test('the bridge origin is admitted even when it differs from vs', () {
        // vsPath and bridgeBase are resolved by separate functions on web
        // (webview_web.dart) and agree only by convention. A policy derived
        // from one of them silently leaves the other unadmitted.
        final csp = PageCsp.fromHtml(buildWeb());
        expect(
          csp.admitsWithoutSelf(
            'script-src',
            '$bridgeOrigin/assets/monaco/bridge/boot.js',
          ),
          isTrue,
        );
      });

      test('every script the page references is admitted without self', () {
        final html = buildWeb();
        final csp = PageCsp.fromHtml(html);
        final urls = scriptUrlsIn(html);

        expect(urls, contains('$vsOrigin/assets/monaco/min/vs/loader.js'));
        for (final name in monacoBridgeScripts) {
          expect(urls, contains('$bridgeOrigin/assets/monaco/bridge/$name'));
        }
        for (final url in urls) {
          expect(
            csp.admitsWithoutSelf('script-src', url),
            isTrue,
            reason: 'script-src does not admit $url',
          );
        }
      });

      test('credentials in an asset URL never reach the policy', () {
        // Uri.authority would emit `https://user:pass@app.example`, which is
        // not a valid CSP host-source: browsers discard the expression and
        // the block returns with no signal.
        final csp = PageCsp.fromHtml(
          _build(
            isWeb: true,
            vsPath: 'https://user:pass@app.example/assets/monaco/min/vs',
            bridgeBase: 'https://user:pass@app.example/assets/monaco/bridge',
          ),
        );

        expect(csp.directives['script-src'], contains(vsOrigin));
        for (final sources in csp.directives.values) {
          expect(sources.join(' '), isNot(contains('@')));
          expect(sources.join(' '), isNot(contains('pass')));
        }
      });

      test('native asset paths leave the policy byte-identical', () {
        // Native is served from file:// and its 'self'/file: behaviour comes
        // from the host WebView, which this package does not control. Web
        // work must not perturb it, so the generated policy is pinned.
        const expected =
            "default-src 'self' file: 'unsafe-inline' 'unsafe-eval'; "
            "script-src 'self' file: 'unsafe-inline' 'unsafe-eval'; "
            "style-src 'self' 'unsafe-inline'; "
            "font-src 'self' file: data:; "
            "img-src 'self' data: blob: file:; "
            "worker-src 'self' blob:; "
            "connect-src 'self' blob:;";

        for (final vsPath in ['monaco/min/vs', 'file:///C:/app/min/vs']) {
          final html = _build(vsPath: vsPath, bridgeBase: 'bridge');
          expect(html, contains('content="$expected"'), reason: vsPath);
        }
      });
    });

    test('the web message token is JSON-encoded in every interpolation', () {
      const token = r"tok'; window.pwned = true; '";
      final html = _build(isWeb: true, messageToken: token);

      // A raw single-quoted interpolation would let a token containing a
      // quote terminate the string literal and run code; both sites must
      // emit a JSON-encoded literal instead.
      expect(
        html,
        contains('window.flutterMonacoToken = ${jsonEncode(token)};'),
      );
      expect(html, isNot(contains("window.flutterMonacoToken = 'tok';")));
    });
  });
}
