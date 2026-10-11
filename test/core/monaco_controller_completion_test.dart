import 'dart:async';

import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_platform_webview_controller.dart';

Future<MonacoController> _createController(
  FakePlatformWebViewController webview,
) async {
  return MonacoController.createForTesting(
    webViewController: webview,
    markReady: true,
  );
}

/// Emits a `completion` request envelope like the page's completion
/// provider does (protocol 6.5).
void _emitCompletionRequest(
  FakePlatformWebViewController webview, {
  required String providerId,
  String id = 'q1',
  String requestId = 'req-1',
  String language = 'dart',
  int line = 1,
  int column = 2,
}) {
  webview.emitRequest(id, 'completion', {
    'providerId': providerId,
    'requestId': requestId,
    'language': language,
    'position': {'lineNumber': line, 'column': column},
    'defaultRange': {
      'startLineNumber': line,
      'startColumn': 1,
      'endLineNumber': line,
      'endColumn': column,
    },
    'lineText': 'test line',
  });
}

/// Dart's answer to the single outstanding completion request.
Map<String, Object?> _singleRespond(FakePlatformWebViewController webview) {
  expect(webview.responded, hasLength(1));
  return webview.responded.single;
}

List<Object?> _suggestionsOf(Map<String, Object?> respond) {
  final value = respond['value']! as Map<String, Object?>;
  return value['suggestions']! as List<Object?>;
}

