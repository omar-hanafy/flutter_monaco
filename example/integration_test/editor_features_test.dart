import 'dart:async';

import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

/// Real-boot smoke for the v3 request channel and document registry.
///
/// Covers what the unit-test fakes cannot: Dart-defined actions and
/// completion providers riding the JS-to-Dart request channel of a real
/// bridge, the multi-document workflow against real Monaco models, and two
/// live editors with isolated channels in one widget tree.
///
/// Run with:
///   cd example && flutter test integration_test/editor_features_test.dart -d macos
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Dart action and completion provider round-trip a real bridge', (
    tester,
  ) async {
    final controller = await MonacoController.create(
      initialText: 'hello\n',
      options: const EditorOptions(language: MonacoLanguage.plaintext),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MonacoEditor(controller: controller)),
      ),
    );
    await controller.whenReady;
    expect(controller.isReady, isTrue);

    // Dart-defined action (D16): registering runs the JS keybinding
    // encoder for real; executeAction triggers the Monaco action, whose
    // run() calls back into Dart over the request channel.
    final actionRan = Completer<void>();
    final action = await controller.addAction(
      MonacoActionDescriptor(
        id: const MonacoAction('probe.save'),
        label: 'Probe Save',
        keybindings: const [
          MonacoKeybinding(key: MonacoKey.keyS, ctrlCmd: true),
        ],
      ),
      () async {
        if (!actionRan.isCompleted) actionRan.complete();
      },
    );
    await controller.executeAction(const MonacoAction('probe.save'));
    await actionRan.future.timeout(const Duration(seconds: 10));
    await action.dispose();

    // Completion provider: triggerSuggest makes real Monaco query the Dart
    // provider over the same request channel.
    final providerAsked = Completer<void>();
    final completions = await controller.registerCompletions(
      languages: [MonacoLanguage.plaintext],
      provider: (request) async {
        if (!providerAsked.isCompleted) providerAsked.complete();
        return const CompletionList(
          suggestions: [CompletionItem(label: 'probe_completion')],
        );
      },
    );
    addTearDown(completions.dispose);

    // Suggest only queries providers on a focused editor; retry with real
    // wall-clock delays (pump does not wait real time under this binding).
    for (var i = 0; i < 20 && !providerAsked.isCompleted; i++) {
      await controller.requestFocus(intent: MonacoFocusIntent.user);
      await controller.executeAction(
        const MonacoAction('editor.action.triggerSuggest'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await tester.pump();
    }
    expect(
      providerAsked.isCompleted,
      isTrue,
      reason: 'completion provider was never queried over the bridge',
    );
  });

  testWidgets('multi-document workflow round-trips a real bridge', (
    tester,
  ) async {
    final controller = await MonacoController.create();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MonacoEditor(controller: controller)),
      ),
    );
    await controller.whenReady;

    final noteDoc = await controller.openDocument(
      text: 'alpha content',
      language: MonacoLanguage.markdown,
      uri: Uri.parse('file:///probe/a.md'),
    );
    final codeDoc = await controller.openDocument(
      text: 'const b = 1;\n',
      language: MonacoLanguage.javascript,
      uri: Uri.parse('file:///probe/b.js'),
    );

    await controller.activateDocument(noteDoc);
    expect(await controller.document.getText(), 'alpha content');

    // A pinned handle edits its model even while another document is
    // active. setText is a clean programmatic load (it re-baselines dirty
    // tracking); real edits flip isDirty until markSaved.
    await codeDoc.setText('const b = 2;\n');
    expect(await codeDoc.getText(), 'const b = 2;\n');
    expect(await codeDoc.isDirty(), isFalse);

    await codeDoc.insert(const Position(line: 1, column: 1), '// edited\n');
    expect(await codeDoc.getText(), '// edited\nconst b = 2;\n');
    expect(await codeDoc.isDirty(), isTrue);
    expect(await noteDoc.isDirty(), isFalse);

    await codeDoc.markSaved();
    expect(await codeDoc.isDirty(), isFalse);
    await codeDoc.setText('const b = 2;\n');

    await controller.activateDocument(codeDoc);
    expect(await controller.document.getText(), 'const b = 2;\n');

    final uris = [
      for (final doc in await controller.listDocuments()) '${doc.uri}',
    ];
    expect(uris, containsAll(['file:///probe/a.md', 'file:///probe/b.js']));

    await noteDoc.close();
    final urisAfterClose = [
      for (final doc in await controller.listDocuments()) '${doc.uri}',
    ];
    expect(urisAfterClose, isNot(contains('file:///probe/a.md')));
    expect(urisAfterClose, contains('file:///probe/b.js'));
  });

  testWidgets('two editors in one tree keep isolated channels', (tester) async {
    final first = await MonacoController.create(initialText: 'first');
    addTearDown(first.dispose);
    final second = await MonacoController.create(initialText: 'second');
    addTearDown(second.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(child: MonacoEditor(controller: first)),
              Expanded(child: MonacoEditor(controller: second)),
            ],
          ),
        ),
      ),
    );
    await Future.wait([first.whenReady, second.whenReady]);

    expect(await first.document.getText(), 'first');
    expect(await second.document.getText(), 'second');

    // Writes through one channel must not leak into the other.
    await first.document.setText('first edited');
    expect(await first.document.getText(), 'first edited');
    expect(await second.document.getText(), 'second');
  });
}
