import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum AiEvaluationClient { claude, codex }

const _evaluationPath = 'plugins/flutter-monaco/evals/cases.json';
const _pluginPath = 'plugins/flutter-monaco';
const _defaultCaseTimeout = Duration(minutes: 10);
const _gracefulShutdownTimeout = Duration(seconds: 5);
const _maximumUntrackedArtifactBytes = 128 * 1024;
const _maximumUntrackedReportBytes = 1024 * 1024;
const _maximumUntrackedArtifactCount = 200;

const _claudeExecutionAllowedTools = <String>[
  'Bash(dart analyze)',
  'Bash(dart format .)',
  'Bash(dart format lib)',
  'Bash(dart format lib test)',
  'Bash(dart format lib/editor_screen.dart)',
  'Bash(dart pub get)',
  'Bash(dart pub publish --dry-run)',
  'Bash(dart test)',
  'Bash(flutter analyze)',
  'Bash(flutter pub get)',
  'Bash(flutter test)',
  'Bash(flutter test test/assets test/protocol test/lsp)',
  'Bash(flutter test test/protocol test/assets/bridge_files_test.dart)',
  'Bash(node --test tool/bridge_tests/*_test.mjs)',
];

final class BehaviorRunnerOptions {
  const BehaviorRunnerOptions({
    required this.client,
    required this.caseIds,
    required this.runAll,
    required this.keepFixtures,
    required this.claudeBudgetUsd,
    required this.claudeModel,
    required this.caseTimeout,
    this.claudeConfigDirPath,
    this.codexHomePath,
    this.outputPath,
  });

  final AiEvaluationClient? client;
  final Set<String> caseIds;
  final bool runAll;
  final bool keepFixtures;
  final double claudeBudgetUsd;
  final String claudeModel;
  final Duration caseTimeout;
  final String? claudeConfigDirPath;
  final String? codexHomePath;
  final String? outputPath;
}

Future<void> main(List<String> arguments) async {
  final repositoryRoot = _findRepositoryRoot(Directory.current);
  late final BehaviorRunnerOptions options;
  try {
    options = parseBehaviorRunnerOptions(arguments);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }

  final cases = loadEvaluationCases(repositoryRoot);
  if (options.client == null) {
    stdout.writeln(_usage);
    stdout.writeln('\nAvailable cases:');
    for (final evaluationCase in cases) {
      stdout.writeln(
        '  ${evaluationCase['id']} '
        '(${evaluationCase['skill']}, ${evaluationCase['kind']})',
      );
    }
    return;
  }

  final selectedCases = cases.where((evaluationCase) {
    if (options.runAll) return true;
    return options.caseIds.contains(evaluationCase['id']);
  }).toList();
  if (selectedCases.isEmpty) {
    stderr.writeln('No evaluation cases were selected.');
    exitCode = 64;
    return;
  }

  final knownIds = cases.map((entry) => entry['id']).toSet();
  final unknownIds = options.caseIds.difference(knownIds);
  if (unknownIds.isNotEmpty) {
    stderr.writeln('Unknown evaluation cases: ${unknownIds.join(', ')}');
    exitCode = 64;
    return;
  }

  if (options.client == AiEvaluationClient.claude) {
    final claudeConfig = Directory(options.claudeConfigDirPath!).absolute;
    final problem = await _claudePluginProblem(
      repositoryRoot,
      claudeConfig,
      timeout: options.caseTimeout,
    );
    if (problem != null) {
      stderr.writeln(problem);
      exitCode = 78;
      return;
    }
  } else if (options.client == AiEvaluationClient.codex) {
    final codexHome = Directory(options.codexHomePath!).absolute;
    final problem = await _codexPluginProblem(
      repositoryRoot,
      codexHome,
      timeout: options.caseTimeout,
    );
    if (problem != null) {
      stderr.writeln(problem);
      exitCode = 78;
      return;
    }
  }

  final results = <Map<String, Object?>>[];
  for (final evaluationCase in selectedCases) {
    final id = evaluationCase['id']! as String;
    stdout.writeln('Running $id with ${options.client!.name}...');
    results.add(
      await _runCase(
        repositoryRoot: repositoryRoot,
        evaluationCase: evaluationCase,
        options: options,
      ),
    );
  }

  final report = <String, Object?>{
    'schemaVersion': 1,
    'client': options.client!.name,
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'repositoryHead': await _gitOutput(repositoryRoot, ['rev-parse', 'HEAD']),
    'results': results,
  };
  final encoded = const JsonEncoder.withIndent('  ').convert(report);
  if (options.outputPath == null) {
    stdout.writeln(encoded);
  } else {
    final output = File(options.outputPath!).absolute;
    output.parent.createSync(recursive: true);
    output.writeAsStringSync('$encoded\n');
    stdout.writeln('Wrote ${output.path}');
  }

  if (results.any((result) => result['exitCode'] != 0)) {
    exitCode = 1;
  }
}

