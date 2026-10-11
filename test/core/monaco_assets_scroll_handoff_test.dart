import 'package:flutter_test/flutter_test.dart';

import '../helpers/bridge_sources.dart';
import '../helpers/generate_index_html.dart';

/// Source-level tests for the edge scroll handoff JS bridge module. These
/// assert the contract Dart depends on: the toggle entry point, listener
/// registration flags, input guards, and the bridge event shape.
void main() {
  final html = bridgeSource('scroll-handoff.js');

  group('generated scroll handoff module', () {
    test('defines the flutterMonaco.setScrollHandoff toggle exactly once', () {
      expect('setScrollHandoff'.allMatches(html).length, greaterThan(0));
      expect(
        'window.flutterMonaco.setScrollHandoff = '.allMatches(html).length,
        1,
      );
      // The module script is referenced on every platform variant.
      for (final pageHtml in [
        generateIndexHtml('min/vs'),
        generateIndexHtml(
          'http://localhost/assets/monaco/min/vs',
          isWeb: true,
          messageToken: 'token-1',
        ),
      ]) {
        expect(pageHtml, contains('scroll-handoff.js'));
      }
    });

    test('wheel listener is capture-phase and non-passive', () {
      expect(html, contains('{ capture: true, passive: false }'));
      expect(html, contains("addEventListener('wheel'"));
      expect(html, contains("removeEventListener('wheel'"));
    });

    test('touch listeners are observation-only (passive)', () {
      final start = html.indexOf('const gestureTouch');
      final end = html.indexOf('window.flutterMonaco.setScrollHandoff');
      expect(start, isNonNegative);
      expect(end, greaterThan(start));
      final touchRegion = html.substring(start, end);
      expect(touchRegion, contains('passive: true'));
      expect(touchRegion, isNot(contains('preventDefault')));
      expect(touchRegion, isNot(contains('stopPropagation')));
      expect(touchRegion, isNot(contains('.focus(')));
    });

    test('ctrl and meta wheel input is never handed off', () {
      expect(html, contains('event.ctrlKey || event.metaKey'));
    });

    test('normalizes wheel deltaMode for line and page units', () {
      expect(html, contains('event.deltaMode'));
      expect(html, contains('lineHeight'));
    });

    test('respects a disabled Monaco mouse wheel', () {
      expect(html, contains('handleMouseWheel'));
    });

    test('only the main editor scroll region may hand off', () {
      expect(html, contains('editor-scrollable'));
      expect(html, contains('.monaco-scrollable-element'));
      expect(html, contains('.suggest-widget'));
      expect(html, contains('.monaco-hover'));
      expect(html, contains('.context-view'));
      expect(html, contains('.peekview-widget'));
    });

    test('posts the scrollHandoff event through the shared post helper', () {
      expect(html, contains("post('scrollHandoff'"));
      expect(html, contains('atTop'));
      expect(html, contains('atBottom'));
    });

    test('registers the page.setScrollHandoff command on the v3 wire', () {
      expect(
        html,
        contains("window.FlutterMonaco.register('page.setScrollHandoff'"),
      );
      // The adapter must delegate to the single toggle definition.
      expect(html, contains('window.flutterMonaco.setScrollHandoff({'));
    });

    test('touch forwarding yields to text selection', () {
      final start = html.indexOf('const gestureTouch');
      final end = html.indexOf('window.flutterMonaco.setScrollHandoff');
      expect(start, isNonNegative);
      expect(end, greaterThan(start));
      final touchRegion = html.substring(start, end);
      expect(touchRegion, contains('onDidChangeCursorSelection'));
      expect(touchRegion, contains('gesture.cancelled = true'));
    });
  });
}
