# Flutter Monaco

[![pub package](https://img.shields.io/pub/v/flutter_monaco.svg?label=pub)](https://omar-hanafy.github.io/flutter-monaco/)
[![License: MIT](https://img.shields.io/badge/License-MIT-success.svg)](https://omar-hanafy.github.io/flutter-monaco/)
[![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Windows%20%7C%20Web-blue)](https://omar-hanafy.github.io/flutter-monaco/)

A Flutter plugin for integrating the Monaco Editor (VS Code's editor) into Flutter applications via WebView.

Check the [live demo here](https://omar-hanafy.github.io/flutter-monaco/) to try Flutter Monaco in your browser.

<p align="center">
  <a href="https://omar-hanafy.github.io/flutter-monaco/">
    <img src="https://github.com/omar-hanafy/flutter_monaco/blob/main/screenshots/macos.png?raw=true" alt="Flutter Monaco Editor on macOS" width="90%">
  </a>
</p>

## Features

- 🎨 **Full Monaco Editor** - The same editor that powers VS Code
- 🌐 **100+ Language Support** - Syntax highlighting for all major languages
- 🎭 **Multiple Themes** - Dark, Light, and High Contrast themes
- 💾 **Versioned Asset Caching** - Efficient one-time asset installation
- 🖥️ **Cross-Platform** - Works on Android, iOS, macOS, Windows, and Web
- ⚡ **Multiple Editors** - Support for unlimited independent editor instances
- 📊 **Live Statistics** - Real-time line/character counts and selection info
- 🎯 **Type-safe API** - Comprehensive typed bindings for Monaco's JavaScript API
- 🧠 **Custom IntelliSense** - Register multiple completion providers (static or remote)
- 🔍 **Find & Replace** - Full programmatic find/replace with regex support
- 🎭 **Decorations & Markers** - Add highlights, errors, warnings to your code
- 📡 **Event Streams** - Listen to content changes, selection, focus events
- 🎨 **Themeable Chrome** - Customize loading, error, and status-bar UI via `MonacoEditorTheme`
- 🧰 **Typed Actions** - `MonacoAction` constants cover Monaco's full command surface (fold, indent, comment, format, find, and more)

> **⚠️ Platform Support:** Currently supports **Android**, **iOS**, **macOS**, **Windows**, and **Web**. Linux is **not supported** at this time.

## Screenshots

<table>
  <tr>
    <td align="center" width="50%"><b>iOS</b></td>
    <td align="center" width="50%"><b>Android</b></td>
  </tr>
  <tr>
    <td><a href="https://omar-hanafy.github.io/flutter-monaco/"><img src="https://github.com/omar-hanafy/flutter_monaco/blob/main/screenshots/ios.jpg?raw=true" alt="iOS Screenshot" width="100%"></a></td>
    <td><a href="https://omar-hanafy.github.io/flutter-monaco/"><img src="https://github.com/omar-hanafy/flutter_monaco/blob/main/screenshots/android.jpg?raw=true" alt="Android Screenshot" width="100%"></a></td>
  </tr>
  <tr>
    <td align="center" colspan="2"><b>Windows</b></td>
  </tr>
  <tr>
    <td colspan="2"><a href="https://omar-hanafy.github.io/flutter-monaco/"><img src="https://github.com/omar-hanafy/flutter_monaco/blob/main/screenshots/windows.png?raw=true" alt="Windows Screenshot" width="100%"></a></td>
  </tr>
  <tr>
    <td align="center" colspan="2"><b>Web</b></td>
  </tr>
  <tr>
    <td colspan="2"><a href="https://omar-hanafy.github.io/flutter-monaco/"><img src="https://github.com/omar-hanafy/flutter_monaco/blob/main/screenshots/web.png?raw=true" alt="Web Screenshot" width="100%"></a></td>
  </tr>
</table>

## Known Issues

- **Windows window focus flicker.** When clicking inside the embedded WebView (Monaco) on Windows, the host Flutter window may momentarily lose activation, which disables global keyboard shortcuts until the next click. This is a `flutter_webview_windows`/WebView2 quirk tracked upstream in [jnschulze/flutter-webview-windows#230](https://github.com/jnschulze/flutter-webview-windows/issues/230). We are monitoring that issue and will adopt the upstream fix as soon as it lands. Other platforms are unaffected.

## Installation

Add `flutter_monaco` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_monaco: ^<latest version>
```

## Migrating from another Flutter code editor

If you're moving from another Flutter code editor package (such as `flutter_code_editor`), keep your existing settings model and toolbar wiring - map them into Monaco's typed APIs instead of replacing your app structure.

### 1. Map app settings to `EditorOptions`

```dart
class CodeEditorSettings {
  const CodeEditorSettings({
    required this.languageId,
    required this.themeId,
    required this.fontSize,
    required this.tabSize,
    required this.wordWrap,
  });

  final String languageId;
  final String themeId; // built-in id ("vs-dark") or custom theme id
  final double fontSize;
  final int tabSize;
  final bool wordWrap;
}

EditorOptions toMonacoOptions(CodeEditorSettings s) {
  return EditorOptions(
    language: MonacoLanguage.fromId(s.languageId),
    theme: MonacoTheme.vsDark,
    themeId: s.themeId, // overrides theme when set; custom themes work too
    fontSize: s.fontSize,
    tabSize: s.tabSize,
    wordWrap: s.wordWrap,
  );
}
```

### 2. Persist and register custom themes once

Use `MonacoThemeDefinition` for custom syntax themes that should round-trip with your app settings:

```dart
const appDark = MonacoThemeDefinition(
  id: 'app-dark',
  base: MonacoTheme.vsDark,
  rules: [
    MonacoThemeRule(token: 'comment', foreground: '6A9955', fontStyle: 'italic'),
  ],
  colors: {
    'editor.background': '#1E1E1E',
    'editor.foreground': '#D4D4D4',
  },
);

await controller.defineTheme(appDark);
await controller.setThemeById('app-dark'); // or set EditorOptions.themeId
```

For Monaco theme JSON exported elsewhere, use `controller.defineThemeFromJson(id, data)`.

### 3. Style the editor chrome with `MonacoEditorTheme`

Customize the built-in loading/error/status-bar widgets without replacing them:

```dart
MonacoEditorTheme(
  data: MonacoEditorThemeData(
    statusBarBackgroundColor: Theme.of(context).colorScheme.surface,
    statusBarBorderColor: Theme.of(context).dividerColor,
    loadingIndicatorColor: Theme.of(context).colorScheme.primary,
  ),
  child: MonacoEditor(options: options, showStatusBar: true),
);
```

### 4. Wire toolbar buttons through the controller

Dispatch any Monaco command via `executeAction` with a typed `MonacoAction` constant:

```dart
await controller.executeAction(MonacoAction.foldAll);
await controller.executeAction(MonacoAction.unfoldAll);
await controller.executeAction(MonacoAction.commentLine);
await controller.executeAction(MonacoAction.indentLines);
await controller.executeAction(MonacoAction.outdentLines);
await controller.executeAction(MonacoAction.formatDocument);
```

`MonacoAction` exposes the full set of Monaco's built-in command ids as autocomplete-friendly constants. For commands not enumerated (e.g. custom actions registered via Monaco's `editor.addCommand`), pass the raw id string to `executeAction` instead.

### 5. Backgrounds

`setBackgroundColor` recolors the native WebView container. `setHostPageBackgroundColor` recolors Monaco's HTML host page (more reliable on macOS). To recolor Monaco's editor surface itself, set `editor.background` in a `MonacoThemeDefinition` rather than relying on these.

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Flutter Monaco',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Monaco Editor'),
        ),
        body: const MonacoEditor(
          showStatusBar: true,
        ),
      ),
    ),
  );
}
```

## Type-Safe Enums

Flutter Monaco provides type-safe enums for all configuration options, preventing runtime errors from invalid string values:

```dart
// Languages - 70+ programming languages supported
const EditorOptions(
  language: MonacoLanguage.typescript,  // Instead of 'typescript'
  theme: MonacoTheme.vsDark,           // Instead of 'vs-dark'
  cursorBlinking: CursorBlinking.smooth,
  cursorStyle: CursorStyle.block,
  renderWhitespace: RenderWhitespace.boundary,
  autoClosingBrackets: AutoClosingBehavior.languageDefined,
  autoClosingQuotes: AutoClosingBehavior.languageDefined,
);

// Dynamic language selection (when loading from user preferences, etc.)
final language = MonacoLanguage.fromId('python');  // Convert string to enum
await controller.setLanguage(language);

// Theme selection with dynamic conversion
final theme = MonacoTheme.fromId('vs-dark');  // Convert string to enum
await controller.setTheme(theme);
```

### Available Enums

**MonacoTheme**

- `MonacoTheme.vs` - Light theme
- `MonacoTheme.vsDark` - Dark theme
- `MonacoTheme.hcBlack` - High contrast dark
- `MonacoTheme.hcLight` - High contrast light

**MonacoLanguage** (70+ languages including)

- `MonacoLanguage.javascript`, `MonacoLanguage.typescript`, `MonacoLanguage.python`
- `MonacoLanguage.dart`, `MonacoLanguage.java`, `MonacoLanguage.csharp`
- `MonacoLanguage.go`, `MonacoLanguage.rust`, `MonacoLanguage.swift`
- `MonacoLanguage.html`, `MonacoLanguage.css`, `MonacoLanguage.scss`
- `MonacoLanguage.json`, `MonacoLanguage.yaml`, `MonacoLanguage.xml`
- `MonacoLanguage.markdown`, `MonacoLanguage.sql`, `MonacoLanguage.dockerfile`
- And many more...

**CursorBlinking**

- `CursorBlinking.blink` - Default blinking
- `CursorBlinking.smooth` - Smooth fade animation
- `CursorBlinking.phase` - Phase animation
- `CursorBlinking.expand` - Expand animation
- `CursorBlinking.solid` - No blinking

**CursorStyle**

- `CursorStyle.line` - Vertical line (default)
- `CursorStyle.block` - Block cursor
- `CursorStyle.underline` - Underline cursor
- `CursorStyle.lineThin` - Thin vertical line
- `CursorStyle.blockOutline` - Outlined block
- `CursorStyle.underlineThin` - Thin underline

**RenderWhitespace**

- `RenderWhitespace.none` - Don't render whitespace
- `RenderWhitespace.boundary` - Render whitespace at word boundaries
- `RenderWhitespace.selection` - Render whitespace in selection
- `RenderWhitespace.trailing` - Render trailing whitespace
- `RenderWhitespace.all` - Render all whitespace

**AutoClosingBehavior (Brackets and Quotes)**

- `AutoClosingBehavior.always` - Always auto-close brackets
- `AutoClosingBehavior.languageDefined` - Use language defaults
- `AutoClosingBehavior.beforeWhitespace` - Auto-close before whitespace
- `AutoClosingBehavior.never` - Never auto-close

## Custom IntelliSense Completions

Monaco already knows how to merge results from multiple completion providers. Flutter Monaco now exposes this capability with a tiny, type-safe API that keeps all of the heavy lifting in Dart. Register static keyword/snippet lists or dynamic providers that call your own services.

```dart
// Note: On web, prefer MonacoEditor with onReady instead of calling create.
final controller = await MonacoController.create(
  options: const EditorOptions(
    language: MonacoLanguage.typescript,
    theme: MonacoTheme.vsDark,
  ),
);

// Static completions (keywords/snippets/etc.)
await controller.registerStaticCompletions(
  id: 'keywords',
  languages: [
    MonacoLanguage.typescript.id,
    MonacoLanguage.javascript.id,
  ],
  triggerCharacters: const [' ', '.'],
  items: const [
    CompletionItem(
      label: 'pipeline',
      kind: CompletionItemKind.snippet,
      detail: 'Begin a pipeline section',
      documentation: 'Expands to a snippet with placeholders.',
      insertText: 'pipeline(${1:source}) {\n  ${2:// body}\n}',
      insertTextRules: {InsertTextRule.insertAsSnippet},
    ),
    CompletionItem(
      label: 'logger.info',
      kind: CompletionItemKind.method,
      detail: 'Log a message at INFO level',
      documentation: 'Simple helper around window.logger',
    ),
  ],
);

// Dynamic completions - call your own API or local data
await controller.registerCompletionSource(
  id: 'acme-api',
  languages: [MonacoLanguage.typescript.id],
  triggerCharacters: const ['.', '_'],
  provider: (CompletionRequest request) async {
    // You get request.language, uri, cursor position, current line, etc.
    final token = _currentWord(request);

    // Call your service (HTTP, database, anything)
    final response = await _completionClient.fetch(
      language: request.language,
      word: token,
      contextLine: request.lineText,
    );

    return CompletionList(
      suggestions: response.suggestions
          .map(
            (result) => CompletionItem(
              label: result.label,
              insertText: result.insertText,
              detail: result.detail,
              documentation: result.documentation,
              kind: CompletionItemKind.method,
              range: request.defaultRange,
            ),
          )
          .toList(),
      isIncomplete: response.hasMore,
    );
  },
);
```

Helper to grab the token before the cursor:

```dart
String _currentWord(CompletionRequest request) {
  final line = request.lineText ?? '';
  if (line.isEmpty) return '';
  final cursor = (request.position.column - 1).clamp(0, line.length);
  final prefix = line.substring(0, cursor);
  final match = RegExp(r'([a-zA-Z0-9_.]+)$').firstMatch(prefix);
  return match?.group(0) ?? '';
}
```

`CompletionRequest` includes useful metadata:

- `providerId`, `requestId` – identify the provider and respond to Monaco.
- `language`, `uri` – the model that triggered the request.
- `position`, `defaultRange`, `lineText` – cursor info plus the word range Monaco wants you to replace.
- `triggerKind`, `triggerCharacter` – what caused the completion (manual `Ctrl+Space`, character, etc.).

Need to remove a provider? Call `controller.unregisterCompletionSource(id)` at any time. You can register as many providers as you need. Monaco merges them and sorts via each item's `sortText`.

## Multiple Editors Example

Create a multi-editor layout with different languages and themes. This approach works on all platforms including web:

```dart
class MultiEditorView extends StatefulWidget {
  @override
  State<MultiEditorView> createState() => _MultiEditorViewState();
}

class _MultiEditorViewState extends State<MultiEditorView> {
  MonacoController? _dartController;
  MonacoController? _jsController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dart editor
        Expanded(
          child: MonacoEditor(
            initialValue: '// Dart code\nvoid main() {}',
            options: const EditorOptions(
              language: MonacoLanguage.dart,
              theme: MonacoTheme.vsDark,
            ),
            onReady: (c) => setState(() => _dartController = c),
          ),
        ),
        const Divider(height: 1),
        // JavaScript editor
        Expanded(
          child: MonacoEditor(
            initialValue: '// JavaScript code\nfunction main() {}',
            options: const EditorOptions(
              language: MonacoLanguage.javascript,
              theme: MonacoTheme.vs,  // Light theme
            ),
            onReady: (c) => setState(() => _jsController = c),
          ),
        ),
      ],
    );
  }
}
```

Alternative for native platforms only: if you need more control, you can still use `MonacoController.create()` directly:

```dart
// Native platforms only. On web, use MonacoEditor and onReady instead.
Future<void> _initializeEditors() async {
  _dartController = await MonacoController.create(
    options: const EditorOptions(
      language: MonacoLanguage.dart,
      theme: MonacoTheme.vsDark,
    ),
  );
  await _dartController!.setValue('// Dart code');
  setState(() {});
}
```

## API Reference

### MonacoController

Main controller for interacting with the editor:

```dart
// Content management
await controller.setValue('const x = 42;');
String content = await controller.getValue();

// Language and theme (type-safe enums)
await controller.setLanguage(MonacoLanguage.javascript);
await controller.setTheme(MonacoTheme.vsDark);

// Editor actions
await controller.format();           // Format document
await controller.find();             // Open find dialog
await controller.replace();          // Open replace dialog
await controller.selectAll();        // Select all text
await controller.undo();             // Undo last action
await controller.redo();             // Redo last undone action

// Clipboard
await controller.cut();
await controller.copy();
await controller.paste();

// Navigation
await controller.scrollToTop();
await controller.scrollToBottom();
await controller.revealLine(100);    // Jump to line 100
await controller.focus();            // Request focus

// Custom actions (type-safe action ids)
await controller.executeAction(MonacoAction.toggleLineComment);
// Or use a raw Monaco action id string if needed:
// await controller.executeAction('editor.action.commentLine');

// JavaScript escape hatch for uncovered Monaco APIs
await controller.runJavaScript('''
  monaco.languages.json.jsonDefaults.setDiagnosticsOptions({
    validate: true,
    schemas: [{
      uri: 'http://my-schema',
      fileMatch: ['*'],
      schema: { type: 'object' }
    }]
  });
''');

final editorCount = await controller.evaluateJavaScript<int>(
  'monaco.editor.getEditors().length',
);

final rawEditorCount = await controller.runJavaScriptReturningResultRaw(
  'monaco.editor.getEditors().length',
);

// Live statistics
controller.liveStats.addListener(() {
  final stats = controller.liveStats.value;
  print('Lines: ${stats.lineCount.value}');
  print('Characters: ${stats.charCount.value}');
  print('Selected: ${stats.selectedCharacters.value}');
});

// Event streams
controller.onContentChanged.listen((isFlush) {
  print('Content changed (full replace: $isFlush)');
});

controller.onSelectionChanged.listen((range) {
  print('Selection: $range');
});

controller.onFocus.listen((_) => print('Editor focused'));
controller.onBlur.listen((_) => print('Editor blurred'));
```

For a full set of bundled action IDs, use `MonacoAction` (exported by this
package) to avoid stringly-typed calls.

### JavaScript Escape Hatch

For Monaco APIs not yet wrapped by the typed Dart API, `MonacoController`
provides an advanced JavaScript escape hatch. Prefer typed methods such as
`setValue`, `getSelection`, `setMarkers`, and `executeAction` when they cover
your use case.

| Method | Use case |
| --- | --- |
| `runJavaScript(script)` | Fire-and-forget configuration or commands. |
| `evaluateJavaScript<T>(expression)` | Read a JSON-serializable value with cross-platform type normalization. |
| `runJavaScriptReturningResultRaw(script)` | Advanced raw platform-native result access. |

```dart
await controller.runJavaScript('''
  monaco.languages.json.jsonDefaults.setDiagnosticsOptions({
    validate: true,
    schemas: [{
      uri: 'http://my-schema',
      fileMatch: ['*'],
      schema: { type: 'object' }
    }]
  });
''');

final editorCount = await controller.evaluateJavaScript<int>(
  'monaco.editor.getEditors().length',
);
```

Use raw result access only when you specifically need platform-native WebView
behavior:

```dart
final raw = await controller.runJavaScriptReturningResultRaw(
  'monaco.editor.getEditors().length',
);
```

These methods do not sanitize input. Do not concatenate untrusted strings into
a script. Use `jsonEncode` to safely embed dynamic values:

```dart
import 'dart:convert';

// Bad if userInput is attacker-controlled.
await controller.runJavaScript('window.setName("$userInput")');

// Good: jsonEncode creates a safe JavaScript literal.
await controller.runJavaScript(
  'window.setName(${jsonEncode(userInput)})',
);
```

### Advanced Features

```dart
// Find and replace
final matches = await controller.findMatches(
  'TODO',
  options: const FindOptions(
    isRegex: false,
    matchCase: true,
    wholeWord: true,
  ),
);
print('Found ${matches.length} TODOs');

// Add error markers
await controller.setErrorMarkers([
  MarkerData.error(
    range: Range.lines(10, 10),
    message: 'Undefined variable',
    code: 'E001',
  ),
]);

// Add decorations (highlights)
await controller.addLineDecorations(
  [5, 10, 15],  // Line numbers
  'highlight-line',  // CSS class
);

// Work with multiple models
final uri = await controller.createModel(
  'console.log("New file");',
  language: MonacoLanguage.javascript.id,
);
await controller.setModel(uri);
```

### JSON Diagnostics

Enable schema-based validation for JSON content. Monaco will show inline errors and warnings based on the schemas you provide:

```dart
void _onEditorReady(MonacoController controller) {
  controller.setJsonDiagnostics(JsonDiagnosticsOptions(
    validate: true,
    allowComments: true,
    trailingCommas: DiagnosticsSeverity.warning,
    schemaValidation: DiagnosticsSeverity.error,
    schemas: [
      JsonDiagnosticsSchema(
        uri: Uri.parse('https://example.com/my-schema.json'),
        fileMatch: ['*'],
        schema: {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
            'version': {'type': 'integer'},
          },
          'required': ['name'],
        },
      ),
    ],
  ));
}
```

**DiagnosticsSeverity** values:
- `DiagnosticsSeverity.error` - Red squiggly underline
- `DiagnosticsSeverity.warning` - Yellow squiggly underline
- `DiagnosticsSeverity.ignore` - Suppress diagnostics

**Options reference:**

| Field | Type | Description |
|-------|------|-------------|
| `validate` | `bool?` | Enable schema validation |
| `allowComments` | `bool?` | Tolerate comments in JSON |
| `enableSchemaRequest` | `bool?` | Load remote schemas on demand via `fetch` |
| `schemaValidation` | `DiagnosticsSeverity?` | Severity for schema validation errors |
| `schemaRequest` | `DiagnosticsSeverity?` | Severity for schema fetch failures |
| `trailingCommas` | `DiagnosticsSeverity?` | Severity for trailing commas |
| `comments` | `DiagnosticsSeverity?` | Severity for comments (overrides `allowComments`) |
| `schemas` | `List<JsonDiagnosticsSchema>?` | Schema definitions and file associations |

**Note on `fileMatch`:** Patterns match against the Monaco model URI, not file paths. Use `['*']` to apply a schema to all JSON models, or set a meaningful model URI when calling `controller.createModel()`.

**Note on `enableSchemaRequest`:** Remote schema fetching requires the schema host to be allowed by the Content Security Policy. The default CSP uses `connect-src 'self' blob:`, which blocks external hosts. This package does not currently expose a public API for adding external hosts to `connect-src`, so prefer inline `schema` maps or schemas hosted where the current CSP already permits requests.

### EditorOptions

Configure the editor appearance and behavior with type-safe enums:

```dart
const EditorOptions(
  language: MonacoLanguage.javascript,
  theme: MonacoTheme.vsDark,      // vs, vsDark, hcBlack, hcLight
  fontSize: 14,
  fontFamily: 'Consolas, monospace',
  lineHeight: 1.4,                // Multiplier (< 8) or pixels (>= 8)
  wordWrap: true,                  // or false
  minimap: false,
  lineNumbers: true,               // or false
  rulers: [80, 120],
  tabSize: 2,
  insertSpaces: true,
  readOnly: false,
  automaticLayout: true,           // Auto-resize with container
  scrollBeyondLastLine: true,
  smoothScrolling: false,
  cursorBlinking: CursorBlinking.blink,    // blink, smooth, phase, expand, solid
  cursorStyle: CursorStyle.line,           // line, block, underline, lineThin, blockOutline, underlineThin
  renderWhitespace: RenderWhitespace.selection,  // none, boundary, selection, trailing, all
  bracketPairColorization: true,
  formatOnPaste: false,
  formatOnType: false,
  quickSuggestions: true,
  parameterHints: true,
  hover: true,
  contextMenu: true,
  mouseWheelZoom: false,
  autoClosingBrackets: AutoClosingBehavior.languageDefined,  // always, languageDefined, beforeWhitespace, never
  autoClosingQuotes: AutoClosingBehavior.languageDefined,    // always, languageDefined, beforeWhitespace, never
);
```

### MonacoAssets

Manage Monaco Editor assets:

```dart
// One-time initialization (called automatically)
await MonacoAssets.ensureReady();

// Get asset information
final info = await MonacoAssets.assetInfo();
print('Monaco cache: ${info['path']}');
print('Total size: ${info['totalSizeMB']} MB');
print('File count: ${info['fileCount']}');

// Clear cache (forces re-extraction on next use)
await MonacoAssets.clearCache();
```

### Web: Handling Overlays

Web platform only. This does not affect native platforms.

On Flutter Web, Monaco is hosted in an `iframe`. The browser routes pointer events inside that iframe to its own document first, so Flutter widgets that visually sit on top of the editor can appear correctly but never receive clicks or drags.

Common symptoms:

- Dialogs and popup menus are visible but their buttons do not respond
- Dragging across a dropdown highlights text inside the editor instead of the menu items
- FloatingActionButtons or other widgets stacked over the editor are unreactive

There are two kinds of overlays, and the package provides one primitive for each.

#### 1. Route overlays (dialogs, popup menus, dropdowns)

Anything pushed as a `ModalRoute` - `showDialog`, `showMenu`, `PopupMenuButton`, `DropdownButton`, modal bottom sheets. Provide a `MonacoRouteObserver` and place a `MonacoFocusGuard` near each editor. The guard listens for route pushes and disables iframe interaction automatically while the overlay is on top.

```dart
final MonacoRouteObserver monacoRouteObserver = MonacoRouteObserver();

MaterialApp(
  navigatorObservers: [monacoRouteObserver],
  // ...
);
```

```dart
MonacoFocusGuard(
  controller: controller,
  modalRouteObserver: monacoRouteObserver,
  // autoDisableInteraction defaults to true
)
```

#### 2. Static overlays (FABs, drawers, in-tree stacked widgets)

Persistent widgets that share the page with the editor - a `floatingActionButton`, a `Drawer`, a persistent footer, anything inside a `Stack` over the editor - do not push a route, so the focus guard cannot fire for them. The package provides two complementary tools:

**`MonacoScaffold`** - drop-in replacement for `Scaffold` that automatically protects the standard overlay slots (`floatingActionButton`, `drawer`, `endDrawer`, `bottomSheet`, `bottomNavigationBar`, `persistentFooterButtons`):

```dart
MonacoScaffold(
  appBar: AppBar(...),
  body: MonacoEditor(controller: controller),
  floatingActionButton: FloatingActionButton(
    onPressed: doSomething,
    child: const Icon(Icons.add),
  ),
)
```

**`MonacoOverlayBoundary`** - the underlying primitive. Wrap any custom overlay subtree (e.g. a `Stack` child positioned over the editor):

```dart
Stack(
  children: [
    MonacoEditor(controller: controller),
    Positioned(
      right: 24,
      bottom: 24,
      child: MonacoOverlayBoundary(
        child: MyFloatingPalette(),
      ),
    ),
  ],
)
```

On web, the boundary creates a transparent DOM `<div>` over the widget's global bounds with maximum z-index, and disables pointer events on any intersecting Monaco iframe while the user is hovering or pressing the overlay. On native platforms it is a pass-through.

Tip: for `floatingActionButton: Row(...)`, set `mainAxisSize: MainAxisSize.min` so the shield only covers the actual buttons rather than the full Scaffold width.

#### Transient overlays (snackbars, toasts, imperative Overlay entries)

For overlays that are neither routes nor static enough for a `MonacoOverlayBoundary` - a `ScaffoldMessenger` snackbar with an action button, a temporary toast, an `Overlay.insert` entry shown for a known duration - use `controller.runWithInteractionDisabled` to scope the interaction toggle to the lifetime of the overlay:

```dart
await controller.runWithInteractionDisabled(() async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Saved'),
      action: SnackBarAction(label: 'Undo', onPressed: undo),
    ),
  );
  await Future<void>.delayed(const Duration(seconds: 4));
});
```

The previous interaction state is restored in a `finally` block. On native platforms this is a thin pass-through (no behavior change).

#### Manual override

If you cannot use route observers, overlay boundaries, or the convenience helper, toggle the editor manually:

```dart
MonacoEditor(
  interactionEnabled: !isOverlayOpen,
  // ...
)
```

## Architecture

### Asset Management

The plugin uses a versioned cache system:

- Monaco assets (~30MB) are bundled with the plugin in `assets/monaco/min/`
- Assets are extracted once to the app's support directory
- Assets are versioned (e.g., `monaco-0.54.0/`) for clean updates
- Multiple editors share the same asset installation
- Thread-safe initialization with re-entrant protection

### Platform Support

**Supported Platforms:**

- **Android**: WebView via `webview_flutter`
- **iOS**: WKWebView with automatic blob worker shim for file:// protocol
- **macOS**: WKWebView via `webview_flutter` with blob worker shim
- **Windows**: WebView2 via `webview_windows` (requires WebView2 Runtime)
- **Web**: Native iframe-based integration with Monaco assets served from Flutter's asset bundle

**Not Supported:**

- **Linux**: Not currently supported (WebKitGTK integration pending)

### Performance

- **Memory**: Each editor instance uses ~30-100MB depending on content
- **Startup**: First launch extracts assets (one-time ~1-2 seconds)
- **Multiple Editors**: Tested with 4+ simultaneous editors on desktop
- **Workers**: Web Workers run in separate threads for syntax highlighting

## Requirements

### macOS

- macOS 10.13 or later
- Xcode (for development)

### Windows

- Windows 10 version 1809 or later
- Microsoft Edge WebView2 Runtime (auto-installed on most Windows 10/11 systems)

### Android

- Android 5.0 (API level 21) or later
- WebView support (included by default)

### iOS

- iOS 11.0 or later
- Info.plist must allow local file access

### Web

- Modern browser with ES6+ support (Chrome, Firefox, Safari, Edge)
- No additional configuration required

> **Important:** On web, use `MonacoEditor` with `onReady`, or await `controller.onReady` after the widget is mounted. `MonacoController.create()` returns before the editor is ready on web, and it will time out if called before the iframe is in the DOM. See the [Web Usage](#web-usage) section below.

## Web Usage

On web, the Monaco Editor runs inside an iframe that must be mounted in the DOM before initialization can complete. This means you should **not** call `MonacoController.create()` before the widget tree is built (e.g., in `initState`).

**Recommended pattern for web:**

```dart
class MyEditor extends StatefulWidget {
  @override
  State<MyEditor> createState() => _MyEditorState();
}

class _MyEditorState extends State<MyEditor> {
  MonacoController? _controller;

  void _onEditorReady(MonacoController controller) {
    setState(() => _controller = controller);
    // Now you can use the controller for advanced operations
  }

  @override
  Widget build(BuildContext context) {
    return MonacoEditor(
      initialValue: 'print("Hello!");',
      options: const EditorOptions(
        language: MonacoLanguage.dart,
        theme: MonacoTheme.vsDark,
      ),
      onReady: _onEditorReady,
    );
  }
}
```

This pattern works on all platforms and is the recommended approach. The `MonacoEditor` widget handles controller lifecycle internally and provides the controller via `onReady` callback once initialized.

**Why this matters on web:**
- On web, `MonacoController.create()` returns before Monaco signals "ready"
- Use `controller.onReady` or the `MonacoEditor` `onReady` callback for readiness
- The iframe must be in the DOM for Monaco JS to initialize
- Calling `create()` in `initState` (before `build`) can cause a timeout
- Native platforms do not have this constraint because WebView initialization is different

## Example App

### Live Web Demo

You can try the [live web demo here](https://omar-hanafy.github.io/flutter-monaco/).

The [example](example/) directory contains a full demonstration app with:

- Basic single editor setup
- Language and theme switching
- Multi-editor layout (3 editors simultaneously)
- Live statistics display
- Content extraction and manipulation
- Cross-editor content copying

Run the example:

```bash
cd example
flutter run -d macos  # or android, ios, windows, chrome
```

## Important Notes

### Asset Management

Monaco Editor assets are **automatically bundled** with this plugin. You do not need to add any assets to your application. The plugin handles:

- Asset extraction on first launch
- Versioned caching for fast subsequent loads
- Automatic cleanup when updating versions

### Content Queuing

The controller automatically queues content and language changes made before the editor is ready. Your content won't be lost even if you call `setValue()` immediately after creating the controller.

### Event Handling

For advanced users, you can listen to raw JavaScript events:

```dart
controller.onContentChanged.listen((isFlush) { });
controller.onSelectionChanged.listen((range) { });
controller.onFocus.listen((_) { });
controller.onBlur.listen((_) { });
```

### Marker Owners

When using markers (diagnostics), the `clearAllMarkers()` method only clears markers from known owners ('flutter', 'flutter-errors', 'flutter-warnings'). Custom owners must be tracked and cleared separately.

## Troubleshooting

If you are seeing issues where the editor loses keyboard focus after navigating away and back, or after switching apps on macOS/Windows, see the comprehensive guide:

- Focus, First Responder, and Keyboard on Platform Views (macOS/Windows): doc/focus-and-platform-views.md

### Desktop Focus Helper (optional)

For apps that frequently switch routes or windows, you can drop in a tiny helper to reassert focus automatically:

```dart
// Once you have a MonacoController instance
MonacoFocusGuard(
  controller: controller,
  // optionally provide a RouteObserver to re-focus on route return
  // routeObserver: myRouteObserver,
);
```

See the guide above for details and best practices.

### Windows: WebView2 not found

If you get a WebView2 error on Windows, install the WebView2 Runtime:
https://developer.microsoft.com/en-us/microsoft-edge/webview2/

### macOS/iOS: Workers not loading

The plugin automatically configures a blob worker shim. If you still have issues:

1. Check the console output for errors
2. Ensure file:// access is allowed in your WebView configuration

### Assets not loading

If Monaco assets fail to load:

1. Check the console for error messages
2. Try clearing the cache: `await MonacoAssets.clearCache()`
3. Ensure your app has file system permissions

### Editor not responding

If the editor becomes unresponsive:

1. Check that JavaScript is enabled in the WebView
2. Verify the HTML file was generated correctly
3. Look for JavaScript errors in the console output

### Multiple editors performance

If performance degrades with multiple editors:

1. Limit to 3-4 editors on mobile devices
2. Disable minimap for better performance
3. Consider lazy initialization of editors

## Limitations

- **No Linux Support**: The plugin currently supports Android, iOS, macOS, Windows, and Web. Linux is not yet supported.
- **Performance**: While optimized, running multiple editor instances (4+) can be resource-intensive, especially on older hardware. Each instance runs in a separate WebView, consuming 30-100MB of memory depending on content.
- **Startup Time**: The first time the app is launched, Monaco's assets (~30MB) are extracted, which can take 1-2 seconds. Subsequent launches are much faster.
- **WebView Dependencies**: The plugin relies on platform-specific WebView implementations (WebView2 on Windows, WKWebView on Apple platforms). Ensure the target system has the necessary dependencies.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Support

If you find this package useful, please consider giving it a star on [GitHub](https://github.com/omar-hanafy/flutter_monaco) and sharing it with the Flutter community.

## License

This plugin is licensed under the MIT License. See LICENSE file for details.

Monaco Editor is licensed under the MIT License by Microsoft.