BehaviorRunnerOptions parseBehaviorRunnerOptions(List<String> arguments) {
  AiEvaluationClient? client;
  final caseIds = <String>{};
  var runAll = false;
  var keepFixtures = false;
  var claudeBudgetUsd = 0.75;
  var claudeModel = 'sonnet';
  var caseTimeout = _defaultCaseTimeout;
  String? claudeConfigDirPath;
  String? codexHomePath;
  String? outputPath;

  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    String takeValue(String option) {
      if (index + 1 >= arguments.length) {
        throw FormatException('$option requires a value.');
      }
      return arguments[++index];
    }

    switch (argument) {
      case '--client':
        final value = takeValue(argument);
        client = switch (value) {
          'claude' => AiEvaluationClient.claude,
          'codex' => AiEvaluationClient.codex,
          _ => throw const FormatException(
            '--client must be either claude or codex.',
          ),
        };
      case '--case':
        caseIds.add(takeValue(argument));
      case '--all':
        runAll = true;
      case '--keep-fixtures':
        keepFixtures = true;
      case '--claude-budget-usd':
        final value = takeValue(argument);
        claudeBudgetUsd = double.tryParse(value) ?? -1;
        if (claudeBudgetUsd <= 0) {
          throw const FormatException(
            '--claude-budget-usd must be a positive number.',
          );
        }
      case '--claude-model':
        claudeModel = takeValue(argument);
        if (claudeModel.trim().isEmpty) {
          throw const FormatException('--claude-model cannot be empty.');
        }
      case '--case-timeout-seconds':
        final value = int.tryParse(takeValue(argument));
        if (value == null || value <= 0) {
          throw const FormatException(
            '--case-timeout-seconds must be a positive integer.',
          );
        }
        caseTimeout = Duration(seconds: value);
      case '--claude-config-dir':
        claudeConfigDirPath = takeValue(argument);
      case '--codex-home':
        codexHomePath = takeValue(argument);
      case '--output':
        outputPath = takeValue(argument);
      case '--help' || '-h':
        return const BehaviorRunnerOptions(
          client: null,
          caseIds: <String>{},
          runAll: false,
          keepFixtures: false,
          claudeBudgetUsd: 0.75,
          claudeModel: 'sonnet',
          caseTimeout: _defaultCaseTimeout,
        );
      default:
        throw FormatException('Unknown option: $argument');
    }
  }

  if (runAll && caseIds.isNotEmpty) {
    throw const FormatException('Use either --all or --case, not both.');
  }
  if (client != null && !runAll && caseIds.isEmpty) {
    throw const FormatException(
      '--client requires --all or at least one --case.',
    );
  }
  if (client == AiEvaluationClient.codex && codexHomePath == null) {
    throw const FormatException(
      '--client codex requires --codex-home for an isolated installation.',
    );
  }
  if (client == AiEvaluationClient.claude && claudeConfigDirPath == null) {
    throw const FormatException(
      '--client claude requires --claude-config-dir for an isolated '
      'installation.',
    );
  }
  if (claudeConfigDirPath != null) {
    claudeConfigDirPath = Directory(claudeConfigDirPath).absolute.path;
  }
  if (codexHomePath != null) {
    codexHomePath = Directory(codexHomePath).absolute.path;
  }
  return BehaviorRunnerOptions(
    client: client,
    caseIds: caseIds,
    runAll: runAll,
    keepFixtures: keepFixtures,
    claudeBudgetUsd: claudeBudgetUsd,
    claudeModel: claudeModel,
    caseTimeout: caseTimeout,
    claudeConfigDirPath: claudeConfigDirPath,
    codexHomePath: codexHomePath,
    outputPath: outputPath,
  );
}

List<Map<String, Object?>> loadEvaluationCases(Directory repositoryRoot) {
  final file = File.fromUri(repositoryRoot.uri.resolve(_evaluationPath));
  final decoded = jsonDecode(file.readAsStringSync());
  final root = (decoded as Map).cast<String, Object?>();
  return (root['cases']! as List<Object?>)
      .map((entry) => (entry! as Map).cast<String, Object?>())
      .toList(growable: false);
}

String buildEvaluationPrompt(
  Map<String, Object?> evaluationCase,
  AiEvaluationClient client,
) {
  final prompt = evaluationCase['prompt']! as String;
  if (evaluationCase['kind'] != 'execution') return prompt;
  final skill = evaluationCase['skill']! as String;
  final invocation = client == AiEvaluationClient.claude
      ? '/flutter-monaco:$skill'
      : '\$$skill';
  return '$invocation\n\n$prompt';
}

Future<Map<String, Object?>> _runCase({
  required Directory repositoryRoot,
  required Map<String, Object?> evaluationCase,
  required BehaviorRunnerOptions options,
}) async {
  final fixture = await Directory.systemTemp.createTemp(
    'flutter-monaco-ai-eval-',
  );
  final stopwatch = Stopwatch()..start();
  ProcessResult? processResult;
  String? setupError;
  String? baselineRevision;
  try {
    await prepareEvaluationFixture(repositoryRoot, fixture, evaluationCase);
    baselineRevision = await createEvaluationGitBaseline(fixture);
    final prompt = buildEvaluationPrompt(evaluationCase, options.client!);
    processResult = await _runClient(
      client: options.client!,
      fixture: fixture,
      prompt: prompt,
      execution: evaluationCase['kind'] == 'execution',
      claudeBudgetUsd: options.claudeBudgetUsd,
      claudeModel: options.claudeModel,
      claudeConfigDirPath: options.claudeConfigDirPath,
      codexHomePath: options.codexHomePath,
      timeout: options.caseTimeout,
    );
  } on Object catch (error) {
    setupError = error.toString();
  } finally {
    stopwatch.stop();
  }

  var status = '';
  var diff = '';
  var untrackedArtifacts = const <Map<String, Object?>>[];
  String? artifactCaptureError;
  if (baselineRevision != null) {
    try {
      final changes = await captureEvaluationFixtureChanges(
        fixture,
        baselineRevision,
      );
      status = changes.status;
      diff = changes.diff;
      untrackedArtifacts = changes.untrackedArtifacts;
    } on Object catch (error) {
      artifactCaptureError = error.toString();
    }
  } else {
    artifactCaptureError = 'The evaluation fixture baseline was not created.';
  }
  final processExitCode = processResult?.exitCode ?? 1;
  final result = <String, Object?>{
    'id': evaluationCase['id'],
    'skill': evaluationCase['skill'],
    'kind': evaluationCase['kind'],
    'prompt': evaluationCase['prompt'],
    'promptSent': buildEvaluationPrompt(evaluationCase, options.client!),
    'expectations': evaluationCase['expectations'],
    'exitCode': artifactCaptureError == null ? processExitCode : 1,
    'durationMs': stopwatch.elapsedMilliseconds,
    'stdout': processResult?.stdout?.toString() ?? '',
    'stderr': processResult?.stderr?.toString() ?? setupError ?? '',
    'fixtureStatus': status,
    'fixtureDiff': diff,
    'fixtureUntrackedArtifacts': untrackedArtifacts,
    if (options.keepFixtures) 'fixturePath': fixture.path,
  };
  if (artifactCaptureError != null) {
    result['artifactCaptureError'] = artifactCaptureError;
  }

  if (!options.keepFixtures) {
    try {
      fixture.deleteSync(recursive: true);
    } on FileSystemException {
      result['cleanupWarning'] = 'Could not remove ${fixture.path}';
    }
  }
  return result;
}

