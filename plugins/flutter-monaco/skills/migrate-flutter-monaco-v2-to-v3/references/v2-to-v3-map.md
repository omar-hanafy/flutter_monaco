# Flutter Monaco 2.x to 3.x map

The package README contains the symbol table against 2.3.0. Use this file as an execution map, then verify exact signatures in the installed 3.x source. A migration is complete only when it preserves the app's chosen behavior, persisted data, and platform lifecycle, not merely when it compiles.

This skill supports released 2.x applications moving to the current 3.x release. For an earlier 2.x release, review the intervening 2.x changelog for additive APIs. Version 1.7.1 does not require a separate supported-API source rewrite before this map: the 1.7.1 to 2.3.0 barrel is source compatible for normal consumers. It does require a prerequisite audit because 2.0 raised Dart from 3.0 to 3.12, Flutter from 3.29 to 3.44, and replaced `webview_windows` with `webview_flutter_windows`. Tests or forks that import `package:flutter_monaco/src/...` and implement `PlatformWebViewController` must also add the 2.x native-focus methods and `allowedConnectSources` load parameter. See the representative cases under `fixtures/cases.json`.

## Detector

Search application code, tests, generated adapters, and wrappers. Replace `controller` with every controller alias used by the app.

First find removed names and obvious rewrites:

```sh
rg -n "initialValue|controller\.onReady|setValue|getValue|getLineCount|getLineContent|getLinesContent|insertText|hasUnsavedChanges|createModel|setModel|disposeModel|listModels|themeId|effectiveThemeId|setThemeById|controller\.getThemeId|defineThemeFromJson|MonacoConstants|MonacoFont\b|MonacoJavaScriptException|controller\.(setMarkers|setErrorMarkers|setWarningMarkers|clearMarkers|clearAllMarkers)|setDecorations|addInlineDecorations|addLineDecorations|clearDecorations|registerCompletionSource|unregisterCompletionSource|revealLines|setCursorPositionZeroBased|getWordAtPosition|executeBatch|ensureEditorFocus|releaseNativeInputFocus|liveStats|getStatistics|controller\.onContentChanged|controller\.onFocus\b|controller\.onBlur\b|saveViewState|customCss|allowCdnFonts|allowedConnectSources|htmlGenerationVersion|generateIndexHtml|indexHtmlPath|assetBaseDir|Monaco(Theme|Language)\.(values|fromId)"
```

Then inspect every use whose name survived but whose signature, return type, default, or failure contract changed:

```sh
rg -n "executeAction\(|restoreViewState\(|registerStaticCompletions\(|evaluateJavaScript(?:<[^>]+>)?\(|readyTimeout\s*:|createForTesting\(|MonacoAssets\.assetInfo\(|MonacoScrollHandoff\.edge\("
```

Finally find public value parsing and state code that may continue to compile with different behavior:

```sh
rg -n "(EditorOptions|Position|Range|MarkerData|RelatedInformation|DecorationOptions|EditOperation|CompletionItem|CompletionList|CompletionRequest|FindOptions|FindMatch|JsonDiagnosticsOptions|JsonDiagnosticsSchema|MonacoThemeDefinition|MonacoThemeRule|LiveStats|EditorState)\.fromJson\(|\bLiveStats\b|LiveStats\.defaults\(|\.allStats\b|EditorState\(|\.wordCount\b|MonacoConstants\.|is Monaco(Theme|Language|Action)\b"
```

After identifying local variable names, repeat this alias-sensitive review with the app's names in place of `options`, `stats`, and `state`:

```sh
rg -n "\b(options|editorOptions)\.|\b(stats|liveStats)\.(lineCount|charCount|selectedLines|selectedCharacters|caretCount|cursorPosition)(\.(value|label))?|\b(state|editorState)\.(isEmpty|wordCount|toJson|language|theme|stats)\b"
```

These searches are review queues, not pass/fail commands. Also manually audit:

- Reads of every `EditorOptions` field. All v2 fields became nullable, and four changed shape.
- `MonacoTheme`, `MonacoLanguage`, or `MonacoAction` `.name`, `.index`, `Enum` bounds, exhaustive switches, labels, raw-String consumers, and runtime type tests.
- `MonacoAssets.assetInfo()` map indexing such as `['version']` or `['totalSizeMB']`.
- `LiveStats` record `.value` and `.label` reads. A generic regex for those names is too noisy.
- Every source-compatible `revealLine` call whose input might be outside the document.

## Lifecycle, boot, and page policy

| 2.x | 3.x | Preservation rule |
| --- | --- | --- |
| `MonacoController.create` blocks until ready on native | `create` returns before readiness everywhere | await `whenReady` before commands; on Web mount and paint `webViewWidget` before awaiting it |
| controller `onReady` future | `whenReady` | the widget's `onReady` callback remains supported |
| `isReady` means the readiness completer finished, including a failed Web boot | `isReady` is true only after successful boot | code that needs completion including failure must await `whenReady` in `try/catch` |
| `readyTimeout: Duration?` | non-nullable `Duration`, defaulting to `MonacoDefaults.readyTimeout` | resolve nullable app configuration before passing it |
| `MonacoEditor.initialValue` | `initialText` | boot text now paints in the first frame |
| loose `customCss`, `allowCdnFonts`, `allowedConnectSources` | `page: MonacoPageConfig(...)` | changing page policy still requires a new controller |
| `createForTesting(..., bridge:)` | no `bridge`; optional `runBoot`, `bootOptions`, and `bootInitialText` | update test harnesses to drive the real protocol fake |

`MonacoEditor.onReady`, `onContentChanged`, `onRawContentChanged`, `onSelectionChanged`, `onFocus`, and `onBlur` remain widget callbacks. Do not rewrite them as controller streams. In 3.x, a synchronous exception thrown by the widget `onReady` callback is reported through `FlutterError` and does not turn a healthy editor into a boot failure. The callback type is synchronous, so an `async` callback returns an ignored future whose later errors are not caught by the widget. Start asynchronous setup from a synchronous callback and make that operation catch and report its own failures, as demonstrated by the normal fixture.

### Default editor behavior changed

`MonacoEditor(options: const EditorOptions())` was the actual 2.3.0 default. It did not use `MonacoConstants.defaultOptions`. An empty 3.x `EditorOptions()` is sparse and gets `MonacoDefaults.editorOptions` at boot.

| Setting | 2.3.0 empty options | 3.x empty options | Preserve v2 explicitly |
| --- | --- | --- | --- |
| language | Dart | Markdown | `language: MonacoLanguage.dart` |
| theme | fixed `vs-dark` | ambient light/dark in the widget, dark headlessly | `theme: MonacoTheme.vsDark` |
| font family | `Consolas, "Courier New", monospace` | Cascadia-first stack | pass the old CSS stack |
| line height | `1.4` | unset, Monaco-managed | `lineHeight: 1.4` |
| smooth scrolling | `false` | `true` | `smoothScrolling: false` |
| mouse-wheel zoom | `false` | `true` | `mouseWheelZoom: false` |
| padding | none | 10px top | `padding: MonacoPadding(top: 0, bottom: 0)` |

Treat defaults as an application decision. `MonacoDefaults.editorOptions` is not an exact replacement for either v2 `EditorOptions()` or `MonacoConstants.defaultOptions`.

## Content and documents

Move content operations to `controller.document`, which tracks the active Monaco model:

| 2.x | 3.x |
| --- | --- |
| `getValue` / `setValue` | `document.getText` / `setText` |
| `getLineCount` / `getLineContent` | `document.lineCount` / `lineAt` |
| `setLanguage`, `applyEdits`, `deleteRange`, `replaceRange`, `findMatches`, `replaceMatches`, `markSaved` | same intent on `document` |
| `insertText` | `document.insert` |
| `hasUnsavedChanges` | `document.isDirty` |
| `deleteLine(n)` | `document.deleteRange(Range.lines(n, n))` |
| `revealLines(start, end, {center})` | `revealRange(Range.lines(start, end), center: center)` |
| `setCursorPositionZeroBased(line, column)` | `setCursorPosition(Position.fromZeroBased(line, column))` |
| `getWordAtPosition(position)` | `document.getWordAt(position)` |
| `executeBatch(operations)` | an explicit `for` loop that awaits each operation; the removed helper was sequential, not one bridge batch |

