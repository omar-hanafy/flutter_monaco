import 'dart:io';

import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_platform_webview_controller.dart';

Future<List<String>> _loadActionValues() async {
  final file = File('lib/src/options/action.dart');
  if (!file.existsSync()) {
    throw StateError('action.dart not found');
  }
  final contents = await file.readAsString();
  final regex = RegExp(
    r"static const\s+\w+\s*=\s*MonacoAction\(\s*'([^']*)',?\s*\)",
    multiLine: true,
    dotAll: true,
  );
  final matches = regex.allMatches(contents).toList();
  if (matches.isEmpty) {
    throw StateError('No MonacoAction constants found');
  }
  final values = <String>[];
  for (final match in matches) {
    final value = match.group(1);
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
      expect(MonacoAction.formatDocument.id, 'editor.action.formatDocument');
      expect(MonacoAction.find.id, 'actions.find');
      expect(
        MonacoAction.startFindReplaceAction.id,
        'editor.action.startFindReplaceAction',
      );
      // Deprecated because standalone Monaco never registers it; the id is
      // unchanged.
      // ignore: deprecated_member_use_from_same_package
      expect(MonacoAction.toggleWordWrap.id, 'editor.action.toggleWordWrap');
      expect(MonacoAction.selectAll.id, 'editor.action.selectAll');
      expect(MonacoAction.undo.id, 'undo');
      expect(MonacoAction.redo.id, 'redo');
      expect(
        MonacoAction.clipboardCutAction.id,
        'editor.action.clipboardCutAction',
      );
      expect(
        MonacoAction.clipboardCopyAction.id,
        'editor.action.clipboardCopyAction',
      );
      expect(
        MonacoAction.clipboardPasteAction.id,
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
        await controller.executeAction(MonacoAction(actionId));
      }

      final executedIds = <String>{};
      // Every command rides the v3 wire as FlutterMonaco.dispatch with
      // method editor.executeAction and params {actionId, args}.
      for (final call in webview.dispatched) {
        if (call['method'] != 'editor.executeAction') continue;
        final params = call['params']! as Map<String, Object?>;
        executedIds.add(params['actionId']! as String);
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