Future<ProcessResult> _runClient({
  required AiEvaluationClient client,
  required Directory fixture,
  required String prompt,
  required bool execution,
  required double claudeBudgetUsd,
  required String claudeModel,
  required String? claudeConfigDirPath,
  required String? codexHomePath,
  required Duration timeout,
}) {
  return switch (client) {
    AiEvaluationClient.claude => runBehaviorProcess(
      'claude',
      buildClaudeArguments(
        prompt: prompt,
        execution: execution,
        budgetUsd: claudeBudgetUsd,
        model: claudeModel,
      ),
      workingDirectory: fixture.path,
      environment: buildClaudeEnvironment(claudeConfigDirPath!),
      timeout: timeout,
    ),
    AiEvaluationClient.codex => runBehaviorProcess(
      'codex',
      [
        'exec',
        '--ephemeral',
        '--sandbox',
        execution ? 'workspace-write' : 'read-only',
        '--json',
        '--cd',
        fixture.path,
        prompt,
      ],
      workingDirectory: fixture.path,
      environment: {'CODEX_HOME': codexHomePath!},
      timeout: timeout,
    ),
  };
}

Map<String, String> buildClaudeEnvironment(String claudeConfigDirPath) => {
  'CLAUDE_CONFIG_DIR': claudeConfigDirPath,
  'CLAUDE_CODE_DISABLE_AUTO_MEMORY': '1',
};

List<String> buildClaudeArguments({
  required String prompt,
  required bool execution,
  required double budgetUsd,
  required String model,
}) => [
  '-p',
  '--no-session-persistence',
  '--setting-sources',
  'user',
  '--strict-mcp-config',
  '--mcp-config',
  '{"mcpServers":{}}',
  '--permission-mode',
  execution ? 'acceptEdits' : 'dontAsk',
  '--tools',
  execution ? 'Read,Grep,Glob,Skill,Edit,Write,Bash' : 'Read,Grep,Glob,Skill',
  if (execution) ...['--allowedTools', _claudeExecutionAllowedTools.join(',')],
  '--output-format',
  'stream-json',
  '--verbose',
  '--max-budget-usd',
  budgetUsd.toString(),
  '--model',
  model,
  prompt,
];

Future<ProcessResult> runBehaviorProcess(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
  required Duration timeout,
  Map<String, String>? environment,
  Duration outputDrainTimeout = _gracefulShutdownTimeout,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  );
  await process.stdin.close();
  final stdoutBuffer = StringBuffer();
  final stderrBuffer = StringBuffer();
  final stdoutDone = Completer<void>();
  final stderrDone = Completer<void>();
  final stdoutSubscription = process.stdout
      .transform(const Utf8Decoder(allowMalformed: true))
      .listen(
        stdoutBuffer.write,
        onDone: stdoutDone.complete,
        onError: stdoutDone.completeError,
      );
  final stderrSubscription = process.stderr
      .transform(const Utf8Decoder(allowMalformed: true))
      .listen(
        stderrBuffer.write,
        onDone: stderrDone.complete,
        onError: stderrDone.completeError,
      );
  var timedOut = false;
  final actualExitCode = await process.exitCode.timeout(
    timeout,
    onTimeout: () async {
      timedOut = true;
      process.kill();
      try {
        return await process.exitCode.timeout(_gracefulShutdownTimeout);
      } on TimeoutException {
        if (Platform.isWindows) {
          process.kill();
        } else {
          process.kill(ProcessSignal.sigkill);
        }
        return process.exitCode.timeout(
          _gracefulShutdownTimeout,
          onTimeout: () => -1,
        );
      }
    },
  );
  var outputDrainTimedOut = false;
  try {
    await Future.wait([stdoutDone.future, stderrDone.future])
        .timeout(outputDrainTimeout);
  } on TimeoutException {
    outputDrainTimedOut = true;
    await Future.wait([
      stdoutSubscription.cancel(),
      stderrSubscription.cancel(),
    ]);
  }
  final stdoutText = stdoutBuffer.toString();
  final stderrText = stderrBuffer.toString();
  final timeoutMessage = timedOut
      ? 'Behavior case exceeded ${timeout.inSeconds} seconds and was terminated.'
      : null;
  final errorLines = <String>[];
  if (timeoutMessage != null) errorLines.add(timeoutMessage);
  if (outputDrainTimedOut) {
    errorLines.add(
      'Behavior client exited but inherited output streams remained open for '
      '${outputDrainTimeout.inSeconds} seconds; captured output may be incomplete.',
    );
  }
  if (stderrText.isNotEmpty) errorLines.add(stderrText);
  return ProcessResult(
    process.pid,
    timedOut ? 124 : actualExitCode,
    stdoutText,
    errorLines.join('\n'),
  );
}

