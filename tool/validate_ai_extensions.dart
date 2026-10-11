import 'dart:convert';
import 'dart:io';

const expectedAiSkillNames = <String>[
  'integrate-flutter-monaco',
  'configure-flutter-monaco-lsp',
  'diagnose-flutter-monaco',
  'migrate-flutter-monaco-v2-to-v3',
  'maintain-flutter-monaco-bridge',
  'upgrade-bundled-monaco',
];

const expectedEvaluationKinds = <String>{
  'positive-selection',
  'execution',
  'negative-trigger',
  'missing-input',
};

const expectedMigrationFixtureKinds = <String>{
  'normal',
  'edge-persisted-options',
  'already-migrated',
  'prerequisite-audit',
  'unsupported-version',
  'validation-failure-recovery',
};

final class AiExtensionValidationReport {
  const AiExtensionValidationReport(this.errors);

  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

/// The package's own license: the root `LICENSE` up to the first line of 80
/// hyphens, which introduces the licenses of bundled third-party code (the
/// format Flutter's license collector reads). The assistant plugin ships no
/// third-party code, so only this part must match its `LICENSE`.
String packageOwnLicense(String rootLicense) {
  final separator = '\n${'-' * 80}\n';
  final index = rootLicense.indexOf(separator);
  return index < 0 ? rootLicense : rootLicense.substring(0, index + 1);
}

List<String> validatePluginTreeHygiene(
  Directory pluginDirectory, {
  String pathPrefix = '',
}) {
  if (!pluginDirectory.existsSync()) return const <String>[];

  const forbiddenNames = <String>{
    '.ds_store',
    '.spotlight-v100',
    '.trashes',
    '__macosx',
    'desktop.ini',
    'thumbs.db',
  };
  const forbiddenSuffixes = <String>{'.bak', '.orig', '.swo', '.swp', '.tmp'};
  final errors = <String>[];
  final normalizedPrefix = pathPrefix
      .replaceAll('\\', '/')
      .replaceAll(RegExp(r'/+$'), '');

  for (final entity in pluginDirectory.listSync(
    recursive: true,
    followLinks: false,
  )) {
    final name = _basename(entity.path);
    final lowerName = name.toLowerCase();
    final isJunk =
        forbiddenNames.contains(lowerName) ||
        name.startsWith('._') ||
        name.endsWith('~') ||
        forbiddenSuffixes.any(lowerName.endsWith);
    if (!isJunk) continue;

    final relativePath = _relativeToDirectory(pluginDirectory, entity.path);
    final displayPath = normalizedPrefix.isEmpty
        ? relativePath
        : '$normalizedPrefix/$relativePath';
    errors.add('$displayPath: generated filesystem junk is forbidden');
  }
  return errors;
}

AiExtensionValidationReport validateAiExtensions(Directory repositoryRoot) {
  final validator = _AiExtensionValidator(repositoryRoot.absolute);
  validator.validate();
  return AiExtensionValidationReport(List.unmodifiable(validator.errors));
}

List<String> validateEvaluationData(
  Object? decoded, {
  Iterable<String> expectedSkills = expectedAiSkillNames,
}) {
  final errors = <String>[];
  final root = _asStringKeyedMap(decoded);
  if (root == null) {
    return ['the document must be a JSON object'];
  }

  if (root['schemaVersion'] != 1) {
    errors.add('schemaVersion must be the integer 1');
  }

  final cases = root['cases'];
  if (cases is! List<Object?> || cases.isEmpty) {
    errors.add('cases must be a non-empty array');
    return errors;
  }

  final expectedSkillSet = expectedSkills.toSet();
  final seenIds = <String>{};
  final kindsBySkill = <String, Set<String>>{
    for (final skill in expectedSkillSet) skill: <String>{},
  };

  for (var index = 0; index < cases.length; index++) {
    final evaluationCase = _asStringKeyedMap(cases[index]);
    final label = 'cases[$index]';
    if (evaluationCase == null) {
      errors.add('$label must be an object');
      continue;
    }

    final id = _nonEmptyString(evaluationCase['id']);
    if (id == null) {
      errors.add('$label.id must be a non-empty string');
    } else {
      if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(id)) {
        errors.add('$label.id must use lowercase kebab-case');
      }
      if (!seenIds.add(id)) {
        errors.add('$label.id duplicates "$id"');
      }
    }

    final skill = _nonEmptyString(evaluationCase['skill']);
    if (skill == null) {
      errors.add('$label.skill must be a non-empty string');
    } else if (!expectedSkillSet.contains(skill)) {
      errors.add('$label.skill references unexpected skill "$skill"');
    }

    final kind = _nonEmptyString(evaluationCase['kind']);
    if (kind == null) {
      errors.add('$label.kind must be a non-empty string');
    } else if (!expectedEvaluationKinds.contains(kind)) {
      errors.add('$label.kind has unsupported value "$kind"');
    } else if (skill != null && expectedSkillSet.contains(skill)) {
      if (!kindsBySkill[skill]!.add(kind)) {
        errors.add('$label duplicates $kind coverage for "$skill"');
      }
    }

    final prompt = _nonEmptyString(evaluationCase['prompt']);
    if (prompt == null || prompt.length < 24) {
      errors.add('$label.prompt must be a realistic prompt of 24+ characters');
    }

    final expectations = evaluationCase['expectations'];
    if (expectations is! List<Object?> || expectations.length < 2) {
      errors.add('$label.expectations must contain at least two checks');
    } else {
      for (
        var expectationIndex = 0;
        expectationIndex < expectations.length;
        expectationIndex++
      ) {
        final expectation = _nonEmptyString(expectations[expectationIndex]);
        if (expectation == null || expectation.length < 8) {
          errors.add(
            '$label.expectations[$expectationIndex] must be a useful string',
          );
        }
      }
    }
  }

