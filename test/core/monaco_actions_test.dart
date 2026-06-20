import 'dart:convert';
import 'dart:io';

import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_platform_webview_controller.dart';

Future<List<String>> _loadActionValues() async {
  final file = File('lib/src/core/monaco_actions.dart');
  if (!await file.exists()) {
    throw StateError('monaco_actions.dart not found');
  }
  final contents = await file.readAsString();
  final regex = RegExp(
    r"static const String\s+(\w+)\s*=\s*'([^']*)';",
    multiLine: true,
    dotAll: true,
  );
  final matches = regex.allMatches(contents).toList();
  if (matches.isEmpty) {
    throw StateError('No MonacoAction constants found');
  }
  final values = <String>[];
  for (final match in matches) {
    final value = match.group(2);
    if (value == null || value.isEmpty) {
      throw StateError('MonacoAction value missing');
    }
    values.add(value);
  }
  return values;
}

void main() {
  group('MonacoAction', () {
    test('all action constants are non-empty and unique', () async {
      final values = await _loadActionValues();
      expect(values, isNotEmpty);
      final unique = values.toSet();
      expect(unique.length, values.length);
    });

    test('core action ids match expected values', () {
      expect(MonacoAction.formatDocument, 'editor.action.formatDocument');
      expect(MonacoAction.find, 'actions.find');
      expect(
        MonacoAction.startFindReplaceAction,
        'editor.action.startFindReplaceAction',
      );
      expect(MonacoAction.toggleWordWrap, 'editor.action.toggleWordWrap');
      expect(MonacoAction.selectAll, 'editor.action.selectAll');
      expect(MonacoAction.undo, 'undo');
      expect(MonacoAction.redo, 'redo');
      expect(
        MonacoAction.clipboardCutAction,
        'editor.action.clipboardCutAction',
      );
      expect(
        MonacoAction.clipboardCopyAction,
        'editor.action.clipboardCopyAction',
      );
      expect(
        MonacoAction.clipboardPasteAction,
        'editor.action.clipboardPasteAction',
      );
    });

    test('executeAction accepts every MonacoAction id', () async {
      final values = await _loadActionValues();
      final webview = FakePlatformWebViewController();
      final controller = await MonacoController.createForTesting(
        webViewController: webview,
        markReady: true,
      );

      for (final actionId in values) {
        await controller.executeAction(actionId);
      }

      final executedIds = <String>{};
      // The envelope dispatcher invokes flutterMonaco.executeAction via
      // window.flutterMonacoInvoke("executeAction", [<id>, <args>]).
      final regex = RegExp(
        r'flutterMonacoInvoke\("executeAction",\s*\[(".*?")',
      );
      for (final script in webview.executed) {
        final match = regex.firstMatch(script);
        if (match == null) continue;
        executedIds.add(jsonDecode(match.group(1)!));
      }

      for (final actionId in values) {
        expect(
          executedIds.contains(actionId),
          true,
          reason: 'Missing action id: $actionId',
        );
      }
    });
  });
}
