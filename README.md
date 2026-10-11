# Flutter Monaco

[![pub package](https://img.shields.io/pub/v/flutter_monaco.svg?label=pub)](https://omar-hanafy.github.io/flutter_monaco/)
[![License: MIT](https://img.shields.io/badge/License-MIT-success.svg)](https://omar-hanafy.github.io/flutter_monaco/)
[![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Windows%20%7C%20Web-blue)](https://omar-hanafy.github.io/flutter_monaco/)

A Flutter plugin for integrating the Monaco Editor (VS Code's editor) into Flutter applications via WebView.

Check the [live demo here](https://omar-hanafy.github.io/flutter_monaco/) to try Flutter Monaco in your browser.

<p align="center">
  <a href="https://omar-hanafy.github.io/flutter_monaco/">
    <img src="https://github.com/omar-hanafy/flutter_monaco/blob/main/screenshots/macos.png?raw=true" alt="Flutter Monaco Editor on macOS" width="90%">
  </a>
</p>

## AI coding-assistant support

This repository ships an optional, package-specific plugin for Claude Code and OpenAI Codex. It contains six skills for integrating, migrating, diagnosing, configuring LSP, maintaining the bridge, and upgrading the bundled Monaco engine. The plugin runs no background service, hook, executable, or MCP server, and it does not require credentials. `dart pub add flutter_monaco` installs only the runtime Flutter package, not this repository-hosted assistant plugin.

### Claude Code

```sh
claude plugin marketplace add omar-hanafy/flutter_monaco --sparse .claude-plugin plugins
claude plugin install flutter-monaco@flutter-monaco-plugins --scope user
```

Run `/reload-plugins` in an active Claude Code session or start a new session, then
invoke a skill explicitly when useful:

```text
/flutter-monaco:integrate-flutter-monaco
/flutter-monaco:diagnose-flutter-monaco
```

The commands above were validated with Claude Code CLI 2.1.215. Claude Code's VS
Code extension and Desktop Code local or SSH sessions are documented plugin
surfaces, but were not smoke-tested for this release. Local user plugins do not
transfer automatically to Claude Code on the web.

### OpenAI Codex

```sh
codex plugin marketplace add omar-hanafy/flutter_monaco --sparse .agents --sparse plugins
codex plugin add flutter-monaco@flutter-monaco
```

Start a new Codex session, then invoke a skill explicitly when useful. In Codex
CLI, you can also enter `/plugins` to browse the configured marketplace and manage
the plugin interactively:

```text
$integrate-flutter-monaco
$diagnose-flutter-monaco
```

These repository commands configure Claude Code and Codex CLI. A clone opened in
the ChatGPT desktop app can expose its repo marketplace in Work mode or Codex after
an app restart. ChatGPT web can install only plugins available through its curated
or workspace-shared catalog; this repository release is not a public-directory
submission. Plugins are not available in Chat mode, Codex IDE integrations, or
mobile. Codex project agents require a checkout of this repository. See
[AI assistant support](doc/ai-assistant-support.md) for the full inventory,
compatibility, updates, removal, security model, validation, and example prompts.

The consumer skills target `flutter_monaco` 3.x after inspecting the resolved dependency; the dedicated migration skill covers released 2.x applications and 1.7.1 applications after a toolchain/platform prerequisite audit. Useful natural-language requests include "Integrate flutter_monaco with three tabs and stable file URIs" and "Diagnose why this Web editor never becomes ready."

Update or remove the Claude Code installation:

```sh
claude plugin marketplace update flutter-monaco-plugins
claude plugin update flutter-monaco@flutter-monaco-plugins
claude plugin uninstall flutter-monaco@flutter-monaco-plugins --scope user
claude plugin marketplace remove flutter-monaco-plugins
```

After an update, run `/reload-plugins` or start a new Claude Code session.

Update or remove the Codex installation:

```sh
codex plugin marketplace upgrade flutter-monaco
codex plugin add flutter-monaco@flutter-monaco
codex plugin remove flutter-monaco@flutter-monaco
codex plugin marketplace remove flutter-monaco
```

Start a new Codex session after updating or reinstalling the plugin.

## Features

- 🎨 **Full Monaco Editor** - The same editor that powers VS Code
- 🌐 **100+ Language Support** - Syntax highlighting for all major languages
- 🎭 **Multiple Themes** - Dark, Light, High Contrast, and custom themes; the default theme follows your app's brightness
- 🔀 **Diff Editor** - `MonacoDiffEditor` widget and headless `MonacoDiffController` for side-by-side or inline diffs
- ⌨️ **Custom Actions & Keybindings** - Define editor actions in Dart with typed keybindings (Cmd/Ctrl+S save hooks, command palette, context menu)
- 📑 **Multi-Document Editing** - One editor, many documents: open, switch, and edit models with independent undo stacks and dirty tracking
- 🔌 **Language Server Protocol** - Connect real language servers (pyright, typescript-language-server, gopls, ...) for server-grade completions, diagnostics, hover, rename, and more
- 🧠 **Custom IntelliSense** - Register multiple completion providers (static or remote)
- 📡 **Typed Events** - A sealed `MonacoEvent` union plus typed streams for content, selection, and focus changes
- 🚨 **Typed Errors** - A sealed `MonacoException` hierarchy; bridge failures throw instead of returning silent defaults
- 🛰️ **Protocol v3 Wire** - One request-correlated JSON envelope channel that behaves identically on Android, iOS, macOS, Windows, and Web
- 🎯 **Type-safe API** - Extension-type ids (`MonacoTheme`, `MonacoLanguage`, `MonacoAction`) with const catalogs over open sets
- 🔍 **Find & Replace** - Full programmatic find/replace with regex support
- 🖍️ **Decorations & Markers** - Independent decoration sets and owner-scoped markers for highlights, errors, warnings
- 📊 **Live Statistics** - Real-time line/character counts and selection info
- 🎨 **Themeable Chrome** - Customize loading, error, and status-bar UI via `MonacoEditorTheme`
- 🖱️ **Edge Scroll Handoff** - Opt-in: wheel/trackpad scrolling continues into the surrounding page once the editor hits its scroll edge
- 💾 **Versioned Asset Caching** - Efficient one-time asset installation
- ⚡ **Multiple Editors** - Support for unlimited independent editor instances
- 🖥️ **Cross-Platform** - Works on Android, iOS, macOS, Windows, and Web

> **⚠️ Platform Support:** Currently supports **Android**, **iOS**, **macOS**, **Windows**, and **Web**. Linux is **not supported** at this time.

## Screenshots

<table>
  <tr>
    <td align="center" width="50%"><b>iOS</b></td>
    <td align="center" width="50%"><b>Android</b></td>
  </tr>
  <tr>
    <td><a href="https://omar-hanafy.github.io/flutter_monaco/"><img src="https://github.com/omar-hanafy/flutter_monaco/blob/main/screenshots/ios.jpg?raw=true" alt="iOS Screenshot" width="100%"></a></td>
    <td><a href="https://omar-hanafy.github.io/flutter_monaco/"><img src="https://github.com/omar-hanafy/flutter_monaco/blob/main/screenshots/android.jpg?raw=true" alt="Android Screenshot" width="100%"></a></td>
  </tr>
  <tr>
    <td align="center" colspan="2"><b>Windows</b></td>
  </tr>
  <tr>
    <td colspan="2"><a href="https://omar-hanafy.github.io/flutter_monaco/"><img src="https://github.com/omar-hanafy/flutter_monaco/blob/main/screenshots/windows.png?raw=true" alt="Windows Screenshot" width="100%"></a></td>
  </tr>
  <tr>
    <td align="center" colspan="2"><b>Web</b></td>
  </tr>
  <tr>
    <td colspan="2"><a href="https://omar-hanafy.github.io/flutter_monaco/"><img src="https://github.com/omar-hanafy/flutter_monaco/blob/main/screenshots/web.png?raw=true" alt="Web Screenshot" width="100%"></a></td>
  </tr>
</table>

## Installation

Add `flutter_monaco` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_monaco: ^<latest version>
```

> Upgrading from 2.x? See [Migrating from 2.x to 3.0](#migrating-from-2x-to-30).

## Quick Start

The `MonacoEditor` widget owns the whole lifecycle: it creates a controller, shows loading and error chrome, and hands you the ready controller via `onReady`. This works the same on every platform, including web.

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
        appBar: AppBar(title: const Text('Monaco Editor')),
        body: MonacoEditor(
          initialText: 'void main() {\n  print("Hello, Monaco!");\n}\n',
          options: const EditorOptions(language: MonacoLanguage.dart),
          showStatusBar: true,
          onReady: (controller) {
            // The full controller API is available here.
          },
        ),
      ),
    ),
  );
}
```

Leave `EditorOptions.theme` unset and the editor follows your app's brightness (dark mode gets `vs-dark`, light mode gets `vs`) and reacts to platform dark-mode changes. Set an explicit theme and it always wins.

### Using the controller directly

`MonacoController.create` returns before the editor is ready (asset preparation and WebView setup are still awaited); await `whenReady` before treating the editor as live. Content and model operations live on `controller.document`; editor-level operations (theme, actions, view state, focus) stay on the controller.

```dart
final controller = await MonacoController.create(
  options: const EditorOptions(
    language: MonacoLanguage.python,
    fontSize: 16,
  ),
  initialText: 'print("Hello, World!")',
);
await controller.whenReady;

// Content lives on the document handle.
final text = await controller.document.getText();
await controller.document.setText('print("Hi!")');
await controller.document.setLanguage(MonacoLanguage.javascript);

// Editor-level operations stay on the controller.
await controller.setTheme(MonacoTheme.vsDark);
await controller.executeAction(MonacoAction.formatDocument);
```

Display a self-created controller by passing it to the widget. You still own creation, disposal, and its boot-time `MonacoPageConfig`. On first readiness, `MonacoEditor` applies its current widget options, resolved theme/language, initial text, background, interaction, and scroll settings. After page recovery it reapplies configuration but deliberately leaves app-owned content alone. Keep the controller's boot options consistent with the widget, or deliberately make the widget the live configuration owner:

```dart
final options = const EditorOptions(
  language: MonacoLanguage.python,
  theme: MonacoTheme.vsDark,
);
final controller = await MonacoController.create(
  initialText: source,
  options: options,
  page: const MonacoPageConfig(),
);

MonacoEditor(controller: controller, options: options);
```

> **Dot shorthands:** `MonacoTheme`, `MonacoLanguage`, and `MonacoAction` are extension types with const catalogs, so with Dart 3.10+ enum shorthands call sites like `executeAction(.formatDocument)` and `setTheme(.vsDark)` work out of the box.

## Documents and Multi-Document Editing

The editor is a viewport; documents are Monaco models you open, switch, and edit independently. `controller.document` always tracks the active document, while `openDocument` returns handles pinned to a URI.

If the underlying page reloads, only the boot document is recreated automatically. Other models disappear and their pinned `MonacoDocument` handles become stale. Listen to `onPageReloaded`, reopen each model with its stable URI, and replace the old handles before issuing more document commands.

```dart
// Open each file once with a stable file:/// URI. Opening does not activate.
final mainDart = await controller.openDocument(
  text: dartSource,
  language: MonacoLanguage.dart,
  uri: Uri.parse('file:///demo/main.dart'),
);
final notes = await controller.openDocument(
  text: '# Notes\n',
  language: MonacoLanguage.markdown,
  uri: Uri.parse('file:///demo/NOTES.md'),
);

// Switch the visible document; every document keeps its own undo stack.
await controller.activateDocument(mainDart);

// Pinned handles edit their model even while another document is visible.
await notes.insert(const Position(line: 1, column: 1), 'TODO: review\n');

// Dirty tracking per document.
final dirty = await mainDart.isDirty();
await mainDart.markSaved();

// Enumerate, look up, and close.
final open = await controller.listDocuments();
final byUri = controller.documentByUri(Uri.parse('file:///demo/main.dart'));
await notes.close();
```

Every `MonacoDocument` (including the active-tracking `controller.document`) exposes the full text API: `getText`, `setText`, `lineCount`, `lineAt`, `getLines`, `insert`, `deleteRange`, `replaceRange`, `applyEdits`, `findMatches`, `replaceMatches`, `getWordAt`, `isDirty`, `markSaved`, `getLanguage`, `setLanguage`, `setMarkers`, and `clearMarkers`.

Content-change events carry the document URI, so one stream can keep per-tab dirty markers accurate:

```dart
controller.onContentChanged.listen((event) async {
  final uri = event.documentUri;
  // event.isFlush, event.changes, event.truncated are also available.
});
```

Language servers key their state on these URIs, so open documents with stable `file:///...` URIs when using LSP. See `example/lib/multi_editor_example.dart` for a complete tabbed-editor demo.

## Decorations

Decorations are handle-based: each `MonacoDecorationSet` is an independent owner, so search highlights and lint underlines (for example) never clobber each other.

```dart
final highlights = await controller.createDecorationSet();

await highlights.set([
  DecorationOptions.line(
    range: Range.lines(5, 5),
    className: 'highlight-line', // CSS class from MonacoPageConfig.customCss
  ),
  DecorationOptions.inlineClass(
    range: Range.singleLine(10, startColumn: 3, endColumn: 12),
    className: 'squiggly-word',
    hoverMessage: 'Did you mean "flutter"?',
  ),
]);

await highlights.clear();   // remove the decorations, keep the set
await highlights.dispose(); // release the set
```

`DecorationOptions.line`, `.inlineClass`, and `.glyphMargin` cover the common cases; the raw `options` map accepts any Monaco `IModelDecorationOptions` key. Ship the CSS classes via `MonacoPageConfig(customCss: ...)`.

## Custom Actions and Keybindings

Define editor actions in Dart with `controller.addAction`. The action gets a keybinding, shows up in the command palette (F1), and can be placed in the context menu. This is the way to intercept Cmd/Ctrl+S:

```dart
final save = await controller.addAction(
  const MonacoActionDescriptor(
    id: MonacoAction('demo.save'),
    label: 'Save',
    keybindings: [MonacoKeybinding(key: MonacoKey.keyS, ctrlCmd: true)],
    contextMenuGroupId: 'navigation',
    contextMenuOrder: 1,
  ),
  () async {
    final text = await controller.document.getText();
    await saveToDisk(text);
  },
);

// Later, remove the action (keybinding and menu entry included):
await save.dispose();
```

`MonacoKeybinding` composes a `MonacoKey` with `ctrlCmd` (Cmd on macOS, Ctrl elsewhere), `shift`, `alt`, and `winCtrl` modifiers. Multiple keybindings per action are supported.

Built-in editor commands run through `executeAction` with the `MonacoAction` catalog (~386 typed command ids):

```dart
await controller.executeAction(MonacoAction.formatDocument);
await controller.executeAction(MonacoAction.commentLine);
await controller.executeAction(MonacoAction.foldAll);
// Any command id works, including ones not in the catalog:
await controller.executeAction(MonacoAction('my.custom.command'));
```

## Custom IntelliSense Completions

Monaco merges results from multiple completion providers. Register static keyword/snippet lists or dynamic providers that call your own services; each registration returns a `MonacoCompletionRegistration` you can dispose at any time.

```dart
// Static completions (keywords/snippets/etc.)
final keywords = await controller.registerStaticCompletions(
  id: 'keywords',
  languages: const [MonacoLanguage.typescript, MonacoLanguage.javascript],
  triggerCharacters: const [' ', '.'],
  items: const [
    CompletionItem(
      label: 'pipeline',
      kind: CompletionItemKind.snippet,
      detail: 'Begin a pipeline section',
      documentation: 'Expands to a snippet with placeholders.',
      insertText: 'pipeline(\${1:source}) {\n  \${2:// body}\n}',
      insertTextRules: {InsertTextRule.insertAsSnippet},
    ),
    CompletionItem(
      label: 'logger.info',
      kind: CompletionItemKind.method,
      detail: 'Log a message at INFO level',
    ),
  ],
);

// Dynamic completions - call your own API or local data
final acmeApi = await controller.registerCompletions(
  id: 'acme-api',
  languages: const [MonacoLanguage.typescript],
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

// Need to remove a provider? Dispose its registration:
await acmeApi.dispose();
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

- `providerId`, `requestId` - identify the provider and the request.
- `language`, `uri` - the model that triggered the request.
- `position`, `defaultRange`, `lineText` - cursor info plus the word range Monaco wants you to replace.
- `triggerKind`, `triggerCharacter` - what caused the completion (manual `Ctrl+Space`, character, etc.).

You can register as many providers as you need. Monaco merges them and sorts via each item's `sortText`.

## Diff Editor

`MonacoDiffEditor` renders an original/modified pair side by side or inline, with the same loading/error chrome as `MonacoEditor`:

```dart
MonacoDiffEditor(
  original: originalSource,
  modified: modifiedSource,
  language: MonacoLanguage.dart,
  diffOptions: const MonacoDiffOptions(renderSideBySide: true),
  onReady: (controller) => _diffController = controller,
)
```

`MonacoDiffOptions` covers `renderSideBySide`, `readOnly`, `originalEditable`, `ignoreTrimWhitespace`, `renderMarginRevertIcon`, plus an `extra` map for any other Monaco diff option.

For headless use, create the controller yourself:

```dart
final diff = await MonacoDiffController.create(
  original: before,
  modified: after,
  language: MonacoLanguage.json,
  diff: const MonacoDiffOptions(renderSideBySide: false),
);
await diff.whenReady;

await diff.setTexts(
  original: v1,
  modified: v2,
  language: MonacoLanguage.dart,
);
await diff.revealNextChange();
await diff.revealPreviousChange();

final merged = await diff.getModifiedText();
final changedBlocks = await diff.getLineChangeCount();

await diff.updateOptions(const EditorOptions(fontSize: 13));
await diff.updateDiffOptions(const MonacoDiffOptions(renderSideBySide: true));
await diff.setTheme(MonacoTheme.vsDark);
```

Try it: `flutter run -t lib/diff_example.dart` in `example/`.

## Language Server Protocol (LSP)

Flutter Monaco can connect the editor to a **real language server** using Monaco's built-in LSP client (Monaco 0.55+). Once connected, everything the server advertises works directly inside the editor - completions, hover, signature help, go-to-definition, references, rename, formatting, code actions, folding, inlay hints, semantic tokens, and live diagnostics. Nothing is mirrored into Dart: **the package owns the transport, Monaco owns the language smarts.**

```dart
final connection = await controller.connectLanguageServer(
  id: 'pyright',
  transport: LspWebSocketTransport(
    url: Uri.parse('ws://127.0.0.1:3000/python'),
  ),
);

connection.stateChanges.listen(print); // connecting → open → closed/failed
// ... later
await connection.disconnect();
```

### Transports

Pick the transport that matches where your server lives:

| Transport | Use case | Platforms |
|-----------|----------|-----------|
| `LspWebSocketTransport` | Server (or a proxy) speaks WebSocket | All (CSP opt-in required) |
| `LspBridgedTransport` + `LspServerProcess` | Local stdio server binary, no network | Desktop (macOS, Windows) |
| `LspCustomTransport` | Worker/iframe/custom transports you build in JS | Depends on your code |

**WebSocket** - most stdio language servers don't speak WebSocket natively; front them with a thin proxy:

```sh
npx jsonrpc-ws-proxy --port 3000 \
  --languageServers '{"python": ["pyright-langserver", "--stdio"]}'
```

The editor page's Content-Security-Policy blocks all network connections by default, so allow the endpoint explicitly when creating the editor:

```dart
final controller = await MonacoController.create(
  page: const MonacoPageConfig(
    allowedConnectSources: ['ws://127.0.0.1:3000'], // CSP connect-src opt-in
  ),
);
// or on the widget:
MonacoEditor(
  page: const MonacoPageConfig(
    allowedConnectSources: ['wss://lsp.example.com'],
  ),
)
```

> Browser WebSockets cannot carry custom headers. If your server needs auth,
> pass a token in the URL query string or build an authenticated socket with
> `LspCustomTransport`.

**Local stdio server (desktop)** - the killer feature for desktop apps: spawn the server as a child process and relay JSON-RPC through the Flutter bridge. No port, no proxy, no CSP changes:

```dart
final server = await LspServerProcess.start('pyright-langserver', ['--stdio']);
final connection = await controller.connectLanguageServer(
  id: 'pyright',
  transport: server.transport,
);
// Disconnecting (or disposing the controller) stops the process automatically.
```

> **macOS App Sandbox:** a sandboxed app cannot spawn external binaries
> (`ProcessException: Operation not permitted`). Disable
> `com.apple.security.app-sandbox` in your entitlements (fine outside the
> App Store) or bundle the server inside the app with inherit entitlements.
> The example app disables the sandbox in debug builds for this reason.

**Custom** - register a factory on `window.flutterMonacoLspTransports` (e.g. via `controller.runJavaScript`) and reference it by name. The factory must return an object implementing Monaco's `IMessageTransport`; Monaco's own helpers (`monaco.lsp.createTransportToWorker`, `createTransportToIFrame`, `WebSocketTransport.fromWebSocket`) all qualify:

```dart
await controller.runJavaScript('''
  window.flutterMonacoLspTransports = {
    myWorker: (config) => monaco.lsp.createTransportToWorker(
      new Worker(config.workerUrl)),
  };
''');
final connection = await controller.connectLanguageServer(
  id: 'worker',
  transport: LspCustomTransport(
    factoryName: 'myWorker',
    config: {'workerUrl': 'my-language-server.js'},
  ),
);
```

### Lifecycle, reconnects, and observability

- `connectLanguageServer` resolves only after the LSP `initialize` handshake completes; on failure it throws and nothing is registered.
- `connection.state` / `stateChanges` report `connecting → open → closed/failed`; `whenClosed` completes when the connection permanently ends.
- Unexpected drops can auto-reconnect with `reconnectPolicy: LspReconnectPolicy.exponentialBackoff(...)` (WebSocket/custom transports only - a bridged server process must be respawned by your code).
- `MonacoController.dispose()` tears down all connections and stops bridged server processes.
- Experimental `connection.sendRequest` / `sendNotification` forward raw JSON-RPC for non-standard server extensions (e.g. `pyright/createConfigFile`). They rely on Monaco internals verified against 0.57.0 and may break on future Monaco upgrades.

### Good to know

- **Document URIs matter.** Language servers key their state on document URIs - open documents with stable `file:///...` URIs (`openDocument(..., uri: ...)`) instead of relying on Monaco's default `inmemory://` model.
- **Diagnostics owner.** LSP diagnostics appear as Monaco markers under the owner `'lsp'`; they're cleared automatically when the last connection closes.
- **Multiple servers.** Allowed, but Monaco synchronizes *all* models to every connected server and all LSP diagnostics share one marker owner - prefer one server per editor unless your servers handle disjoint files.
- **Multiple editors.** Each `MonacoController` is an isolated WebView with its own JavaScript context; connect each editor separately (most servers handle multiple client connections fine).
- **Try it:** `flutter run -t lib/lsp_example.dart` in `example/` demonstrates both the WebSocket and the local stdio paths.

## Edge Scroll Handoff

By default the editor traps wheel and touch input, the way an embedded WebView always does. For documentation pages, playgrounds, and forms that embed editors inside a scrollable page, you can opt in to **edge scroll handoff**: the editor consumes scroll input while it can, and forwards the rest to a Flutter scrollable once it reaches its scroll edge.

```dart
final pageScrollController = ScrollController();

SingleChildScrollView(
  controller: pageScrollController,
  child: Column(
    children: [
      // ... page content ...
      SizedBox(
        height: 320,
        child: MonacoEditor(
          scrollHandoff: MonacoScrollHandoff.edge(
            controller: pageScrollController,
          ),
        ),
      ),
      // ... more page content ...
    ],
  ),
)
```

Behavior with `MonacoScrollHandoff.edge()`:

- A scrollable editor consumes the wheel until its top/bottom edge. The gesture that reaches the edge **stops there**: its remaining input, trackpad momentum included, is absorbed like a native nested scroll "wall" and never jerks the page. To scroll the page, stop and start a new gesture while the editor is at its edge; reversing direction immediately returns the wheel to the editor.
- A non-scrollable editor (short snippet) hands new gestures straight to the page, so the page scrolls through it.
- The delta goes to the explicit `controller` if provided, otherwise to the nearest enclosing vertical `Scrollable` (`useNearestScrollable: true` by default). Provide `onHandoff` and return `true` to consume deltas yourself.
- Ctrl/meta wheel (editor `mouseWheelZoom`, browser zoom, macOS pinch) is never handed off, and Monaco-owned scrollable overlays (suggest list, hover docs, menus, peek editors) keep their own wheel handling.
- `scrollBeyondLastLine` blank space counts as editor-scrollable; set it to `false` in `EditorOptions` if you want handoff to begin at the real last line.
- Multiple editors route independently: each editor forwards only to its own configured target.

The boundary behavior is a policy. `MonacoScrollBoundaryPolicy.newGestureOnly` (the default since 3.3.0) gives the native wall feel described above; `MonacoScrollBoundaryPolicy.continuous` restores the pre-3.3 behavior where every unconsumed delta chains to the page immediately, mid-gesture:

```dart
MonacoScrollHandoff.edge(
  policy: MonacoScrollBoundaryPolicy.continuous, // opt out of the wall
)
```

Headless / custom-widget integrations can skip the widget wiring and consume the stream directly:

```dart
await controller.setScrollHandoffSources(wheel: true);
controller.onScrollHandoff.listen((details) {
  // details.deltaY uses wheel semantics (positive scrolls down).
});
```

### What edge handoff is (and is not)

This is **edge scroll handoff, not native nested scrolling**. Monaco lives inside a WebView/iframe, so the platform gesture itself never enters Flutter's gesture arena; the package forwards the unconsumed scroll intent across the bridge instead. Wheel and trackpad input is the stable, supported source on macOS, Windows, and desktop web (plus external mice on mobile where the WebView reports wheel events).

Touch forwarding is a separate, **experimental** opt-in (`mobileTouch: true`). It is observation-only: it never blocks Monaco's own touch handling, never opens the keyboard, and yields to text selection, but there is no native momentum or fling transfer, and iOS Safari on Flutter Web remains best-effort. Under the default boundary policy a drag that starts over scrollable editor content belongs to the editor for its whole lifetime (it is contained at the edge); only a drag that starts while the editor is already at the edge scrolls the page.

See `example/lib/scroll_handoff_example.dart` for a full page with short, long, and handoff-disabled editors.

## Migrating from 2.x to 3.x

3.x is a ground-up rebuild of the package's spine: one wire protocol, a document/editor split, sparse options, typed errors, and typed events. The LSP signatures and supporting overlay widgets remain source compatible. Scroll handoff keeps its source shape but changes its default boundary policy, and focus controller methods were renamed. The table below is complete against the 2.3.0 public barrel; the `(Dxx)` tags reference the numbered design decisions recorded in the v3 blueprint (`upcoming/v3.md` in the repository).

### Symbol-level changes

| 2.3.0 | 3.x | Migration |
|---|---|---|
| `MonacoAction.foldAll` (a `String`) | `MonacoAction.foldAll` (a `MonacoAction`) | append `.id` where a raw String is required; call sites into `executeAction` unchanged textually |
| `controller.executeAction(String, [dynamic args])` | `executeAction(MonacoAction, {Object? args})` | wrap raw ids: `MonacoAction(id)`; args becomes named |
| `MonacoTheme` enum | open `MonacoTheme` extension type | `MonacoTheme.vsDark` is unchanged textually and `.values` -> `.builtIn`; a constructor preserves unknown custom ids, so replace tolerant `fromId` with explicit null/unknown fallback logic where that behavior matters |
| `MonacoLanguage` enum | open `MonacoLanguage` extension type | same pattern; v2 `fromId` accepted null/unknown and fell back to Markdown, while `MonacoLanguage(s)` requires a non-null string and preserves unknown ids |
| `EditorOptions.themeId`, `effectiveThemeId` | deleted | `EditorOptions(theme: MonacoTheme('app-dark'))` |
| `controller.setThemeById(String)` | deleted | `setTheme(MonacoTheme(id))` |
| `controller.getThemeId()` | `getTheme(): Future<MonacoTheme?>` | use `.id` when a raw string is required; `getEditorState().theme` is available when reading the full state |
| `controller.defineThemeFromJson(id, map)` | deleted | `defineTheme(MonacoThemeDefinition.fromMonacoThemeData(id, map))` |
| `EditorOptions` full-state, non-null fields | sparse, nullable fields (D09) | construction often still compiles, but field reads now need null handling; `updateOptions` changes only provided fields; use `MonacoDefaults.editorOptions.merge(...)` only when the current curated defaults are intended |
| `EditorOptions.padding: Map<String,int>?` | `MonacoPadding` | `MonacoPadding(top: 10)` |
| `EditorOptions.minimap/wordWrap/lineNumbers: bool` | `MonacoMinimapOptions` / `MonacoWordWrap` / `MonacoLineNumbers` | `minimap: MonacoMinimapOptions(enabled: true)`, `wordWrap: .on`, `lineNumbers: .on` |
| `MonacoConstants` | deleted | only `defaultTheme`, `defaultLanguage`, and `defaultFontSize` have close `MonacoDefaults` mappings; the min/max values, rulers, file-size limits, and v2 tab-size/default-options policy must remain app-owned |
| `MonacoFont` | `MonacoFontStacks` statics | `MonacoFont.jetBrainsMono.value` -> `MonacoFontStacks.jetBrainsMono` |
| `MonacoJavaScriptException` | `MonacoJavaScriptError` (extends sealed `MonacoException`) | rename in catches |
| `getValue({defaultValue})` / `getLineCount({defaultValue})` / `getLineContent(...)` | `controller.document.getText()` / `lineCount()` / `lineAt()`; all throw on failure (D06) | wrap in `MonacoException` handling where fallback behavior is intentional |
| `getLinesContent(List<int>, {lineDefaultValue})` | no one-call equivalent | preserve arbitrary/repeated line ordering with an explicit `lineAt` loop and per-line `MonacoException`/`RangeError` fallback; `getLines(start, end)` is only for a contiguous range |
| `setValue(v)` | `controller.document.setText(v)` | |
| `setLanguage(lang)` | `controller.document.setLanguage(lang)` | |
| `applyEdits/insertText/deleteRange/replaceRange` | same names on `controller.document` (`insertText` -> `insert`) | |
| `deleteLine(n)` | `document.deleteRange(Range.lines(n, n))` | |
| `findMatches/replaceMatches` | same names on `controller.document` | `findMatches` keeps `limit`; `replaceMatches.defaultCount` is removed and failures throw |
| `hasUnsavedChanges()/markSaved()` | `document.isDirty()/markSaved()` | |
| `setMarkers/setErrorMarkers/setWarningMarkers/clearMarkers/clearAllMarkers` | `document.setMarkers(markers, owner:)/clearMarkers(owner:)` (severity conveniences and the 3-owner clearAll are deleted) | build `MarkerData.error(...)` lists; clear owners explicitly |
| `setDecorations/addInlineDecorations/addLineDecorations/clearDecorations` | `createDecorationSet()` + `set/clear/dispose` | one set per concern; `DecorationOptions.inlineClass/line` factories unchanged |
| `createModel(value, language: String, uri:, defaultUri:)` | `openDocument(text:, language: MonacoLanguage, uri:) -> MonacoDocument` | `defaultUri` fallback is gone; opening does not activate the document |
| `setModel(Uri)` / `disposeModel(Uri)` / `listModels(): List<Uri>` | `activateDocument(MonacoDocument)` / `document.close()` / `listDocuments(): List<MonacoDocument>` | retain pinned handles or use `documentByUri(uri)`; read handle `.uri` when a raw URI is needed |
| `revealLines(start, end, {center})` | `revealRange(Range.lines(start, end), center: center)` | construct the range explicitly |
| `setCursorPositionZeroBased(line, column)` | `setCursorPosition(Position.fromZeroBased(line, column))` | keep the coordinate conversion explicit |
| `getWordAtPosition(position)` | `document.getWordAt(position)` | content queries live on the document |
| `executeBatch(operations)` | deleted | await the operations in an explicit sequential loop; the old helper did not combine them into one bridge round trip |
| `revealLine(line)` with Dart-side clamp | same source signature, no v2 clamp | validate or clamp against `await document.lineCount()` if the input can be out of range |
| `format()/find()/replace()/toggleWordWrap()/selectAll()/undo()/redo()/cut()/copy()/paste()/foldAll()/unfoldAll()/toggleLineComment()/indentLines()/outdentLines()` | deleted (D19) | use `executeAction`: format -> `.formatDocument`, find -> `.find`, replace -> `.startFindReplaceAction`, cut/copy/paste -> `.clipboardCutAction`/`.clipboardCopyAction`/`.clipboardPasteAction`, toggleLineComment -> `.commentLine`, and the remaining helpers map to same-named constants |
| `focus()` / `ensureEditorFocus({attempts, interval, intent})` | `requestFocus({intent})` (D20) | retry tuning stays available as optional parameters (same defaults) |
| `releaseNativeInputFocus()` | `releaseNativeFocus()` | rename |
| `liveStats` (`ValueNotifier<LiveStats>`) | `stats` (`ValueListenable<MonacoLiveStats>`) | labeled records become ints, cursor becomes `Position?`, language becomes `MonacoLanguage?`, and labels move to UI |
| `getStatistics()` | `stats.value` | |
| `LiveStats.defaults()` / `allStats` / `toJson()` | `const MonacoLiveStats()` / deleted / deleted | build UI rows and persistence maps in the app; `hasSelection` and `hasMultipleCursors` remain |
| `MonacoEditor.onLiveStats` / `statusBarBuilder` using `LiveStats` | callbacks using `MonacoLiveStats` | update callback parameter types and remove record `.value`/`.label` reads |
| controller `onContentChanged: Stream<bool>` | `Stream<MonacoContentChanged>` | `isFlush` is a field; the widget's text `onContentChanged` and bool `onRawContentChanged` callbacks remain supported |
| controller `onFocus`/`onBlur` streams | `onFocusChanged: Stream<bool>` | `.where((f) => f)` / `.where((f) => !f)`; `MonacoEditor.onFocus`/`onBlur` widget callbacks remain supported |
| `getEditorState()` / `EditorState` | same controller name, one round trip | `hasUnsavedChanges` -> `isDirty`; language/theme become typed ids; stats is non-null; `isEmpty` -> `content.isEmpty`; `wordCount` and `toJson` become app-owned |
| `saveViewState(): Map` / `restoreViewState(Map)` | `captureViewState(): MonacoViewState` / `restoreViewState(MonacoViewState)` | persist via `toJson()` |
| `evaluateJavaScript<T>(..., defaultValue:)` | same source signature, stricter conversion | default applies only to JavaScript `undefined`/`null`; an incompatible non-null value now throws `MonacoProtocolError` instead of returning the default |
| `runJavaScript` / `runJavaScriptReturningResultRaw` | unchanged signatures | |
| `registerCompletionSource(...): Future<String>` / `unregisterCompletionSource(id)` | `registerCompletions(...): Future<MonacoCompletionRegistration>` / `registration.dispose()`; `languages` is now `List<MonacoLanguage>` | |
| `registerStaticCompletions(...): Future<String>` | same method name returning `Future<MonacoCompletionRegistration>` | `languages` is `List<MonacoLanguage>`; retain and dispose the registration |
| `create({options, customCss, allowCdnFonts, allowedConnectSources, readyTimeout})` | `create({options, initialText, page, readyTimeout})`; returns before readiness, use `whenReady` (D05) | native callers relying on blocking create: `final c = await MonacoController.create(...); await c.whenReady;` |
| `onReady` future getter | `whenReady` | rename |
| `isReady` completed even after a failed Web boot | true only after successful boot | await `whenReady` in `try/catch` when completion including failure matters |
| nullable `readyTimeout` | non-null `Duration`, defaulting to `MonacoDefaults.readyTimeout` | resolve nullable app configuration before passing it |
| `createForTesting(..., bridge:)` | no bridge injection; optional `runBoot`, `bootOptions`, `bootInitialText` | update test harnesses to use the protocol fake |
| `MonacoEditor.initialValue` | `MonacoEditor.initialText` | rename |
| `MonacoEditor.customCss/allowCdnFonts/allowedConnectSources` | `MonacoEditor.page: MonacoPageConfig` | wrap |
| `MonacoAssets.htmlGenerationVersion` / `generateIndexHtml` | deleted (D03/D25) | package-owned regeneration is automatic; there is no public custom-host generator replacement |
| `MonacoAssets.indexHtmlPath` / `MonacoAssets.assetBaseDir` | internal | apps needing paths use `assetInfo().path` |
| `MonacoAssets.assetInfo(): Map` | `Future<MonacoAssetDiagnostics>` | map keys become typed fields; `version` -> `monacoVersion`, `totalSize` -> `totalSizeBytes`, and formatted String `totalSizeMB` -> double `totalSizeMB` |
| `LiveStats` | `MonacoLiveStats` | see stats rows above |
| v2 tolerant public `fromJson` factories | strict current-shape parsers | audit persisted/adapted `Position`, `Range`, markers, decorations, edits, completions, find models, JSON diagnostics, theme definitions/rules, stats, and editor state |
| `MonacoScrollHandoff.edge()` continuous chaining | defaults to `newGestureOnly` | pass `policy: MonacoScrollBoundaryPolicy.continuous` to preserve v2 behavior; details add `phase`, `gestureId`, and `momentum` |
| LSP exports | source-compatible signatures | `disconnect()` now awaits bridged `onClose`; `LspStdioMessageDecoder` adds optional size limits |
| `MonacoEditorTheme(Data)`, `MonacoFocusGuard`, `MonacoOverlayBoundary`, `MonacoRouteObserver`, `MonacoScaffold` | source-compatible public surface | no source rewrite |

### Behavioral changes

1. Reads throw typed exceptions instead of returning defaults. `evaluateJavaScript` is also stricter for non-null conversion failures.
2. `create` never blocks on readiness; commands issued before ready are ordered FIFO after ready (this preserves the old queue's last-write-wins outcome for consecutive `setText` calls).
3. `updateOptions` is sparse: only the fields you set are sent to Monaco, and reads of sparse option fields are nullable.
4. Empty editor options no longer reproduce v2 defaults. V2 used Dart, fixed `vs-dark`, a Consolas-first font, line height 1.4, no padding, smooth scrolling off, and wheel zoom off. Current defaults use Markdown, ambient widget theme, a Cascadia-first font, Monaco-managed line height, 10px top padding, smooth scrolling on, and wheel zoom on. Pass explicit values when preserving v2 behavior.
5. No boot-theme flash; initial text, language, theme, and options paint in the first frame.
6. Unknown JS events no longer `debugPrint` as unhandled; they surface as `MonacoUnknownEvent`.
7. `MonacoThemeDefinition.base` is `MonacoBaseTheme` and its parser now rejects missing or unknown base ids.
8. `EditorOptions.fromJson` parses only the 3.x `toJson` shape (strict keys, typed sub-options). Other public model parsers also dropped v2 aliases and forgiving defaults. Re-create typed values, keep the old stored data recoverable until verified, and serialize the new shape once.
9. `MonacoTheme` and `MonacoLanguage` are open string-backed types. Audit enum switches, `.name`, `.index`, `Enum` constraints, runtime type tests, and nullable labels in addition to `.values`/`.fromId` calls.
10. `MonacoScrollHandoff.edge()` defaults to gesture containment. Choose `.continuous` explicitly when v2 mid-gesture chaining is required.

### Starting from 1.x

The supported barrel did not require a separate source-symbol rewrite from 1.7.1 to 2.3.0. A direct 1.7.1-to-3.x source migration can use this same map after verifying the 2.0 prerequisites: Dart 3.12, Flutter 3.44, and the Windows WebView backend replacement. Local forks or tests implementing internal `PlatformWebViewController` are outside the supported barrel and must also adopt the 2.x focus and load-contract additions.

The separate 0.1.0-to-1.0.0 hop is additive and does not warrant a dedicated migration skill: `MonacoFocusGuard`, `ensureEditorFocus`, and `layout` were added without removing or changing a supported root-exported signature. Verify the new Flutter 3.16 floor. `focus()` and autofocus now preserve the cursor and initial selection instead of forcing line 1, column 1. The `wordWrap: true` and `minimap: false` defaults are identical at both release commits despite the 1.0.0 changelog wording.

## API Reference

A tour of the main surface. The complete reference lives on [pub.dev](https://pub.dev/documentation/flutter_monaco/latest/).

### Typed ids: themes, languages, actions

`MonacoTheme`, `MonacoLanguage`, and `MonacoAction` are zero-cost extension types over `String` with const catalogs. The catalogs give you autocomplete; the constructors keep the sets open:

```dart
MonacoTheme.vsDark            // vs, vsDark, hcBlack, hcLight
MonacoLanguage.typescript     // 85 built-in language ids
MonacoAction.formatDocument   // ~386 Monaco command ids

MonacoTheme('app-dark')       // custom theme ids are first-class
MonacoLanguage('mylang')      // contributed languages too
MonacoAction('my.command')    // and arbitrary command ids

MonacoTheme.builtIn           // catalog lists (replaces enum .values)
```

Closed sets stay enums: `CursorBlinking`, `CursorStyle`, `RenderWhitespace`, `AutoClosingBehavior`, `MonacoWordWrap`, `MonacoLineNumbers`, `MonacoLineHighlight`, `MonacoFoldingControls`, `MonacoScrollbarVisibility`, `MonacoBaseTheme`, `MarkerSeverity`, `DiagnosticsSeverity`.

### MonacoController

```dart
// Lifecycle: create returns before the editor is ready.
final controller = await MonacoController.create();
await controller.whenReady;
print(controller.isReady);                      // true
print(controller.capabilities.monacoVersion);   // '0.57.0'

// Content and models: controller.document (see Documents section above)
await controller.document.setText('const x = 42;');
final content = await controller.document.getText();

// Language and theme
await controller.document.setLanguage(MonacoLanguage.javascript);
await controller.setTheme(MonacoTheme.vsDark);
final theme = await controller.getTheme();

// Built-in editor actions
await controller.executeAction(MonacoAction.formatDocument);
await controller.executeAction(MonacoAction.find);
await controller.executeAction(MonacoAction.selectAll);

// Navigation and view
await controller.revealLine(100, center: true);
await controller.revealRange(Range.lines(10, 20));
await controller.scrollToTop();
await controller.scrollToBottom();

// Selection and cursor
final selection = await controller.getSelection();
await controller.setSelection(Range.lines(1, 3));
final cursor = await controller.getCursorPosition();
await controller.setCursorPosition(const Position(line: 1, column: 1));

// View state: persist and restore scroll/cursor/folding across sessions
final viewState = await controller.captureViewState();
final json = viewState.toJson(); // store it anywhere
await controller.restoreViewState(viewState);

// One-round-trip snapshot of everything
final state = await controller.getEditorState();
print('${state.lineCount} lines, dirty: ${state.isDirty}, '
    'language: ${state.language}, theme: ${state.theme}');

// Focus
await controller.requestFocus(intent: MonacoFocusIntent.user);
final hasFocus = await controller.hasNativeInputFocus();
await controller.releaseNativeFocus();

// Live statistics (typed fields; render labels in your own UI)
controller.stats.addListener(() {
  final stats = controller.stats.value;
  print('Lines: ${stats.lineCount}, chars: ${stats.charCount}, '
      'selected: ${stats.selectedCharacters}');
});
```

### Events

`controller.events` is a sealed `MonacoEvent` union you can switch over exhaustively; typed convenience streams cover the common cases:

```dart
controller.onContentChanged.listen((change) {
  // change.documentUri, change.isFlush,
  // change.changes (structured ranges, null when truncated),
  // change.truncated
});
controller.onSelectionChanged.listen((Range? range) => print('Selection: $range'));
controller.onFocusChanged.listen((focused) => print(focused ? 'Focus' : 'Blur'));
controller.onScrollHandoff.listen((details) => print(details.deltaY));

controller.events.listen((event) {
  switch (event) {
    case MonacoContentChanged():
    case MonacoSelectionChanged():
    case MonacoFocusChanged():
    case MonacoScrollHandoffEvent():
    case MonacoUnknownEvent(): // forward compatibility, never dropped
      break;
  }
});
```

### Errors

Every bridge failure surfaces as a typed exception under the sealed `MonacoException` base; reads throw instead of returning silent defaults:

```dart
try {
  final text = await controller.document.getText();
} on MonacoTimeoutError {
  // the bridge did not answer in time (also catchable as TimeoutException)
} on MonacoJavaScriptError catch (e) {
  // the JS side threw; e.name, e.stack, e.operation carry details
} on MonacoDisposedError {
  // controller used after dispose
} on MonacoException catch (e) {
  // sealed base: everything above plus MonacoProtocolError
  print('${e.operation}: ${e.message}');
}
```

### Find, replace, and markers

```dart
// Find and replace (on the document)
final matches = await controller.document.findMatches(
  'TODO',
  options: const FindOptions(matchCase: true, wholeWord: true),
);
final replaced = await controller.document.replaceMatches(
  r'colou?r',
  'color',
  options: const FindOptions(isRegex: true),
);

// Markers are grouped by owner; owners never clobber each other
await controller.document.setMarkers(
  [
    MarkerData.error(
      range: Range.lines(10, 10),
      message: 'Undefined variable',
      code: 'E001',
    ),
  ],
  owner: 'my-linter',
);
await controller.document.clearMarkers(owner: 'my-linter');
```

### JavaScript escape hatch

For Monaco APIs not yet wrapped by the typed Dart API, `MonacoController` provides an advanced JavaScript escape hatch. Prefer typed methods when they cover your use case.

| Method | Use case |
| --- | --- |
| `runJavaScript(script)` | Fire-and-forget configuration or commands. |
| `evaluateJavaScript<T>(expression)` | Read a JSON-serializable value with cross-platform type normalization. |
| `runJavaScriptReturningResultRaw(script)` | Advanced raw platform-native result access. |

```dart
await controller.runJavaScript('''
  monaco.editor.getEditors().forEach((e) => e.render());
''');

final editorCount = await controller.evaluateJavaScript<int>(
  'monaco.editor.getEditors().length',
);
```

These methods do not sanitize input. Do not concatenate untrusted strings into a script. Use `jsonEncode` to safely embed dynamic values:

```dart
import 'dart:convert';

// Bad if userInput is attacker-controlled.
await controller.runJavaScript('window.setName("$userInput")');

// Good: jsonEncode creates a safe JavaScript literal.
await controller.runJavaScript(
  'window.setName(${jsonEncode(userInput)})',
);
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

**Note on `fileMatch`:** Patterns match against the Monaco model URI, not file paths. Use `['*']` to apply a schema to all JSON models, or open documents with meaningful URIs via `controller.openDocument(..., uri: ...)`.

**Note on `enableSchemaRequest`:** Remote schema fetching requires the schema host to be allowed by the Content-Security-Policy. The default CSP uses `connect-src 'self' blob:`; allow additional hosts with `MonacoPageConfig(allowedConnectSources: [...])` or prefer inline `schema` maps.

### EditorOptions

`EditorOptions` is sparse: every field is nullable, and only the fields you set are sent to Monaco. At boot, the widget merges your options over `MonacoDefaults.editorOptions` (the curated base: word wrap on, minimap off, line numbers on, fontSize 14, tab size 4, and so on). After boot, `updateOptions` changes only what you pass:

```dart
const options = EditorOptions(
  language: MonacoLanguage.javascript,
  fontSize: 14,
  fontFamily: MonacoFontStacks.jetBrainsMono,
  lineHeight: 1.4,                            // multiplier (< 8) or pixels (>= 8)
  wordWrap: MonacoWordWrap.on,
  lineNumbers: MonacoLineNumbers.on,
  minimap: MonacoMinimapOptions(enabled: false),
  padding: MonacoPadding(top: 10),
  scrollbar: MonacoScrollbarOptions(
    vertical: MonacoScrollbarVisibility.auto,
  ),
  guides: MonacoGuidesOptions(bracketPairs: true, indentation: true),
  stickyScroll: MonacoStickyScroll(enabled: true),
  rulers: [80, 120],
  tabSize: 2,
  insertSpaces: true,
  readOnly: false,
  cursorBlinking: CursorBlinking.smooth,
  cursorStyle: CursorStyle.line,
  renderWhitespace: RenderWhitespace.selection,
  autoClosingBrackets: AutoClosingBehavior.languageDefined,
  bracketPairColorization: true,
  // Escape hatch: raw Monaco options merged last; these keys win.
  extra: {
    'unicodeHighlight': {'ambiguousCharacters': false},
  },
);

// Later: changes ONLY the font size, nothing else.
await controller.updateOptions(const EditorOptions(fontSize: 16));
```

- `theme: null` follows the ambient Flutter brightness and reacts to platform dark-mode changes; an explicit theme always wins.
- `merge(other)` layers options (non-null fields of `other` win) - useful for settings screens.
- `MonacoFontStacks` provides ready-made monospace font stack strings (`jetBrainsMono`, `firaCodePrimary`, `cascadiaCodePrimary`, `sfMono`, ...).

### Custom themes

```dart
const appDark = MonacoThemeDefinition(
  id: 'app-dark',
  base: MonacoBaseTheme.vsDark,
  rules: [
    MonacoThemeRule(token: 'comment', foreground: '6A9955', fontStyle: 'italic'),
  ],
  colors: {
    'editor.background': '#1E1E1E',
    'editor.foreground': '#D4D4D4',
  },
);

await controller.defineTheme(appDark);
await controller.setTheme(MonacoTheme('app-dark'));
// or boot with it: EditorOptions(theme: MonacoTheme('app-dark'))
```

For Monaco theme JSON exported elsewhere, use `MonacoThemeDefinition.fromMonacoThemeData(id, data)`.

To style the editor's Flutter chrome (loading, error, and status-bar widgets), wrap the editor in a `MonacoEditorTheme`:

```dart
MonacoEditorTheme(
  data: MonacoEditorThemeData(
    statusBarBackgroundColor: Theme.of(context).colorScheme.surface,
    loadingIndicatorColor: Theme.of(context).colorScheme.primary,
  ),
  child: MonacoEditor(showStatusBar: true),
)
```

Backgrounds: `setBackgroundColor` recolors the native WebView container, `setHostPageBackgroundColor` recolors Monaco's HTML host page (more reliable on macOS). To recolor Monaco's editor surface itself, set `editor.background` in a `MonacoThemeDefinition`.

### MonacoAssets

```dart
// One-time initialization (called automatically)
await MonacoAssets.ensureReady();

// Typed asset diagnostics
final info = await MonacoAssets.assetInfo();
print('Monaco ${info.monacoVersion} at ${info.path}');
print('${info.fileCount} files, ${info.totalSizeMB.toStringAsFixed(1)} MB');

// Clear cache (forces re-extraction on next use)
await MonacoAssets.clearCache();
```

### Web performance: precache the Monaco bundle

Web platform only; on native `precache()` is simply `ensureReady()`.

On Flutter Web the first (cold-cache) editor boot downloads Monaco over the
network - dominated by one hash-named ~3.6MB chunk - and that download only
starts when the first editor mounts. Warm the browser's HTTP cache ahead of
time and every editor (including several mounting at once) boots from cache:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MonacoAssets.precache()); // fire-and-forget
  runApp(const MyApp());
}
```

The warmup is best-effort: if any fetch fails, the editor downloads the
files itself exactly as before.

To start the warmup even earlier - in parallel with the Flutter engine
download itself - add this snippet to your `web/index.html` (this is what
the [live demo](https://omar-hanafy.github.io/flutter_monaco/) ships):

```html
<script>
  // Warm the HTTP cache with Monaco's files while the Flutter engine
  // downloads. The hashed chunk name changes per Monaco release, so it is
  // recovered from editor.main.js instead of hard-coded.
  (function () {
    'use strict';
    var vs = 'assets/packages/flutter_monaco/assets/monaco/min/vs/';
    function warm(file) {
      return fetch(vs + file, { priority: 'low' })
        .then(function (r) { return r.ok ? r.arrayBuffer() : null; })
        .catch(function () {});
    }
    warm('loader.js');
    warm('editor/editor.main.css');
    fetch(vs + 'editor/editor.main.js', { priority: 'low' })
      .then(function (r) { return r.ok ? r.text() : ''; })
      .then(function (src) {
        var seen = {};
        var re = /\.\.\/(editor\.api-[A-Za-z0-9_-]+)/g;
        var m;
        while ((m = re.exec(src || '')) !== null) {
          if (!seen[m[1]]) { seen[m[1]] = true; warm(m[1] + '.js'); }
        }
      })
      .catch(function () {});
  })();
</script>
```

If you deploy with a non-root `--base-href`, keep the snippet's URLs
relative (as above) so they resolve against `<base href>` like every other
Flutter asset.

What to expect: warming moves the download earlier, it does not add
bandwidth - on a connection fully saturated by the initial load the total
time until an editor is interactive stays the same. The win is that the
editor is served from cache the moment it mounts (no multi-megabyte fetch
racing `readyTimeout` after first frame), which is a strict improvement
whenever your first editor appears after startup - behind navigation, a
tab, or below the fold. The `{ priority: 'low' }` hint keeps the warmup
behind the engine download on HTTP/2 servers; on plain HTTP/1.1 the two
share connections, which can delay first paint on slow links - if your
very first screen is an editor and your users are bandwidth-constrained,
prefer `MonacoAssets.precache()` over the `index.html` snippet.

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

> **Nested navigators:** the guard only sees routes pushed on the `Navigator` its own route belongs to. If your editor lives inside a nested navigator while dialogs go to the root navigator (`showDialog`'s default `useRootNavigator: true`), the root observer never notifies the guard. In that layout, observe every navigator that can host overlays and call `controller.setInteractionEnabled(...)` from your own observer instead - `setInteractionEnabled(false)` also hands the keyboard back to Flutter so Escape/Tab reach the dialog.

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

### Wire protocol v3

- **One channel, one contract.** Every Dart-to-JS command travels through a single request-correlated JSON envelope; every JS-to-Dart message (responses, events, completion/action requests, logs) is a versioned envelope on one channel. No platform-specific result decoding exists anywhere, so behavior is identical on Android, iOS, macOS, Windows, and Web, and every failure surfaces as a typed `MonacoException`.
- **Bridge JavaScript is real files.** The editor bridge ships as plain `.js` assets (`assets/monaco/bridge/`), not Dart string literals. The host HTML is generated internally and rewritten on every load, so a package upgrade can never serve a stale bridge.
- **Two-phase boot.** The page announces readiness with a protocol/version/capability handshake, Dart sends one boot command carrying options, initial text, language, and theme, and the editor is created already configured - no default-theme flash and no post-ready patching. The handshake is exposed as `controller.capabilities` (`protocolVersion`, `monacoVersion`, `lsp`, `diff`).

### Asset Management

The plugin uses a versioned cache system:

- Monaco assets (~30MB) are bundled with the plugin in `assets/monaco/min/`
- Assets are extracted once to the app's support directory
- Assets are versioned (e.g., `monaco-0.57.0/`) for clean updates
- Multiple editors share the same asset installation
- Thread-safe initialization with re-entrant protection

### Platform Support

**Supported Platforms:**

- **Android**: WebView via `webview_flutter`
- **iOS**: WKWebView with automatic blob worker shim for file:// protocol
- **macOS**: WKWebView via `webview_flutter` with blob worker shim
- **Windows**: WebView2 via `webview_flutter_windows` (requires WebView2 Runtime)
- **Web**: Native iframe-based integration with Monaco assets served from Flutter's asset bundle

**Not Supported:**

- **Linux**: Not currently supported (WebKitGTK integration pending)

### Performance

- **Memory**: Each editor instance uses ~30-100MB depending on content
- **Startup**: First launch extracts assets (one-time ~1-2 seconds)
- **Multiple Editors**: Tested with 4+ simultaneous editors on desktop
- **Workers**: Web Workers run in separate threads for syntax highlighting

## Requirements

- Flutter 3.44 / Dart 3.12 or later

### macOS

- macOS 10.15 or later
- Xcode (for development)

### Windows

- Windows 10 version 1809 or later
- Microsoft Edge WebView2 Runtime (auto-installed on most Windows 10/11 systems)

### Android

- Android 7.0 (API level 24) or later
- WebView support (included by default)

### iOS

- iOS 13.0 or later
- Info.plist must allow local file access

### Web

- Modern browser with ES6+ support (Chrome, Firefox, Safari, Edge)
- No additional configuration required

> **Important:** On web, use `MonacoEditor` with `onReady`, or await `controller.whenReady` after the widget is mounted. The iframe must be in the DOM before the editor can finish booting. See the [Web Usage](#web-usage) section below.

## Web Usage

On web, the Monaco Editor runs inside an iframe that must be mounted in the DOM before initialization can complete. This means you should **not** create a controller and await `whenReady` before the widget tree is built (e.g., in `initState`).

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
      initialText: 'print("Hello!");',
      options: const EditorOptions(
        language: MonacoLanguage.dart,
      ),
      onReady: _onEditorReady,
    );
  }
}
```

This pattern works on all platforms and is the recommended approach. The `MonacoEditor` widget handles controller lifecycle internally and provides the controller via `onReady` callback once initialized.

**Why this matters on web:**
- `MonacoController.create()` returns before the editor is ready; readiness is signaled by `controller.whenReady`
- The iframe must be attached to the DOM for Monaco JS to initialize, so `whenReady` cannot complete until the editor's widget is in the tree
- Awaiting `whenReady` in `initState` (before `build`) will therefore time out
- The `MonacoEditor` widget sequences attachment, boot, and readiness for you

### Mobile browsers (iOS Safari, Android Chrome)

No configuration is needed; the package handles both of these automatically:

- **Scroll containment.** The editor document declares `touch-action: none` and
  `overscroll-behavior: none`, so touch scrolling inside the editor moves
  Monaco's content and never pans the surrounding Flutter page - including
  touches that start on the line-number margin or a scrollbar.
- **Soft keyboard fit.** While the on-screen keyboard constrains the browser's
  visual viewport, the editor pins itself to the visible part of its frame and
  keeps the caret revealed, so the first and last lines stay reachable. The
  normal layout is restored when the keyboard closes.

## Example App

### Live Web Demo

You can try the [live web demo here](https://omar-hanafy.github.io/flutter_monaco/).

The [example](example/) directory contains a full demonstration app with:

- Basic single editor setup with completions and a Cmd/Ctrl+S save action
- Language and theme switching
- Multi-document editor (tabs over one editor, dirty tracking)
- Diff editor with side-by-side / inline toggle
- LSP demos (WebSocket and local stdio server)
- Edge scroll handoff playground
- Live statistics display

Run the examples:

```bash
cd example
flutter run -d macos                                     # main demo
flutter run -d macos -t lib/diff_example.dart            # diff editor
flutter run -d macos -t lib/lsp_example.dart             # language servers
flutter run -d macos -t lib/scroll_handoff_example.dart  # edge scroll handoff
```

Replace `-d macos` with `android`, `ios`, `windows`, or `chrome` as needed.

## Important Notes

### Asset Management

Monaco Editor assets are **automatically bundled** with this plugin. You do not need to add any assets to your application. The plugin handles:

- Asset extraction on first launch
- Versioned caching for fast subsequent loads
- Automatic cleanup when updating versions

### Commands Before Ready

Every controller command awaits readiness internally: calls issued before the editor is ready are queued and run in FIFO order once it is. Calling `controller.document.setText(...)` immediately after `create` is safe; the last write wins, exactly as you would expect.

### Marker Owners

Markers are grouped by `owner`. `document.setMarkers(markers, owner: 'my-linter')` replaces that owner's markers and `document.clearMarkers(owner: 'my-linter')` clears them; different owners never interfere. LSP diagnostics live under the `'lsp'` owner and are managed automatically.

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
2. Look for JavaScript errors in the console output
3. Check `controller.whenReady` for a typed boot error (`MonacoTimeoutError`, `MonacoJavaScriptError`, ...)

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

You can also support ongoing development by buying me a coffee:

[![Buy Me A Coffee](https://img.buymeacoffee.com/button-api/?text=Buy%20me%20a%20coffee&emoji=&slug=omar.hanafy&button_colour=FFDD00&font_colour=000000&font_family=Comic&outline_colour=000000&coffee_colour=ffffff)](https://buymeacoffee.com/omar.hanafy)

## License

This plugin is licensed under the MIT License. See LICENSE file for details.

Monaco Editor is licensed under the MIT License by Microsoft.