Future<String?> _claudePluginProblem(
  Directory repositoryRoot,
  Directory claudeConfig, {
  required Duration timeout,
}) async {
  if (!claudeConfig.existsSync()) {
    return 'The isolated Claude config directory does not exist: '
        '${claudeConfig.path}';
  }
  final userHome = Platform.environment['HOME'];
  if (userHome != null &&
      _canonicalDirectory(claudeConfig) ==
          _canonicalDirectory(Directory('$userHome/.claude'))) {
    return '--claude-config-dir must not be the normal user Claude config '
        'directory. Create a disposable directory and install only this local '
        'marketplace.';
  }

  final authResult = await runBehaviorProcess(
    'claude',
    ['auth', 'status', '--json'],
    workingDirectory: repositoryRoot.path,
    environment: buildClaudeEnvironment(claudeConfig.path),
    timeout: timeout < const Duration(seconds: 30)
        ? timeout
        : const Duration(seconds: 30),
  );
  if (authResult.exitCode != 0) {
    return 'Could not inspect authentication for the isolated Claude config:\n'
        '${authResult.stderr}';
  }
  Object? authStatus;
  try {
    authStatus = jsonDecode(authResult.stdout.toString());
  } on FormatException catch (error) {
    return 'Claude returned invalid auth status JSON: ${error.message}';
  }
  final auth = _stringKeyedMap(authStatus);
  if (auth?['loggedIn'] != true) {
    return 'The isolated Claude config is not authenticated. Run `claude auth '
        'login` with CLAUDE_CONFIG_DIR set to ${claudeConfig.path}.';
  }

  final result = await runBehaviorProcess(
    'claude',
    ['plugin', 'list', '--json'],
    workingDirectory: repositoryRoot.path,
    environment: buildClaudeEnvironment(claudeConfig.path),
    timeout: timeout < const Duration(seconds: 30)
        ? timeout
        : const Duration(seconds: 30),
  );
  if (result.exitCode != 0) {
    return 'Could not inspect the isolated Claude installation:\n'
        '${result.stderr}';
  }

  Object? decoded;
  try {
    decoded = jsonDecode(result.stdout.toString());
  } on FormatException catch (error) {
    return 'Claude returned invalid plugin JSON: ${error.message}';
  }
  final metadataProblem = claudePluginMetadataProblem(
    decoded,
    repositoryRoot,
    claudeConfig,
  );
  if (metadataProblem != null) return metadataProblem;

  final marketplacesFile = File.fromUri(
    claudeConfig.uri.resolve('plugins/known_marketplaces.json'),
  );
  if (!marketplacesFile.existsSync()) {
    return 'The isolated Claude config has no known marketplace metadata.';
  }
  Object? marketplaces;
  try {
    marketplaces = jsonDecode(marketplacesFile.readAsStringSync());
  } on FormatException catch (error) {
    return 'Claude marketplace metadata is invalid JSON: ${error.message}';
  }
  final marketplaceRoot = _stringKeyedMap(marketplaces);
  final marketplace = _stringKeyedMap(
    marketplaceRoot?['flutter-monaco-plugins'],
  );
  final source = _stringKeyedMap(marketplace?['source']);
  final sourcePath = source?['path'];
  if (source?['source'] != 'directory' || sourcePath is! String) {
    return 'The Claude plugin must come from this checkout as a local '
        'directory marketplace.';
  }
  if (_canonicalDirectory(Directory(sourcePath)) !=
      _canonicalDirectory(repositoryRoot)) {
    return 'The Claude plugin must come from this checkout as a local '
        'marketplace, not $sourcePath.';
  }
  return null;
}

String? claudePluginMetadataProblem(
  Object? decoded,
  Directory repositoryRoot,
  Directory claudeConfig,
) {
  if (decoded is! List<Object?>) {
    return 'Claude plugin JSON must be an array.';
  }
  final installedEntries = <Map<String, Object?>>[];
  for (var index = 0; index < decoded.length; index++) {
    final entry = _stringKeyedMap(decoded[index]);
    if (entry == null) {
      return 'Claude plugin JSON entry $index must be an object.';
    }
    installedEntries.add(entry);
  }
  final installed = installedEntries
      .where((entry) => entry['id'] == 'flutter-monaco@flutter-monaco-plugins')
      .toList();
  if (installed.length != 1) {
    return 'The isolated Claude config must contain exactly one installed '
        'flutter-monaco@flutter-monaco-plugins plugin.';
  }

  final plugin = installed.single;
  final expectedVersion = _packageVersion(repositoryRoot);
  if (plugin['version'] != expectedVersion || plugin['enabled'] != true) {
    return 'The isolated Claude plugin must be enabled at version '
        '$expectedVersion; found version ${plugin['version']}, enabled '
        '${plugin['enabled']}.';
  }
  final installPath = plugin['installPath'];
  if (installPath is! String) {
    return 'The installed Claude plugin has no installPath.';
  }
  final installedPlugin = Directory(installPath);
  final cacheRoot = Directory.fromUri(
    claudeConfig.uri.resolve('plugins/cache/'),
  );
  if (!_isWithinDirectory(installedPlugin, cacheRoot)) {
    return 'The installed Claude plugin is outside the isolated cache: '
        '$installPath.';
  }
  final localPlugin = Directory.fromUri(
    repositoryRoot.uri.resolve('$_pluginPath/'),
  );
  if (!installedPlugin.existsSync() ||
      !_directoryTreesMatch(localPlugin, installedPlugin)) {
    return 'The installed Claude plugin cache is not a self-contained '
        'byte-for-byte copy of ${localPlugin.path}. Reinstall it from this '
        'checkout.';
  }
  return null;
}

Future<String?> _codexPluginProblem(
  Directory repositoryRoot,
  Directory codexHome, {
  required Duration timeout,
}) async {
  if (!codexHome.existsSync()) {
    return 'The isolated Codex home does not exist: ${codexHome.path}';
  }
  final userHome = Platform.environment['HOME'];
  if (userHome != null &&
      _canonicalDirectory(codexHome) ==
          _canonicalDirectory(Directory('$userHome/.codex'))) {
    return '--codex-home must not be the normal user Codex home. Create a '
        'disposable directory and install only this local marketplace.';
  }

  final result = await runBehaviorProcess(
    'codex',
    ['plugin', 'list', '--json'],
    workingDirectory: repositoryRoot.path,
    environment: {'CODEX_HOME': codexHome.path},
    timeout: timeout < const Duration(seconds: 30)
        ? timeout
        : const Duration(seconds: 30),
  );
  if (result.exitCode != 0) {
    return 'Could not inspect the isolated Codex installation:\n${result.stderr}';
  }

  Object? decoded;
  try {
    decoded = jsonDecode(result.stdout.toString());
  } on FormatException catch (error) {
    return 'Codex returned invalid plugin JSON: ${error.message}';
  }
  return codexPluginMetadataProblem(decoded, repositoryRoot);
}