  for (final entry in kindsBySkill.entries) {
    final missingKinds = expectedEvaluationKinds.difference(entry.value);
    if (missingKinds.isNotEmpty) {
      final sortedKinds = missingKinds.toList()..sort();
      errors.add(
        'skill "${entry.key}" is missing evaluation kinds: '
        '${sortedKinds.join(', ')}',
      );
    }
  }

  return errors;
}

List<String> validateMigrationFixtureData(Object? decoded) {
  final errors = <String>[];
  final root = _asStringKeyedMap(decoded);
  if (root == null) return ['the document must be a JSON object'];
  if (root['schemaVersion'] != 1) {
    errors.add('schemaVersion must be the integer 1');
  }

  final cases = root['cases'];
  if (cases is! List<Object?> || cases.isEmpty) {
    errors.add('cases must be a non-empty array');
    return errors;
  }

  final seenIds = <String>{};
  final seenKinds = <String>{};
  for (var index = 0; index < cases.length; index++) {
    final fixture = _asStringKeyedMap(cases[index]);
    final label = 'cases[$index]';
    if (fixture == null) {
      errors.add('$label must be an object');
      continue;
    }

    final id = _nonEmptyString(fixture['id']);
    if (id == null) {
      errors.add('$label.id must be a non-empty string');
    } else if (!seenIds.add(id)) {
      errors.add('$label.id duplicates "$id"');
    }

    final kind = _nonEmptyString(fixture['kind']);
    if (kind == null || !expectedMigrationFixtureKinds.contains(kind)) {
      errors.add('$label.kind must be a supported migration fixture kind');
    } else if (!seenKinds.add(kind)) {
      errors.add('$label.kind duplicates "$kind"');
    }

    for (final key in [
      'sourceVersion',
      'targetVersion',
      'input',
      'expectedDisposition',
      'expectedOutput',
    ]) {
      if (_nonEmptyString(fixture[key]) == null) {
        errors.add('$label.$key must be a non-empty string');
      }
    }

    final disposition = _nonEmptyString(fixture['expectedDisposition']);
    if (kind == 'prerequisite-audit' &&
        disposition != 'migrate-after-prerequisite-audit') {
      errors.add(
        '$label.expectedDisposition must require the prerequisite audit',
      );
    }
    if (kind == 'unsupported-version' && disposition != 'stop') {
      errors.add('$label.expectedDisposition must stop unsupported migrations');
    }

    final evidence = fixture['expectedEvidence'];
    if (evidence is! List<Object?> || evidence.length < 2) {
      errors.add('$label.expectedEvidence must contain at least two checks');
    }
  }

  final missingKinds = expectedMigrationFixtureKinds.difference(seenKinds);
  if (missingKinds.isNotEmpty) {
    final sortedKinds = missingKinds.toList()..sort();
    errors.add(
      'migration fixtures are missing kinds: ${sortedKinds.join(', ')}',
    );
  }

  Map<String, Object?>? normal;
  Map<String, Object?>? recovery;
  for (final item in cases) {
    final fixture = _asStringKeyedMap(item);
    if (fixture?['kind'] == 'normal') normal ??= fixture;
    if (fixture?['kind'] == 'validation-failure-recovery') {
      recovery ??= fixture;
    }
  }
  if (normal != null) {
    final input = _nonEmptyString(normal['input']) ?? '';
    final output = _nonEmptyString(normal['expectedOutput']) ?? '';
    if (!input.contains('setValue') ||
        !output.contains('document.setText') ||
        !output.contains('MonacoPageConfig')) {
      errors.add('normal fixture must prove legacy content and page migration');
    }
  }

  if (recovery != null) {
    final input = _nonEmptyString(recovery['input']) ?? '';
    final output = _nonEmptyString(recovery['expectedOutput']) ?? '';
    if (!input.contains('whenReady') ||
        !input.contains('setState') ||
        !output.contains('whenReady') ||
        !output.contains('setState') ||
        input.indexOf('whenReady') > input.indexOf('setState') ||
        output.indexOf('setState') > output.indexOf('whenReady')) {
      errors.add(
        'recovery fixture must move mounting before the readiness wait',
      );
    }
  }

  return errors;
}