void main() {
  group('MonacoController completions', () {
    group('registration validation', () {
      test('empty languages list throws ArgumentError', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);

        expect(
          () => controller.registerCompletions(
            id: 'p1',
            languages: const [],
            provider: (_) async => const CompletionList(suggestions: []),
          ),
          throwsArgumentError,
        );
      });

      test('duplicate provider id throws ArgumentError', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);

        await controller.registerCompletions(
          id: 'p1',
          languages: const [MonacoLanguage.dart],
          provider: (_) async => const CompletionList(suggestions: []),
        );

        expect(
          () => controller.registerCompletions(
            id: 'p1',
            languages: const [MonacoLanguage.dart],
            provider: (_) async => const CompletionList(suggestions: []),
          ),
          throwsArgumentError,
        );
      });

      test('null id generates unique id', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);

        final registration1 = await controller.registerCompletions(
          languages: const [MonacoLanguage.dart],
          provider: (_) async => const CompletionList(suggestions: []),
        );

        final registration2 = await controller.registerCompletions(
          languages: const [MonacoLanguage.dart],
          provider: (_) async => const CompletionList(suggestions: []),
        );

        expect(registration1.id, isNot(equals(registration2.id)));
        expect(registration1.id, startsWith('flutter_'));
        expect(registration2.id, startsWith('flutter_'));
      });
    });

    group('JS bridge calls', () {
      test('register dispatches completions.register with payload', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);

        final registration = await controller.registerCompletions(
          id: 'myProvider',
          languages: const [MonacoLanguage.dart, MonacoLanguage.typescript],
          triggerCharacters: const ['.', '@'],
          provider: (_) async => const CompletionList(suggestions: []),
        );

        expect(registration.id, 'myProvider');
        final call = webview.dispatched.singleWhere(
          (d) => d['method'] == 'completions.register',
        );
        final params = call['params']! as Map<String, Object?>;
        expect(params['id'], 'myProvider');
        expect(params['languages'], ['dart', 'typescript']);
        expect(params['triggerCharacters'], ['.', '@']);
      });

      test('registration.dispose dispatches completions.unregister', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);

        final registration = await controller.registerCompletions(
          id: 'p1',
          languages: const [MonacoLanguage.dart],
          provider: (_) async => const CompletionList(suggestions: []),
        );

        expect(registration.isDisposed, isFalse);
        await registration.dispose();
        expect(registration.isDisposed, isTrue);

        final calls = webview.dispatched
            .where((d) => d['method'] == 'completions.unregister')
            .toList();
        expect(calls, hasLength(1));
        final params = calls.single['params']! as Map<String, Object?>;
        expect(params['id'], 'p1');
      });

      test('double dispose is a no-op', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);

        final registration = await controller.registerCompletions(
          id: 'p1',
          languages: const [MonacoLanguage.dart],
          provider: (_) async => const CompletionList(suggestions: []),
        );

        await registration.dispose();
        await registration.dispose();

        final calls = webview.dispatched
            .where((d) => d['method'] == 'completions.unregister')
            .toList();
        expect(calls, hasLength(1));
      });

      test('failed bridge registration rolls the provider back', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);

        webview.injectCommandFailure(
          'completions.register',
          message: 'no editor',
        );
        await expectLater(
          controller.registerCompletions(
            id: 'p1',
            languages: const [MonacoLanguage.dart],
            provider: (_) async => const CompletionList(suggestions: []),
          ),
          throwsA(isA<MonacoJavaScriptError>()),
        );

        // The id is free again.
        final registration = await controller.registerCompletions(
          id: 'p1',
          languages: const [MonacoLanguage.dart],
          provider: (_) async => const CompletionList(suggestions: []),
        );
        expect(registration.id, 'p1');
      });
    });

    group('completion request handling', () {
      test('invokes provider and responds with suggestions', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);
        final requestCompleter = Completer<CompletionRequest>();

        await controller.registerCompletions(
          id: 'p1',
          languages: const [MonacoLanguage.dart],
          provider: (request) async {
            requestCompleter.complete(request);
            return const CompletionList(
              suggestions: [
                CompletionItem(
                  label: 'print',
                  kind: CompletionItemKind.functionType,
                  detail: 'Print to console',
                ),
                CompletionItem(
                  label: 'println',
                  kind: CompletionItemKind.functionType,
                ),
              ],
            );
          },
        );

        _emitCompletionRequest(webview, providerId: 'p1');
        await pumpEventQueue();

        final request = await requestCompleter.future;
        expect(request.providerId, 'p1');
        expect(request.requestId, 'req-1');
        expect(request.language, 'dart');
        expect(request.position.line, 1);
        expect(request.position.column, 2);

        final respond = _singleRespond(webview);
        expect(respond['id'], 'q1');
        expect(respond['ok'], isTrue);
        final suggestions = _suggestionsOf(respond);
        expect(suggestions, hasLength(2));
        final first = suggestions.first! as Map<String, Object?>;
        expect(first['label'], 'print');
        expect(first['kind'], 'Function');
        expect(first['detail'], 'Print to console');
      });

      test('receives trigger context', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);
        CompletionRequest? receivedRequest;

        await controller.registerCompletions(
          id: 'p1',
          languages: const [MonacoLanguage.dart],
          triggerCharacters: const ['.'],
          provider: (request) async {
            receivedRequest = request;
            return const CompletionList(suggestions: []);
          },
        );

        webview.emitRequest('q2', 'completion', {
          'providerId': 'p1',
          'requestId': 'req-2',
          'language': 'dart',
          'position': {'lineNumber': 5, 'column': 10},
          'defaultRange': {
            'startLineNumber': 5,
            'startColumn': 1,
            'endLineNumber': 5,
            'endColumn': 10,
          },
          'lineText': 'object.',
          'triggerKind': 2,
          'triggerCharacter': '.',
        });
        await pumpEventQueue();

        expect(receivedRequest, isNotNull);
        expect(receivedRequest!.lineText, 'object.');
        expect(receivedRequest!.triggerKind, 2);
        expect(receivedRequest!.triggerCharacter, '.');
      });

      test('unknown provider returns empty suggestions', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);

        // Register a provider but request from a different one.
        await controller.registerCompletions(
          id: 'registered',
          languages: const [MonacoLanguage.dart],
          provider: (_) async => const CompletionList(
            suggestions: [CompletionItem(label: 'should not appear')],
          ),
        );

        _emitCompletionRequest(webview, providerId: 'unknown');
        await pumpEventQueue();

        final respond = _singleRespond(webview);
        expect(respond['ok'], isTrue);
        expect(_suggestionsOf(respond), isEmpty);
      });

      test('provider exception returns empty suggestions', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);

        await controller.registerCompletions(
          id: 'p1',
          languages: const [MonacoLanguage.dart],
          provider: (_) async {
            throw StateError('Provider error');
          },
        );

        _emitCompletionRequest(webview, providerId: 'p1');
        await pumpEventQueue();

        final respond = _singleRespond(webview);
        expect(respond['ok'], isTrue);
        expect(_suggestionsOf(respond), isEmpty);
      });

      test('malformed request payload returns empty suggestions', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);

        await controller.registerCompletions(
          id: 'p1',
          languages: const [MonacoLanguage.dart],
          provider: (_) async =>
              const CompletionList(suggestions: [CompletionItem(label: 'x')]),
        );

        webview.emitRequest('q1', 'completion', {'providerId': 'p1'});
        await pumpEventQueue();

        final respond = _singleRespond(webview);
        expect(respond['ok'], isTrue);
        expect(_suggestionsOf(respond), isEmpty);
      });

      test('slow provider still sends a response', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);

        await controller.registerCompletions(
          id: 'p1',
          languages: const [MonacoLanguage.dart],
          provider: (_) async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return const CompletionList(
              suggestions: [CompletionItem(label: 'delayed')],
            );
          },
        );

        _emitCompletionRequest(webview, providerId: 'p1');

        await Future<void>.delayed(const Duration(milliseconds: 100));
        await pumpEventQueue();

        final respond = _singleRespond(webview);
        final suggestions = _suggestionsOf(respond);
        expect((suggestions.single! as Map)['label'], 'delayed');
      });
    });

    group('completion item serialization', () {
      test('all CompletionItem fields serialized', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);

        await controller.registerCompletions(
          id: 'p1',
          languages: const [MonacoLanguage.dart],
          provider: (_) async => const CompletionList(
            suggestions: [
              CompletionItem(
                label: 'testItem',
                insertText: 'testItem()',
                kind: CompletionItemKind.method,
                detail: 'A test method',
                documentation: 'Detailed documentation',
                sortText: '00001',
                filterText: 'test',
                range: Range(
                  startLine: 1,
                  startColumn: 1,
                  endLine: 1,
                  endColumn: 5,
                ),
                commitCharacters: ['(', '.'],
                insertTextRules: {InsertTextRule.insertAsSnippet},
              ),
            ],
            isIncomplete: true,
          ),
        );

        _emitCompletionRequest(webview, providerId: 'p1');
        await pumpEventQueue();

        final respond = _singleRespond(webview);
        final value = respond['value']! as Map<String, Object?>;
        expect(value['isIncomplete'], isTrue);
        final item = _suggestionsOf(respond).single! as Map<String, Object?>;
        expect(item['label'], 'testItem');
        expect(item['insertText'], 'testItem()');
        expect(item['kind'], 'Method');
        expect(item['detail'], 'A test method');
        expect(item['documentation'], 'Detailed documentation');
        expect(item['sortText'], '00001');
        expect(item['filterText'], 'test');
        expect(item['range'], {
          'startLineNumber': 1,
          'startColumn': 1,
          'endLineNumber': 1,
          'endColumn': 5,
        });
        expect(item['commitCharacters'], ['(', '.']);
        expect(item['insertTextRules'], ['InsertAsSnippet']);
      });

      test('all CompletionItemKind values serialized correctly', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);

        final allKinds = CompletionItemKind.values;
        final suggestions = allKinds
            .map((k) => CompletionItem(label: k.name, kind: k))
            .toList();

        await controller.registerCompletions(
          id: 'p1',
          languages: const [MonacoLanguage.dart],
          provider: (_) async => CompletionList(suggestions: suggestions),
        );

        _emitCompletionRequest(webview, providerId: 'p1');
        await pumpEventQueue();

        final serializedKinds = _suggestionsOf(_singleRespond(webview))
            .map((item) => (item! as Map<String, Object?>)['kind'])
            .toList();
        expect(serializedKinds, [for (final kind in allKinds) kind.jsonValue]);
      });
    });

    group('static completions', () {
      test('registerStaticCompletions returns items', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);

        await controller.registerStaticCompletions(
          id: 'static1',
          languages: const [MonacoLanguage.dart],
          items: const [
            CompletionItem(label: 'static1'),
            CompletionItem(label: 'static2'),
          ],
        );

        _emitCompletionRequest(webview, providerId: 'static1');
        await pumpEventQueue();

        final labels = _suggestionsOf(_singleRespond(webview))
            .map((item) => (item! as Map<String, Object?>)['label'])
            .toList();
        expect(labels, ['static1', 'static2']);
      });

      test('registerStaticCompletions with isIncomplete', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);

        await controller.registerStaticCompletions(
          id: 'static1',
          languages: const [MonacoLanguage.dart],
          items: const [CompletionItem(label: 'item')],
          isIncomplete: true,
        );

        _emitCompletionRequest(webview, providerId: 'static1');
        await pumpEventQueue();

        final value = _singleRespond(webview)['value']! as Map<String, Object?>;
        expect(value['isIncomplete'], isTrue);
      });
    });

    group('multiple providers', () {
      test('multiple providers for same language', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);
        final calls = <String>[];

        await controller.registerCompletions(
          id: 'p1',
          languages: const [MonacoLanguage.dart],
          provider: (_) async {
            calls.add('p1');
            return const CompletionList(
              suggestions: [CompletionItem(label: 'from_p1')],
            );
          },
        );

        await controller.registerCompletions(
          id: 'p2',
          languages: const [MonacoLanguage.dart],
          provider: (_) async {
            calls.add('p2');
            return const CompletionList(
              suggestions: [CompletionItem(label: 'from_p2')],
            );
          },
        );

        _emitCompletionRequest(webview, providerId: 'p1');
        await pumpEventQueue();
        expect(calls, ['p1']);

        _emitCompletionRequest(
          webview,
          providerId: 'p2',
          id: 'q2',
          requestId: 'req-2',
        );
        await pumpEventQueue();
        expect(calls, ['p1', 'p2']);
      });

      test('disposed provider stops receiving requests', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);
        var callCount = 0;

        final registration = await controller.registerCompletions(
          id: 'p1',
          languages: const [MonacoLanguage.dart],
          provider: (_) async {
            callCount++;
            return const CompletionList(suggestions: []);
          },
        );

        _emitCompletionRequest(webview, providerId: 'p1');
        await pumpEventQueue();
        expect(callCount, 1);

        await registration.dispose();

        _emitCompletionRequest(
          webview,
          providerId: 'p1',
          id: 'q2',
          requestId: 'req-2',
        );
        await pumpEventQueue();
        expect(callCount, 1); // Not incremented.

        // The dead provider still gets an (empty) answer.
        expect(webview.responded, hasLength(2));
        expect(_suggestionsOf(webview.responded.last), isEmpty);
      });
    });

    group('edge cases', () {
      test('handles concurrent requests', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);
        var completedCount = 0;

        await controller.registerCompletions(
          id: 'p1',
          languages: const [MonacoLanguage.dart],
          provider: (_) async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            completedCount++;
            return CompletionList(
              suggestions: [CompletionItem(label: 'result_$completedCount')],
            );
          },
        );

        // Fire multiple requests quickly.
        _emitCompletionRequest(webview, providerId: 'p1');
        _emitCompletionRequest(
          webview,
          providerId: 'p1',
          id: 'q2',
          requestId: 'req-2',
        );
        _emitCompletionRequest(
          webview,
          providerId: 'p1',
          id: 'q3',
          requestId: 'req-3',
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        await pumpEventQueue();

        expect(completedCount, 3);
        expect(webview.responded, hasLength(3));
        expect(webview.responded.map((r) => r['id']).toSet(), {
          'q1',
          'q2',
          'q3',
        });
      });

      test('empty suggestions list handled', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);

        await controller.registerCompletions(
          id: 'p1',
          languages: const [MonacoLanguage.dart],
          provider: (_) async => const CompletionList(suggestions: []),
        );

        _emitCompletionRequest(webview, providerId: 'p1');
        await pumpEventQueue();

        expect(_suggestionsOf(_singleRespond(webview)), isEmpty);
      });

      test('completion item omits null optional fields', () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);

        await controller.registerCompletions(
          id: 'p1',
          languages: const [MonacoLanguage.dart],
          provider: (_) async => const CompletionList(
            suggestions: [CompletionItem(label: 'minimal')],
          ),
        );

        _emitCompletionRequest(webview, providerId: 'p1');
        await pumpEventQueue();

        final item =
            _suggestionsOf(_singleRespond(webview)).single!
                as Map<String, Object?>;
        expect(item, {'label': 'minimal'});
      });

      test('unknown request name is answered with an error', () async {
        final webview = FakePlatformWebViewController();
        await _createController(webview);

        webview.emitRequest('q9', 'mystery', {});
        await pumpEventQueue();

        final respond = _singleRespond(webview);
        expect(respond['id'], 'q9');
        expect(respond['ok'], isFalse);
      });
    });
  });
}