String? codexPluginMetadataProblem(Object? decoded, Directory repositoryRoot) {
  final root = _stringKeyedMap(decoded);
  if (root == null) {
    return 'Codex plugin JSON must be an object with an installed array.';
  }
  final installedValue = root['installed'];
  if (installedValue is! List<Object?>) {
    return 'Codex plugin JSON must contain an installed array.';
  }
  final installedEntries = <Map<String, Object?>>[];
  for (var index = 0; index < installedValue.length; index++) {
    final entry = _stringKeyedMap(installedValue[index]);
    if (entry == null) {
      return 'Codex plugin JSON installed[$index] must be an object.';
    }
    installedEntries.add(entry);
  }
  final installed = installedEntries
      .where((entry) => entry['pluginId'] == 'flutter-monaco@flutter-monaco')
      .toList();
  if (installed.length != 1) {
    return 'The isolated Codex home must contain exactly one installed '
        'flutter-monaco@flutter-monaco plugin.';
  }

  final plugin = installed.single;
  final expectedVersion = _packageVersion(repositoryRoot);
  if (plugin['version'] != expectedVersion ||
      plugin['installed'] != true ||
      plugin['enabled'] != true) {
    return 'The isolated Codex plugin must be installed and enabled at '
        'version $expectedVersion; found version ${plugin['version']}, '
        'installed ${plugin['installed']}, enabled ${plugin['enabled']}.';
  }

  final marketplace = _stringKeyedMap(plugin['marketplaceSource']);
  if (marketplace == null || marketplace['source'] is! String) {
    return 'The installed Codex plugin has invalid marketplaceSource metadata.';
  }
  if (marketplace['sourceType'] != 'local' ||
      _canonicalDirectory(Directory(marketplace['source']! as String)) !=
          _canonicalDirectory(repositoryRoot)) {
    return 'The Codex plugin must come from this checkout as a local '
        'marketplace, not ${marketplace['source']}.';
  }

  final source = _stringKeyedMap(plugin['source']);
  if (source == null || source['path'] is! String) {
    return 'The installed Codex plugin has invalid source metadata.';
  }
  final installedPlugin = Directory(source['path']! as String);
  final localPlugin = Directory.fromUri(
    repositoryRoot.uri.resolve('$_pluginPath/'),
  );
  if (!installedPlugin.existsSync() ||
      !_directoryTreesMatch(localPlugin, installedPlugin)) {
    return 'The installed Codex plugin cache is not a self-contained byte-for-'
        'byte copy of ${localPlugin.path}. Reinstall it from this checkout.';
  }
  return null;
}

Map<String, Object?>? _stringKeyedMap(Object? value) {
  if (value is! Map) return null;
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String) return null;
    result[key] = entry.value;
  }
  return result;
}

String _packageVersion(Directory repositoryRoot) {
  final pubspec = File.fromUri(repositoryRoot.uri.resolve('pubspec.yaml'))
      .readAsStringSync();
  final match = RegExp(
    r'^version:\s*([^\s#]+)',
    multiLine: true,
  ).firstMatch(pubspec);
  if (match == null) throw StateError('pubspec.yaml has no version.');
  return match.group(1)!;
}

String _canonicalDirectory(Directory directory) => directory.existsSync()
    ? directory.resolveSymbolicLinksSync()
    : directory.absolute.path;

bool _isWithinDirectory(Directory candidate, Directory parent) {
  final parentPath = _canonicalDirectory(parent);
  final candidatePath = _canonicalDirectory(candidate);
  final prefix = parentPath.endsWith(Platform.pathSeparator)
      ? parentPath
      : '$parentPath${Platform.pathSeparator}';
  return candidatePath.startsWith(prefix);
}

bool _directoryTreesMatch(Directory expected, Directory actual) {
  Map<String, File> files(Directory root) {
    final absolute = root.absolute.path;
    final prefix = absolute.endsWith(Platform.pathSeparator)
        ? absolute
        : '$absolute${Platform.pathSeparator}';
    return {
      for (final entity in root.listSync(recursive: true, followLinks: false))
        if (entity is File)
          entity.absolute.path.substring(prefix.length): entity,
    };
  }

  final expectedFiles = files(expected);
  final actualFiles = files(actual);
  if (expectedFiles.keys
          .toSet()
          .difference(actualFiles.keys.toSet())
          .isNotEmpty ||
      actualFiles.keys
          .toSet()
          .difference(expectedFiles.keys.toSet())
          .isNotEmpty) {
    return false;
  }
  for (final path in expectedFiles.keys) {
    final left = expectedFiles[path]!.readAsBytesSync();
    final right = actualFiles[path]!.readAsBytesSync();
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
  }
  return true;
}