void main(List<String> arguments) {
  final repositoryRoot = arguments.isEmpty
      ? Directory.current
      : Directory(arguments.single);
  final report = validateAiExtensions(repositoryRoot);

  if (report.isValid) {
    stdout.writeln('AI extension validation passed.');
    return;
  }

  stderr.writeln('AI extension validation failed:');
  for (final error in report.errors) {
    stderr.writeln('  - $error');
  }
  exitCode = 1;
}

final class _AiExtensionValidator {
  _AiExtensionValidator(this.root);

  final Directory root;
  final List<String> errors = <String>[];

  static const _pluginRoot = 'plugins/flutter-monaco';
  static const _marketplaceFiles = <String>[
    '.agents/plugins/marketplace.json',
    '.claude-plugin/marketplace.json',
  ];
  static const _pluginManifestFiles = <String>[
    'plugins/flutter-monaco/.codex-plugin/plugin.json',
    'plugins/flutter-monaco/.claude-plugin/plugin.json',
  ];

  void validate() {
    final packageVersion = _readPackageVersion();
    _validateNativeMetadata(packageVersion);
    for (final marketplacePath in _marketplaceFiles) {
      _validateMarketplace(marketplacePath, packageVersion);
    }
    for (final manifestPath in _pluginManifestFiles) {
      _validatePluginManifest(manifestPath, packageVersion);
    }
    _validateSkills();
    _validateEvaluations();
    _validateMigrationFixtures();
    _validatePubignore();
    _validateRequiredFiles();
    _validateReviewerAgents();
    _validateRootGuidance();
    _validatePluginTreeHygiene();
    _validatePluginTextFiles();
  }

  String? _readPackageVersion() {
    final file = _file('pubspec.yaml');
    if (!file.existsSync()) {
      errors.add('pubspec.yaml is missing');
      return null;
    }

    final match = RegExp(
      r'^version:\s*([^\s#]+)',
      multiLine: true,
    ).firstMatch(file.readAsStringSync());
    if (match == null) {
      errors.add('pubspec.yaml does not declare a package version');
      return null;
    }
    return match.group(1);
  }

