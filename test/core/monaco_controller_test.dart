import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_monaco/src/platform/platform_webview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../fakes/fake_platform_webview_controller.dart';

class _TestBundle {
  _TestBundle(this.controller, this.webview);

  final MonacoController controller;
  final FakePlatformWebViewController webview;
}

Future<_TestBundle> _createBundle({bool ready = true}) async {
  final webview = FakePlatformWebViewController();
  final controller = await MonacoController.createForTesting(
    webViewController: webview,
    markReady: ready,
  );
  return _TestBundle(controller, webview);
}

/// All dispatched protocol calls whose dotted method equals [method].
List<Map<String, Object?>> _dispatchesOf(
  FakePlatformWebViewController webview,
  String method,
) {
  return webview.dispatched.where((d) => d['method'] == method).toList();
}

/// The params map of a parsed dispatch call.
Map<String, Object?> _paramsOf(Map<String, Object?> call) {
  return (call['params']! as Map).cast<String, Object?>();
}

void main() {
  group('MonacoController', () {
    group('initialization', () {
      test('createForTesting wires channel and marks ready', () async {
        final webview = FakePlatformWebViewController();
        final controller = await MonacoController.createForTesting(
          webViewController: webview,
          markReady: true,
        );
        expect(webview.hasChannel('flutterChannel'), true);
        expect(webview.initialized, true);
        expect(webview.jsEnabled, true);
        await expectLater(controller.whenReady, completes);
      });

      test('createForTesting with custom channel name', () async {
        final webview = FakePlatformWebViewController();
        await MonacoController.createForTesting(
          webViewController: webview,
          markReady: true,
          channelName: 'customChannel',
        );
        expect(webview.hasChannel('customChannel'), true);
      });

      test('completeReadyForTesting is idempotent', () async {
        final bundle = await _createBundle(ready: false);
        bundle.controller.completeReadyForTesting();
        bundle.controller.completeReadyForTesting(); // Should not throw
        await expectLater(bundle.controller.whenReady, completes);
      });

      test('isReady reflects ready state', () async {
        final bundle = await _createBundle(ready: false);
        expect(bundle.controller.isReady, false);

        bundle.controller.completeReadyForTesting();
        expect(bundle.controller.isReady, true);
      });
    });

    group('ready gating', () {
      test('ensureReady blocks operations until ready', () async {
        final bundle = await _createBundle(ready: false);
        final future = bundle.controller.updateOptions(
          const EditorOptions(fontSize: 18),
        );
        expect(bundle.webview.executed, isEmpty);
        bundle.controller.completeReadyForTesting();
        await future;
        expect(bundle.webview.executed.join('\n'), contains('updateOptions'));
      });

      test('execute helpers wait for ready on JS results', () async {
        final bundle = await _createBundle(ready: false);
        bundle.webview.injectCommandSuccess(
          'document.findMatches',
          value: <Map<String, dynamic>>[],
        );
        final future = bundle.controller.document.findMatches('x');
        expect(bundle.webview.executed, isEmpty);
        bundle.controller.completeReadyForTesting();
        await future;
        expect(
          _dispatchesOf(bundle.webview, 'document.findMatches'),
          isNotEmpty,
        );
      });

      test('multiple operations queue correctly', () async {
        final bundle = await _createBundle(ready: false);
        final futures = [
          bundle.controller.setTheme(MonacoTheme.vs),
          bundle.controller.document.setLanguage(MonacoLanguage.python),
          bundle.controller.requestFocus(),
        ];

        expect(bundle.webview.executed, isEmpty);
        bundle.controller.completeReadyForTesting();
        await Future.wait(futures);

        final joined = bundle.webview.executed.join('\n');
        expect(joined.contains('setTheme'), true);
        expect(joined.contains('setLanguage'), true);
        expect(joined.contains('focus.force'), true);
      });

      test(
        'executeAction routes toolbar commands to monaco action ids',
        () async {
          final bundle = await _createBundle();

          const ids = [
            MonacoAction.foldAll,
            MonacoAction.unfoldAll,
            MonacoAction.commentLine,
            MonacoAction.indentLines,
            MonacoAction.outdentLines,
          ];
          for (final id in ids) {
            await bundle.controller.executeAction(id);
          }

          final joined = bundle.webview.executed.join('\n');
          for (final id in ids) {
            expect(joined.contains(id.id), true, reason: 'missing ${id.id}');
          }
        },
      );

      test('command failure envelope throws MonacoJavaScriptError', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandFailure(
          'executeAction',
          message: 'broken action',
        );

        await expectLater(
          () => bundle.controller.executeAction(const MonacoAction('whatever')),
          throwsA(
            isA<MonacoJavaScriptError>()
                .having((e) => e.operation, 'operation', 'editor.executeAction')
                .having((e) => e.message, 'message', 'broken action'),
          ),
        );
      });
    });

    group('theme registration', () {
      test('defineTheme serializes MonacoThemeDefinition data', () async {
        final bundle = await _createBundle();
        const theme = MonacoThemeDefinition(
          id: 'app-dark',
          base: MonacoBaseTheme.vsDark,
          rules: [MonacoThemeRule(token: 'comment', foreground: '6A9955')],
          colors: {'editor.background': '#101010'},
        );

        await bundle.controller.defineTheme(theme);

        final invocation = bundle.webview
            .scriptsContaining('editor.defineTheme')
            .single;
        expect(invocation, contains('"app-dark"'));
        expect(invocation, contains('"vs-dark"'));
        expect(invocation, contains('"6A9955"'));
        expect(invocation, contains('"editor.background"'));
      });

      test('defineTheme forwards raw Monaco theme data loaded via '
          'fromMonacoThemeData', () async {
        final bundle = await _createBundle();
        await bundle.controller.defineTheme(
          MonacoThemeDefinition.fromMonacoThemeData('raw-id', const {
            'base': 'vs',
            'inherit': false,
            'rules': <Map<String, Object?>>[],
            'colors': {'editor.background': '#FFFFFF'},
          }),
        );

        final invocation = bundle.webview
            .scriptsContaining('editor.defineTheme')
            .single;
        expect(invocation, contains('"raw-id"'));
        expect(invocation, contains('"editor.background"'));
        expect(invocation, contains('"#FFFFFF"'));
      });

      test('setTheme rejects empty ids', () async {
        final bundle = await _createBundle();
        expect(
          () => bundle.controller.setTheme(const MonacoTheme('   ')),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('defineTheme rejects empty ids', () async {
        final bundle = await _createBundle();
        expect(
          () => bundle.controller.defineTheme(
            const MonacoThemeDefinition(id: '', base: MonacoBaseTheme.vs),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('MonacoThemeDefinition.fromJson throws on unknown or missing base '
          'instead of falling back', () {
        expect(
          () => MonacoThemeDefinition.fromJson(const {
            'id': 'x',
            'base': 'solarized',
          }),
          throwsFormatException,
        );
        expect(
          () => MonacoThemeDefinition.fromJson(const {'id': 'x'}),
          throwsFormatException,
        );
      });

      test('getTheme returns value from bridge', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess(
          'editor.getTheme',
          value: 'company-dark',
        );
        expect(
          await bundle.controller.getTheme(),
          const MonacoTheme('company-dark'),
        );
      });

      test('getTheme rethrows bridge errors', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandFailure(
          'editor.getTheme',
          message: 'monaco.editor.getTheme is not a function',
        );
        await expectLater(
          bundle.controller.getTheme(),
          throwsA(isA<MonacoJavaScriptError>()),
        );
      });

      test('getTheme returns null when bridge reports empty string', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess('editor.getTheme', value: '');
        expect(await bundle.controller.getTheme(), isNull);
      });

      test(
        'MonacoThemeDefinition JSON round-trip preserves rules and colors',
        () {
          const original = MonacoThemeDefinition(
            id: 'roundtrip',
            base: MonacoBaseTheme.hcBlack,
            inherit: false,
            rules: [
              MonacoThemeRule(
                token: 'keyword',
                foreground: '569CD6',
                fontStyle: 'italic',
              ),
              MonacoThemeRule(token: 'string', foreground: 'CE9178'),
            ],
            colors: {
              'editor.background': '#1E1E1E',
              'editor.foreground': '#D4D4D4',
            },
          );

          final json = original.toJson();
          final restored = MonacoThemeDefinition.fromJson(json);

          expect(restored, equals(original));
        },
      );

      test(
        'MonacoThemeRule.fromJson accepts empty token as default selector',
        () {
          final rule = MonacoThemeRule.fromJson(const {
            'token': '',
            'foreground': 'D4D4D4',
          });
          expect(rule.token, isEmpty);
          expect(rule.foreground, 'D4D4D4');
        },
      );

      test('MonacoThemeDefinition.fromMonacoThemeData attaches the id', () {
        final restored = MonacoThemeDefinition.fromMonacoThemeData(
          'third-party-dark',
          const {
            'base': 'vs-dark',
            'inherit': true,
            'rules': [
              {'token': 'comment', 'foreground': '6A9955'},
            ],
            'colors': {'editor.background': '#1E1E1E'},
          },
        );

        expect(restored.id, 'third-party-dark');
        expect(restored.base, MonacoBaseTheme.vsDark);
        expect(restored.rules.single.token, 'comment');
        expect(restored.colors['editor.background'], '#1E1E1E');
      });

      test('EditorOptions.theme carries custom ids in the open theme type', () {
        const custom = EditorOptions(theme: MonacoTheme('custom-dark'));
        expect(custom.theme, const MonacoTheme('custom-dark'));
        expect(custom.theme!.isBuiltIn, false);

        const builtIn = EditorOptions(theme: MonacoTheme.hcLight);
        expect(builtIn.theme, MonacoTheme.hcLight);
        expect(builtIn.theme!.isBuiltIn, true);
      });

      test('EditorOptions.fromJson keeps custom theme ids as-is', () {
        final custom = EditorOptions.fromJson(const {'theme': 'app-dark'});
        expect(custom.theme, const MonacoTheme('app-dark'));
        expect(custom.theme!.isBuiltIn, false);

        final builtIn = EditorOptions.fromJson(const {'theme': 'vs'});
        expect(builtIn.theme, MonacoTheme.vs);
        expect(builtIn.theme!.isBuiltIn, true);
      });

      test('EditorOptions.fromJson rejects the legacy themeId key', () {
        expect(
          () => EditorOptions.fromJson(const {
            'theme': 'hc-light',
            'themeId': 'app-dark',
          }),
          throwsFormatException,
        );
      });
    });

    group('interaction', () {
      test('isInteractionEnabled defaults to true', () async {
        final bundle = await _createBundle(ready: false);
        expect(bundle.controller.isInteractionEnabled, true);
      });

      test(
        'setInteractionEnabled updates state and webview immediately',
        () async {
          final bundle = await _createBundle(ready: false);

          await bundle.controller.setInteractionEnabled(false);

          expect(bundle.controller.isInteractionEnabled, false);
          expect(bundle.webview.interactionEnabled, false);
          expect(
            bundle.webview.executed.any((s) => s == 'SET_INTERACTION:false'),
            true,
          );
        },
      );
    });

    group('pre-ready commands', () {
      test('setText calls wait for readiness and apply in order', () async {
        final bundle = await _createBundle(ready: false);
        final first = bundle.controller.document.setText('A');
        final second = bundle.controller.document.setText('B');
        expect(_dispatchesOf(bundle.webview, 'document.setText'), isEmpty);

        bundle.controller.completeReadyForTesting();
        await Future.wait([first, second]);

        // FIFO after ready: both dispatch, the newest write wins.
        final invocations = _dispatchesOf(bundle.webview, 'document.setText');
        expect(invocations.length, 2);
        expect(_paramsOf(invocations.first)['text'], 'A');
        expect(_paramsOf(invocations.last)['text'], 'B');
      });

      test('setLanguage calls wait for readiness and apply in order', () async {
        final bundle = await _createBundle(ready: false);
        final first = bundle.controller.document.setLanguage(
          MonacoLanguage.dart,
        );
        final second = bundle.controller.document.setLanguage(
          MonacoLanguage.python,
        );
        expect(_dispatchesOf(bundle.webview, 'document.setLanguage'), isEmpty);

        bundle.controller.completeReadyForTesting();
        await Future.wait([first, second]);

        final invocations = _dispatchesOf(
          bundle.webview,
          'document.setLanguage',
        );
        expect(invocations.length, 2);
        expect(_paramsOf(invocations.first)['language'], 'dart');
        expect(_paramsOf(invocations.last)['language'], 'python');
      });

      test('setText after ready executes immediately', () async {
        final bundle = await _createBundle();
        await bundle.controller.document.setText('immediate');
        final invocation = _dispatchesOf(
          bundle.webview,
          'document.setText',
        ).single;
        expect(_paramsOf(invocation)['text'], 'immediate');
      });
    });

    group('getText', () {
      test('does not JSON-decode content', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess(
          'document.getText',
          value: '{"a":1}',
        );
        final value = await bundle.controller.document.getText();
        expect(value, '{"a":1}');
      });

      test('throws MonacoJavaScriptError on bridge error', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandFailure(
          'document.getText',
          message: 'boom',
        );
        await expectLater(
          bundle.controller.document.getText(),
          throwsA(
            isA<MonacoJavaScriptError>().having(
              (e) => e.message,
              'message',
              'boom',
            ),
          ),
        );
      });

      test('throws MonacoProtocolError on a non-string result', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess('document.getText', value: null);
        await expectLater(
          bundle.controller.document.getText(),
          throwsA(isA<MonacoProtocolError>()),
        );
      });

      test('handles unicode content', () async {
        final bundle = await _createBundle();
        const unicode = 'مرحبا 👋🏽 é 🇪🇬';
        bundle.webview.injectCommandSuccess('document.getText', value: unicode);
        final value = await bundle.controller.document.getText();
        expect(value, unicode);
      });
    });

    group('selection operations', () {
      test('getSelection parses the response map', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess(
          'editor.getSelection',
          value: {
            'startLineNumber': 1,
            'startColumn': 2,
            'endLineNumber': 3,
            'endColumn': 4,
          },
        );
        final selection = await bundle.controller.getSelection();
        expect(selection, isNotNull);
        expect(selection!.startLine, 1);
        expect(selection.startColumn, 2);
        expect(selection.endLine, 3);
        expect(selection.endColumn, 4);
      });

      test('getSelection rethrows bridge errors', () async {
        final bundle = await _createBundle();
        bundle.webview.throwOn((s) => s.contains('getSelection'));
        await expectLater(
          bundle.controller.getSelection(),
          throwsA(isA<MonacoJavaScriptError>()),
        );
      });

      test('setSelection generates correct payload', () async {
        final bundle = await _createBundle();
        const range = Range(
          startLine: 1,
          startColumn: 1,
          endLine: 2,
          endColumn: 5,
        );
        await bundle.controller.setSelection(range);
        final joined = bundle.webview.executed.join('\n');
        expect(joined, contains('setSelection'));
        expect(joined, contains('startLineNumber'));
      });
    });

    group('navigation', () {
      test(
        'revealLine dispatches a line range (clamping is JS-side)',
        () async {
          final bundle = await _createBundle();
          await bundle.controller.revealLine(5);

          final call = _dispatchesOf(bundle.webview, 'editor.reveal').single;
          final params = _paramsOf(call);
          expect(params['center'], false);
          final range = (params['range']! as Map).cast<String, Object?>();
          expect(range['startLineNumber'], 5);
          expect(range['endLineNumber'], 5);
        },
      );

      test('revealLine with center option', () async {
        final bundle = await _createBundle();
        await bundle.controller.revealLine(5, center: true);

        final call = _dispatchesOf(bundle.webview, 'editor.reveal').single;
        expect(_paramsOf(call)['center'], true);
      });

      test('revealRange generates correct payload', () async {
        final bundle = await _createBundle();
        const range = Range(
          startLine: 1,
          startColumn: 1,
          endLine: 5,
          endColumn: 10,
        );
        await bundle.controller.revealRange(range, center: true);

        final call = _dispatchesOf(bundle.webview, 'editor.reveal').single;
        final params = _paramsOf(call);
        expect(params['center'], true);
        final sent = (params['range']! as Map).cast<String, Object?>();
        expect(sent['startLineNumber'], 1);
        expect(sent['endLineNumber'], 5);
        expect(sent['endColumn'], 10);
      });

      test('revealRange with Range.lines reveals a multi-line span', () async {
        final bundle = await _createBundle();
        await bundle.controller.revealRange(Range.lines(2, 5));

        final call = _dispatchesOf(bundle.webview, 'editor.reveal').single;
        final range = (_paramsOf(call)['range']! as Map)
            .cast<String, Object?>();
        expect(range['startLineNumber'], 2);
        expect(range['endLineNumber'], 5);
      });

      test('revealPosition creates collapsed range', () async {
        final bundle = await _createBundle();
        const pos = Position(line: 3, column: 7);
        await bundle.controller.revealPosition(pos);

        final call = _dispatchesOf(bundle.webview, 'editor.reveal').single;
        final range = (_paramsOf(call)['range']! as Map)
            .cast<String, Object?>();
        expect(range['startLineNumber'], 3);
        expect(range['startColumn'], 7);
        expect(range['endLineNumber'], 3);
        expect(range['endColumn'], 7);
      });
    });

    group('actions', () {
      test('executeAction forwards args to JS', () async {
        final bundle = await _createBundle();
        await bundle.controller.executeAction(
          const MonacoAction('myAction'),
          args: {'foo': 'bar'},
        );

        final joined = bundle.webview.executed.join('\n');
        expect(joined, contains('executeAction'));
        expect(joined, contains('"foo":"bar"'));
      });
    });

    group('line operations', () {
      test('lineCount returns valid count', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess('document.lineCount', value: 42);
        final count = await bundle.controller.document.lineCount();
        expect(count, 42);
      });

      test('lineCount rethrows bridge errors', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandFailure(
          'document.lineCount',
          message: 'boom',
        );
        await expectLater(
          bundle.controller.document.lineCount(),
          throwsA(isA<MonacoJavaScriptError>()),
        );
      });

      test('lineAt(0) throws RangeError without dispatching', () async {
        final bundle = await _createBundle();
        await expectLater(
          bundle.controller.document.lineAt(0),
          throwsRangeError,
        );
        expect(_dispatchesOf(bundle.webview, 'document.getLines'), isEmpty);
      });

      test('lineAt past the document end clamps JS-side', () async {
        // Upper-bound validation moved into the page: no Dart-side
        // lineCount round trip, the JS bridge clamps and answers.
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess(
          'document.getLines',
          value: ['last line'],
        );
        final value = await bundle.controller.document.lineAt(10);
        expect(value, 'last line');
        final call = _dispatchesOf(bundle.webview, 'document.getLines').single;
        expect(_paramsOf(call)['startLine'], 10);
        expect(_paramsOf(call)['endLine'], 10);
      });

      test('lineAt returns content for valid line', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess(
          'document.getLines',
          value: ['line 3'],
        );
        final value = await bundle.controller.document.lineAt(3);
        expect(value, 'line 3');
      });

      test('getLines rejects endLine before startLine', () async {
        final bundle = await _createBundle();
        await expectLater(
          bundle.controller.document.getLines(3, 2),
          throwsRangeError,
        );
        expect(_dispatchesOf(bundle.webview, 'document.getLines'), isEmpty);
      });

      test('getLines fetches a contiguous range in one call', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess(
          'document.getLines',
          value: ['a', 'b', 'c'],
        );

        final lines = await bundle.controller.document.getLines(1, 3);
        expect(lines, ['a', 'b', 'c']);

        final calls = _dispatchesOf(bundle.webview, 'document.getLines');
        expect(calls, hasLength(1));
        expect(_paramsOf(calls.single)['startLine'], 1);
        expect(_paramsOf(calls.single)['endLine'], 3);
      });
    });

    group('edit operations', () {
      test('applyEdits skips empty list', () async {
        final bundle = await _createBundle();
        await bundle.controller.document.applyEdits([]);
        expect(
          bundle.webview.executed.any((s) => s.contains('applyEdits')),
          false,
        );
      });

      test('applyEdits generates expected payload', () async {
        final bundle = await _createBundle();
        final edits = [
          EditOperation.insert(
            position: const Position(line: 1, column: 1),
            text: 'hi',
            forceMoveMarkers: true,
          ),
          EditOperation.delete(
            range: const Range(
              startLine: 2,
              startColumn: 1,
              endLine: 2,
              endColumn: 5,
            ),
          ),
        ];
        await bundle.controller.document.applyEdits(edits);

        final joined = bundle.webview.executed.join('\n');
        expect(joined, contains('applyEdits'));
        expect(joined, contains('"text":"hi"'));
        expect(joined, contains('"forceMoveMarkers":true'));
      });

      test('insert creates insert operation', () async {
        final bundle = await _createBundle();
        await bundle.controller.document.insert(
          const Position(line: 1, column: 1),
          'inserted',
        );
        final joined = bundle.webview.executed.join('\n');
        expect(joined, contains('applyEdits'));
        expect(joined, contains('"inserted"'));
      });

      test('deleteRange creates delete operation', () async {
        final bundle = await _createBundle();
        await bundle.controller.document.deleteRange(
          const Range(startLine: 1, startColumn: 1, endLine: 1, endColumn: 5),
        );
        final joined = bundle.webview.executed.join('\n');
        expect(joined, contains('applyEdits'));
        expect(joined, contains('"text":""'));
      });

      test('replaceRange creates replace operation', () async {
        final bundle = await _createBundle();
        await bundle.controller.document.replaceRange(
          const Range(startLine: 1, startColumn: 1, endLine: 1, endColumn: 5),
          'replacement',
        );
        final joined = bundle.webview.executed.join('\n');
        expect(joined, contains('applyEdits'));
        expect(joined, contains('"replacement"'));
      });

      test('deleteRange with Range.lines deletes a whole line', () async {
        final bundle = await _createBundle();
        await bundle.controller.document.deleteRange(Range.lines(3, 3));
        final joined = bundle.webview.executed.join('\n');
        expect(joined, contains('applyEdits'));
        expect(joined, contains('"startLineNumber":3'));
      });
    });

    group('decorations', () {
      test('createDecorationSet returns a live set with the page id', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess('decorations.create', value: 'ds1');

        final set = await bundle.controller.createDecorationSet();
        expect(set.id, 'ds1');
        expect(set.isDisposed, isFalse);
        expect(
          _dispatchesOf(bundle.webview, 'decorations.create'),
          hasLength(1),
        );
      });

      test(
        'createDecorationSet throws MonacoProtocolError on malformed result',
        () async {
          final bundle = await _createBundle();
          // Default auto-response is an undefined-success envelope (no id).
          await expectLater(
            bundle.controller.createDecorationSet(),
            throwsA(
              isA<MonacoProtocolError>().having(
                (e) => e.operation,
                'operation',
                'decorations.create',
              ),
            ),
          );
        },
      );

      test('set sends inline decoration options under this set id', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess('decorations.create', value: 'ds1');
        final set = await bundle.controller.createDecorationSet();

        await set.set([
          DecorationOptions.inlineClass(
            range: const Range(
              startLine: 1,
              startColumn: 1,
              endLine: 1,
              endColumn: 5,
            ),
            className: 'highlight',
            hoverMessage: 'hover text',
          ),
        ]);

        final call = _dispatchesOf(bundle.webview, 'decorations.set').single;
        expect(_paramsOf(call)['setId'], 'ds1');
        final joined = bundle.webview.executed.join('\n');
        expect(joined, contains('inlineClassName'));
        expect(joined, contains('hover text'));
      });

      test('set sends whole-line decoration options', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess('decorations.create', value: 'ds1');
        final set = await bundle.controller.createDecorationSet();

        await set.set([
          DecorationOptions.line(
            range: Range.lines(1, 2),
            className: 'line-highlight',
          ),
        ]);

        expect(bundle.webview.executed.join('\n'), contains('isWholeLine'));
      });

      test('independent sets carry distinct set ids', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess('decorations.create', value: 'ds1');
        bundle.webview.injectCommandSuccess('decorations.create', value: 'ds2');

        final first = await bundle.controller.createDecorationSet();
        final second = await bundle.controller.createDecorationSet();
        await first.set(const []);
        await second.set(const []);

        final setIds = _dispatchesOf(
          bundle.webview,
          'decorations.set',
        ).map((c) => _paramsOf(c)['setId']).toList();
        expect(setIds, ['ds1', 'ds2']);
      });

      test(
        'clear dispatches decorations.clear and keeps the set usable',
        () async {
          final bundle = await _createBundle();
          bundle.webview.injectCommandSuccess(
            'decorations.create',
            value: 'ds1',
          );
          final set = await bundle.controller.createDecorationSet();

          await set.clear();
          final call = _dispatchesOf(
            bundle.webview,
            'decorations.clear',
          ).single;
          expect(_paramsOf(call)['setId'], 'ds1');

          await set.set(const []);
          expect(
            _dispatchesOf(bundle.webview, 'decorations.set'),
            hasLength(1),
          );
        },
      );

      test('dispose releases the set and rejects further use', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess('decorations.create', value: 'ds1');
        final set = await bundle.controller.createDecorationSet();

        await set.dispose();
        expect(set.isDisposed, isTrue);
        final call = _dispatchesOf(
          bundle.webview,
          'decorations.dispose',
        ).single;
        expect(_paramsOf(call)['setId'], 'ds1');

        await expectLater(set.set(const []), throwsStateError);
        await expectLater(set.clear(), throwsStateError);

        // Double dispose is a no-op (no second wire call).
        await set.dispose();
        expect(
          _dispatchesOf(bundle.webview, 'decorations.dispose'),
          hasLength(1),
        );
      });
    });

    group('markers', () {
      test('setMarkers uses owner and severity values', () async {
        final bundle = await _createBundle();
        await bundle.controller.document.setMarkers([
          MarkerData.error(
            range: const Range(
              startLine: 1,
              startColumn: 1,
              endLine: 1,
              endColumn: 10,
            ),
            message: 'Error message',
          ),
        ], owner: 'flutter-errors');

        final joined = bundle.webview.executed.join('\n');
        expect(joined, contains('document.setMarkers'));
        expect(joined, contains('flutter-errors'));
        expect(joined, contains('"severity":8')); // Error severity
      });

      test('setMarkers defaults to the flutter owner', () async {
        final bundle = await _createBundle();
        await bundle.controller.document.setMarkers([
          MarkerData.warning(
            range: const Range(
              startLine: 1,
              startColumn: 1,
              endLine: 1,
              endColumn: 5,
            ),
            message: 'warn',
          ),
        ]);
        final call = _dispatchesOf(
          bundle.webview,
          'document.setMarkers',
        ).single;
        expect(_paramsOf(call)['owner'], 'flutter');
      });

      test(
        'clearMarkers replaces the owner markers with an empty list',
        () async {
          final bundle = await _createBundle();
          await bundle.controller.document.clearMarkers(owner: 'lints');

          final call = _dispatchesOf(
            bundle.webview,
            'document.setMarkers',
          ).single;
          final params = _paramsOf(call);
          expect(params['owner'], 'lints');
          expect(params['markers'], isEmpty);
        },
      );
    });

    group('find and replace', () {
      test('findMatches returns FindMatch list', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess(
          'document.findMatches',
          value: [
            {
              'match': 'abc',
              'range': {
                'startLineNumber': 1,
                'startColumn': 1,
                'endLineNumber': 1,
                'endColumn': 4,
              },
            },
            {
              'match': 'abc',
              'range': {
                'startLineNumber': 2,
                'startColumn': 5,
                'endLineNumber': 2,
                'endColumn': 8,
              },
            },
          ],
        );

        final matches = await bundle.controller.document.findMatches('abc');
        expect(matches.length, 2);
        expect(matches[0].match, 'abc');
        expect(matches[0].range.startLine, 1);
        expect(matches[1].range.startLine, 2);
      });

      test('findMatches with options', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess(
          'document.findMatches',
          value: <Map<String, dynamic>>[],
        );

        await bundle.controller.document.findMatches(
          'test',
          options: FindOptions.caseSensitive(wholeWord: true),
          limit: 50,
        );

        final call = _dispatchesOf(
          bundle.webview,
          'document.findMatches',
        ).single;
        final params = _paramsOf(call);
        expect(params['query'], 'test');
        expect(params['matchCase'], true);
        expect(params['wholeWord'], true);
        expect(params['limit'], 50);
      });

      test('findMatches rethrows bridge errors', () async {
        final bundle = await _createBundle();
        bundle.webview.throwOn((s) => s.contains('findMatches'));
        await expectLater(
          bundle.controller.document.findMatches('test'),
          throwsA(isA<MonacoJavaScriptError>()),
        );
      });

      test('replaceMatches returns count', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess(
          'document.replaceMatches',
          value: 5,
        );

        final count = await bundle.controller.document.replaceMatches(
          'old',
          'new',
        );
        expect(count, 5);
      });

      test('replaceMatches rethrows bridge errors', () async {
        final bundle = await _createBundle();
        bundle.webview.throwOn((s) => s.contains('replaceMatches'));
        await expectLater(
          bundle.controller.document.replaceMatches('a', 'b'),
          throwsA(isA<MonacoJavaScriptError>()),
        );
      });
    });

    group('view state', () {
      test('captureViewState returns an opaque persistable state', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess(
          'editor.captureViewState',
          value: {
            'cursorState': [
              {'inSelectionMode': false},
            ],
            'scrollTop': 100,
          },
        );

        final state = await bundle.controller.captureViewState();
        expect(state.isEmpty, isFalse);
        expect(state.toJson()['scrollTop'], 100);
      });

      test('captureViewState returns an empty state when there is '
          'none', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess(
          'editor.captureViewState',
          value: null,
        );
        final state = await bundle.controller.captureViewState();
        expect(state.isEmpty, isTrue);
      });

      test('captureViewState rethrows bridge errors', () async {
        final bundle = await _createBundle();
        bundle.webview.throwOn((s) => s.contains('captureViewState'));
        await expectLater(
          bundle.controller.captureViewState(),
          throwsA(isA<MonacoJavaScriptError>()),
        );
      });

      test('restoreViewState skips empty state', () async {
        final bundle = await _createBundle();
        final before = bundle.webview.executed.length;
        await bundle.controller.restoreViewState(
          const MonacoViewState.fromJson({}),
        );
        expect(bundle.webview.executed.length, before);
      });

      test('restoreViewState passes state to JS', () async {
        final bundle = await _createBundle();
        await bundle.controller.restoreViewState(
          const MonacoViewState.fromJson({'scrollTop': 50}),
        );
        expect(
          bundle.webview.executed.join('\n'),
          contains('restoreViewState'),
        );
      });

      test('captured state round-trips through restore', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess(
          'editor.captureViewState',
          value: {'scrollTop': 25},
        );
        final state = await bundle.controller.captureViewState();

        await bundle.controller.restoreViewState(
          MonacoViewState.fromJson(state.toJson()),
        );

        final call = _dispatchesOf(
          bundle.webview,
          'editor.restoreViewState',
        ).single;
        expect((_paramsOf(call)['state']! as Map).cast<String, Object?>(), {
          'scrollTop': 25,
        });
      });
    });

    group('documents', () {
      test('openDocument returns a pinned handle with the created '
          'URI', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess(
          'docs.open',
          value: 'file:///model1',
        );

        final doc = await bundle.controller.openDocument(
          text: 'content',
          language: MonacoLanguage.dart,
        );
        expect(doc.uri.toString(), 'file:///model1');

        final call = _dispatchesOf(bundle.webview, 'docs.open').single;
        final params = _paramsOf(call);
        expect(params['text'], 'content');
        expect(params['language'], 'dart');
      });

      test(
        'openDocument throws MonacoProtocolError on undefined result',
        () async {
          final bundle = await _createBundle();
          // Default auto-response is an undefined-success envelope.

          await expectLater(
            bundle.controller.openDocument(text: 'content'),
            throwsA(isA<MonacoProtocolError>()),
          );
        },
      );

      test('activateDocument calls JS with URI', () async {
        final bundle = await _createBundle();
        await bundle.controller.activateDocument(
          bundle.controller.documentByUri(Uri.parse('file:///test')),
        );
        final call = _dispatchesOf(bundle.webview, 'docs.activate').single;
        expect(_paramsOf(call)['uri'], 'file:///test');
      });

      test('activateDocument rejects the active-tracking handle', () async {
        final bundle = await _createBundle();
        await expectLater(
          bundle.controller.activateDocument(bundle.controller.document),
          throwsArgumentError,
        );
        expect(_dispatchesOf(bundle.webview, 'docs.activate'), isEmpty);
      });

      test('close on a pinned handle calls JS with URI', () async {
        final bundle = await _createBundle();
        await bundle.controller
            .documentByUri(Uri.parse('file:///test'))
            .close();
        final call = _dispatchesOf(bundle.webview, 'docs.close').single;
        expect(_paramsOf(call)['uri'], 'file:///test');
      });

      test('close on the active-tracking handle throws StateError', () async {
        final bundle = await _createBundle();
        await expectLater(bundle.controller.document.close(), throwsStateError);
        expect(_dispatchesOf(bundle.webview, 'docs.close'), isEmpty);
      });

      test('listDocuments returns pinned handles', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess(
          'docs.list',
          value: ['file:///m1', 'file:///m2', 'invalid'],
        );

        final list = await bundle.controller.listDocuments();
        expect(list.length, 3);
        expect(list[0].uri.toString(), 'file:///m1');
      });

      test('pinned handles send their uri; the active handle sends '
          'null', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess(
          'document.getText',
          value: 'pinned',
        );
        bundle.webview.injectCommandSuccess(
          'document.getText',
          value: 'active',
        );

        await bundle.controller
            .documentByUri(Uri.parse('file:///a.dart'))
            .getText();
        await bundle.controller.document.getText();

        final calls = _dispatchesOf(bundle.webview, 'document.getText');
        expect(calls, hasLength(2));
        expect(_paramsOf(calls.first)['uri'], 'file:///a.dart');
        expect(_paramsOf(calls.last)['uri'], isNull);
      });
    });

    group('dirty tracking and cursor', () {
      test('isDirty returns boolean', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess('document.isDirty', value: true);
        final dirty = await bundle.controller.document.isDirty();
        expect(dirty, true);
      });

      test('markSaved calls JS', () async {
        final bundle = await _createBundle();
        await bundle.controller.document.markSaved();
        expect(bundle.webview.executed.join('\n'), contains('markSaved'));
      });

      test('getCursorPosition parses the response map', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess(
          'editor.getCursor',
          value: {'lineNumber': 5, 'column': 10},
        );

        final pos = await bundle.controller.getCursorPosition();
        expect(pos, isNotNull);
        expect(pos!.line, 5);
        expect(pos.column, 10);
      });

      test('setCursorPosition calls JS with coordinates', () async {
        final bundle = await _createBundle();
        await bundle.controller.setCursorPosition(
          const Position(line: 3, column: 7),
        );
        final call = _dispatchesOf(bundle.webview, 'editor.setCursor').single;
        final position = (_paramsOf(call)['position']! as Map)
            .cast<String, Object?>();
        expect(position['lineNumber'], 3);
        expect(position['column'], 7);
      });

      test('Position.fromZeroBased converts to 1-based for '
          'setCursorPosition', () async {
        final bundle = await _createBundle();
        await bundle.controller.setCursorPosition(Position.fromZeroBased(0, 0));
        final call = _dispatchesOf(bundle.webview, 'editor.setCursor').single;
        final position = (_paramsOf(call)['position']! as Map)
            .cast<String, Object?>();
        expect(position['lineNumber'], 1);
        expect(position['column'], 1);
      });

      test('getWordAt returns word', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess(
          'document.getWordAt',
          value: 'hello',
        );
        final word = await bundle.controller.document.getWordAt(
          const Position(line: 1, column: 1),
        );
        expect(word, 'hello');
      });
    });

    group('action catalog dispatch', () {
      test('formatDocument action id reaches the wire', () async {
        final bundle = await _createBundle();
        await bundle.controller.executeAction(MonacoAction.formatDocument);
        expect(bundle.webview.executed.join('\n'), contains('formatDocument'));
      });

      test('find action id reaches the wire', () async {
        final bundle = await _createBundle();
        await bundle.controller.executeAction(MonacoAction.find);
        expect(bundle.webview.executed.join('\n'), contains('actions.find'));
      });

      test('startFindReplaceAction id reaches the wire', () async {
        final bundle = await _createBundle();
        await bundle.controller.executeAction(
          MonacoAction.startFindReplaceAction,
        );
        expect(
          bundle.webview.executed.join('\n'),
          contains('startFindReplaceAction'),
        );
      });

      test('toggleWordWrap action id reaches the wire', () async {
        final bundle = await _createBundle();
        await bundle.controller.executeAction(MonacoAction.toggleWordWrap);
        expect(bundle.webview.executed.join('\n'), contains('toggleWordWrap'));
      });

      test('undo/redo action ids reach the wire', () async {
        final bundle = await _createBundle();
        await bundle.controller.executeAction(MonacoAction.undo);
        await bundle.controller.executeAction(MonacoAction.redo);
        final joined = bundle.webview.executed.join('\n');
        expect(joined, contains('"undo"'));
        expect(joined, contains('"redo"'));
      });

      test('clipboard action ids reach the wire', () async {
        final bundle = await _createBundle();
        await bundle.controller.executeAction(MonacoAction.clipboardCutAction);
        await bundle.controller.executeAction(MonacoAction.clipboardCopyAction);
        await bundle.controller.executeAction(
          MonacoAction.clipboardPasteAction,
        );
        final joined = bundle.webview.executed.join('\n');
        expect(joined, contains('clipboardCutAction'));
        expect(joined, contains('clipboardCopyAction'));
        expect(joined, contains('clipboardPasteAction'));
      });
    });

    group('focus and scroll', () {
      test('requestFocus dispatches focus.force', () async {
        final bundle = await _createBundle();
        await bundle.controller.requestFocus();
        expect(bundle.webview.executed.join('\n'), contains('focus.force'));
      });

      test('requestFocus retries multiple times on desktop', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          final bundle = await _createBundle();
          await bundle.controller.requestFocus(
            attempts: 3,
            interval: Duration.zero,
          );
          expect(_dispatchesOf(bundle.webview, 'focus.force').length, 3);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      test('macOS user intent falls back to input-focus replay when the '
          'native handoff is unavailable', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          final bundle = await _createBundle();
          // Fake default: NativeFocusResult.unsupported (no native plugin
          // registered, as in headless embeddings). The replay fallback
          // must kick in to recover stale WKWebView input readiness.
          await bundle.controller.requestFocus(
            attempts: 1,
            interval: Duration.zero,
            intent: MonacoFocusIntent.user,
          );
          final calls = _dispatchesOf(bundle.webview, 'focus.force');
          expect(calls, hasLength(1));
          expect(_paramsOf(calls.single)['replayInputFocus'], true);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      test(
        'macOS user intent skips the replay when the native handoff succeeds',
        () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
          try {
            for (final handoff in [
              NativeFocusResult.granted,
              NativeFocusResult.alreadyOwned,
            ]) {
              final bundle = await _createBundle();
              bundle.webview.nativeFocusResult = handoff;
              await bundle.controller.requestFocus(
                attempts: 1,
                interval: Duration.zero,
                intent: MonacoFocusIntent.user,
              );
              expect(bundle.webview.executed, contains('REQUEST_NATIVE_FOCUS'));
              final calls = _dispatchesOf(bundle.webview, 'focus.force');
              expect(calls, isNotEmpty);
              // First responder is real, so the caret-blinking blur/refocus
              // replay must not run for either handoff outcome.
              for (final call in calls) {
                expect(_paramsOf(call)['replayInputFocus'], false);
              }
            }
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        },
      );

      test(
        'macOS fallback replay runs at most once across retry attempts',
        () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
          try {
            final bundle = await _createBundle();
            bundle.webview.nativeFocusResult = NativeFocusResult.failed;
            await bundle.controller.requestFocus(
              attempts: 3,
              interval: Duration.zero,
              intent: MonacoFocusIntent.user,
            );
            final calls = _dispatchesOf(bundle.webview, 'focus.force');
            final replays = calls
                .where((c) => _paramsOf(c)['replayInputFocus'] == true)
                .length;
            final plainFocuses = calls
                .where((c) => _paramsOf(c)['replayInputFocus'] == false)
                .length;
            // One recovery replay, then idempotent settle retries: repeating
            // the blur/refocus cycle would multiply the caret blink.
            expect(replays, 1);
            expect(plainFocuses, 2);
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        },
      );

      test('hasNativeInputFocus delegates to the platform layer', () async {
        final bundle = await _createBundle();
        bundle.webview.nativeInputFocus = true;
        expect(await bundle.controller.hasNativeInputFocus(), isTrue);
        bundle.webview.nativeInputFocus = null;
        expect(await bundle.controller.hasNativeInputFocus(), isNull);
        expect(bundle.webview.executed, contains('HAS_NATIVE_INPUT_FOCUS'));
      });

      test('releaseNativeFocus delegates to the platform layer', () async {
        final bundle = await _createBundle();
        await bundle.controller.releaseNativeFocus();
        expect(bundle.webview.executed, contains('RELEASE_NATIVE_FOCUS'));
      });

      test('maintenance focus intent keeps default idempotent focus', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          final bundle = await _createBundle();
          await bundle.controller.requestFocus(
            attempts: 1,
            interval: Duration.zero,
          );
          final calls = _dispatchesOf(bundle.webview, 'focus.force');
          expect(calls, isNotEmpty);
          for (final call in calls) {
            expect(_paramsOf(call)['replayInputFocus'], false);
          }
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      test('requestFocus uses one attempt on mobile', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          final bundle = await _createBundle();
          await bundle.controller.requestFocus(
            attempts: 3,
            interval: Duration.zero,
          );
          expect(_dispatchesOf(bundle.webview, 'focus.force').length, 1);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('maintenance requestFocus does not steal the keyboard from a '
          'focused Flutter text input', (tester) async {
        final bundle = await _createBundle();
        final textInputCalls = <MethodCall>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.textInput,
          (call) async {
            textInputCalls.add(call);
            return null;
          },
        );
        addTearDown(() {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.textInput,
            null,
          );
        });
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextField(focusNode: focusNode, autofocus: true),
            ),
          ),
        );
        await tester.pump();
        expect(focusNode.hasPrimaryFocus, isTrue);
        textInputCalls.clear();

        // While the TextField owns the keyboard, maintenance focus must
        // no-op: on Windows requestNativeFocus would move real Win32 focus
        // to the WebView and typing would land in the editor instead of
        // the field.
        await tester.runAsync(() => bundle.controller.requestFocus());
        await tester.runAsync(
          () => bundle.controller.requestFocus(
            attempts: 2,
            interval: Duration.zero,
          ),
        );
        expect(
          bundle.webview.executed.where((s) => s.contains('focus.force')),
          isEmpty,
        );
        expect(
          bundle.webview.executed,
          isNot(contains('REQUEST_NATIVE_FOCUS')),
        );
        expect(
          textInputCalls.map((call) => call.method),
          isNot(contains('TextInput.hide')),
        );

        // Once the text input releases the keyboard, focusing works again.
        focusNode.unfocus();
        await tester.pump();
        await tester.runAsync(() => bundle.controller.requestFocus());
        expect(bundle.webview.executed, contains('REQUEST_NATIVE_FOCUS'));
        expect(bundle.webview.executed.join('\n'), contains('focus.force'));
      });

      testWidgets(
        'user focus intent releases Flutter text input before editor focus',
        (tester) async {
          debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
          final textInputCalls = <MethodCall>[];
          FakePlatformWebViewController? activeWebview;
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.textInput,
            (call) async {
              textInputCalls.add(call);
              activeWebview?.executed.add('TEXT_INPUT:${call.method}');
              return null;
            },
          );
          addTearDown(() {
            tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
              SystemChannels.textInput,
              null,
            );
            debugDefaultTargetPlatformOverride = null;
          });

          try {
            final bundle = await _createBundle();
            activeWebview = bundle.webview;
            final focusNode = FocusNode();
            addTearDown(focusNode.dispose);

            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: TextField(focusNode: focusNode, autofocus: true),
                ),
              ),
            );
            await tester.pump();
            expect(focusNode.hasPrimaryFocus, isTrue);

            bundle.webview.executed.clear();
            textInputCalls.clear();

            await tester.runAsync(
              () => bundle.controller.requestFocus(
                attempts: 1,
                interval: Duration.zero,
                intent: MonacoFocusIntent.user,
              ),
            );
            await tester.pump();

            expect(focusNode.hasPrimaryFocus, isFalse);
            expect(
              textInputCalls.map((call) => call.method),
              contains('TextInput.hide'),
            );

            final calls = bundle.webview.executed;
            expect(calls, contains('TEXT_INPUT:TextInput.hide'));
            expect(calls, contains('REQUEST_NATIVE_FOCUS'));
            expect(calls.join('\n'), contains('focus.force'));

            final textInputIndex = calls.indexOf('TEXT_INPUT:TextInput.hide');
            final nativeFocusIndex = calls.indexOf('REQUEST_NATIVE_FOCUS');
            final forceFocusIndex = calls.indexWhere(
              (call) => call.contains('focus.force'),
            );
            expect(textInputIndex, isNonNegative);
            expect(nativeFocusIndex, isNonNegative);
            expect(forceFocusIndex, isNonNegative);
            expect(textInputIndex, lessThan(nativeFocusIndex));
            expect(nativeFocusIndex, lessThan(forceFocusIndex));
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        },
      );

      test('layout calls layout', () async {
        final bundle = await _createBundle();
        await bundle.controller.layout();
        expect(bundle.webview.executed.join('\n'), contains('layout'));
      });

      test('scrollToTop scrolls to the top edge', () async {
        final bundle = await _createBundle();
        await bundle.controller.scrollToTop();
        final call = _dispatchesOf(
          bundle.webview,
          'editor.scrollToEdge',
        ).single;
        expect(_paramsOf(call)['edge'], 'top');
      });

      test('scrollToBottom scrolls to the bottom edge', () async {
        final bundle = await _createBundle();
        await bundle.controller.scrollToBottom();
        final call = _dispatchesOf(
          bundle.webview,
          'editor.scrollToEdge',
        ).single;
        expect(_paramsOf(call)['edge'], 'bottom');
      });
    });

    group('editor state snapshot', () {
      test('getEditorState issues one dispatch and parses the map', () async {
        final bundle = await _createBundle();

        // One editor.getState round trip replaces the 2.x five-command
        // fan-out.
        bundle.webview.injectCommandSuccess(
          'editor.getState',
          value: {
            'content': 'content',
            'selection': {
              'startLineNumber': 1,
              'startColumn': 1,
              'endLineNumber': 1,
              'endColumn': 5,
            },
            'cursorPosition': {'lineNumber': 1, 'column': 3},
            'lineCount': 5,
            'isDirty': false,
            'language': 'dart',
            'theme': 'vs-dark',
            'stats': {'lineCount': 5, 'charCount': 7},
          },
        );

        final state = await bundle.controller.getEditorState();

        expect(state.content, 'content');
        expect(state.selection?.endColumn, 5);
        expect(state.cursorPosition?.column, 3);
        expect(state.lineCount, 5);
        expect(state.isDirty, false);
        expect(state.language, MonacoLanguage.dart);
        expect(state.theme, MonacoTheme.vsDark);
        expect(state.stats.charCount, 7);

        expect(_dispatchesOf(bundle.webview, 'editor.getState'), hasLength(1));
        expect(_dispatchesOf(bundle.webview, 'document.getText'), isEmpty);
        expect(_dispatchesOf(bundle.webview, 'editor.getSelection'), isEmpty);
      });

      test('getEditorState throws MonacoProtocolError on a non-map '
          'result', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess('editor.getState', value: 'nope');
        await expectLater(
          bundle.controller.getEditorState(),
          throwsA(isA<MonacoProtocolError>()),
        );
      });
    });

    group('event streams', () {
      test('onContentChanged delivers typed events with the flush '
          'flag', () async {
        final bundle = await _createBundle();
        final events = <MonacoContentChanged>[];
        final sub = bundle.controller.onContentChanged.listen(events.add);

        // A bare payload (fake pages, older shells) still decodes.
        bundle.webview.emitEvent('contentChanged', {'isFlush': true});
        bundle.webview.emitEvent('contentChanged', {
          'uri': 'file:///a.dart',
          'isFlush': false,
          'changes': [
            {
              'range': {
                'startLineNumber': 1,
                'startColumn': 1,
                'endLineNumber': 1,
                'endColumn': 1,
              },
              'text': 'x',
            },
          ],
        });

        await pumpEventQueue();
        expect(events.map((e) => e.isFlush).toList(), [true, false]);
        expect(events.first.documentUri, isNull);
        expect(events.first.changes, isNull);
        expect(events.first.truncated, isFalse);
        expect(events.last.documentUri, Uri.parse('file:///a.dart'));
        expect(events.last.changes, hasLength(1));
        expect(events.last.changes!.single.text, 'x');
        await sub.cancel();
      });

      test('events surfaces unknown names as MonacoUnknownEvent', () async {
        final bundle = await _createBundle();
        final events = <MonacoEvent>[];
        final sub = bundle.controller.events.listen(events.add);

        bundle.webview.emitEvent('somethingNew', {'k': 1});

        await pumpEventQueue();
        expect(events.single, isA<MonacoUnknownEvent>());
        final unknown = events.single as MonacoUnknownEvent;
        expect(unknown.name, 'somethingNew');
        expect(unknown.data, {'k': 1});
        await sub.cancel();
      });

      test('onSelectionChanged delivers Range', () async {
        final bundle = await _createBundle();
        final events = <Range?>[];
        final sub = bundle.controller.onSelectionChanged.listen(events.add);

        bundle.webview.emitEvent('selectionChanged', {
          'selection': {
            'startLineNumber': 1,
            'startColumn': 1,
            'endLineNumber': 2,
            'endColumn': 3,
          },
        });

        await pumpEventQueue();
        expect(events.length, 1);
        expect(events.first?.endLine, 2);
        await sub.cancel();
      });

      test('onFocusChanged delivers focus transitions', () async {
        final bundle = await _createBundle();
        final transitions = <bool>[];
        final sub = bundle.controller.onFocusChanged.listen(transitions.add);

        bundle.webview.emitEvent('focusChanged', {'focused': true});
        bundle.webview.emitEvent('focusChanged', {'focused': false});

        await pumpEventQueue();
        expect(transitions, [true, false]);

        await sub.cancel();
      });
    });

    group('stats', () {
      test('stats listenable exposes the latest live stats value', () async {
        final bundle = await _createBundle();

        bundle.webview.emitEvent('stats', {'lineCount': 10, 'charCount': 50});
        await pumpEventQueue();

        final stats = bundle.controller.stats.value;
        expect(stats.lineCount, 10);
        expect(stats.charCount, 50);
      });
    });

    group('setJsonDiagnostics', () {
      test('waits for ready before executing', () async {
        final bundle = await _createBundle(ready: false);
        final future = bundle.controller.setJsonDiagnostics(
          const JsonDiagnosticsOptions(validate: true),
        );
        expect(bundle.webview.executed, isEmpty);
        bundle.controller.completeReadyForTesting();
        await future;
        expect(bundle.webview.hasExecuted('json.configureDiagnostics'), true);
      });

      test('generates correct JS payload', () async {
        final bundle = await _createBundle();
        await bundle.controller.setJsonDiagnostics(
          JsonDiagnosticsOptions(
            validate: true,
            allowComments: true,
            schemaValidation: DiagnosticsSeverity.error,
            trailingCommas: DiagnosticsSeverity.warning,
            schemas: [
              JsonDiagnosticsSchema(
                uri: Uri.parse('https://example.com/schema.json'),
                fileMatch: ['*'],
              ),
            ],
          ),
        );

        final joined = bundle.webview.executed.join('\n');
        expect(joined, contains('json.configureDiagnostics'));
        expect(joined, contains('"validate":true'));
        expect(joined, contains('"allowComments":true'));
        expect(joined, contains('"schemaValidation":"error"'));
        expect(joined, contains('"trailingCommas":"warning"'));
        expect(joined, contains('"uri":"https://example.com/schema.json"'));
        expect(joined, contains('"fileMatch":["*"]'));
      });

      test('propagates JavaScript errors', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandFailure(
          'json.configureDiagnostics',
          message: 'json diagnostics failed',
        );

        await expectLater(
          () => bundle.controller.setJsonDiagnostics(
            const JsonDiagnosticsOptions(validate: true),
          ),
          throwsA(
            isA<MonacoJavaScriptError>()
                .having(
                  (e) => e.operation,
                  'operation',
                  'json.configureDiagnostics',
                )
                .having((e) => e.message, 'message', 'json diagnostics failed'),
          ),
        );
      });
    });

    group('runJavaScript', () {
      test('executes script after ready', () async {
        final bundle = await _createBundle();
        await bundle.controller.runJavaScript('console.log("hello")');
        expect(
          bundle.webview.executed.any((s) => s.contains('console.log')),
          true,
        );
      });

      test('waits for ready before executing', () async {
        final bundle = await _createBundle(ready: false);
        final future = bundle.controller.runJavaScript('myCustomSetup()');
        expect(bundle.webview.executed, isEmpty);
        bundle.controller.completeReadyForTesting();
        await future;
        expect(
          bundle.webview.executed.any((s) => s.contains('myCustomSetup')),
          true,
        );
      });

      test('propagates platform exceptions', () async {
        final bundle = await _createBundle();
        bundle.webview.throwOnContains('throw new Error');

        await expectLater(
          bundle.controller.runJavaScript('throw new Error()'),
          throwsStateError,
        );
      });
    });

    group('evaluateJavaScript', () {
      test('sends the expression through page.eval', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess('page.eval', value: 42);

        await bundle.controller.evaluateJavaScript<int>(
          'monaco.editor.getEditors().length',
        );

        final call = _dispatchesOf(bundle.webview, 'page.eval').single;
        expect(
          _paramsOf(call)['expression'],
          'monaco.editor.getEditors().length',
        );
      });

      test('normalizes numeric result to int', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess('page.eval', value: 42);

        final result = await bundle.controller.evaluateJavaScript<int>(
          'myQuery()',
        );

        expect(result, 42);
        expect(result, isA<int>());
      });

      test('normalizes boolean result to bool', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess('page.eval', value: true);

        final result = await bundle.controller.evaluateJavaScript<bool>(
          'someFlag',
        );

        expect(result, true);
        expect(result, isA<bool>());
      });

      test('preserves string result', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess('page.eval', value: 'hello');

        final result = await bundle.controller.evaluateJavaScript<String>(
          '"hello"',
        );

        expect(result, 'hello');
      });

      test(
        'preserves numeric-looking string result when T is String',
        () async {
          final bundle = await _createBundle();
          bundle.webview.injectCommandSuccess('page.eval', value: '42');

          final result = await bundle.controller.evaluateJavaScript<String>(
            '"42"',
          );

          expect(result, '42');
          expect(result, isA<String>());
        },
      );

      test('returns maps', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess('page.eval', value: {'count': 2});

        final result = await bundle.controller
            .evaluateJavaScript<Map<String, dynamic>>('({ count: 2 })');

        expect(result, {'count': 2});
      });

      test('returns lists', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess('page.eval', value: [1, 2, 3]);

        final result = await bundle.controller
            .evaluateJavaScript<List<dynamic>>('[1, 2, 3]');

        expect(result, [1, 2, 3]);
      });

      test('returns null when JavaScript returns null', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess('page.eval');

        final result = await bundle.controller.evaluateJavaScript<int>(
          'missingThing',
        );

        expect(result, isNull);
      });

      test('returns null when JavaScript returns undefined', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess('page.eval', isUndefined: true);

        final result = await bundle.controller.evaluateJavaScript<int>(
          'missingThing',
        );

        expect(result, isNull);
      });

      test(
        'throws MonacoProtocolError when value cannot convert to T',
        () async {
          final bundle = await _createBundle();
          bundle.webview.injectCommandSuccess('page.eval', value: {'count': 2});

          await expectLater(
            bundle.controller.evaluateJavaScript<int>('({ count: 2 })'),
            throwsA(isA<MonacoProtocolError>()),
          );
        },
      );

      test('waits for ready before executing', () async {
        final bundle = await _createBundle(ready: false);
        bundle.webview.injectCommandSuccess('page.eval', value: 7);
        final future = bundle.controller.evaluateJavaScript<int>('myQuery()');
        expect(bundle.webview.executed, isEmpty);
        bundle.controller.completeReadyForTesting();
        final result = await future;
        expect(result, 7);
        expect(bundle.webview.executed.any((s) => s.contains('myQuery')), true);
      });

      test('propagates dispatch failures', () async {
        final bundle = await _createBundle();
        bundle.webview.throwOnContains('badExpression');

        await expectLater(
          bundle.controller.evaluateJavaScript<int>('badExpression()'),
          throwsA(
            isA<MonacoJavaScriptError>().having(
              (e) => e.operation,
              'operation',
              'page.eval',
            ),
          ),
        );
      });
    });

    group('runJavaScriptReturningResultRaw', () {
      test('returns platform-native value unchanged', () async {
        final bundle = await _createBundle();
        bundle.webview.enqueueResult('myQuery()', '42');

        final result = await bundle.controller.runJavaScriptReturningResultRaw(
          'myQuery()',
        );

        expect(result, '42');
      });

      test('waits for ready before executing', () async {
        final bundle = await _createBundle(ready: false);
        final future = bundle.controller.runJavaScriptReturningResultRaw(
          'myQuery()',
        );
        expect(bundle.webview.executed, isEmpty);

        bundle.webview.enqueueResult('myQuery()', 42);
        bundle.controller.completeReadyForTesting();

        final result = await future;
        expect(result, 42);
        expect(bundle.webview.executed.any((s) => s.contains('myQuery')), true);
      });

      test('propagates platform exceptions', () async {
        final bundle = await _createBundle();
        bundle.webview.throwOnContains('badQuery');

        await expectLater(
          bundle.controller.runJavaScriptReturningResultRaw('badQuery()'),
          throwsStateError,
        );
      });
    });

    group('failed boot gating', () {
      test(
        'a command issued after a failed boot rethrows the boot error',
        () async {
          final bundle = await _createBundle(ready: false);
          final bootError = const MonacoTimeoutError(
            message: 'boot timed out',
            timeout: Duration(seconds: 1),
            operation: 'boot',
          );
          bundle.controller.failReadyForTesting(bootError);

          await expectLater(
            bundle.controller.whenReady,
            throwsA(same(bootError)),
          );
          await expectLater(
            bundle.controller.getTheme(),
            throwsA(same(bootError)),
          );
          // The failed controller must never enter the protocol.
          expect(bundle.webview.dispatched, isEmpty);
        },
      );

      test(
        'a command queued before a failed boot receives the boot error',
        () async {
          final bundle = await _createBundle(ready: false);
          final pending = bundle.controller.getTheme();
          final bootError = const MonacoTimeoutError(
            message: 'boot timed out',
            timeout: Duration(seconds: 1),
            operation: 'boot',
          );
          bundle.controller.failReadyForTesting(bootError);

          await expectLater(pending, throwsA(same(bootError)));
          expect(bundle.webview.dispatched, isEmpty);
        },
      );

      test(
        'a command after dispose-during-boot throws MonacoDisposedError',
        () async {
          final bundle = await _createBundle(ready: false);
          bundle.controller.dispose();

          await expectLater(
            bundle.controller.getTheme().timeout(const Duration(seconds: 1)),
            throwsA(isA<MonacoDisposedError>()),
          );
        },
      );

      test(
        'commands issued before ready dispatch FIFO in call order',
        () async {
          final bundle = await _createBundle(ready: false);
          final futures = [
            bundle.controller.document.setText('a'),
            bundle.controller.updateOptions(const EditorOptions(fontSize: 11)),
            bundle.controller.document.setText('b'),
          ];
          bundle.controller.completeReadyForTesting();
          await Future.wait(futures);

          final methods = bundle.webview.dispatched
              .map((d) => d['method'])
              .toList();
          expect(methods, [
            'document.setText',
            'editor.updateOptions',
            'document.setText',
          ]);
          expect(_paramsOf(bundle.webview.dispatched[0])['text'], 'a');
          expect(_paramsOf(bundle.webview.dispatched[2])['text'], 'b');
        },
      );
    });

    group('interaction disable composition', () {
      test('overlapping runWithInteractionDisabled scopes stay disabled until '
          'the LAST one completes', () async {
        final bundle = await _createBundle();
        final gateA = Completer<void>();
        final gateB = Completer<void>();

        final runA = bundle.controller.runWithInteractionDisabled(
          () => gateA.future,
        );
        final runB = bundle.controller.runWithInteractionDisabled(
          () => gateB.future,
        );
        await Future<void>.delayed(Duration.zero);
        expect(bundle.webview.interactionEnabled, false);

        gateA.complete();
        await runA;
        expect(
          bundle.webview.interactionEnabled,
          false,
          reason: 'run B still needs interaction disabled',
        );

        gateB.complete();
        await runB;
        expect(bundle.webview.interactionEnabled, true);
      });

      test(
        'setInteractionEnabled(false) during a run survives the run',
        () async {
          final bundle = await _createBundle();
          final gate = Completer<void>();

          final run = bundle.controller.runWithInteractionDisabled(
            () => gate.future,
          );
          await Future<void>.delayed(Duration.zero);
          await bundle.controller.setInteractionEnabled(false);

          gate.complete();
          await run;
          expect(
            bundle.webview.interactionEnabled,
            false,
            reason: 'the finally block must not clobber the external disable',
          );
          expect(bundle.controller.isInteractionEnabled, false);
        },
      );
    });

    group('find options wiring', () {
      test('findMatches forwards searchOnlyEditableRange', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess(
          'document.findMatches',
          value: <Map<String, dynamic>>[],
        );

        await bundle.controller.document.findMatches(
          'query',
          options: const FindOptions(searchOnlyEditableRange: true),
        );

        final call = _dispatchesOf(bundle.webview, 'document.findMatches');
        expect(_paramsOf(call.single)['searchOnlyEditableRange'], true);
      });

      test(
        'findMatches applies limitResultCount as an additional cap',
        () async {
          final bundle = await _createBundle();
          bundle.webview.injectCommandSuccess(
            'document.findMatches',
            value: <Map<String, dynamic>>[],
          );

          await bundle.controller.document.findMatches(
            'query',
            options: const FindOptions(limitResultCount: 5),
          );

          final call = _dispatchesOf(bundle.webview, 'document.findMatches');
          expect(_paramsOf(call.single)['limit'], 5);
        },
      );

      test('lineAt requests a STRICT ranged read', () async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess(
          'document.getLines',
          value: <String>['hello'],
        );

        await bundle.controller.document.lineAt(3);

        final call = _dispatchesOf(bundle.webview, 'document.getLines');
        expect(_paramsOf(call.single)['strict'], true);
      });
    });

    group('capabilities surface', () {
      test('capabilities retains the raw set and answers supports()', () async {
        final bundle = await _createBundle();

        final capabilities = bundle.controller.capabilities;
        expect(capabilities.raw, containsAll(<String>['lsp', 'diff']));
        expect(capabilities.supports('lsp'), true);
        expect(capabilities.supports('holograms'), false);
      });
    });
  });
}