Future<void> prepareEvaluationFixture(
  Directory repositoryRoot,
  Directory fixture,
  Map<String, Object?> evaluationCase,
) async {
  final kind = evaluationCase['kind']! as String;
  final skill = evaluationCase['skill']! as String;
  if (kind != 'negative-trigger' &&
      (skill == 'maintain-flutter-monaco-bridge' ||
          skill == 'upgrade-bundled-monaco')) {
    await _copyMaintainerFixture(repositoryRoot, fixture);
    if (skill == 'maintain-flutter-monaco-bridge' && kind == 'execution') {
      _seedBridgeMismatch(fixture);
    }
    return;
  }

  if (kind == 'missing-input') {
    _writeFixtureFile(
      fixture,
      'README.md',
      '# Incomplete reproduction\n\nThe editor request has not been scoped yet.\n',
    );
    return;
  }

  if (kind == 'negative-trigger' &&
      (skill == 'integrate-flutter-monaco' ||
          skill == 'diagnose-flutter-monaco')) {
    _writeFixtureFile(
      fixture,
      'pubspec.yaml',
      _consumerPubspec(
        includeMonaco: false,
        monacoConstraint: null,
        localOverridePath: null,
      ),
    );
    _writeFixtureFile(
      fixture,
      'lib/settings_form.dart',
      "import 'package:material_ui/material_ui.dart';\n\n"
          'class SettingsForm extends StatelessWidget {\n'
          '  const SettingsForm({super.key});\n\n'
          '  @override\n'
          '  Widget build(BuildContext context) => const TextField(maxLines: 4);\n'
          '}\n',
    );
    return;
  }

  final legacy =
      skill == 'migrate-flutter-monaco-v2-to-v3' && kind != 'negative-trigger';
  final monacoConstraint =
      skill == 'upgrade-bundled-monaco' && kind == 'negative-trigger'
      ? '^3.4.1'
      : legacy
      ? '^2.3.0'
      : '^4.0.0';
  _writeFixtureFile(
    fixture,
    'pubspec.yaml',
    _consumerPubspec(
      includeMonaco: true,
      monacoConstraint: monacoConstraint,
      localOverridePath: kind == 'execution'
          ? legacy
                ? 'vendor/flutter_monaco_legacy'
                : 'vendor/flutter_monaco_current'
          : null,
    ),
  );
  _writeFixtureFile(
    fixture,
    'lib/editor_screen.dart',
    legacy
        ? _legacyEditorSource
        : skill == 'diagnose-flutter-monaco' && kind == 'execution'
        ? _focusFailureSource
        : skill == 'configure-flutter-monaco-lsp' && kind == 'negative-trigger'
        ? _jsonEditorSource
        : _currentEditorSource,
  );
  _writeFixtureFile(
    fixture,
    'README.md',
    '# AI evaluation fixture\n\n'
        'Target platforms: Web, macOS, and Windows.\n\n'
        '${skill == 'configure-flutter-monaco-lsp' && kind == 'execution' ? _lspFixtureContract : ''}'
        '${kind != 'execution'
            ? ''
            : legacy
            ? 'The dependency starts on the 2.3.0 API stub at vendor/flutter_monaco_legacy. After rewriting the app, change the dependency override to vendor/flutter_monaco_current for 4.0.0 validation. Do not edit either vendor tree.\n'
            : 'The 4.0.0 package at vendor/flutter_monaco_current is a read-only fixture dependency. Do not edit it.\n'}',
  );
  if (kind == 'execution') {
    _writeFixtureFile(fixture, 'analysis_options.yaml', '''analyzer:
  exclude:
    - vendor/**
''');
    await _copyVendoredCurrentPackage(repositoryRoot, fixture);
    if (legacy) _writeLegacyPackage(fixture);
  }
}

void _seedBridgeMismatch(Directory fixture) {
  final controller = File.fromUri(
    fixture.uri.resolve('lib/src/editor/controller.dart'),
  );
  const anchor = '''  Future<MonacoTheme?> getTheme() async {
    final result = await _invoke('editor.getTheme', {});
    return result is String && result.isNotEmpty ? MonacoTheme(result) : null;
  }
''';
  const mismatch = '''$anchor
  /// Evaluation fixture: the JavaScript handler and harness are missing.
  Future<String> evalFixturePing() async {
    final result = await _invoke('editor.evalFixturePing', {});
    return result! as String;
  }
''';
  final source = controller.readAsStringSync();
  if (!source.contains(anchor)) {
    throw StateError('Could not seed the bridge mismatch fixture.');
  }
  controller.writeAsStringSync(source.replaceFirst(anchor, mismatch));
}

Future<void> _copyMaintainerFixture(
  Directory repositoryRoot,
  Directory fixture,
) async {
  final tracked = await Process.run('git', [
    'ls-files',
  ], workingDirectory: repositoryRoot.path);
  if (tracked.exitCode != 0) {
    throw StateError('git ls-files failed: ${tracked.stderr}');
  }
  for (final relativePath in const LineSplitter().convert(
    tracked.stdout.toString(),
  )) {
    if (relativePath.isEmpty ||
        relativePath.startsWith('plugins/flutter-monaco/evals/') ||
        relativePath.startsWith('test/ai_extensions/') ||
        relativePath == 'tool/ai_extension_behavior_runner.dart' ||
        relativePath == 'tool/validate_ai_extensions.dart') {
      continue;
    }
    final source = File.fromUri(repositoryRoot.uri.resolve(relativePath));
    if (!source.existsSync()) continue;
    final destination = File.fromUri(fixture.uri.resolve(relativePath));
    destination.parent.createSync(recursive: true);
    source.copySync(destination.path);
  }
}

Future<void> _copyVendoredCurrentPackage(
  Directory repositoryRoot,
  Directory fixture,
) async {
  final tracked = await Process.run('git', [
    'ls-files',
    '--',
    'pubspec.yaml',
    'LICENSE',
    'README.md',
    'CHANGELOG.md',
    'lib',
    'assets',
    'android',
    'ios',
    'macos',
    'windows',
    'web',
    'hook',
  ], workingDirectory: repositoryRoot.path);
  if (tracked.exitCode != 0) {
    throw StateError(
      'git ls-files for package fixture failed: ${tracked.stderr}',
    );
  }
  final destinationRoot = Directory.fromUri(
    fixture.uri.resolve('vendor/flutter_monaco_current/'),
  );
  for (final relativePath in const LineSplitter().convert(
    tracked.stdout.toString(),
  )) {
    if (relativePath.isEmpty) continue;
    final source = File.fromUri(repositoryRoot.uri.resolve(relativePath));
    if (!source.existsSync()) continue;
    final destination = File.fromUri(destinationRoot.uri.resolve(relativePath));
    destination.parent.createSync(recursive: true);
    source.copySync(destination.path);
  }
}