`getLinesContent(List<int> lines, {lineDefaultValue})` has no one-call equivalent. `document.getLines(start, end)` reads a contiguous inclusive range and clamps its end, so it is not behavior-preserving for arbitrary or repeated line numbers. Preserve the old result ordering and fallback with an explicit loop:

```dart
final lines = <String>[];
for (final line in requestedLines) {
  try {
    lines.add(await controller.document.lineAt(line));
  } on MonacoException {
    lines.add(lineDefaultValue);
  } on RangeError {
    lines.add(lineDefaultValue);
  }
}
```

Read methods no longer accept silent default values. `replaceMatches` also removes `defaultCount`; it returns a count or throws. Catch the sealed `MonacoException` family only where the app has an intentional fallback.

`findMatches` retains `limit`, and `FindOptions.limitResultCount` provides an additional cap. Existing calls can move to the document without losing the limit.

`revealLine` keeps its source signature but no longer performs the v2 Dart-side `1..lineCount` clamp. If callers can pass invalid input, validate or clamp against `await document.lineCount()` first.

### Model-to-document ownership

| 2.x | 3.x | Important type change |
| --- | --- | --- |
| `createModel(value, language: String, uri:, defaultUri:) -> Uri` | `openDocument(text:, language: MonacoLanguage, uri:) -> MonacoDocument` | `defaultUri` fallback is gone; invalid bridge results throw |
| `setModel(Uri)` | `activateDocument(MonacoDocument)` | retain the handle, or create one with `documentByUri(uri)` |
| `disposeModel(Uri)` | `document.close()` | only pinned document handles can close |
| `listModels() -> List<Uri>` | `listDocuments() -> List<MonacoDocument>` | read each handle's nullable `.uri` when raw URIs are needed |

Opening a document does not activate it. Give LSP-backed documents stable file-like URIs.

## Types and options

- `EditorOptions` is sparse and every v2 field is now nullable. Construction often still compiles, but reads such as `final double size = options.fontSize` require an explicit fallback or a resolved options object. `updateOptions(EditorOptions(fontSize: 16))` changes only font size.
- Replace map/bool option shapes with `MonacoPadding`, `MonacoMinimapOptions`, `MonacoWordWrap`, and `MonacoLineNumbers`.
- `MonacoTheme` and `MonacoLanguage` changed from closed enums to open extension types. `.values` becomes `.builtIn`, but `.fromId(value)` is not a behavior-preserving rename: v2 accepted null and unknown IDs and returned a fallback; `MonacoTheme(value)` and `MonacoLanguage(value)` require a non-null string and preserve unknown custom IDs. Implement the old fallback explicitly when it matters.
- Open extension types have nullable `.label` for custom IDs, no enum `.name` or `.index`, no exhaustive closed-set switch, and no useful runtime `is MonacoTheme` / `is MonacoLanguage` check because they erase to `String`.
- `MonacoAction` constants are typed. Wrap a runtime id with `MonacoAction(id)`, pass action args as named `args:`, and append `.id` for any unrelated raw-String API.
- `MonacoFont.*.value` becomes the matching `MonacoFontStacks.*` string. `MonacoFont.all` becomes `MonacoFontStacks.all`.
- Custom themes use `MonacoTheme(id)` and `MonacoThemeDefinition`; `base` is `MonacoBaseTheme`.
- `MonacoJavaScriptException` becomes `MonacoJavaScriptError` under sealed `MonacoException`.

### Removed constants

`MonacoDefaults` is only a partial successor to `MonacoConstants`:

| 2.x member | 3.x mapping |
| --- | --- |
| `defaultTheme` | `MonacoDefaults.darkTheme.id` |
| `defaultLanguage` | `MonacoDefaults.language.id` |
| `defaultFontSize` | `MonacoDefaults.editorOptions.fontSize` (nullable) |
| `defaultOptions` | no exact replacement; choose and construct the intended app defaults |
| `defaultTabSize` | no value-preserving package replacement: v2 was 2, current boot default is 4 |
| `minFontSize`, `maxFontSize`, `minTabSize`, `maxTabSize`, `commonRulers`, `maxFileSize`, `warningFileSize` | no replacement; retain app-owned policy constants if used |

### Strict public parsers

3.x `fromJson` factories parse their documented current wire or persistence shape. They no longer accept many v2 aliases, missing required values, or wrong types. Audit every direct or persisted call for:

- `EditorOptions`
- `Position` and `Range`
- `MarkerData` and `RelatedInformation`
- `DecorationOptions` and `EditOperation`
- `CompletionItem`, `CompletionList`, and `CompletionRequest`
- `FindOptions` and `FindMatch`
- `JsonDiagnosticsOptions` and `JsonDiagnosticsSchema`
- `MonacoThemeDefinition` and `MonacoThemeRule`
- `MonacoLiveStats` and `EditorState`

Examples of removed aliases include `Position.line`/`col`, `EditOperation.newText`, `FindMatch.text`, and `JsonDiagnosticsSchema.schemaUri`. Do not feed hand-built 2.x `theme`/`themeId` option blobs to 3.x `EditorOptions.fromJson`. Canonicalize app-owned data, construct typed 3.x values, and persist a verified 3.x `toJson()` shape while retaining a recoverable copy of the old data.

## Stats and editor state

| 2.x | 3.x | Migration |
| --- | --- | --- |
| `liveStats: ValueNotifier<LiveStats>` | `stats: ValueListenable<MonacoLiveStats>` | labels move to the app's UI |
| labeled record fields such as `stats.lineCount.value` | plain ints such as `stats.lineCount` | remove `.value`; supply labels in widgets |
| `cursorPosition: ({value, label})?` | `Position?` | use `.line` and `.column` |
| `language: String?` | `MonacoLanguage?` | append `.id` for raw strings |
| `LiveStats.defaults()` | `const MonacoLiveStats()` | constructor replacement |
| `allStats` / `toJson()` | removed | build an app list or persistence map explicitly |
| `hasSelection` / `hasMultipleCursors` | unchanged | no rewrite |

`MonacoEditor.onLiveStats` and `statusBarBuilder` also change their callback parameter from `LiveStats` to `MonacoLiveStats`.

For `EditorState`:

- `hasUnsavedChanges` becomes `isDirty`.
- `language` and `theme` become typed IDs; use `.id` for strings.
- `stats` becomes non-null `MonacoLiveStats`.
- `isEmpty` becomes `content.isEmpty`.
- `wordCount` and `toJson()` have no package replacement; keep app-owned helpers when needed.
- `fromJson` uses strict current keys, including `isDirty` rather than tolerant v2 aliases.

## Handles, completions, events, and view state

| 2.x | 3.x |
| --- | --- |
| marker convenience methods | `document.setMarkers(markers, owner:)` and `clearMarkers(owner:)`; build severities explicitly and clear each owner explicitly |
| controller decoration methods | one `MonacoDecorationSet` per concern, with `set`, `clear`, and `dispose` |
| dynamic completion id plus unregister | `MonacoCompletionRegistration`, then `dispose()` |
| `registerStaticCompletions(languages: List<String>) -> Future<String>` | same method name, `List<MonacoLanguage>`, returning `Future<MonacoCompletionRegistration>`; retain and dispose the handle |
| controller `onContentChanged: Stream<bool>` | `Stream<MonacoContentChanged>`; read `isFlush` |
| controller `onFocus` / `onBlur` streams | `controller.onFocusChanged: Stream<bool>` |
| map view state | `captureViewState` / typed `MonacoViewState` / `restoreViewState` |

