import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/ai_extension_behavior_runner.dart';

void main() {
  final repositoryRoot = _findRepositoryRoot();
  final cases = loadEvaluationCases(repositoryRoot);

  test('natural-discovery prompts do not leak skill names', () {
    for (final evaluationCase in cases.where(
      (entry) => entry['kind'] != 'execution',
    )) {
      final skill = evaluationCase['skill']! as String;
      expect(
        buildEvaluationPrompt(evaluationCase, AiEvaluationClient.codex),
        isNot(contains('\$$skill')),
        reason: evaluationCase['id']! as String,
      );
      expect(
        buildEvaluationPrompt(evaluationCase, AiEvaluationClient.claude),
        isNot(contains('/flutter-monaco:$skill')),
        reason: evaluationCase['id']! as String,
      );
    }
  });

  test('execution prompts use each client native explicit invocation', () {
    for (final evaluationCase in cases.where(
      (entry) => entry['kind'] == 'execution',
    )) {
      final skill = evaluationCase['skill']! as String;
      expect(
        buildEvaluationPrompt(evaluationCase, AiEvaluationClient.codex),
        startsWith('\$$skill\n\n'),
      );
      expect(
        buildEvaluationPrompt(evaluationCase, AiEvaluationClient.claude),
        startsWith('/flutter-monaco:$skill\n\n'),
      );
    }
  });

  test('runner requires an explicit case selection', () {
    expect(
      () => parseBehaviorRunnerOptions(['--client', 'claude']),
      throwsFormatException,
    );
    expect(
      () => parseBehaviorRunnerOptions(['--all', '--case', 'one']),
      throwsFormatException,
    );
    expect(
      () => parseBehaviorRunnerOptions([
        '--client',
        'claude',
        '--case',
        'integrate-positive-selection',
      ]),
      throwsFormatException,
    );
    expect(
      () => parseBehaviorRunnerOptions([
        '--client',
        'codex',
        '--case',
        'integrate-positive-selection',
      ]),
      throwsFormatException,
    );
  });

  test('runner normalizes Codex home and validates the case timeout', () {
    final options = parseBehaviorRunnerOptions([
      '--client',
      'codex',
      '--case',
      'integrate-positive-selection',
      '--codex-home',
      'isolated-codex-home',
      '--case-timeout-seconds',
      '17',
    ]);

    expect(
      options.codexHomePath,
      Directory('isolated-codex-home').absolute.path,
    );
    expect(options.caseTimeout, const Duration(seconds: 17));
    expect(
      () => parseBehaviorRunnerOptions([
        '--client',
        'claude',
        '--case',
        'integrate-positive-selection',
        '--claude-config-dir',
        'isolated-claude-config',
        '--case-timeout-seconds',
        '0',
      ]),
      throwsFormatException,
    );
  });

  test('Claude runs without user settings, hooks, or MCP servers', () {
    final arguments = buildClaudeArguments(
      prompt: 'Inspect the fixture.',
      execution: false,
      budgetUsd: 0.75,
      model: 'sonnet',
    );

    expect(arguments, containsAllInOrder(['--setting-sources', 'user']));
    expect(arguments, contains('--strict-mcp-config'));
    expect(arguments, contains('{"mcpServers":{}}'));
    expect(arguments, contains('--no-session-persistence'));
    expect(arguments, containsAllInOrder(['--permission-mode', 'dontAsk']));
    expect(arguments, containsAllInOrder(['--model', 'sonnet']));
    expect(arguments, isNot(contains('--allowedTools')));
    final environment = buildClaudeEnvironment('/tmp/isolated-claude');
    expect(environment['CLAUDE_CONFIG_DIR'], '/tmp/isolated-claude');
    expect(environment['CLAUDE_CODE_DISABLE_AUTO_MEMORY'], '1');
    expect(arguments, isNot(contains('--plugin-dir')));
    expect(arguments, isNot(contains('Task')));
  });

  test('Claude execution preapproves only focused verification commands', () {
    final arguments = buildClaudeArguments(
      prompt: 'Repair and verify the fixture.',
      execution: true,
      budgetUsd: 0.75,
      model: 'sonnet',
    );
    final allowedToolsIndex = arguments.indexOf('--allowedTools');

    expect(allowedToolsIndex, greaterThanOrEqualTo(0));
    final allowedTools = arguments[allowedToolsIndex + 1];
    expect(allowedTools, contains('Bash(dart analyze)'));
    expect(allowedTools, contains('Bash(flutter test)'));
    expect(
      allowedTools,
      contains('Bash(node --test tool/bridge_tests/*_test.mjs)'),
    );
    expect(allowedTools, isNot(contains('Bash(*)')));
    expect(arguments, containsAllInOrder(['--permission-mode', 'acceptEdits']));
  });

  test('behavior subprocesses terminate at the per-case timeout', () async {
    final fixture = await Directory.systemTemp.createTemp(
      'flutter-monaco-timeout-test-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));
    final script = File.fromUri(fixture.uri.resolve('wait.dart'))
      ..writeAsStringSync('''
Future<void> main() async {
  await Future<void>.delayed(const Duration(seconds: 30));
}
''');

    final result = await runBehaviorProcess(
      'dart',
      [script.path],
      workingDirectory: fixture.path,
      timeout: const Duration(milliseconds: 100),
    );

    expect(result.exitCode, 124);
    expect(result.stderr, contains('exceeded 0 seconds'));
  });

  test(
    'behavior subprocesses bound inherited output stream draining',
    () async {
      if (Platform.isWindows) return;
      final fixture = await Directory.systemTemp.createTemp(
        'flutter-monaco-output-drain-test-',
      );
      addTearDown(() => fixture.deleteSync(recursive: true));

      final stopwatch = Stopwatch()..start();
      final result = await runBehaviorProcess(
        'sh',
        ['-c', r'sleep 30 & echo $!'],
        workingDirectory: fixture.path,
        timeout: const Duration(seconds: 5),
        outputDrainTimeout: const Duration(milliseconds: 100),
      );
      stopwatch.stop();
      final childPid = int.parse(result.stdout.toString().trim());
      addTearDown(() => Process.killPid(childPid));

      expect(result.exitCode, 0);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
      expect(result.stderr, contains('inherited output streams remained open'));
    },
  );

  test('fixture change capture includes staged and committed edits', () async {
    final fixture = await Directory.systemTemp.createTemp(
      'flutter-monaco-git-capture-test-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));
    final trackedFile = File.fromUri(fixture.uri.resolve('tracked.txt'))
      ..writeAsStringSync('before\n');
    final baseline = await createEvaluationGitBaseline(fixture);

    trackedFile.writeAsStringSync('after staging\n');
    File.fromUri(fixture.uri.resolve('test/new_behavior_test.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}\n');
    File.fromUri(fixture.uri.resolve('binary-output.bin'))
        .writeAsBytesSync(<int>[0, 1, 2, 3]);
    final addResult = await Process.run('git', [
      'add',
      'tracked.txt',
    ], workingDirectory: fixture.path);
    expect(addResult.exitCode, 0, reason: addResult.stderr.toString());
    final staged = await captureEvaluationFixtureChanges(fixture, baseline);
    expect(staged.status, contains('M  tracked.txt'));
    expect(staged.status, contains('?? test/'));
    expect(staged.diff, contains('+after staging'));
    final textArtifact = staged.untrackedArtifacts.singleWhere(
      (artifact) => artifact['path'] == 'test/new_behavior_test.dart',
    );
    expect(textArtifact['kind'], 'text');
    expect(textArtifact['content'], 'void main() {}\n');
    expect(textArtifact['truncated'], isFalse);
    final binaryArtifact = staged.untrackedArtifacts.singleWhere(
      (artifact) => artifact['path'] == 'binary-output.bin',
    );
    expect(binaryArtifact['kind'], 'binary');
    expect(binaryArtifact['contentOmitted'], isTrue);
    expect(binaryArtifact, isNot(contains('content')));

    final commitResult = await Process.run('git', [
      '-c',
      'user.name=flutter_monaco eval',
      '-c',
      'user.email=eval@invalid.example',
      'commit',
      '--quiet',
      '-m',
      'Agent commit',
    ], workingDirectory: fixture.path);
    expect(commitResult.exitCode, 0, reason: commitResult.stderr.toString());
    final committed = await captureEvaluationFixtureChanges(fixture, baseline);
    expect(committed.status, contains('?? test/'));
    expect(committed.diff, contains('+after staging'));
    expect(
      committed.untrackedArtifacts,
      contains(containsPair('path', 'test/new_behavior_test.dart')),
    );
  });

  test('fixture change capture surfaces Git failures', () async {
    final fixture = await Directory.systemTemp.createTemp(
      'flutter-monaco-git-failure-test-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));

    await expectLater(
      captureEvaluationFixtureChanges(fixture, 'missing-baseline'),
      throwsA(isA<StateError>()),
    );
  });

  test('malformed Codex plugin metadata returns actionable failures', () {
    expect(
      codexPluginMetadataProblem(null, repositoryRoot),
      contains('must be an object'),
    );
    expect(
      codexPluginMetadataProblem(<String, Object?>{
        'installed': 'not-an-array',
      }, repositoryRoot),
      contains('installed array'),
    );
    expect(
      codexPluginMetadataProblem(<String, Object?>{
        'installed': <Object?>[
          <String, Object?>{
            'pluginId': 'flutter-monaco@flutter-monaco',
            'version': '4.0.0',
            'installed': true,
            'enabled': true,
          },
        ],
      }, repositoryRoot),
      contains('invalid marketplaceSource metadata'),
    );
  });

  test('malformed Claude plugin metadata returns actionable failures', () {
    final config = Directory.systemTemp;
    expect(
      claudePluginMetadataProblem(null, repositoryRoot, config),
      contains('must be an array'),
    );
    expect(
      claudePluginMetadataProblem(<Object?>[null], repositoryRoot, config),
      contains('must be an object'),
    );
    expect(
      claudePluginMetadataProblem(
        <Object?>[
          <String, Object?>{
            'id': 'flutter-monaco@flutter-monaco-plugins',
            'version': '4.0.0',
            'enabled': true,
            'installPath': repositoryRoot.path,
          },
        ],
        repositoryRoot,
        config,
      ),
      contains('outside the isolated cache'),
    );
  });

  test(
    'realistic diagnostic and bridge cases contain a concrete defect',
    () async {
      final diagnosticFixture = await Directory.systemTemp.createTemp(
        'flutter-monaco-diagnostic-fixture-test-',
      );
      final bridgeFixture = await Directory.systemTemp.createTemp(
        'flutter-monaco-bridge-fixture-test-',
      );
      addTearDown(() {
        diagnosticFixture.deleteSync(recursive: true);
        bridgeFixture.deleteSync(recursive: true);
      });

      await prepareEvaluationFixture(
        repositoryRoot,
        diagnosticFixture,
        cases.singleWhere(
          (entry) => entry['id'] == 'diagnose-realistic-execution',
        ),
      );
      final diagnosticSource = File.fromUri(
        diagnosticFixture.uri.resolve('lib/editor_screen.dart'),
      ).readAsStringSync();
      expect(diagnosticSource, contains('TextField(focusNode: _searchFocus)'));
      expect(diagnosticSource, contains('onBlur: ()'));
      expect(diagnosticSource, contains('controller.requestFocus()'));

      await prepareEvaluationFixture(
        repositoryRoot,
        bridgeFixture,
        cases.singleWhere(
          (entry) => entry['id'] == 'bridge-realistic-execution',
        ),
      );
      final controllerSource = File.fromUri(
        bridgeFixture.uri.resolve('lib/src/editor/controller.dart'),
      ).readAsStringSync();
      expect(controllerSource, contains("_invoke('editor.evalFixturePing'"));
      final bridgeSource =
          Directory.fromUri(bridgeFixture.uri.resolve('assets/monaco/bridge/'))
              .listSync()
              .whereType<File>()
              .map((file) => file.readAsStringSync())
              .join('\n');
      expect(bridgeSource, isNot(contains('editor.evalFixturePing')));
    },
  );

  test('engine execution case requires provenance and a clean dry run', () {
    final engineCase = cases.singleWhere(
      (entry) => entry['id'] == 'engine-upgrade-realistic-execution',
    );
    expect(engineCase['prompt'], contains('No target version'));
    expect(engineCase['prompt'], contains('do not modify assets'));
    expect(
      engineCase['expectations'],
      contains(contains('leave the fixture diff clean')),
    );
  });

  test('consumer execution fixtures resolve local package sources', () async {
    final integrationFixture = await Directory.systemTemp.createTemp(
      'flutter-monaco-integration-fixture-test-',
    );
    final migrationFixture = await Directory.systemTemp.createTemp(
      'flutter-monaco-migration-fixture-test-',
    );
    addTearDown(() {
      integrationFixture.deleteSync(recursive: true);
      migrationFixture.deleteSync(recursive: true);
    });

    await prepareEvaluationFixture(
      repositoryRoot,
      integrationFixture,
      cases.singleWhere(
        (entry) => entry['id'] == 'integrate-realistic-execution',
      ),
    );
    final integrationPubspec = File.fromUri(
      integrationFixture.uri.resolve('pubspec.yaml'),
    ).readAsStringSync();
    expect(integrationPubspec, contains('flutter_monaco: ^4.0.0'));
    expect(integrationPubspec, contains('path: vendor/flutter_monaco_current'));
    expect(integrationPubspec, isNot(contains('../')));
    expect(integrationPubspec, isNot(contains('path: /')));
    final vendoredPubspec = File.fromUri(
      integrationFixture.uri.resolve(
        'vendor/flutter_monaco_current/pubspec.yaml',
      ),
    ).readAsStringSync();
    expect(vendoredPubspec, contains('version: 4.0.0'));
    expect(
      File.fromUri(
        integrationFixture.uri.resolve(
          'vendor/flutter_monaco_current/lib/flutter_monaco.dart',
        ),
      ).existsSync(),
      isTrue,
    );
    expect(
      File.fromUri(
        integrationFixture.uri.resolve(
          'vendor/flutter_monaco_current/README.md',
        ),
      ).existsSync(),
      isTrue,
    );
    expect(
      File.fromUri(
        integrationFixture.uri.resolve(
          'vendor/flutter_monaco_current/CHANGELOG.md',
        ),
      ).existsSync(),
      isTrue,
    );

    await prepareEvaluationFixture(
      repositoryRoot,
      migrationFixture,
      cases.singleWhere(
        (entry) => entry['id'] == 'migration-realistic-execution',
      ),
    );
    final migrationPubspec = File.fromUri(
      migrationFixture.uri.resolve('pubspec.yaml'),
    ).readAsStringSync();
    final migrationReadme = File.fromUri(
      migrationFixture.uri.resolve('README.md'),
    ).readAsStringSync();
    expect(migrationPubspec, contains('flutter_monaco: ^2.3.0'));
    expect(migrationPubspec, contains('path: vendor/flutter_monaco_legacy'));
    expect(migrationPubspec, isNot(contains('../')));
    expect(migrationPubspec, isNot(contains('path: /')));
    expect(migrationReadme, contains('change the dependency override'));
    expect(
      File.fromUri(
        migrationFixture.uri.resolve(
          'vendor/flutter_monaco_legacy/lib/flutter_monaco.dart',
        ),
      ).existsSync(),
      isTrue,
    );
    expect(
      File.fromUri(
        migrationFixture.uri.resolve(
          'vendor/flutter_monaco_current/lib/flutter_monaco.dart',
        ),
      ).existsSync(),
      isTrue,
    );
  });

  test(
    'LSP execution fixture provides an exact authentication contract',
    () async {
      final fixture = await Directory.systemTemp.createTemp(
        'flutter-monaco-lsp-fixture-test-',
      );
      addTearDown(() => fixture.deleteSync(recursive: true));

      await prepareEvaluationFixture(
        repositoryRoot,
        fixture,
        cases.singleWhere((entry) => entry['id'] == 'lsp-realistic-execution'),
      );
      final readme = File.fromUri(fixture.uri.resolve('README.md'))
          .readAsStringSync();

      expect(readme, contains('wss://lsp.test.invalid/dart'));
      expect(readme, contains('wss://lsp.test.invalid` only'));
      expect(readme, contains('access_token'));
      expect(readme, contains('Never hard-code, persist, or log'));
    },
  );

  test(
    'adjacent negatives use consumer fixtures without maintainer bias',
    () async {
      final fixtureRoot = await Directory.systemTemp.createTemp(
        'flutter-monaco-negative-fixture-test-',
      );
      addTearDown(() => fixtureRoot.deleteSync(recursive: true));

      Future<Directory> prepare(String id) async {
        final fixture = Directory.fromUri(fixtureRoot.uri.resolve('$id/'))
          ..createSync();
        await prepareEvaluationFixture(
          repositoryRoot,
          fixture,
          cases.singleWhere((entry) => entry['id'] == id),
        );
        return fixture;
      }

      final lsp = await prepare('lsp-negative-trigger');
      final lspSource = File.fromUri(lsp.uri.resolve('lib/editor_screen.dart'))
          .readAsStringSync();
      expect(lspSource, contains('MonacoLanguage.json'));
      expect(lspSource, isNot(contains('LanguageServer')));

      final bridge = await prepare('bridge-negative-trigger');
      expect(
        File.fromUri(bridge.uri.resolve('lib/editor_screen.dart')).existsSync(),
        isTrue,
      );
      expect(
        Directory.fromUri(bridge.uri.resolve('assets/monaco/bridge/'))
            .existsSync(),
        isFalse,
      );

      final engine = await prepare('engine-upgrade-negative-trigger');
      final enginePubspec = File.fromUri(engine.uri.resolve('pubspec.yaml'))
          .readAsStringSync();
      expect(enginePubspec, contains('flutter_monaco: ^3.4.1'));
      expect(
        Directory.fromUri(engine.uri.resolve('assets/monaco/')).existsSync(),
        isFalse,
      );
    },
  );
}

Directory _findRepositoryRoot() {
  var candidate = Directory.current.absolute;
  while (true) {
    if (File.fromUri(candidate.uri.resolve('pubspec.yaml')).existsSync()) {
      return candidate;
    }
    if (candidate.parent.path == candidate.path) {
      throw StateError('Could not locate the repository root.');
    }
    candidate = candidate.parent;
  }
}
