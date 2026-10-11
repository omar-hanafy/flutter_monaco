/// Helpers that check the generated page's JavaScript the way a browser
/// would, using Node: string assertions cannot tell whether an interpolated
/// value still parses.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// The bodies of every inline `<script>` element (those without `src`).
List<String> inlineScriptsIn(String html) =>
    RegExp(r'<script>([\s\S]*?)</script>')
        .allMatches(html)
        .map((m) => m.group(1)!)
        .toList();

/// Whether a `node` executable is available; tests that execute page
/// JavaScript skip with this reason when it is not.
final String? nodeUnavailableReason = () {
  try {
    final result = Process.runSync('node', ['--version']);
    return result.exitCode == 0 ? null : 'node --version failed';
  } on ProcessException {
    return 'Node.js is not installed';
  }
}();

/// Runs `node --check` over each of [scripts]; returns the failures, each
/// naming the script and Node's SyntaxError.
Future<List<String>> jsSyntaxErrors(List<String> scripts) async {
  final dir = await Directory.systemTemp.createTemp('fm_page_scripts_');
  try {
    final failures = <String>[];
    for (var i = 0; i < scripts.length; i++) {
      final file = File(p.join(dir.path, 'script_$i.js'))
        ..writeAsStringSync(scripts[i]);
      final result = await Process.run('node', ['--check', file.path]);
      if (result.exitCode != 0) {
        failures.add('script $i: ${result.stderr}\n${scripts[i]}');
      }
    }
    return failures;
  } finally {
    await dir.delete(recursive: true);
  }
}

/// Evaluates [script] in a fresh Node `vm` context with a recording
/// `console`, then evaluates [expression] there and returns its JSON value.
Future<Object?> evaluateInNode(String script, String expression) async {
  final dir = await Directory.systemTemp.createTemp('fm_page_eval_');
  try {
    final runner = File(p.join(dir.path, 'run.cjs'))
      ..writeAsStringSync('''
const vm = require('vm');
const fs = require('fs');
const context = vm.createContext({ console: { log() {}, warn() {}, error() {} } });
vm.runInContext(fs.readFileSync(process.argv[2], 'utf8'), context);
process.stdout.write(JSON.stringify(vm.runInContext(process.argv[3], context)));
''');
    final scriptFile = File(p.join(dir.path, 'script.js'))
      ..writeAsStringSync(script);
    final result = await Process.run('node', [
      runner.path,
      scriptFile.path,
      expression,
    ]);
    if (result.exitCode != 0) {
      throw StateError('node failed: ${result.stderr}');
    }
    return jsonDecode(result.stdout as String);
  } finally {
    await dir.delete(recursive: true);
  }
}