  void _validateMarketplace(String path, String? packageVersion) {
    final marketplace = _readJsonObject(path);
    if (marketplace == null) return;

    final expectedName = path.startsWith('.agents/')
        ? 'flutter-monaco'
        : 'flutter-monaco-plugins';
    if (marketplace['name'] != expectedName) {
      errors.add('$path: name must be $expectedName');
    }

    final plugins = marketplace['plugins'];
    if (plugins is! List<Object?> || plugins.isEmpty) {
      errors.add('$path: plugins must be a non-empty array');
      return;
    }

    final matchingPlugins = <Map<String, Object?>>[];
    for (var index = 0; index < plugins.length; index++) {
      final plugin = _asStringKeyedMap(plugins[index]);
      if (plugin == null) {
        errors.add('$path: plugins[$index] must be an object');
        continue;
      }
      if (plugin['name'] == 'flutter-monaco') matchingPlugins.add(plugin);
    }

    if (matchingPlugins.length != 1) {
      errors.add(
        '$path: plugins must contain exactly one flutter-monaco entry',
      );
      return;
    }

    final plugin = matchingPlugins.single;
    final source = plugin['source'];
    String? sourcePath;
    if (source is String) {
      sourcePath = source;
    } else {
      sourcePath = _nonEmptyString(_asStringKeyedMap(source)?['path']);
    }
    if (sourcePath != './plugins/flutter-monaco') {
      errors.add(
        '$path: flutter-monaco source must be ./plugins/flutter-monaco',
      );
    }

    final marketplaceVersion = _nonEmptyString(plugin['version']);
    if (marketplaceVersion == null) {
      errors.add('$path: plugin version must be a non-empty string');
    } else if (packageVersion != null && marketplaceVersion != packageVersion) {
      errors.add(
        '$path: plugin version $marketplaceVersion does not match '
        'pubspec version $packageVersion',
      );
    }
  }

  void _validatePluginManifest(String path, String? packageVersion) {
    final manifest = _readJsonObject(path);
    if (manifest == null) return;

    if (manifest['name'] != 'flutter-monaco') {
      errors.add('$path: name must be flutter-monaco');
    }
    if (_nonEmptyString(manifest['description']) == null) {
      errors.add('$path: description must be a non-empty string');
    }

    final manifestVersion = _nonEmptyString(manifest['version']);
    if (manifestVersion == null) {
      errors.add('$path: version must be a non-empty string');
    } else if (packageVersion != null && manifestVersion != packageVersion) {
      errors.add(
        '$path: version $manifestVersion does not match '
        'pubspec version $packageVersion',
      );
    }

    if (path.contains('.codex-plugin')) {
      final skillsPath = _nonEmptyString(manifest['skills']);
      if (skillsPath != './skills/' && skillsPath != 'skills/') {
        errors.add('$path: skills must point to ./skills/');
      }
    }

    final allowedFields = path.contains('.codex-plugin')
        ? const <String>{
            r'$schema',
            'name',
            'version',
            'description',
            'author',
            'homepage',
            'repository',
            'license',
            'keywords',
            'skills',
            'interface',
          }
        : const <String>{
            r'$schema',
            'name',
            'displayName',
            'version',
            'description',
            'author',
            'homepage',
            'repository',
            'license',
            'keywords',
            'commands',
            'agents',
            'skills',
            'hooks',
            'mcpServers',
            'lspServers',
            'outputStyles',
          };
    final unsupportedFields =
        manifest.keys.toSet().difference(allowedFields).toList()..sort();
    if (unsupportedFields.isNotEmpty) {
      errors.add(
        '$path: unsupported manifest fields: ${unsupportedFields.join(', ')}',
      );
    }

    for (final forbiddenComponent in ['hooks', 'mcpServers', 'apps']) {
      if (manifest.containsKey(forbiddenComponent)) {
        errors.add(
          '$path: $forbiddenComponent is not part of this instruction-only '
          'plugin',
        );
      }
    }
  }

  void _validateSkills() {
    final skillsDirectory = _directory('$_pluginRoot/skills');
    if (!skillsDirectory.existsSync()) {
      errors.add('$_pluginRoot/skills is missing');
      return;
    }

    final actualSkillNames = skillsDirectory
        .listSync(followLinks: false)
        .whereType<Directory>()
        .map((directory) => _basename(directory.path))
        .toSet();
    final expectedSkillSet = expectedAiSkillNames.toSet();

    final missingSkills = expectedSkillSet.difference(actualSkillNames).toList()
      ..sort();
    final unexpectedSkills =
        actualSkillNames.difference(expectedSkillSet).toList()..sort();
    if (missingSkills.isNotEmpty) {
      errors.add('missing skill directories: ${missingSkills.join(', ')}');
    }
    if (unexpectedSkills.isNotEmpty) {
      errors.add(
        'unexpected skill directories: ${unexpectedSkills.join(', ')}',
      );
    }

    for (final skillName in expectedAiSkillNames) {
      _validateSkill(skillName);
    }
  }

