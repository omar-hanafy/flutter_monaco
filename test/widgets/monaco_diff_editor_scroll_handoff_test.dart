import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../fakes/fake_platform_webview_controller.dart';

class _Bundle {
  _Bundle(this.controller, this.webview);

  final MonacoDiffController controller;
  final FakePlatformWebViewController webview;
}

Future<_Bundle> _createBundle() async {
  final webview = FakePlatformWebViewController(
    widget: const SizedBox(key: Key('webview')),
  );
  final controller = await MonacoDiffController.createForTesting(
    webViewController: webview,
  );
  return _Bundle(controller, webview);
}

void _emitHandoff(
  FakePlatformWebViewController webview, {
  String source = 'wheel',
  double deltaY = 40,
  bool atTop = false,
  bool atBottom = true,
}) {
  webview.emitEvent('scrollHandoff', {
    'source': source,
    'deltaX': 0,
    'deltaY': deltaY,
    'atTop': atTop,
    'atBottom': atBottom,
    'atLeft': true,
    'atRight': true,
  });
}

/// Delivers pending broadcast-stream events, then runs the coalescing
/// frame callback.
Future<void> _settleHandoff(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Widget _diffInScrollView({
  required MonacoDiffController controller,
  required ScrollController scrollController,
  MonacoScrollHandoff scrollHandoff = const MonacoScrollHandoff.disabled(),
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          children: [
            SizedBox(
              height: 300,
              child: MonacoDiffEditor(
                controller: controller,
                scrollHandoff: scrollHandoff,
              ),
            ),
            const SizedBox(height: 3000, width: 100),
          ],
        ),
      ),
    ),
  );
}

