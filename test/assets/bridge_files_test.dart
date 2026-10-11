import 'dart:io';

import 'package:flutter_monaco/src/assets/html_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bridge_sources.dart';

/// Structural checks for the bridge JavaScript assets: every file the HTML
/// template references must exist, be non-trivial UTF-8, and carry the
/// installer markers `boot.js` invokes.
void main() {
  group('bridge asset files', () {
    test('every referenced bridge file exists and is non-trivial', () {
      for (final name in bridgeFileNames) {
        final file = File('assets/monaco/bridge/$name');
        expect(file.existsSync(), isTrue, reason: '$name is missing');
        final content = file.readAsStringSync();
        expect(
          content.length,
          greaterThan(500),
          reason: '$name looks truncated',
        );
      }
    });

    test('html template references every bridge file, boot.js last', () {
      final html = buildMonacoIndexHtml(
        vsPath: 'min/vs',
        bridgeBase: 'bridge',
        monacoVersion: '0.57.0',
        isWeb: true,
        messageToken: 'token',
      );
      var previousIndex = -1;
      for (final name in bridgeFileNames) {
        final index = html.indexOf('bridge/$name');
        expect(index, isNonNegative, reason: '$name not referenced');
        expect(
          index,
          greaterThan(previousIndex),
          reason: '$name out of load order',
        );
        previousIndex = index;
      }
    });

    test('installer functions match what boot.js invokes', () {
      const installers = {
        'core.js': ['window.__FMB.core = function (ctx)'],
        'focus.js': [
          'window.__FMB.focusHelpers = function (ctx)',
          'window.__FMB.focusMobile = function (ctx)',
        ],
        'editor-api.js': [
          'window.__FMB.editorApi = function (ctx)',
          'window.__FMB.completions = function (ctx)',
        ],
        'scroll-handoff.js': ['window.__FMB.scrollHandoff = function (ctx)'],
        'lsp.js': ['window.__FMB.lsp = function (ctx)'],
        'viewport-fit.js': ['window.__FMB.viewportFit = function (ctx)'],
      };
      installers.forEach((file, markers) {
        final source = bridgeSource(file);
        for (final marker in markers) {
          expect(source, contains(marker), reason: '$file lacks $marker');
        }
      });

      final boot = bridgeSource('boot.js');
      for (final call in [
        'FMB.core(ctx)',
        'FMB.focusHelpers(ctx)',
        'FMB.editorApi(ctx)',
        'FMB.focusMobile(ctx)',
        'if (FMB.viewportFit) FMB.viewportFit(ctx)',
        'FMB.completions(ctx)',
        'FMB.scrollHandoff(ctx)',
        'FMB.lsp(ctx)',
      ]) {
        expect(boot, contains(call), reason: 'boot.js lacks $call');
      }
    });

    test('diff boot wires edge scroll handoff over both panes', () {
      // The diff path drives the handoff module with the modified editor as
      // the vertical scroll master and a scope that accepts both panes.
      final boot = bridgeSource('boot.js');
      for (final marker in [
        'diffCtx.bootDiff(params)',
        'window.diffEditor.getModifiedEditor()',
        'diffCtx.handoffScope',
        '.scrollHandoff(diffCtx)',
      ]) {
        expect(boot, contains(marker), reason: 'boot.js lacks $marker');
      }

      final handoff = bridgeSource('scroll-handoff.js');
      for (final marker in [
        'ctx.handoffScope || null',
        'handoffScope.regionRoot',
        'handoffScope.editorDoms',
        // Diff pages never run core.js, so the module must create the
        // legacy namespace before assigning the toggle onto it.
        'window.flutterMonaco = window.flutterMonaco || {}',
      ]) {
        expect(
          handoff,
          contains(marker),
          reason: 'scroll-handoff.js lacks $marker',
        );
      }
    });
  });
}
