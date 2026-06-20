import 'package:flutter_monaco/flutter_monaco.dart';

/// Registration id for the custom playground theme.
const String kMidnightThemeId = 'flutter-monaco-midnight';

/// A custom theme registered via [MonacoController.defineTheme], proving that
/// apps can ship their own Monaco themes (not just the built-in four).
final MonacoThemeDefinition kMidnightTheme = MonacoThemeDefinition(
  id: kMidnightThemeId,
  base: MonacoTheme.vsDark,
  rules: const [
    MonacoThemeRule(
      token: 'comment',
      foreground: '6E7681',
      fontStyle: 'italic',
    ),
    MonacoThemeRule(token: 'keyword', foreground: '6E5BFF'),
    MonacoThemeRule(token: 'string', foreground: '00D8FF'),
    MonacoThemeRule(token: 'number', foreground: '7EE787'),
    MonacoThemeRule(token: 'type', foreground: '0098FF'),
    MonacoThemeRule(token: 'function', foreground: 'D2A8FF'),
  ],
  colors: const {
    'editor.background': '#0D1117',
    'editor.foreground': '#E6EDF3',
    'editorLineNumber.foreground': '#484F58',
    'editorCursor.foreground': '#00D8FF',
    'editor.selectionBackground': '#1F6FEB44',
    'editor.lineHighlightBackground': '#161B22',
    'editorIndentGuide.background1': '#21262D',
  },
);

/// Static completion items registered on the playground editor. They surface
/// for the languages passed to `registerStaticCompletions`.
const List<CompletionItem> kDemoCompletions = [
  CompletionItem(
    label: 'pr',
    kind: CompletionItemKind.snippet,
    insertText: r'print(${1:value});',
    insertTextRules: {InsertTextRule.insertAsSnippet},
    detail: 'print(...)',
    documentation:
        'Print a value to the console (flutter_monaco demo snippet).',
  ),
  CompletionItem(
    label: 'todo',
    kind: CompletionItemKind.snippet,
    insertText: r'// TODO(${1:you}): ${2:description}',
    insertTextRules: {InsertTextRule.insertAsSnippet},
    detail: 'TODO comment',
    documentation: 'Insert a tagged TODO comment.',
  ),
  CompletionItem(
    label: 'flutterMonaco',
    kind: CompletionItemKind.constant,
    insertText: 'flutter_monaco',
    detail: 'package name',
    documentation: 'The package powering this editor.',
  ),
];

/// A JSON document that is syntactically valid but violates [kJsonSchema]
/// (wrong types + an extra property), so schema squiggles appear immediately.
const String kInvalidJsonSample = '''
{
  "name": "flutter_monaco",
  "version": 2,
  "port": "8080",
  "extra": true
}
''';

/// Options enabling JSON schema validation against [kJsonSchema] for any model.
final JsonDiagnosticsOptions kJsonDiagnostics = JsonDiagnosticsOptions(
  validate: true,
  allowComments: true,
  schemaValidation: DiagnosticsSeverity.error,
  schemas: [
    JsonDiagnosticsSchema(
      uri: Uri.parse('https://flutter-monaco.dev/demo.schema.json'),
      fileMatch: const ['*'],
      schema: const {
        r'$schema': 'http://json-schema.org/draft-07/schema#',
        'type': 'object',
        'additionalProperties': false,
        'required': ['name', 'version', 'port'],
        'properties': {
          'name': {'type': 'string'},
          'version': {'type': 'string'},
          'port': {'type': 'integer', 'minimum': 1, 'maximum': 65535},
          'debug': {'type': 'boolean'},
        },
      },
    ),
  ],
);

/// A short snippet used by the markers demo so the diagnostics line up with
/// real code.
const String kMarkersDemoCode = '''
function calculateTotal(items) {
  var total = 0;
  let unused = 42;
  for (const item of items) {
    total += item.price;
  }
  return total;
}
''';

/// Error markers positioned against [kMarkersDemoCode].
const List<MarkerData> kDemoErrorMarkers = [
  MarkerData(
    range: Range(startLine: 5, startColumn: 14, endLine: 5, endColumn: 24),
    message: "Object is possibly 'undefined'.",
    severity: MarkerSeverity.error,
    code: 'TS2532',
    source: 'flutter_monaco demo',
  ),
];

/// Warning markers positioned against [kMarkersDemoCode].
const List<MarkerData> kDemoWarningMarkers = [
  MarkerData(
    range: Range(startLine: 2, startColumn: 3, endLine: 2, endColumn: 6),
    message: "Unexpected 'var', prefer 'let' or 'const'.",
    severity: MarkerSeverity.warning,
    source: 'flutter_monaco demo',
  ),
  MarkerData(
    range: Range(startLine: 3, startColumn: 7, endLine: 3, endColumn: 13),
    message: "'unused' is assigned a value but never used.",
    severity: MarkerSeverity.warning,
    source: 'flutter_monaco demo',
  ),
];

/// CSS injected into the editor's host page so decoration class names render.
/// Used by the decorations demo (`addLineDecorations`).
const String kEditorCustomCss = '''
.demo-line-highlight {
  background: rgba(110, 91, 255, 0.16);
}
.demo-line-highlight-glyph {
  background: #00d8ff;
  width: 4px !important;
  margin-left: 3px;
  border-radius: 2px;
}
''';
