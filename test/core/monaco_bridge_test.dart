import 'package:flutter_monaco/src/core/monaco_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_platform_webview_controller.dart';

void main() {
  group('MonacoBridge', () {
    group('initialization', () {
      test('onReady completes once and ignores duplicates', () async {
        final bridge = MonacoBridge();
        bridge.handleJavaScriptMessage('{"event":"onEditorReady"}');
        await expectLater(bridge.onReady.future, completes);

        // Duplicate should not cause issues
        bridge.handleJavaScriptMessage('{"event":"onEditorReady"}');
        await expectLater(bridge.onReady.future, completes);
      });

      test('isDisposed returns correct state', () {
        final bridge = MonacoBridge();
        expect(bridge.isDisposed, false);
        bridge.dispose();
        expect(bridge.isDisposed, true);
      });
    });

    group('message handling', () {
      test('handles String messages', () {
        final bridge = MonacoBridge();
        bridge.handleJavaScriptMessage('{"event":"stats","lineCount":5}');
        expect(bridge.liveStats.value.lineCount.value, 5);
      });

      test('handles Map messages', () {
        final bridge = MonacoBridge();
        bridge.handleJavaScriptMessage({
          'event': 'stats',
          'lineCount': 3,
          'charCount': 10,
        });
        expect(bridge.liveStats.value.lineCount.value, 3);
        expect(bridge.liveStats.value.charCount.value, 10);
      });

      test('handles List messages gracefully', () {
        final bridge = MonacoBridge();
        // Lists should not crash, just not be processed as events
        bridge.handleJavaScriptMessage([
          {'event': 'stats'},
        ]);
        expect(bridge.liveStats.value.lineCount.value, 0); // Default
      });

      test('handles null messages gracefully', () {
        final bridge = MonacoBridge();
        expect(() => bridge.handleJavaScriptMessage(null), returnsNormally);
      });

      test('handles numeric messages gracefully', () {
        final bridge = MonacoBridge();
        expect(() => bridge.handleJavaScriptMessage(12345), returnsNormally);
      });

      test('handles malformed JSON gracefully', () {
        final bridge = MonacoBridge();
        expect(
          () => bridge.handleJavaScriptMessage('{invalid json}'),
          returnsNormally,
        );
      });

      test('handles log messages', () {
        final bridge = MonacoBridge();
        // Should not throw, just log
        expect(
          () => bridge.handleJavaScriptMessage('log:Test message'),
          returnsNormally,
        );
      });

      test('ignores messages after disposal', () {
        final bridge = MonacoBridge();
        bridge.dispose();
        // Should not throw or update state
        bridge.handleJavaScriptMessage('{"event":"stats","lineCount":99}');
        expect(bridge.liveStats.value.lineCount.value, 0);
      });
    });

    group('stats parsing', () {
      test('parses complete stats with cursor position', () {
        final bridge = MonacoBridge();
        bridge.handleJavaScriptMessage('''{
          "event": "stats",
          "lineCount": 10,
          "charCount": 250,
          "selLines": 2,
          "selChars": 15,
          "caretCount": 1,
          "cursorLine": 5,
          "cursorColumn": 12,
          "language": "dart"
        }''');

        final stats = bridge.liveStats.value;
        expect(stats.lineCount.value, 10);
        expect(stats.charCount.value, 250);
        expect(stats.selectedLines.value, 2);
        expect(stats.selectedCharacters.value, 15);
        expect(stats.caretCount.value, 1);
        expect(stats.cursorPosition?.label, '5:12');
        expect(stats.language, 'dart');
      });

      test('parses stats with missing optional fields', () {
        final bridge = MonacoBridge();
        bridge.handleJavaScriptMessage('{"event":"stats","lineCount":5}');

        final stats = bridge.liveStats.value;
        expect(stats.lineCount.value, 5);
        expect(stats.charCount.value, 0);
        expect(stats.cursorPosition, isNull);
        expect(stats.language, isNull);
      });

      test('handles stats with alternative key names', () {
        final bridge = MonacoBridge();
        bridge.handleJavaScriptMessage('''{
          "event": "stats",
          "lines": 7,
          "chars": 100,
          "selectedLines": 1,
          "selectedChars": 5
        }''');

        final stats = bridge.liveStats.value;
        expect(stats.lineCount.value, 7);
        expect(stats.charCount.value, 100);
        expect(stats.selectedLines.value, 1);
        expect(stats.selectedCharacters.value, 5);
      });
    });

    group('raw listeners', () {
      test('receives all events', () {
        final bridge = MonacoBridge();
        final received = <String>[];

        bridge.addRawListener((json) {
          received.add(json['event'] as String? ?? 'unknown');
        });

        bridge.handleJavaScriptMessage('{"event":"contentChanged"}');
        bridge.handleJavaScriptMessage('{"event":"selectionChanged"}');
        bridge.handleJavaScriptMessage('{"event":"focus"}');
        bridge.handleJavaScriptMessage('{"event":"blur"}');

        expect(received, [
          'contentChanged',
          'selectionChanged',
          'focus',
          'blur',
        ]);
      });

      test('isolates exceptions between listeners', () {
        final bridge = MonacoBridge();
        var successCalls = 0;

        bridge.addRawListener((_) {
          throw StateError('First listener error');
        });
        bridge.addRawListener((_) {
          successCalls++;
        });
        bridge.addRawListener((_) {
          throw StateError('Third listener error');
        });
        bridge.addRawListener((_) {
          successCalls++;
        });

        bridge.handleJavaScriptMessage('{"event":"test"}');
        expect(successCalls, 2);
      });

      test('can be removed', () {
        final bridge = MonacoBridge();
        var calls = 0;
        void listener(Map<String, dynamic> _) => calls++;

        bridge.addRawListener(listener);
        bridge.handleJavaScriptMessage('{"event":"test"}');
        expect(calls, 1);

        bridge.removeRawListener(listener);
        bridge.handleJavaScriptMessage('{"event":"test"}');
        expect(calls, 1); // Still 1, listener removed
      });

      test('not added after disposal', () {
        final bridge = MonacoBridge();
        bridge.dispose();

        var calls = 0;
        bridge.addRawListener((_) => calls++);
        bridge.handleJavaScriptMessage('{"event":"test"}');
        expect(calls, 0);
      });

      test('cleared on disposal', () {
        final bridge = MonacoBridge();
        var calls = 0;
        bridge.addRawListener((_) => calls++);

        bridge.dispose();
        // Even if we could process messages, listeners are cleared
        expect(calls, 0);
      });
    });

    group('disposal', () {
      test('completes onReady with error if not ready', () async {
        final bridge = MonacoBridge();
        bridge.dispose();
        await expectLater(bridge.onReady.future, throwsA(isA<StateError>()));
      });

      test('does not complete onReady with error if already ready', () async {
        final bridge = MonacoBridge();
        bridge.handleJavaScriptMessage('{"event":"onEditorReady"}');
        await bridge.onReady.future;

        bridge.dispose();
        // Should still be completed successfully
        await expectLater(bridge.onReady.future, completes);
      });

      test('is idempotent', () {
        final bridge = MonacoBridge();
        bridge.dispose();
        expect(() => bridge.dispose(), returnsNormally);
      });

      test('throws when attaching WebView after disposal', () {
        final bridge = MonacoBridge();
        bridge.dispose();

        expect(
          () => bridge.attachWebView(FakePlatformWebViewController()),
          throwsStateError,
        );
      });
    });

    group('event routing', () {
      test('routes error events', () {
        final bridge = MonacoBridge();
        // Should not throw, just log
        expect(
          () => bridge.handleJavaScriptMessage(
            '{"event":"error","message":"Test error"}',
          ),
          returnsNormally,
        );
      });

      test('routes unknown events', () {
        final bridge = MonacoBridge();
        var received = false;
        bridge.addRawListener((_) => received = true);

        bridge.handleJavaScriptMessage('{"event":"unknownEvent"}');
        expect(received, true);
      });

      test('handles message without event field', () {
        final bridge = MonacoBridge();
        var received = false;
        bridge.addRawListener((_) => received = true);

        bridge.handleJavaScriptMessage('{"data":"test"}');
        expect(received, true); // Still notifies raw listeners
      });
    });
  });
}
