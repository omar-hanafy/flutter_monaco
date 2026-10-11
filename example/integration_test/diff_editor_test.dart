import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

/// Real-boot smoke for the diff editor page mode (Phase 11).
///
/// Boots a real WebView with `page.boot mode: 'diff'` and proves the
/// diff.* command registry round-trips: texts land in both models, the
/// line-change count reflects a real Monaco diff computation, and
/// setTexts/getModifiedText work end to end.
///
/// Run with:
///   cd example && flutter test integration_test/diff_editor_test.dart -d macos
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('diff mode boots and diff.* commands round-trip', (tester) async {
    final controller = await MonacoDiffController.create(
      original: 'line one\nline two\n',
      modified: 'line one\nline 2\nline three\n',
      language: MonacoLanguage.plaintext,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MonacoDiffEditor(controller: controller)),
      ),
    );
    await controller.whenReady;
    expect(controller.isReady, isTrue);

    expect(
      await controller.getModifiedText(),
      'line one\nline 2\nline three\n',
    );

    // Monaco computes the diff asynchronously; poll with real wall-clock
    // delays (tester.pump does not wait real time under the live binding).
    var changes = 0;
    for (var i = 0; i < 40; i++) {
      changes = await controller.getLineChangeCount();
      if (changes > 0) break;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await tester.pump();
    }
    expect(changes, greaterThan(0));

    await controller.setTexts(
      original: 'same',
      modified: 'same',
      language: MonacoLanguage.markdown,
    );
    expect(await controller.getModifiedText(), 'same');

    await controller.revealNextChange();
    await controller.revealPreviousChange();
    await controller.updateDiffOptions(
      const MonacoDiffOptions(renderSideBySide: false),
    );
    await controller.setTheme(MonacoTheme.vs);
  });
}