void _writeLegacyPackage(Directory fixture) {
  _writeFixtureFile(
    fixture,
    'vendor/flutter_monaco_legacy/pubspec.yaml',
    '''name: flutter_monaco
version: 2.3.0
publish_to: none
environment:
  sdk: ^3.12.0
dependencies:
  flutter:
    sdk: flutter
''',
  );
  _writeFixtureFile(
    fixture,
    'vendor/flutter_monaco_legacy/lib/flutter_monaco.dart',
    _legacyPackageStub,
  );
}

final class EvaluationFixtureChanges {
  const EvaluationFixtureChanges({
    required this.status,
    required this.diff,
    required this.untrackedArtifacts,
  });

  final String status;
  final String diff;
  final List<Map<String, Object?>> untrackedArtifacts;
}

Future<String> createEvaluationGitBaseline(Directory fixture) async {
  for (final command in [
    ['init', '--quiet'],
    ['add', '.'],
    [
      '-c',
      'user.name=flutter_monaco eval',
      '-c',
      'user.email=eval@invalid.example',
      'commit',
      '--quiet',
      '-m',
      'Evaluation baseline',
    ],
  ]) {
    final result = await Process.run(
      'git',
      command,
      workingDirectory: fixture.path,
    );
    if (result.exitCode != 0) {
      throw StateError('git ${command.join(' ')} failed: ${result.stderr}');
    }
  }
  return _gitOutput(fixture, ['rev-parse', 'HEAD']);
}

Future<EvaluationFixtureChanges> captureEvaluationFixtureChanges(
  Directory fixture,
  String baselineRevision,
) async {
  final status = await _gitOutput(fixture, ['status', '--short']);
  final diff = await _gitOutput(fixture, [
    'diff',
    '--no-ext-diff',
    baselineRevision,
    '--',
  ]);
  final untrackedArtifacts = await _captureUntrackedArtifacts(fixture);
  return EvaluationFixtureChanges(
    status: status,
    diff: diff,
    untrackedArtifacts: untrackedArtifacts,
  );
}

Future<List<Map<String, Object?>>> _captureUntrackedArtifacts(
  Directory fixture,
) async {
  final result = await Process.run(
    'git',
    ['ls-files', '--others', '--exclude-standard', '-z'],
    workingDirectory: fixture.path,
    stdoutEncoding: null,
  );
  if (result.exitCode != 0) {
    throw StateError(
      'git ls-files --others failed in ${fixture.path}: ${result.stderr}',
    );
  }
  final output = utf8.decode(
    (result.stdout! as List<int>),
    allowMalformed: true,
  );
  final paths = output.split('\u0000').where((path) => path.isNotEmpty).toList()
    ..sort();
  final artifacts = <Map<String, Object?>>[];
  var remainingReportBytes = _maximumUntrackedReportBytes;
  for (
    var index = 0;
    index < paths.length && index < _maximumUntrackedArtifactCount;
    index++
  ) {
    final path = paths[index];
    final segments = path.split('/');
    if (path.startsWith('/') || segments.contains('..')) {
      artifacts.add({
        'path': path,
        'kind': 'unsafe-path',
        'contentOmitted': true,
      });
      continue;
    }
    final absolutePath = [
      fixture.path,
      ...segments,
    ].join(Platform.pathSeparator);
    final type = FileSystemEntity.typeSync(absolutePath, followLinks: false);
    if (type == FileSystemEntityType.link) {
      artifacts.add({
        'path': path,
        'kind': 'symlink',
        'target': Link(absolutePath).targetSync(),
        'contentOmitted': true,
      });
      continue;
    }
    if (type != FileSystemEntityType.file) {
      artifacts.add({
        'path': path,
        'kind': type == FileSystemEntityType.directory
            ? 'directory'
            : type == FileSystemEntityType.notFound
            ? 'not-found'
            : 'other',
        'contentOmitted': true,
      });
      continue;
    }

    final file = File(absolutePath);
    final byteLength = file.lengthSync();
    final byteLimit = byteLength
        .clamp(
          0,
          _maximumUntrackedArtifactBytes < remainingReportBytes
              ? _maximumUntrackedArtifactBytes
              : remainingReportBytes,
        )
        .toInt();
    final bytes = <int>[];
    if (byteLimit > 0) {
      final handle = file.openSync();
      try {
        bytes.addAll(handle.readSync(byteLimit));
      } finally {
        handle.closeSync();
      }
    }
    final binary = bytes.contains(0) || !_isUtf8(bytes);
    final artifact = <String, Object?>{
      'path': path,
      'kind': binary ? 'binary' : 'text',
      'byteLength': byteLength,
      'truncated': byteLimit < byteLength,
    };
    if (binary) {
      artifact['contentOmitted'] = true;
    } else {
      final content = utf8.decode(bytes);
      artifact['content'] = content;
      remainingReportBytes -= utf8.encode(content).length;
    }
    artifacts.add(artifact);
  }
  if (paths.length > _maximumUntrackedArtifactCount) {
    artifacts.add({
      'path': '<remaining untracked files>',
      'kind': 'count-limit',
      'omittedCount': paths.length - _maximumUntrackedArtifactCount,
      'contentOmitted': true,
    });
  }
  return artifacts;
}

bool _isUtf8(List<int> bytes) {
  try {
    utf8.decode(bytes);
    return true;
  } on FormatException {
    return false;
  }
}

String _consumerPubspec({
  required bool includeMonaco,
  required String? monacoConstraint,
  required String? localOverridePath,
}) {
  return '''name: flutter_monaco_eval_app
publish_to: none
environment:
  sdk: ^3.13.5
dependencies:
  flutter:
    sdk: flutter
  material_ui: ^1.6.0
${includeMonaco ? '  flutter_monaco: $monacoConstraint\n' : ''}${localOverridePath == null ? '' : '''dependency_overrides:
  flutter_monaco:
    path: $localOverridePath
'''}''';
}

