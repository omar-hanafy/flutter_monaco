import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/validate_ai_extensions.dart';

void main() {
  test('repository AI extensions satisfy the shared contract', () {
    final repositoryRoot = _findRepositoryRoot();

    final report = validateAiExtensions(repositoryRoot);

    expect(report.errors, isEmpty, reason: report.errors.join('\n'));
  });

  test('evaluation validation catches duplicate and incomplete coverage', () {
    final errors = validateEvaluationData(
      <String, Object?>{
        'schemaVersion': 1,
        'cases': <Object?>[
          <String, Object?>{
            'id': 'integration-positive',
            'skill': 'integrate-flutter-monaco',
            'kind': 'positive-selection',
            'prompt': 'Add a Monaco editor to this existing Flutter workspace.',
            'expectations': <String>[
              'Select the integration skill.',
              'Inspect the target platforms first.',
            ],
          },
          <String, Object?>{
            'id': 'integration-positive',
            'skill': 'integrate-flutter-monaco',
            'kind': 'positive-selection',
            'prompt':
                'Add another Monaco editor to a second Flutter workspace.',
            'expectations': <String>[
              'Select the integration skill.',
              'Inspect the package version first.',
            ],
          },
        ],
      },
      expectedSkills: const <String>['integrate-flutter-monaco'],
    );

    expect(errors, contains(contains('duplicates "integration-positive"')));
    expect(
      errors,
      contains(contains('duplicates positive-selection coverage')),
    );
    expect(errors, contains(contains('missing evaluation kinds')));
  });

  test('migration fixture validation requires every migration outcome', () {
    final errors = validateMigrationFixtureData(<String, Object?>{
      'schemaVersion': 1,
      'cases': <Object?>[
        <String, Object?>{
          'id': 'normal-only',
          'kind': 'normal',
          'sourceVersion': '2.3.0',
          'targetVersion': '3.4.2',
          'input': 'await controller.setValue(source);',
          'expectedDisposition': 'migrate',
          'expectedOutput': 'await controller.document.setText(source);',
          'expectedEvidence': <String>['legacy API', 'current API'],
        },
      ],
    });

    expect(errors, contains(contains('migration fixtures are missing kinds')));
    expect(
      errors,
      contains(contains('normal fixture must prove legacy content')),
    );
  });

  test('plugin tree hygiene rejects generated filesystem junk', () {
    final directory = Directory.systemTemp.createTempSync(
      'flutter-monaco-plugin-hygiene-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));

    File.fromUri(directory.uri.resolve('.claude-plugin/plugin.json'))
      ..createSync(recursive: true)
      ..writeAsStringSync('{}');
    File.fromUri(directory.uri.resolve('skills/example/SKILL.md'))
      ..createSync(recursive: true)
      ..writeAsStringSync('# Valid plugin content\n');
    File.fromUri(directory.uri.resolve('.DS_Store')).writeAsBytesSync(<int>[0]);
    File.fromUri(directory.uri.resolve('skills/example/Thumbs.db'))
        .writeAsBytesSync(<int>[0]);
    File.fromUri(directory.uri.resolve('skills/example/SKILL.md.swp'))
        .writeAsBytesSync(<int>[0]);

    final errors = validatePluginTreeHygiene(
      directory,
      pathPrefix: 'plugins/flutter-monaco',
    );

    expect(
      errors,
      contains(
        'plugins/flutter-monaco/.DS_Store: '
        'generated filesystem junk is forbidden',
      ),
    );
    expect(
      errors,
      contains(
        'plugins/flutter-monaco/skills/example/Thumbs.db: '
        'generated filesystem junk is forbidden',
      ),
    );
    expect(
      errors,
      contains(
        'plugins/flutter-monaco/skills/example/SKILL.md.swp: '
        'generated filesystem junk is forbidden',
      ),
    );
    expect(errors, hasLength(3));
  });
}

Directory _findRepositoryRoot() {
  var candidate = Directory.current.absolute;
  while (true) {
    if (File.fromUri(candidate.uri.resolve('pubspec.yaml')).existsSync()) {
      return candidate;
    }
    final parent = candidate.parent;
    if (parent.path == candidate.path) {
      throw StateError('Could not locate the repository root.');
    }
    candidate = parent;
  }
}