The `MonacoEditor.onContentChanged` text callback, `onRawContentChanged` bool callback, and widget focus callbacks remain supported. Qualify controller stream rewrites so widget callbacks are not changed accidentally.

## Actions, focus, and JavaScript

Removed action conveniences map to `executeAction`, including `.formatDocument`, `.find`, `.startFindReplaceAction`, `.selectAll`, `.undo`, `.redo`, `.clipboardCutAction`, `.clipboardCopyAction`, `.clipboardPasteAction`, `.foldAll`, `.unfoldAll`, `.commentLine`, `.indentLines`, and `.outdentLines`. `toggleWordWrap()` was always a no-op because standalone Monaco registers no `editor.action.toggleWordWrap`; from 4.0 `executeAction` throws for it, so replace it with `updateOptions(EditorOptions(wordWrap: ...))`.

`focus` and `ensureEditorFocus` become `requestFocus`; optional retry tuning remains. `releaseNativeInputFocus` becomes `releaseNativeFocus`.

`runJavaScript` and `runJavaScriptReturningResultRaw` keep their signatures. `evaluateJavaScript<T>` does not keep its old fallback behavior: v2 returned `defaultValue` when a non-null value could not convert to `T`; 3.x returns the default only for JavaScript `undefined`/`null`, normalizes numeric types and strings, and otherwise throws `MonacoProtocolError`. If conversion failure was an intended fallback, catch that typed error explicitly.

## Scroll handoff

The source surface is additive, but the default behavior changed. V2 `MonacoScrollHandoff.edge()` continuously forwarded every unconsumed delta when the editor reached an edge. In 3.x it defaults to `MonacoScrollBoundaryPolicy.newGestureOnly`, which keeps the gesture and its momentum inside the editor and hands off only a new gesture that begins at the boundary.

Preserve v2 behavior explicitly:

```dart
const MonacoScrollHandoff.edge(
  policy: MonacoScrollBoundaryPolicy.continuous,
)
```

Custom `onHandoff` consumers must also tolerate the additive `phase`, `gestureId`, and `momentum` fields. Under `newGestureOnly`, `end` and `cancel` messages carry zero deltas.

## Assets

Generated HTML and path ownership are internal in 3.x. `ensureReady`, `clearCache`, and `monacoVersion` remain; `precache` is new.

| 2.x | 3.x |
| --- | --- |
| `htmlGenerationVersion`, `indexHtmlPath`, `assetBaseDir` | no public replacement |
| `generateIndexHtml(...)` | package-owned pages regenerate automatically; no public custom-host generator remains |
| `assetInfo(): Map` | `Future<MonacoAssetDiagnostics>` |

Exact `assetInfo` mapping:

| V2 map key | 3.x typed field |
| --- | --- |
| `exists` | `.exists` |
| `path` | `.path` |
| `version` | `.monacoVersion` |
| `fileCount` | `.fileCount` |
| `totalSize` | `.totalSizeBytes` |
| `totalSizeMB` | `.totalSizeMB` |
| `generatedHtmlCount` | `.generatedHtmlCount` |

V2 native `totalSizeMB` was a formatted `String`; the 3.x field is a `double`. Format it in the app. V2 Web-only `platform` and `note` keys have no typed replacement. An app that used `generateIndexHtml` as a custom host generator must redesign that integration or contribute a supported page API; “automatic” only replaces package-owned page generation.

## LSP and unchanged supporting widgets

The exported LSP connection, transport, server-process, state, and reconnect signatures remain source compatible. Two public behaviors are additive or stronger:

- `LspStdioMessageDecoder` accepts optional `maxHeaderBytes` and `maxBodyBytes` limits.
- Awaiting `LanguageServerConnection.disconnect()` now waits for a bridged transport's `onClose` callback, such as local process shutdown.

`MonacoEditorTheme(Data)`, `MonacoFocusGuard`, `MonacoOverlayBoundary`, `MonacoRouteObserver`, and `MonacoScaffold` keep their public source surface. Closed option enums and ordinary model constructors/factories remain source compatible, subject to the strict parser audit above.