  void _validateSkill(String skillName) {
    final skillPath = '$_pluginRoot/skills/$skillName/SKILL.md';
    final skillFile = _file(skillPath);
    if (!skillFile.existsSync()) {
      errors.add('$skillPath is missing');
      return;
    }

    final normalized = skillFile.readAsStringSync().replaceAll('\r\n', '\n');
    if (!normalized.startsWith('---\n')) {
      errors.add('$skillPath: YAML frontmatter must start on line 1');
    } else {
      final closingDelimiter = normalized.indexOf('\n---\n', 4);
      if (closingDelimiter == -1) {
        errors.add('$skillPath: YAML frontmatter is not closed');
      } else {
        final frontmatter = normalized.substring(4, closingDelimiter);
        final values = <String, String>{};
        for (final line in frontmatter.split('\n')) {
          if (line.trim().isEmpty) continue;
          final match = RegExp(r'^([A-Za-z][A-Za-z0-9_-]*):\s*(.+)$')
              .firstMatch(line);
          if (match == null) {
            errors.add('$skillPath: invalid frontmatter line "$line"');
            continue;
          }
          final key = match.group(1)!;
          if (values.containsKey(key)) {
            errors.add('$skillPath: duplicate frontmatter key "$key"');
          }
          values[key] = _stripYamlQuotes(match.group(2)!.trim());
        }
        if (values['name'] != skillName) {
          errors.add('$skillPath: frontmatter name must be $skillName');
        }
        final unsupportedKeys =
            values.keys
                .where((key) => key != 'name' && key != 'description')
                .toList()
              ..sort();
        if (unsupportedKeys.isNotEmpty) {
          errors.add(
            '$skillPath: shared frontmatter has unsupported keys: '
            '${unsupportedKeys.join(', ')}',
          );
        }
        final description = _nonEmptyString(values['description']);
        if (description == null || description.length < 30) {
          errors.add(
            '$skillPath: frontmatter description must explain the trigger',
          );
        }
      }
    }

    final openAiPath = '$_pluginRoot/skills/$skillName/agents/openai.yaml';
    final openAiFile = _file(openAiPath);
    if (!openAiFile.existsSync()) {
      errors.add('$openAiPath is missing');
      return;
    }

    final openAiYaml = openAiFile.readAsStringSync();
    if (!RegExp(r'^interface:\s*$', multiLine: true).hasMatch(openAiYaml)) {
      errors.add('$openAiPath: interface mapping is missing');
    }
    for (final key in ['display_name', 'short_description', 'default_prompt']) {
      if (_yamlScalar(openAiYaml, key) == null) {
        errors.add('$openAiPath: $key must be a non-empty scalar');
      }
    }
    final defaultPrompt = _yamlScalar(openAiYaml, 'default_prompt');
    if (defaultPrompt != null && !defaultPrompt.contains('\$$skillName')) {
      errors.add(
        '$openAiPath: default_prompt must explicitly invoke \$$skillName',
      );
    }

    final references = RegExp(r'\]\((references/[^)#]+\.md)(?:#[^)]+)?\)')
        .allMatches(normalized)
        .map((match) => match.group(1)!)
        .toSet();
    if (references.isEmpty) {
      errors.add(
        '$skillPath: must link at least one package-specific reference',
      );
    }
    for (final reference in references) {
      final referencePath = '$_pluginRoot/skills/$skillName/$reference';
      if (!_file(referencePath).existsSync()) {
        errors.add('$skillPath: linked reference $reference is missing');
      }
    }

    for (final marker in [
      '**Audience:**',
      '**Expected inputs:**',
      '**Realistic scenario:**',
    ]) {
      if (!normalized.contains(marker)) {
        errors.add(
          '$skillPath: must include $marker in its operating contract',
        );
      }
    }
    final requiredSectionPatterns = <MapEntry<String, RegExp>>[
      MapEntry(
        'workflow or method',
        RegExp(r'^## (?:Workflow|Method)\b', multiLine: true),
      ),
      MapEntry(
        'safety',
        RegExp(r'^## .*safety', multiLine: true, caseSensitive: false),
      ),
      MapEntry(
        'verification',
        RegExp(r'^## (?:Verification|.*Verification)', multiLine: true),
      ),
      MapEntry(
        'failure handling or stop conditions',
        RegExp(
          r'^## .*(?:failure|stop)',
          multiLine: true,
          caseSensitive: false,
        ),
      ),
    ];
    for (final requirement in requiredSectionPatterns) {
      if (!requirement.value.hasMatch(normalized)) {
        errors.add('$skillPath: must include a ${requirement.key} section');
      }
    }
  }