/// Pumps until the diff editor's async bootstrap (whenReady + post-ready
/// option pushes) has completed and the handoff wiring is live.
Future<void> _pumpReady(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pump();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MonacoDiffEditor scroll handoff', () {
    testWidgets('wheel handoff scrolls the enclosing scrollable', (
      tester,
    ) async {
      final bundle = await _createBundle();
      addTearDown(bundle.controller.dispose);
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await _pumpReady(
        tester,
        _diffInScrollView(
          controller: bundle.controller,
          scrollController: scrollController,
          scrollHandoff: const MonacoScrollHandoff.edge(),
        ),
      );

      _emitHandoff(bundle.webview, deltaY: 50);
      await _settleHandoff(tester);

      expect(scrollController.offset, 50);
    });

    testWidgets('scrolling clamps to the scrollable extents', (tester) async {
      final bundle = await _createBundle();
      addTearDown(bundle.controller.dispose);
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await _pumpReady(
        tester,
        _diffInScrollView(
          controller: bundle.controller,
          scrollController: scrollController,
          scrollHandoff: const MonacoScrollHandoff.edge(),
        ),
      );

      _emitHandoff(bundle.webview, deltaY: 999999);
      await _settleHandoff(tester);
      expect(
        scrollController.offset,
        scrollController.position.maxScrollExtent,
      );

      _emitHandoff(bundle.webview, deltaY: -999999, atTop: true);
      await _settleHandoff(tester);
      expect(scrollController.offset, 0);
    });

    testWidgets('disabled config ignores handoff events entirely', (
      tester,
    ) async {
      final bundle = await _createBundle();
      addTearDown(bundle.controller.dispose);
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await _pumpReady(
        tester,
        _diffInScrollView(
          controller: bundle.controller,
          scrollController: scrollController,
        ),
      );

      _emitHandoff(bundle.webview, deltaY: 50);
      await _settleHandoff(tester);

      expect(scrollController.offset, 0);
      bundle.webview.assertNotExecuted('page.setScrollHandoff');
    });

    testWidgets('touch deltas are ignored unless mobileTouch is enabled', (
      tester,
    ) async {
      final bundle = await _createBundle();
      addTearDown(bundle.controller.dispose);
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await _pumpReady(
        tester,
        _diffInScrollView(
          controller: bundle.controller,
          scrollController: scrollController,
          scrollHandoff: const MonacoScrollHandoff.edge(),
        ),
      );

      _emitHandoff(bundle.webview, source: 'touch', deltaY: 50);
      await _settleHandoff(tester);
      expect(scrollController.offset, 0);

      await tester.pumpWidget(
        _diffInScrollView(
          controller: bundle.controller,
          scrollController: scrollController,
          scrollHandoff: const MonacoScrollHandoff.edge(mobileTouch: true),
        ),
      );
      await tester.pump();

      _emitHandoff(bundle.webview, source: 'touch', deltaY: 50);
      await _settleHandoff(tester);
      expect(scrollController.offset, 50);
    });

    testWidgets('an explicit controller wins over the enclosing scrollable', (
      tester,
    ) async {
      final bundle = await _createBundle();
      addTearDown(bundle.controller.dispose);
      final enclosingController = ScrollController();
      addTearDown(enclosingController.dispose);
      final explicitController = ScrollController();
      addTearDown(explicitController.dispose);

      await _pumpReady(
        tester,
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: enclosingController,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: MonacoDiffEditor(
                            controller: bundle.controller,
                            scrollHandoff: MonacoScrollHandoff.edge(
                              controller: explicitController,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2000, width: 100),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: SingleChildScrollView(
                    controller: explicitController,
                    child: const SizedBox(height: 2000, width: 100),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      _emitHandoff(bundle.webview, deltaY: 60);
      await _settleHandoff(tester);

      expect(explicitController.offset, 60);
      expect(enclosingController.offset, 0);
    });

    testWidgets('onHandoff returning true consumes the delta', (tester) async {
      final bundle = await _createBundle();
      addTearDown(bundle.controller.dispose);
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      final seen = <MonacoScrollHandoffDetails>[];

      await _pumpReady(
        tester,
        _diffInScrollView(
          controller: bundle.controller,
          scrollController: scrollController,
          scrollHandoff: MonacoScrollHandoff.edge(
            onHandoff: (details) {
              seen.add(details);
              return true;
            },
          ),
        ),
      );

      _emitHandoff(bundle.webview, deltaY: 50);
      await _settleHandoff(tester);

      expect(seen, hasLength(1));
      expect(seen.single.deltaY, 50);
      expect(scrollController.offset, 0);
    });

    testWidgets('drops deltas silently when no target resolves', (
      tester,
    ) async {
      final bundle = await _createBundle();
      addTearDown(bundle.controller.dispose);

      // No enclosing scrollable and no explicit controller.
      await _pumpReady(
        tester,
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: MonacoDiffEditor(
                controller: bundle.controller,
                scrollHandoff: const MonacoScrollHandoff.edge(),
              ),
            ),
          ),
        ),
      );

      _emitHandoff(bundle.webview, deltaY: 50);
      await _settleHandoff(tester);
      // Nothing to assert beyond "no crash": the delta had nowhere to go.
    });

    testWidgets('same-frame deltas coalesce into one scroll application', (
      tester,
    ) async {
      final bundle = await _createBundle();
      addTearDown(bundle.controller.dispose);
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await _pumpReady(
        tester,
        _diffInScrollView(
          controller: bundle.controller,
          scrollController: scrollController,
          scrollHandoff: const MonacoScrollHandoff.edge(),
        ),
      );

      var notifications = 0;
      scrollController.position.addListener(() => notifications++);

      _emitHandoff(bundle.webview, deltaY: 10);
      _emitHandoff(bundle.webview, deltaY: 15);
      _emitHandoff(bundle.webview, deltaY: 25);
      await _settleHandoff(tester);

      expect(scrollController.offset, 50);
      expect(notifications, 1);
    });

    testWidgets('syncs JS sources on enable and on rebuild to disabled', (
      tester,
    ) async {
      final bundle = await _createBundle();
      addTearDown(bundle.controller.dispose);
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await _pumpReady(
        tester,
        _diffInScrollView(
          controller: bundle.controller,
          scrollController: scrollController,
          scrollHandoff: const MonacoScrollHandoff.edge(),
        ),
      );

      var scripts = bundle.webview.scriptsContaining('page.setScrollHandoff');
      expect(scripts, hasLength(1));
      expect(scripts.single, contains('"wheel":true'));
      expect(scripts.single, contains('"touch":false'));
      expect(scripts.single, contains('"policy":"newGestureOnly"'));

      await tester.pumpWidget(
        _diffInScrollView(
          controller: bundle.controller,
          scrollController: scrollController,
          scrollHandoff: const MonacoScrollHandoff.edge(
            policy: MonacoScrollBoundaryPolicy.continuous,
          ),
        ),
      );
      await tester.pump();

      scripts = bundle.webview.scriptsContaining('page.setScrollHandoff');
      expect(
        scripts,
        hasLength(2),
        reason: 'a policy change alone must re-sync the page',
      );
      expect(scripts.last, contains('"policy":"continuous"'));

      await tester.pumpWidget(
        _diffInScrollView(
          controller: bundle.controller,
          scrollController: scrollController,
        ),
      );
      await tester.pump();

      scripts = bundle.webview.scriptsContaining('page.setScrollHandoff');
      expect(scripts, hasLength(3));
      expect(scripts.last, contains('"wheel":false'));

      // Behavioral: after disabling, deltas no longer move the parent.
      _emitHandoff(bundle.webview, deltaY: 50);
      await _settleHandoff(tester);
      expect(scrollController.offset, 0);
    });

    testWidgets(
      'removing the diff editor disables sources on an external controller',
      (tester) async {
        final bundle = await _createBundle();
        addTearDown(bundle.controller.dispose);
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);

        await _pumpReady(
          tester,
          _diffInScrollView(
            controller: bundle.controller,
            scrollController: scrollController,
            scrollHandoff: const MonacoScrollHandoff.edge(),
          ),
        );
        expect(
          bundle.webview.scriptsContaining('page.setScrollHandoff'),
          hasLength(1),
        );

        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await tester.pump();

        final scripts = bundle.webview.scriptsContaining(
          'page.setScrollHandoff',
        );
        expect(scripts, hasLength(2));
        expect(scripts.last, contains('"wheel":false'));
        expect(scripts.last, contains('"touch":false'));
      },
    );
  });
}