const _currentEditorSource =
    '''import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:material_ui/material_ui.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key, required this.controller});

  final MonacoController controller;

  @override
  Widget build(BuildContext context) => MonacoEditor(controller: controller);
}
''';

const _lspFixtureContract = '''LSP contract:

- WebSocket endpoint: `wss://lsp.test.invalid/dart`.
- CSP connect source: `wss://lsp.test.invalid` only.
- The screen receives a short-lived, URL-safe access token from the app's existing
  authenticated backend.
- The proxy accepts that token only through the `access_token` query parameter because
  browser WebSockets cannot send a custom authorization header.
- Never hard-code, persist, or log the token or the authenticated endpoint URI.

''';

const _jsonEditorSource =
    '''import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:material_ui/material_ui.dart';

class JsonEditorScreen extends StatelessWidget {
  const JsonEditorScreen({super.key, required this.controller});

  final MonacoController controller;

  @override
  Widget build(BuildContext context) => MonacoEditor(
    controller: controller,
    options: const EditorOptions(
      language: MonacoLanguage.json,
      theme: MonacoTheme.vsDark,
    ),
  );
}
''';

const _focusFailureSource = '''import 'dart:async';

import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:material_ui/material_ui.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.controller});

  final MonacoController controller;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _searchFocus = FocusNode();

  Future<void> _showHelp() async {
    await showDialog<void>(
      context: context,
      builder: (context) => const AlertDialog(content: Text('Keyboard help')),
    );
    await widget.controller.requestFocus();
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(focusNode: _searchFocus),
      ElevatedButton(onPressed: _showHelp, child: const Text('Help')),
      Expanded(
        child: MonacoEditor(
          controller: widget.controller,
          onBlur: () {
            unawaited(widget.controller.requestFocus());
          },
        ),
      ),
    ],
  );
}
''';

const _legacyEditorSource = '''import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

class LegacyEditorScreen extends StatefulWidget {
  const LegacyEditorScreen({super.key});

  @override
  State<LegacyEditorScreen> createState() => _LegacyEditorScreenState();
}

class _LegacyEditorScreenState extends State<LegacyEditorScreen> {
  MonacoController? controller;
  StreamSubscription<void>? focusSubscription;
  StreamSubscription<void>? blurSubscription;
  final persistedOptions = <String, Object?>{
    'themeId': 'vs-dark',
    'language': 'dart',
    'wordWrap': true,
  };

  Future<void> replaceText(String text) async {
    await controller?.setValue(text);
  }

  @override
  void dispose() {
    focusSubscription?.cancel();
    blurSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MonacoEditor(
        initialValue: 'void main() {}',
        options: EditorOptions.fromJson(persistedOptions),
        onReady: (value) {
          controller = value;
          focusSubscription = value.onFocus.listen((_) {});
          blurSubscription = value.onBlur.listen((_) {});
        },
      );
}
''';

const _legacyPackageStub = '''library flutter_monaco;

import 'dart:async';

import 'package:flutter/widgets.dart';

final class MonacoController {
  final Stream<void> onFocus = const Stream<void>.empty();
  final Stream<void> onBlur = const Stream<void>.empty();

  Future<void> setValue(String value) async {}
}

final class EditorOptions {
  EditorOptions.fromJson(this.raw);

  final Map<String, Object?> raw;
}

final class MonacoEditor extends StatelessWidget {
  const MonacoEditor({
    super.key,
    required this.initialValue,
    required this.options,
    required this.onReady,
  });

  final String initialValue;
  final EditorOptions options;
  final ValueChanged<MonacoController> onReady;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
''';

void _writeFixtureFile(Directory root, String relativePath, String content) {
  final file = File.fromUri(root.uri.resolve(relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

Future<String> _gitOutput(Directory directory, List<String> arguments) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: directory.path,
  );
  if (result.exitCode != 0) {
    throw StateError(
      'git ${arguments.join(' ')} failed in ${directory.path}: ${result.stderr}',
    );
  }
  return result.stdout.toString().trimRight();
}

Directory _findRepositoryRoot(Directory start) {
  var candidate = start.absolute;
  while (true) {
    if (File.fromUri(candidate.uri.resolve('pubspec.yaml')).existsSync() &&
        File.fromUri(candidate.uri.resolve(_evaluationPath)).existsSync()) {
      return candidate;
    }
    if (candidate.parent.path == candidate.path) {
      throw StateError('Could not find the flutter_monaco repository root.');
    }
    candidate = candidate.parent;
  }
}

const _usage = '''Authenticated flutter_monaco AI behavior evaluations

Usage:
  dart run tool/ai_extension_behavior_runner.dart --client claude \\
    --claude-config-dir <temporary-directory> --case <id>
  dart run tool/ai_extension_behavior_runner.dart --client codex \\
    --codex-home <temporary-directory> --all

Options:
  --client <claude|codex>       Client to exercise.
  --case <id>                   Case to run; may be repeated.
  --all                         Run all 24 cases. This may incur model cost.
  --output <path>               Write the JSON report to this path.
  --keep-fixtures               Keep disposable workspaces for inspection.
  --claude-budget-usd <amount>  Per-case Claude budget. Default: 0.75.
  --claude-model <model>        Claude model alias. Default: sonnet.
  --case-timeout-seconds <n>    Per-case timeout. Default: 600 seconds.
  --claude-config-dir <path>    Required isolated Claude config directory.
  --codex-home <path>           Required isolated Codex home.
  --help                        List this help and available cases.

The runner never injects expectations into model prompts. Only execution cases
name the skill explicitly. Other cases exercise natural discovery or rejection.
Claude loads only user settings from the disposable CLAUDE_CONFIG_DIR plus its
verified installed plugin and an empty MCP set, disables auto-memory, and preapproves
only the listed fixture verification commands. Run Codex from a disposable CODEX_HOME
with only this marketplace installed. Model-backed evaluations require existing
client authentication and are not CI.
''';