  void _validateEvaluations() {
    const path = '$_pluginRoot/evals/cases.json';
    final file = _file(path);
    if (!file.existsSync()) {
      errors.add('$path is missing');
      return;
    }

    Object? decoded;
    try {
      decoded = jsonDecode(file.readAsStringSync());
    } on FormatException catch (error) {
      errors.add('$path: invalid JSON: ${error.message}');
      return;
    }
    for (final error in validateEvaluationData(decoded)) {
      errors.add('$path: $error');
    }
  }

  void _validateMigrationFixtures() {
    const path =
        '$_pluginRoot/skills/migrate-flutter-monaco-v2-to-v3/fixtures/cases.json';
    final fixture = _file(path);
    if (!fixture.existsSync()) {
      errors.add('$path is missing');
      return;
    }

    Object? decoded;
    try {
      decoded = jsonDecode(fixture.readAsStringSync());
    } on FormatException catch (error) {
      errors.add('$path: invalid JSON: ${error.message}');
      return;
    }
    for (final error in validateMigrationFixtureData(decoded)) {
      errors.add('$path: $error');
    }
  }

  void _validatePubignore() {
    final file = _file('.pubignore');
    if (!file.existsSync()) {
      errors.add('.pubignore is missing');
      return;
    }

    final patterns = file
        .readAsLinesSync()
        .map((line) => line.split('#').first.trim().replaceAll('\\', '/'))
        .where((line) => line.isNotEmpty)
        .map((line) => line.startsWith('/') ? line.substring(1) : line)
        .toSet();
    const acceptedPluginPatterns = <String>{
      'plugins',
      'plugins/',
      'plugins/**',
      'plugins/**/*',
    };
    if (patterns.intersection(acceptedPluginPatterns).isEmpty) {
      errors.add(
        '.pubignore must exclude plugins/ so hidden manifests are not '
        'published without their marketplace entry points',
      );
    }
    for (final guidanceFile in ['AGENTS.md', 'CLAUDE.md']) {
      if (!patterns.contains(guidanceFile)) {
        errors.add('.pubignore must exclude $guidanceFile');
      }
    }
    for (final repositoryOnlyPath in [
      'test/ai_extensions/',
      'tool/validate_ai_extensions.dart',
      'tool/ai_extension_behavior_runner.dart',
    ]) {
      if (!patterns.contains(repositoryOnlyPath)) {
        errors.add(
          '.pubignore must exclude $repositoryOnlyPath because the AI plugin '
          'tree is repository-distributed',
        );
      }
    }
    if (!patterns.contains('doc/api/')) {
      errors.add(
        '.pubignore must exclude doc/api/ so generated dartdoc output does '
        'not inflate the package archive',
      );
    }
  }

  void _validateRequiredFiles() {
    const requiredFiles = <String>[
      'plugins/flutter-monaco/README.md',
      'plugins/flutter-monaco/LICENSE',
      'plugins/flutter-monaco/agents/bridge-contract-reviewer.md',
      '.codex/agents/bridge-contract-reviewer.toml',
      'doc/ai-assistant-support.md',
      'AGENTS.md',
      'CLAUDE.md',
      'tool/ai_extension_behavior_runner.dart',
      'test/ai_extensions/behavior_runner_test.dart',
    ];
    for (final path in requiredFiles) {
      if (!_file(path).existsSync()) errors.add('$path is missing');
    }

    final rootLicense = _file('LICENSE');
    final pluginLicense = _file('plugins/flutter-monaco/LICENSE');
    if (rootLicense.existsSync() &&
        pluginLicense.existsSync() &&
        packageOwnLicense(rootLicense.readAsStringSync()) !=
            pluginLicense.readAsStringSync()) {
      errors.add(
        "plugins/flutter-monaco/LICENSE must match the root LICENSE's "
        'package license',
      );
    }
  }

