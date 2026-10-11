import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/dom_probe.dart';

void main() {
  testWidgets('does not read the overlay size before first layout', (
    tester,
  ) async {
    final errors = <FlutterErrorDetails>[];
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = errors.add;

    try {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: _SkipChildLayout(
            child: MonacoOverlayBoundary(
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(
        errors,
        isEmpty,
        reason:
            'Overlay sync must tolerate an unlaid-out RenderBox:\n'
            '${errors.map((error) => error.exceptionAsString()).join('\n')}',
      );
    } finally {
      FlutterError.onError = previousErrorHandler;
    }
  }, skip: !kIsWeb);

  group('when the Flutter view is offset inside the page', () {
    // Flutter's global coordinates are relative to the view, while the
    // shield is a viewport-fixed DOM element compared against iframe
    // viewport rects. An app embedded into a larger page (element
    // embedding, multi-view) starts its view away from the viewport origin.
    const hostOffset = Offset(37, 53);
    const overlayInView = Rect.fromLTWH(10, 20, 40, 30);

    Future<Offset> pumpOffsetOverlay(WidgetTester tester) async {
      // Logical pixels are CSS pixels on the web.
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 600);
      addTearDown(tester.view.reset);
      addTearDown(shiftFlutterViewHost(tester.view.viewId, hostOffset));
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(
            padding: EdgeInsets.only(
              left: overlayInView.left,
              top: overlayInView.top,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox.fromSize(
                size: overlayInView.size,
                child: const MonacoOverlayBoundary(child: SizedBox.expand()),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return flutterViewViewportOrigin(tester.view.viewId);
    }

    testWidgets('places the shield over the overlay in viewport '
        'coordinates', (tester) async {
      final origin = await pumpOffsetOverlay(tester);
      expect(origin, hostOffset);

      expect(overlayShieldViewportRects(), [overlayInView.shift(origin)]);
    }, skip: !kIsWeb);

    testWidgets('hovering the overlay locks the editor iframe under it', (
      tester,
    ) async {
      final origin = await pumpOffsetOverlay(tester);
      // An editor iframe exactly under the overlay as the user sees it.
      final editor = addProbeEditor(
        'probe-editor-under-offset-overlay',
        overlayInView.shift(origin),
      );
      addTearDown(editor.remove);
      expect(editor.pointerEvents(), 'auto');

      hoverOverlayShields();

      expect(editor.pointerEvents(), 'none');
    }, skip: !kIsWeb);
  });
}

class _SkipChildLayout extends SingleChildRenderObjectWidget {
  const _SkipChildLayout({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSkipChildLayout();
  }
}

class _RenderSkipChildLayout extends RenderProxyBox {
  @override
  void performLayout() {
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {}

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {}
}
