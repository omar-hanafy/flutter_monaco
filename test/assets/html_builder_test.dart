import 'dart:convert';
import 'dart:io';

import 'package:flutter_monaco/src/assets/html_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../helpers/csp.dart';
import '../helpers/page_scripts.dart';

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

  group('asset paths reach the page intact', () {
    // Uri.file leaves an apostrophe unescaped, so a Windows profile such as
    // O'Brien, or an app named "Bob's Editor", puts one in every asset URL.
    // Pasted into a single-quoted JavaScript literal it ended the string:
    // the require config became a SyntaxError and the editor never loaded.
    const windowsDir =
        r"C:\Users\O'Brien\AppData\Roaming\Bob's Tools\Bob's Editor"
        r'\monaco_editor_cache\monaco-0.57.0';
    final cases = <String, ({String vsPath, String bridgeBase, bool isWeb})>{
      'Windows file page': (
        vsPath: Uri.file('$windowsDir\\min\\vs', windows: true).toString(),
        bridgeBase: Uri.file('$windowsDir\\bridge', windows: true).toString(),
        isWeb: false,
      ),
      'web page': (
        vsPath: "https://app.example/Bob's/assets/monaco/min/vs",
        bridgeBase: "https://app.example/Bob's/assets/monaco/bridge",
        isWeb: true,
      ),
      'path that tries to close the script element': (
        vsPath: 'file:///C:/x/</script><script>alert(1)//"\'/min/vs',
        bridgeBase: 'file:///C:/x/bridge',
        isWeb: false,
      ),
    };

    cases.forEach((name, paths) {
      String build() => buildMonacoIndexHtml(
        vsPath: paths.vsPath,
        bridgeBase: paths.bridgeBase,
        monacoVersion: '0.57.0',
        isWindows: !paths.isWeb,
        isWeb: paths.isWeb,
        messageToken: paths.isWeb ? 'token' : null,
      );

      test('$name: every inline script parses', () async {
        final html = build();
        expect(html, contains('var require'));
        expect(await jsSyntaxErrors(inlineScriptsIn(html)), isEmpty);
      }, skip: nodeUnavailableReason);

      test('$name: Monaco is configured with the exact vs path', () async {
        final requireScript = inlineScriptsIn(build())
            .singleWhere((script) => script.contains('var require'));
        expect(
          await evaluateInNode(requireScript, 'require.paths.vs'),
          paths.vsPath,
        );
      }, skip: nodeUnavailableReason);

      test('$name: script elements load the exact asset URLs', () {
        final urls = scriptUrlsIn(build());
        expect(urls, contains('${paths.vsPath}/loader.js'));
        for (final script in monacoBridgeScripts) {
          expect(urls, contains('${paths.bridgeBase}/$script'));
        }
      });
    });
  });

  group('allowedConnectSources', () {
    test('character references cannot smuggle a directive into the CSP', () {
      // The attribute decodes &#32; to a space and &#59; to ";", so this
      // entry used to widen connect-src to * and append frame-src *.
      expect(
        () =>
            sanitizeConnectSources(['wss://a.example&#32*&#59frame-src&#32*']),
        throwsArgumentError,
      );
    });

    test('only CSP source expressions are accepted', () {
      for (final invalid in [
        'wss://a.example&amp;',
        'wss://a.example/#fragment',
        'wss://a.example/?query=1',
        'ws://a.example,ws://b.example',
        r'ws://a\b',
        'wss://a.example/%ZZ',
        'wss://a.example:80a',
        "'self'",
        'wss://',
      ]) {
        expect(
          () => sanitizeConnectSources([invalid]),
          throwsArgumentError,
          reason: 'should reject: $invalid',
        );
      }
    });

    test('valid scheme and host sources are kept verbatim', () {
      const valid = [
        '*',
        'https:',
        'wss:',
        'ws://127.0.0.1:3000',
        'wss://lsp.example.com',
        'wss://*.example.com',
        'https://example.com:*',
        'https://example.com/lsp/',
        'https://example.com/a%20b',
        'lsp.example.com',
        'ws://[::1]:8080',
      ];
      expect(sanitizeConnectSources(valid), valid);

      final csp = PageCsp.fromHtml(
        buildMonacoIndexHtml(
          vsPath: 'min/vs',
          bridgeBase: 'bridge',
          monacoVersion: '0.57.0',
          allowedConnectSources: valid,
        ),
      );
      expect(csp.directives['connect-src'], containsAllInOrder(valid));
    });
  });

  group('WebView2 virtual host page', () {
    const base = 'https://flutter-monaco.example/monaco-0.57.0';

    String build({String? bridgeVersion}) => buildMonacoIndexHtml(
      vsPath: '$base/min/vs',
      bridgeBase: '$base/bridge',
      monacoVersion: '0.57.0',
      isWindows: true,
      bridgeVersion: bridgeVersion,
    );

    test('the policy admits the virtual host and blob workers only', () {
      final csp = PageCsp.fromHtml(build());
      const asset = '$base/min/vs/editor/editor.main.js';
      for (final directive in csp.fetchDirectives) {
        expect(
          csp.admitsWithoutSelf(directive, asset),
          isTrue,
          reason: '$directive does not admit $asset',
        );
        // Served over https, the page has no reason to reach the disk.
        expect(csp.directives[directive], isNot(contains('file:')));
        expect(csp.directives[directive], isNot(contains('https:')));
      }
      expect(csp.directives['default-src'], isNot(contains('file:')));
      expect(csp.admitsWithoutSelf('worker-src', 'blob:https://x/1'), isTrue);
    });

    test('bridge scripts carry the bridge fingerprint, loader.js does not', () {
      final urls = scriptUrlsIn(build(bridgeVersion: 'abc123'));
      expect(urls, contains('$base/min/vs/loader.js'));
      for (final script in monacoBridgeScripts) {
        expect(urls, contains('$base/bridge/$script?v=abc123'));
      }
      expect(scriptUrlsIn(build()), contains('$base/bridge/boot.js'));
    });

    test('the page carries no worker safety net', () {
      final html = build();
      expect(html, isNot(contains('__FM_WORKERS')));
      expect(html, isNot(contains('MonacoEnvironment')));
    });
  });

  group('worker safety net', () {
    final windowsFileBase = Uri.file(
      r"C:\Users\O'Brien\cache\monaco-0.57.0",
      windows: true,
    ).toString();
    final pages = <String, String>{
      'Android': buildMonacoIndexHtml(
        vsPath: 'min/vs',
        bridgeBase: 'bridge',
        monacoVersion: '0.57.0',
      ),
      'Apple': buildMonacoIndexHtml(
        vsPath: 'min/vs',
        bridgeBase: 'bridge',
        monacoVersion: '0.57.0',
        isIosOrMacOS: true,
      ),
      'Windows file fallback': buildMonacoIndexHtml(
        vsPath: '$windowsFileBase/min/vs',
        bridgeBase: '$windowsFileBase/bridge',
        monacoVersion: '0.57.0',
        isWindows: true,
      ),
    };

    pages.forEach((name, html) {
      test('$name: installed once, before Monaco can load', () {
        final scripts = inlineScriptsIn(html);
        final safetyNet = scripts.where((s) => s.contains('__FM_WORKERS'));
        expect(safetyNet, hasLength(1));
        expect(safetyNet.single, contains("location.protocol !== 'file:'"));
        final netIndex = html.indexOf('__FM_WORKERS');
        expect(netIndex, greaterThan(html.indexOf('window.__FM_PAGE')));
        expect(netIndex, lessThan(html.indexOf('/loader.js')));
      });
    });

    test('is absent from web pages', () {
      final html = _build(
        isWeb: true,
        vsPath: 'https://app.example/assets/monaco/min/vs',
        bridgeBase: 'https://app.example/assets/monaco/bridge',
      );
      expect(html, isNot(contains('__FM_WORKERS')));
      expect(html, isNot(contains('MonacoEnvironment')));
    });

    test('no page keeps the dead worker shims', () {
      // editor.main.js replaces MonacoEnvironment wholesale while it loads,
      // and vs/base/worker/workerMain.js does not exist in Monaco 0.57.
      for (final html in [
        ...pages.values,
        _build(
          isWeb: true,
          vsPath: 'https://app.example/assets/monaco/min/vs',
          bridgeBase: 'https://app.example/assets/monaco/bridge',
        ),
      ]) {
        expect(html, isNot(contains('getWorkerUrl')));
        expect(html, isNot(contains('workerMain.js')));
        expect(html, isNot(contains('baseUrl')));
        expect(html, isNot(contains('MonacoEnvironment = {')));
      }
    });

    group('in a simulated page', () {
      Future<Map<String, Object?>> run(Map<String, Object?> scenario) async {
        final script = inlineScriptsIn(pages['Android']!)
            .singleWhere((s) => s.contains('__FM_WORKERS'));
        final dir = await Directory.systemTemp.createTemp('fm_safety_net_');
        try {
          final scriptFile = File(p.join(dir.path, 'net.js'))
            ..writeAsStringSync(script);
          final scenarioFile = File(p.join(dir.path, 'scenario.json'))
            ..writeAsStringSync(
              jsonEncode({
                'protocol': 'file:',
                'href': "file:///C:/Users/O'Brien/cache/monaco-0.57.0/monaco_x.html",
                'vsPath': 'min/vs',
                ...scenario,
              }),
            );
          final result = await Process.run('node', [
            p.join('test', 'helpers', 'worker_safety_net_runner.cjs'),
            scriptFile.path,
            scenarioFile.path,
          ]);
          expect(result.exitCode, 0, reason: '${result.stderr}');
          return jsonDecode(result.stdout as String) as Map<String, Object?>;
        } finally {
          await dir.delete(recursive: true);
        }
      }

      Map<String, Object?> outcome(Map<String, Object?> run, String label) =>
          (run['results']! as Map<String, Object?>)[label]!
              as Map<String, Object?>;

      test('keeps Monaco\'s workers where a worker can load scripts', () async {
        final result = await run({'worker': 'loads'});
        expect(result['mode'], 'workers');
        // The probe imported the real bundled loader, resolved like the page.
        expect(result['imported'], [
          "file:///C:/Users/O'Brien/cache/monaco-0.57.0/min/vs/loader.js",
        ]);
        for (final label in ['editorWorkerService', 'json', 'typescript']) {
          expect(outcome(result, label), {'value': 'real worker for $label'});
        }
        expect(result['warnings'], isEmpty);
        expect(result['sameObject'], isTrue);
      }, skip: nodeUnavailableReason);

      test('fails fast where a worker cannot load scripts', () async {
        final result = await run({'worker': 'fails'});
        expect(result['mode'], 'main-thread');
        expect(result['detail'], contains('NetworkError'));
        // Throwing makes Monaco run the editor worker on the main thread.
        expect(outcome(result, 'editorWorkerService'), {
          'threw': {
            'name': 'Error',
            'message': contains('editorWorkerService'),
          },
        });
        // Language services have no main-thread version: Monaco's
        // cancellation shape makes it treat the refusal as "no result".
        for (final label in [
          'json',
          'css',
          'html',
          'typescript',
          'javascript',
        ]) {
          expect(outcome(result, label), {
            'threw': {'name': 'Canceled', 'message': 'Canceled'},
          }, reason: label);
        }
        // One page-level warning plus one per refused label, never repeated.
        expect(result['warnings'], hasLength(7));
      }, skip: nodeUnavailableReason);

      test('fails fast while the probe has not answered', () async {
        final result = await run({'worker': 'silent', 'requestEarly': true});
        expect(result['mode'], 'probing');
        expect(result['early'], {
          'threw': {'name': 'Error', 'message': contains('main thread')},
        });
      }, skip: nodeUnavailableReason);

      test('fails fast when no worker can be created', () async {
        final result = await run({'worker': 'throws'});
        expect(result['mode'], 'main-thread');
        expect(result['detail'], contains('could not start'));
        expect(outcome(result, 'json'), {
          'threw': {'name': 'Canceled', 'message': 'Canceled'},
        });
      }, skip: nodeUnavailableReason);

      test('leaves pages served over http(s) untouched', () async {
        final result = await run({
          'protocol': 'https:',
          'href': 'https://flutter-monaco.example/monaco-0.57.0/monaco_x.html',
          'worker': 'fails',
        });
        expect(result['mode'], isNull);
        expect(result['workers'], 0);
        expect(result['descriptor'], 'data');
        expect(outcome(result, 'json'), {'value': 'real worker for json'});
      }, skip: nodeUnavailableReason);
    });
  });
}