  void _validateReviewerAgents() {
    const canonicalSkill = 'maintain-flutter-monaco-bridge/SKILL.md';
    final claudePath =
        'plugins/flutter-monaco/agents/bridge-contract-reviewer.md';
    final claudeFile = _file(claudePath);
    if (claudeFile.existsSync()) {
      final content = claudeFile.readAsStringSync();
      if (!content.contains('tools: ["Read", "Grep", "Glob"]')) {
        errors.add(
          '$claudePath: tools must be limited to Read, Grep, and Glob',
        );
      }
      if (!content.contains(canonicalSkill) ||
          !RegExp(r'\bread-only\b', caseSensitive: false).hasMatch(content)) {
        errors.add(
          '$claudePath: reviewer must be read-only and use the canonical skill',
        );
      }
    }

    const codexPath = '.codex/agents/bridge-contract-reviewer.toml';
    final codexFile = _file(codexPath);
    if (codexFile.existsSync()) {
      final content = codexFile.readAsStringSync();
      if (!RegExp(
        r'^sandbox_mode\s*=\s*"read-only"\s*$',
        multiLine: true,
      ).hasMatch(content)) {
        errors.add('$codexPath: sandbox_mode must be read-only');
      }
      if (!content.contains(canonicalSkill)) {
        errors.add('$codexPath: reviewer must use the canonical skill');
      }
    }
  }

  void _validateRootGuidance() {
    final agents = _file('AGENTS.md');
    final claude = _file('CLAUDE.md');
    if (agents.existsSync() && agents.readAsStringSync().trim().isEmpty) {
      errors.add('AGENTS.md must contain repository guidance');
    }
    if (claude.existsSync() && claude.readAsStringSync() != '@AGENTS.md\n') {
      errors.add('CLAUDE.md must contain only the native @AGENTS.md import');
    }
  }

  void _validateNativeMetadata(String? packageVersion) {
    const path = 'macos/flutter_monaco.podspec';
    final file = _file(path);
    if (!file.existsSync()) {
      errors.add('$path is missing');
      return;
    }
    final match = RegExp(
      r'''^\s*s\.version\s*=\s*['"]([^'"]+)['"]\s*$''',
      multiLine: true,
    ).firstMatch(file.readAsStringSync());
    if (match == null) {
      errors.add('$path does not declare s.version');
    } else if (packageVersion != null && match.group(1) != packageVersion) {
      errors.add(
        '$path version ${match.group(1)} does not match pubspec version '
        '$packageVersion',
      );
    }
  }

  void _validatePluginTreeHygiene() {
    errors.addAll(
      validatePluginTreeHygiene(
        _directory(_pluginRoot),
        pathPrefix: _pluginRoot,
      ),
    );
  }

  void _validatePluginTextFiles() {
    final pluginDirectory = _directory(_pluginRoot);
    if (!pluginDirectory.existsSync()) return;

    final supportedExtensions = <String>{
      '.json',
      '.md',
      '.toml',
      '.yaml',
      '.yml',
    };
    final forbiddenContent = <MapEntry<RegExp, String>>[
      MapEntry(RegExp(r'\bTODO\b', caseSensitive: false), 'TODO marker'),
      MapEntry(RegExp(r'\bFIXME\b', caseSensitive: false), 'FIXME marker'),
      MapEntry(RegExp(r'\bTBD\b', caseSensitive: false), 'TBD marker'),
      MapEntry(
        RegExp(r'\bREPLACE[_ -]?ME\b', caseSensitive: false),
        'replace-me placeholder',
      ),
      MapEntry(
        RegExp(
          r'''(^|[\s`"'(])/(?:Users|home|private|tmp|var/folders|absolute)(?:/|\\)''',
        ),
        'machine-specific absolute path',
      ),
      MapEntry(
        RegExp(
          r'''\bfile:///(?:Users|home|private|tmp|var/folders|absolute)(?:/|\b)''',
        ),
        'machine-specific file URI',
      ),
      MapEntry(
        RegExp(
          r'''(^|[\s`"'(])[A-Za-z]:[\\/](?:Users|home|Temp)(?:[\\/]|\b)''',
        ),
        'machine-specific Windows path',
      ),
      MapEntry(
        RegExp(r'''(^|[\s`"'(])\.\.(?:/|\\)'''),
        'parent-directory traversal',
      ),
      MapEntry(
        RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
        'private key material',
      ),
      MapEntry(
        RegExp(
          r'\b(?:sk-(?:proj-|ant-)?|ghp_|github_pat_|glpat-)[A-Za-z0-9_-]{16,}',
        ),
        'token-shaped secret',
      ),
      MapEntry(RegExp(r'\bAKIA[0-9A-Z]{16}\b'), 'AWS access key'),
      MapEntry(RegExp(r'\bAIza[0-9A-Za-z_-]{30,}\b'), 'Google API key'),
      MapEntry(RegExp(r'\bxox[baprs]-[0-9A-Za-z-]{16,}\b'), 'Slack token'),
    ];

    for (final entity in pluginDirectory.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is Link) {
        errors.add(
          '${_relativePath(entity.path)}: symbolic links are forbidden',
        );
        continue;
      }
      if (entity is! File) continue;
      if (!Platform.isWindows && (entity.statSync().mode & 0x49) != 0) {
        errors.add(
          '${_relativePath(entity.path)}: executable files are not allowed in '
          'this instruction-only plugin',
        );
      }
      final extension = _extension(entity.path).toLowerCase();
      if (!supportedExtensions.contains(extension)) continue;

      final relativePath = _relativePath(entity.path);
      final content = entity.readAsStringSync();
      for (final forbidden in forbiddenContent) {
        if (forbidden.key.hasMatch(content)) {
          errors.add('$relativePath: contains ${forbidden.value}');
        }
      }
    }
  }

  Map<String, Object?>? _readJsonObject(String path) {
    final file = _file(path);
    if (!file.existsSync()) {
      errors.add('$path is missing');
      return null;
    }

    try {
      final decoded = jsonDecode(file.readAsStringSync());
      final object = _asStringKeyedMap(decoded);
      if (object == null) {
        errors.add('$path: root must be a JSON object');
      }
      return object;
    } on FormatException catch (error) {
      errors.add('$path: invalid JSON: ${error.message}');
      return null;
    }
  }

  File _file(String relativePath) =>
      File.fromUri(root.uri.resolve(relativePath));

  Directory _directory(String relativePath) =>
      Directory.fromUri(root.uri.resolve('$relativePath/'));

  String _relativePath(String absolutePath) {
    final normalizedRoot = root.path.replaceAll('\\', '/');
    final normalizedPath = absolutePath.replaceAll('\\', '/');
    if (normalizedPath.startsWith('$normalizedRoot/')) {
      return normalizedPath.substring(normalizedRoot.length + 1);
    }
    return normalizedPath;
  }
}

Map<String, Object?>? _asStringKeyedMap(Object? value) {
  if (value is! Map) return null;
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) return null;
    result[entry.key as String] = entry.value;
  }
  return result;
}

String? _nonEmptyString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _stripYamlQuotes(String value) {
  if (value.length >= 2 &&
      ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'")))) {
    return value.substring(1, value.length - 1);
  }
  return value;
}

String? _yamlScalar(String yaml, String key) {
  final match = RegExp(
    '^\\s*$key:\\s*(.+?)\\s*\$',
    multiLine: true,
  ).firstMatch(yaml);
  if (match == null) return null;
  return _nonEmptyString(_stripYamlQuotes(match.group(1)!.trim()));
}

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.substring(normalized.lastIndexOf('/') + 1);
}

String _extension(String path) {
  final basename = _basename(path);
  final dot = basename.lastIndexOf('.');
  return dot == -1 ? '' : basename.substring(dot);
}

String _relativeToDirectory(Directory root, String absolutePath) {
  final normalizedRoot = root.absolute.path.replaceAll('\\', '/');
  final normalizedPath = File(absolutePath).absolute.path.replaceAll('\\', '/');
  final prefix = normalizedRoot.endsWith('/')
      ? normalizedRoot
      : '$normalizedRoot/';
  return normalizedPath.startsWith(prefix)
      ? normalizedPath.substring(prefix.length)
      : normalizedPath;
}
