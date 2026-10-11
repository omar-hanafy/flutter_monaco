# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.0.0] - 2026-10-11

Flutter 3.47 moved Material out of the SDK into the `material_ui` package, and flutter_monaco follows it; that type move is the only source-breaking change. The release also upgrades the bundled engine to Monaco 0.57.0, makes Monaco's background workers run on Windows (#43), and fixes a set of bridge, lifecycle, and LSP defects found in a full audit. The README's "Migrating from 3.x to 4.0" section has the short upgrade path.

### Breaking
- **Requires Flutter 3.47.7 and Dart 3.13.5 or later.** Apple targets follow Flutter 3.47's own minimums: iOS 15 and macOS 12. The macOS plugin's Swift package and podspec now declare macOS 12.0 (was 10.15).
- **Material comes from `material_ui`.** The editor chrome (`MonacoEditor`/`MonacoDiffEditor` loading and error surfaces, `MonacoStatusBar`, `MonacoScaffold`, `MonacoEditorTheme`) now uses `package:material_ui`, so the Material types in this package's API are `material_ui`'s: `MonacoScaffold.floatingActionButtonLocation`/`floatingActionButtonAnimator` and `MonacoEditorThemeData.retryButtonStyle` (`ButtonStyle`). Brightness-following defaults and the chrome read `material_ui`'s `Theme`. Migrate the app with `flutter pub add material_ui` and `dart fix --apply --code=migrate_design_widgets`; an app still on `package:flutter/material.dart` gets `material_ui`'s default theme in the editor chrome (set `EditorOptions.theme` explicitly to keep a dark editor).
- **Calls that used to fail silently now throw.** `executeAction` throws for an action or command id that Monaco does not register and for a command that fails, instead of reporting success. Seven `MonacoAction` catalog constants that standalone Monaco does not register are deprecated: `accessibilityHelp`, `accessibleView`, `goToLocation`, `inlineSuggestTriggerInlineEdit`, `inlineSuggestTriggerInlineEditExplicit`, `toggleScreenReaderAccessibilityMode`, and `toggleWordWrap` (set `EditorOptions.wordWrap` with `updateOptions` instead). `executeAction` with a command id, `scrollToTop`, and `scrollToBottom` throw when no document is attached. `getTheme`, `getSelection`, `getCursorPosition`, `document.isDirty()`, and `getWordAt()` throw `MonacoProtocolError` on a malformed bridge result instead of returning `null` or `false`, and `evaluateJavaScript<String>` throws `MonacoProtocolError` for an object or array result instead of returning Dart's `toString()` of it (return `JSON.stringify(...)` from the expression for its JSON text). `MonacoPageConfig.allowedConnectSources` entries are checked against the CSP source-expression grammar: an entry with a query string, a fragment, or `&` (which let an HTML character reference such as `&#59;` add a directive to the policy) now fails `whenReady` with an `ArgumentError`.

### Added
- **Options for Monaco 0.56 and 0.57 features.**
  - `EditorOptions.wordWrapIndicator` draws a marker where soft-wrapped lines break. With `wordWrap: on` or `bounded`, lines wrap one column earlier to make room for it.
  - `EditorOptions.fullwidthCharacterWidth` (`MonacoFullwidthCharacterWidth`): `twoCells` renders full-width characters such as CJK exactly two cells wide in monospace fonts.
  - `EditorOptions.doubleClickSelectsBlock`: since Monaco 0.56, double-clicking just inside brackets or quotes selects the enclosed block; set `false` to keep plain word selection.
  - `EditorOptions.find` (`MonacoFindOptions`): `closeOnResult`, `loop`, `seedSearchStringFromSelection` (`MonacoFindSeedSearchString`), `autoFindInSelection` (`MonacoAutoFindInSelection`), and `addExtraSpaceOnTop`. Like the other structured options, it merges field-wise.
- **`MonacoFocusGuard.onError`** receives failures of the guard's background focus and interaction updates; without it they go to `FlutterError.reportError` instead of escaping as uncaught errors.

### Changed
- **Bundled Monaco Editor 0.57.0** (was 0.55.1). Highlights that reach apps without code changes: double-clicking just inside brackets or quotes selects the enclosed block (opt out with `doubleClickSelectsBlock: false`), better IME/EditContext handling, hidden find-widget inputs leave the tab order, and DOMPurify 3.4.15. Markdown from language servers is now untrusted: `command:` links in hovers and completion docs render as plain text.
- **Web warmup covers the whole 0.57 boot graph.** `MonacoAssets.precache()` now discovers the hash-named editor chunks by following the AMD dependency graph (15 modules, about 4.2 MB) instead of matching a single chunk name.
- **Smaller app footprint for the new engine.** Monaco files no runtime path loads (AMD worker entries and UI translations, 10.6 MB) are left out of the published package, so apps ship about 15 MB of Monaco instead of 25.6 MB.
- **Monaco's MIT license now ships with the package** and appears on apps' license pages; upstream's third-party notices are included under `third_party/monaco-editor/`.
- **Strict parsers reject fractional and non-finite integers.** Integer fields in `EditorOptions.fromJson` (including `rulers`), the sub-option parsers, and the position, range, marker, completion, text-edit, and statistics parsers now throw `FormatException` for values such as `2.5`, `NaN`, or infinity instead of truncating them. Whole-number doubles such as `2.0` still parse.
- **`MonacoThemeDefinition.fromJson` requires string `colors` values.** A `null` or numeric color used to become `"null"` or a bare digit string, which Monaco silently painted red; it now throws `FormatException`.
- Dependencies: `material_ui` 1.6.0 (new), `webview_flutter` 4.14.1, `webview_flutter_windows` 1.3.0 (fixes WebView2 popups such as `<select>` dropdowns opening away from their element), and `path_provider` 2.1.6.
- **Windows: the editor page's origin is `https://flutter-monaco.example`** (see the #43 fix below). Language-server WebSocket handshakes carry it as their `Origin` header.
- **Release automation.** CI pins every action to a verified release commit, tests on Flutter 3.47.7, fails when committed generated code is stale, resolves the lowest allowed dependencies in a separate job, and boots the bundled editor in headless Chrome in the pages the native hosts serve.
- **The example app targets the new floors** (iOS 15, macOS 12) and builds with the Flutter 3.47 Android template (Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0).

### Fixed
- **LSP**
  - `LspServerProcess.stop()` always finishes: it escalates to SIGTERM and SIGKILL even when the server has stopped reading its input.
  - A language server that exits or drops its connection during the `initialize` handshake fails `connectLanguageServer` immediately with the real cause, instead of a 30-second timeout that pointed at CSP. For `LspServerProcess` the cause is a `ProcessException` carrying the exit code and the server's last stderr lines; a server that later crashes with a non-zero exit code moves its connection to `failed` with that error.
  - After an editor page reload, language server connections no longer claim to be open. They end as `failed` with `MonacoPageReloadedError`, their id can be reused right away, and bridged server processes are stopped. Reconnect from `onPageReloaded`.
  - When `connectLanguageServer` fails for a bridged transport, the transport's `onClose` has already completed, whatever the cause (an invalid or duplicate id, a failed handshake, or a controller that was disposed or failed to boot), so apps no longer have to guess whether they still own the server process. A connect on a disposed controller throws `MonacoDisposedError` instead of `StateError`.
  - A connect cut short during the `initialize` handshake settles in the page too, so timed-out reconnect attempts no longer leave pending requests behind.
  - Disposing the controller while a connection is starting no longer leaks the server-stream subscription.
  - Invalid UTF-8 in a server's stderr (for example Windows code-page output) is shown with replacement characters instead of raising an uncaught error.
- **Editor bridge**
  - Peek Definition, Find All References, and other peek views no longer break the editor. Their embedded editor re-installed the bridge, which caused a second ready event, lost decorations, LSP connections, and actions, doubled change events, and "no active model" errors after the peek closed. The bridge now binds once, to the primary editor.
  - `insert`, `replaceRange`, `deleteRange`, `applyEdits`, and `replaceMatches` are each one undo step. Undo after a programmatic edit no longer corrupts the document, and an edit elsewhere no longer deletes the indentation the user just got from pressing Enter.
  - Whole-word find and replace match words that start or end with symbols (`$x`, `@foo`), follow the editor's `wordSeparators` option, and also apply to regex searches.
  - `replaceMatches` replaces every match; it stopped at 9,999.
  - `getTheme()` returns the current theme (the boot theme, then the latest `setTheme` or `updateOptions` theme) instead of always `null`.
  - Marker tags (`unnecessary`, `deprecated`) render, and hovering a marker with related information no longer fails.
  - Disconnecting an LSP connection while its WebSocket or custom transport is still connecting no longer leaves a live client and transport in the page.
- **Lifecycle and widgets**
  - Commands issued while the editor recovers from a page reload wait for the recovered editor and run in order, instead of failing with "Unknown method" JavaScript errors. If recovery fails or misses `readyTimeout`, they fail with `MonacoPageReloadedError`. `isReady` is `false` while the editor recovers.
  - `MonacoDiffEditor` re-applies its texts, options, theme, diff options, and scroll handoff after a page reload, and reports a failed recovery to `onError`.
  - Disposing a `MonacoController` or `MonacoDiffController` before it is ready completes `whenReady` and queued commands at once with `MonacoDisposedError`, instead of after the boot timeout. On Web the pending load stops without leaking blob URLs.
  - `MonacoFocusGuard` no longer raises uncaught errors on app resume or route pop after a failed boot, and no longer overrides interaction changes the app makes while a route covers the editor.
  - `MonacoEditor.onSelectionChanged` fires when it is supplied after the editor is ready, clearing `onContentChanged` while an update is pending no longer reports a null-check error, and autofocus failures go to `onError`.
  - Web: `MonacoOverlayBoundary` protects overlays when the Flutter app is embedded at an offset in a larger page (element embedding or multi-view).
  - macOS: the boot timeout names the most likely cause, a sandboxed app without the Outgoing Connections (Client) entitlement (`com.apple.security.network.client`), and how to enable it. The README's requirements now say so too.
- **Windows and native hosting**
  - Windows: Monaco's background workers run (#43). `MonacoDiffEditor` shows added and removed lines, and links, word suggestions, and the JSON, CSS, HTML, and TypeScript language services answer. WebView2 does not let a worker load scripts from a `file://` page, so the editor page is now served from the WebView2 virtual host `https://flutter-monaco.example/`, mapped onto the extracted assets. If the WebView2 runtime cannot map the host, or `allowedConnectSources` lists a `ws://` or `http://` endpoint that is not on loopback or a bare `*` (an https page may not reach such endpoints), the page loads from `file://` as before.
  - A WebView that cannot start workers from a `file://` page no longer leaves Monaco waiting on them: the diff is computed on the main thread, and the built-in language services return no result at once instead of hanging. `window.__FM_WORKERS.mode` reports which mode the page runs in. Android, iOS, and macOS keep their real workers.
  - The editor loads when the app's data path contains an apostrophe, for example a Windows user named O'Brien or an app named "Bob's Editor".
  - Two page configurations whose `customCss` differs only in non-ASCII characters no longer share one generated page.
  - Asset extraction, bridge updates, and `MonacoAssets.clearCache()` are atomic. Editors or windows starting together no longer see a partially written asset tree, an invalid tree is replaced only once its replacement is complete, and an `ensureReady` during `clearCache` re-extracts instead of returning a tree that is being deleted. On Windows, installing the tree retries while antivirus scanners or the search indexer briefly hold its files open.

## [3.4.3] - 2026-08-06

### Fixed
- **Firefox can now load the editor on Web.** Firefox does not resolve CSP `'self'` to the creating document's origin inside `blob:` documents, so the blob-hosted editor page blocked its own loader, bridge scripts, stylesheet, and workers, failing with "Failed to load Monaco loader.js" while Chrome worked. The page no longer relies on `'self'` for anything it fetches: it names the origin of every resolved asset root explicitly. Native platforms keep a byte-identical policy, and browsers where `'self'` already matches are unaffected.
- **A load blocked by the page's Content-Security-Policy now names the directive that refused it and the URL it refused**, instead of reporting only "Failed to load Monaco loader.js".

## [3.4.2] - 2026-07-19

### Added
- **Optional package-specific AI assistant support for Claude Code and OpenAI Codex.** A repository-hosted plugin provides six focused skills for integration, 2.x-to-3.x migration, diagnostics, LSP configuration, Dart-to-JavaScript bridge maintenance, and bundled Monaco upgrades. A narrow read-only bridge contract reviewer, deterministic extension validator, and selection/execution/negative/failure eval cases keep the guidance maintainable without adding hooks, services, runtime dependencies, credentials, or published package bulk.

### Fixed
- **The complete example no longer waits on editor commands before mounting its controller.** The controller is mounted first so Web can attach and boot its iframe, while initialization continues after readiness. The widget now remains the single live owner of its language and theme instead of reconciling the external controller back to ambient defaults; a regression test protects both contracts.
- **`MonacoOverlayBoundary` no longer reads its render-box size before first layout on Web.** Its startup ticker now treats an attached but unlaid-out boundary as empty instead of throwing a scheduler assertion; a mutation-proven Chrome regression runs in CI.
- **The macOS CocoaPods metadata now reports the package's current version** instead of the stale `2.2.0` value.
- **Public platform requirements now match the effective WebView dependencies:** Android 7/API 24+, iOS 13+, and macOS 10.15+.
- **Focus and LSP documentation now uses the 3.x API:** `requestFocus`, `releaseNativeFocus`, `onFocusChanged`, `MonacoPageConfig`, and `controller.document.setLanguage`.
- **The 2.x-to-3.x migration map now covers the complete released API and behavioral boundary:** lifecycle and readiness, documents and models, sparse option shapes and changed defaults, strict persisted-value parsers, typed state and statistics, open identifiers, JavaScript conversion failures, scroll policy, asset diagnostics, registrations, focus and events, and surviving signatures. Executable fixtures cover normal migration, persisted data, prerequisite audits, already-migrated input, unsupported future versions, and Web-readiness recovery.

### Changed
- **Release automation is stricter.** Auto-release verifies a real version delta, safely reuses a same-commit tag on retry, scopes the tag PAT to one ref-creation step, pins release and trusted-publish workflow revisions, and keeps publication tag-driven. Stable CI now self-tests tag retry behavior, validates AI extension metadata and evals, runs the Web pre-layout regression, and enforces a pinned full Pana score.
- The root and example development-only `platform` floors are constrained to 3.1.6 so both lowest-compatible dependency graphs remain buildable on Dart 3.12; 3.0.0 still references the removed `dart:io Platform.packageRoot` API.
- The example README and issue template now describe the real cross-platform package, including Web.

## [3.4.1] - 2026-07-11

### Fixed
- **Web: a boot whose platform view was never mounted now fails fast with an actionable error instead of a silent 40-second timeout.** On web the editor iframe only loads while `webViewWidget` is mounted and painted; when an app awaited `whenReady` without putting the widget in the tree (or hid it with `Offstage`/`Visibility(visible: false)`, or inserted it only after readiness), the load silently burned two 20-second attempts and surfaced a bare `TimeoutException`. A ready timeout with the iframe still detached now throws a `StateError` immediately that names the requirement: keep `webViewWidget` painted underneath your loading UI (an opaque `Stack` overlay, as the `MonacoEditor` widget does). `MonacoController.create` and `webViewWidget` document the constraint.

## [3.4.0] - 2026-07-11

The editor now survives page reloads it never caused. On Flutter web the engine can detach and re-insert the editor's iframe during platform-view re-composition (closing/opening in-app tabs, route transitions), and re-inserting an iframe makes the browser reload it; native WebView processes can likewise recover from a crash. Both cases previously left a dead editor behind.

### Fixed
- **Web: the editor pane no longer turns into the browser's "It may have been moved, edited, or deleted." error page.** The Monaco page's blob URL was revoked as soon as the page first reported ready, so any later engine-driven iframe re-insertion reloaded a dead URL. The blob URL now lives exactly as long as the iframe and is released on `dispose()`.

### Added
- **Automatic page-reload recovery.** When the page document reloads under a live controller, `MonacoController` and `MonacoDiffController` detect it, re-boot the editor with their original boot payload (options, text, language, theme), and re-register every live `registerCompletions` provider and `addAction` action - existing registration handles stay valid. `MonacoEditor` additionally re-applies its widget-owned options, resolved theme, background color, and scroll-handoff sources.
- **`onPageReloaded` stream on `MonacoController` and `MonacoDiffController`.** Fires after a recovery completes, once the editor accepts commands again. Listen to restore what the package cannot know: document content and models opened with `openDocument` (stale pinned handles throw), post-boot configuration (`updateOptions`, `setTheme`, `defineTheme`, markers, decorations, view states), and LSP connections (reconnect them). A failed recovery surfaces as an error event on the stream.
- **`MonacoPageReloadedError`.** Commands in flight when the page reloads now fail immediately with this typed, retryable error instead of hanging until their timeout. Note for exhaustive `switch`es over the sealed `MonacoException`: this adds a new member.

## [3.3.0] - 2026-07-10

Two independent improvements in one release. Correctness fixes driven by an external architecture audit of v3: two release-blocking fixes (dirty tracking, boot-error propagation), a set of lifecycle repairs, and small API additions; no public API is removed. And edge scroll handoff gains native nested-scroll boundary behavior: the gesture that reaches the editor's scroll edge stops there instead of jerking the surrounding page.

### Fixed
- **Dirty tracking no longer misses the first edit.** Dirty baselines were created lazily on the first `isDirty()` query, so querying after the first edit recorded the already-edited version as "clean" and returned `false` - the exact pattern of updating a dirty marker from `onContentChanged`. Every document (the boot document and each `openDocument`) is now baselined at creation.
- **Commands issued after a failed boot now rethrow the original boot error.** A failed readiness future still reads as "completed", so later commands skipped the gate, entered the protocol of the dead page, and surfaced as unrelated timeouts or JavaScript errors instead of the real boot failure. Both `MonacoController` and `MonacoDiffController` are fixed; commands on a disposed controller now consistently throw `MonacoDisposedError` (they could previously hang when disposal interrupted a boot, and LSP connects threw an untyped `StateError`).
- **`onContentChanged` now fires for edits to inactive documents.** Content events were attached to the editor viewport, so pinned-handle edits to a background document produced no event; each model now carries its own subscription and events are tagged with the document's URI, exactly as documented.
- **Nested option defaults survive partial overrides.** `EditorOptions.merge` replaced structured values wholesale, so e.g. `MonacoMinimapOptions(side: left)` at boot dropped the curated `enabled: false` default and re-enabled the minimap; `minimap`, `padding`, `scrollbar`, `guides`, and `stickyScroll` now merge field-wise.
- **Options changed while the editor was still booting are no longer dropped.** `MonacoEditor` and `MonacoDiffEditor` reconcile the widget's current options, theme (including ambient-brightness flips), and language against the boot snapshot before reporting ready.
- **A throwing `onReady` callback no longer destroys a healthy editor.** Application callback exceptions previously tripped the boot catch (disposing an owned controller and rendering the error surface); they are now reported through `FlutterError` and the editor stays up.
- **`executeAction` waits for asynchronous actions.** The bridge reported success immediately even when the Monaco action returned a promise; failures from async actions now reach Dart.
- **Completion items with an intentionally empty `insertText` no longer insert their label** (`||` -> `??` in the bridge mapping).
- **Overlapping `runWithInteractionDisabled` scopes compose.** The previous snapshot/restore could re-enable interaction while another overlay still needed it disabled, and clobbered an external `setInteractionEnabled` made during the run; disable scopes are now ref-counted over a base state.
- **A stale content pull can no longer fire `onContentChanged` after the widget swapped controllers.**
- **Clearing `MonacoEditor.backgroundColor` (set -> null) now restores the resolved default** instead of leaving the last color baked into the native view and host page.
- **`MonacoDiffEditor` disposes its owned controller on boot failure** (matching `MonacoEditor`) instead of keeping the dead WebView alive until retry/dispose.
- **A throwing `LspBridgedTransport.toServer` now fails the connection** (honoring the reconnect policy) instead of logging and leaving it "open".
- **Live stats refresh immediately on `activateDocument`** instead of waiting for the next keystroke.
- **Generated-page hardening:** `customCss` can no longer terminate its `<style>` element early (an embedded `</style>` no longer becomes markup), and the web message token is JSON-encoded at every interpolation site.
- **Generated HTML cache files no longer accumulate across launches.** The cache file name used `MonacoPageConfig.hashCode`, which Dart seeds per process, so every launch wrote a new orphan `monaco_<hash>.html`; the name now uses a stable content digest (`MonacoPageConfig.stableCacheKey`).
- **`MonacoAssets.clearCache` waits for an in-flight `ensureReady`** instead of deleting the tree mid-extraction.
- **`MonacoViewState` is now truly value-typed:** `toJson()` returns an independent deep copy and equality/hashCode are deep over nested payloads.

### Changed
- **Edge scroll handoff absorbs a gesture's remaining momentum at the editor's scroll boundary.** A wheel/trackpad gesture that starts inside the editor now stops dead at the edge, inertial tail included; the host page scrolls only when a physically distinct gesture starts while the editor is already at its edge. Reversing direction still hands input back to the editor immediately. This is the new default (`MonacoScrollBoundaryPolicy.newGestureOnly`); restore the previous unconsumed-delta chaining with `MonacoScrollHandoff.edge(policy: MonacoScrollBoundaryPolicy.continuous)` or the `policy` parameter of `setScrollHandoffSources`.
- Experimental touch forwarding under the default policy decides ownership once per drag: a drag that starts over scrollable editor content belongs to the editor for its whole lifetime (contained at the edge), and only a drag that starts at an outward edge scrolls the host.
- **`MonacoDiffController.getLineChangeCount` is loud about an uncomputed diff:** when Monaco has not finished computing (throttled/offscreen views) it throws `MonacoTimeoutError` instead of silently returning `0`, so zero always means a real "no changes" result. `diff.getState` reports the pending state as a `null` count.
- **`MonacoDocument.lineAt` is strict:** reading a line beyond the end of the document now throws instead of silently clamping to the last line. The ranged `getLines` keeps its documented clamping.
- **Content-change events also truncate on change count:** deltas are omitted (with `truncated: true`) for events carrying more than 1000 individual changes, not only for 64 KiB of inserted text - multi-cursor edit storms previously shipped unbounded envelopes.
- **`LanguageServerConnection.disconnect()` now completes only after a bridged transport's `onClose` finished** - for `LspServerProcess`, that means the local server process has exited.

### Added
- `MonacoScrollBoundaryPolicy` (`newGestureOnly` | `continuous`) on `MonacoScrollHandoff.edge` and on `setScrollHandoffSources` of both controllers.
- Host-owned handoff gestures arrive sessionized: `MonacoScrollHandoffDetails` gains `phase` (`begin`/`update`/`end`/`cancel` via `MonacoScrollHandoffPhase`), `gestureId`, and `momentum`. The built-in scrolling applies updates only for the gesture it saw begin, so stale deltas can never move the host; custom `onScrollHandoff` consumers can enforce the same rule. Payloads without session fields keep working unchanged.
- **`MonacoCapabilities.raw` and `supports(String)`**: the verbatim capability strings from the page handshake, so apps can feature-gate capabilities this package version has no typed field for.
- **`FindOptions.searchOnlyEditableRange` and `limitResultCount` are now honored** by `findMatches`/`replaceMatches` (they previously serialized but had no effect); `limitResultCount` composes with the `limit` parameter as the smaller cap.
- **`MonacoPageConfig.stableCacheKey()`**: a process-stable digest of the page configuration.
- **`LspStdioMessageDecoder` accepts `maxHeaderBytes`/`maxBodyBytes`** (defaults 16 KiB / 64 MiB) so a broken or hostile server cannot grow memory without bound.

### Notes
- Web: a cross-origin CDN `assetBase` is documented as unsupported for the Monaco assets - the generated page's CSP (`script-src 'self'`) blocks cross-origin bundles; serve flutter_monaco's assets same-origin.

## [3.2.0] - 2026-07-07

### Added
- **`MonacoAssets.precache()`: warm Monaco before the first editor mounts.** On web it fetches the AMD loader, `editor.main.js`/`.css`, and the hash-named editor chunk (~3.6MB, discovered from `editor.main.js` at runtime so it survives Monaco upgrades) into the browser's HTTP cache; the first editor boot is then served from cache instead of starting a multi-megabyte download at mount time. Best-effort and boot-path-untouched: a failed warmup just means the editor downloads the files itself as before. On native platforms it is equivalent to `ensureReady()` (asset extraction). Fire-and-forget from `main()` is the intended use. The README's new "Web performance" section also documents an `index.html` snippet (used by the live demo) that starts the warmup in parallel with the Flutter engine download itself.

### Notes
- Investigated the suspected duplicate bundle download when several editors boot at once on web: with the HTTP cache enabled, browsers coalesce the concurrent identical requests (verified in Chromium - the second iframe's request completes with zero bytes on the wire), so no boot-path serialization was added. Precaching makes a single download the expected behavior on other browsers too, subject to their HTTP cache and response cache policy.

## [3.1.1] - 2026-07-07

### Fixed
- **Web: flaky "Monaco Editor did not report ready in 20 seconds" on cold-cache first loads.** The default `readyTimeout` was a fixed 20 seconds on every platform, but on web the first (uncached) visit must download the multi-megabyte Monaco bundle over the network - a bandwidth-bound wait, not a hang - so slow connections and just-deployed sites (invalidated CDN caches) tripped the deadline mid-download; a retry then succeeded from the warm browser cache. The default is now platform-aware via `MonacoDefaults.readyTimeout` (20s on native, 90s on web). Hard failures (missing assets, script errors) still surface immediately on every platform; the deadline only backstops silent stalls. The web timeout message now also explains the slow-connection case. Explicitly passed `readyTimeout` values behave exactly as before.

## [3.1.0] - 2026-07-07

### Added
- **Edge scroll handoff for the diff editor.** `MonacoDiffEditor.scrollHandoff` takes the same `MonacoScrollHandoff` configuration as `MonacoEditor`: wheel or trackpad input over either pane keeps scrolling the diff until it reaches its vertical scroll edge, then unconsumed deltas are forwarded to the configured `ScrollController` or the nearest enclosing vertical scrollable, so the surrounding page keeps scrolling instead of dying over the editor. Headless integrations get the same building blocks as the single editor: `MonacoDiffController.onScrollHandoff` and `MonacoDiffController.setScrollHandoffSources`.

### Fixed
- **Multi-document: the boot document no longer dies on the first `activateDocument`.** Monaco's standalone editor takes ownership of a model created implicitly from the `value`/`language` create options and disposes it on the first `setModel`; the boot page now creates the initial model explicitly, so switching documents and back preserves the original document.

## [3.0.0] - 2026-07-07

A ground-up rebuild of the package's spine - one wire protocol, a document/editor split, sparse options, typed errors and events - while keeping the battle-tested platform engineering (LSP, focus recovery, mobile web survival kit, scroll handoff, web overlay stack) intact. The README's "Migrating from 2.x to 3.0" section carries the complete symbol-level migration table; the highlights are below.

### Breaking
- **Content and model operations moved to `controller.document`** (a `MonacoDocument` handle): `setValue`/`getValue` become `document.setText()`/`getText()`, `getLineCount`/`getLineContent`/`getLinesContent` become `lineCount()`/`lineAt()`/`getLines(start, end)` (one bridge call for the whole range), `insertText` becomes `insert`, `hasUnsavedChanges()` becomes `isDirty()`, and `setLanguage`/`applyEdits`/`deleteRange`/`replaceRange`/`findMatches`/`replaceMatches`/`markSaved` move over with the same names. Markers are owner-scoped on the document: `setMarkers(markers, owner:)`/`clearMarkers(owner:)`.
- **Multi-model API replaced by documents**: `createModel`/`setModel`/`disposeModel`/`listModels` become `openDocument({text, language, uri})`/`activateDocument(doc)`/`doc.close()`/`listDocuments()`, with `documentByUri(uri)` for lookups.
- **`MonacoController.create` returns before editor readiness on every platform** (it used to block until ready on native; asset preparation and WebView setup are still awaited); await `controller.whenReady` (renamed from the `onReady` future). The signature is now `create({options, initialText, page, readyTimeout})`: `customCss`/`allowCdnFonts`/`allowedConnectSources` moved into `MonacoPageConfig` passed as `page:`. Likewise on the widget: `MonacoEditor.initialValue` is now `initialText` and the three loose page parameters are `page: MonacoPageConfig(...)`.
- **`MonacoTheme` and `MonacoLanguage` are extension types over `String`** (were enums): `MonacoTheme.vsDark`/`MonacoLanguage.dart` are unchanged textually, `.values` becomes `.builtIn`, `fromId(s)` becomes `MonacoTheme(s)`/`MonacoLanguage(s)`, and custom ids are first-class. `EditorOptions.themeId`/`effectiveThemeId`, `setThemeById`, and `defineThemeFromJson` are deleted: a custom theme is just `MonacoTheme('app-dark')`. `MonacoThemeDefinition.base` is the new `MonacoBaseTheme` enum.
- **`MonacoAction` constants are typed `MonacoAction` values** (were `String`s) and `executeAction` takes `MonacoAction` with named `args`; wrap raw command ids with `MonacoAction(id)`.
- **`EditorOptions` is sparse**: every field is nullable, and `updateOptions(EditorOptions(fontSize: 16))` changes only the font size instead of resetting ~40 options to package defaults. `padding` is `MonacoPadding`, `minimap` is `MonacoMinimapOptions`, `wordWrap`/`lineNumbers` are enums, and structured `scrollbar`/`guides`/`stickyScroll` sub-options plus an `extra` map cover the rest of Monaco's option surface.
- **Errors are typed and loud**: `MonacoJavaScriptException` is now `MonacoJavaScriptError` under a sealed `MonacoException` hierarchy, every read/write throws on bridge failure, and the `defaultValue` fallback parameters on reads are gone (an app can no longer mistake "bridge died" for "empty document").
- **Completions return registrations**: `registerCompletionSource`/`unregisterCompletionSource` become `registerCompletions(...)`/`registerStaticCompletions(...)`, both returning a `MonacoCompletionRegistration` with `dispose()`; `languages` takes `List<MonacoLanguage>`.
- **Decorations are handle-based**: `setDecorations`/`addInlineDecorations`/`addLineDecorations`/`clearDecorations` become `createDecorationSet()` with `set`/`clear`/`dispose` per set.
- **Events are typed**: `onContentChanged` is `Stream<MonacoContentChanged>` (was `Stream<bool>`; `isFlush` is a field), `onFocus`/`onBlur` merge into `onFocusChanged: Stream<bool>`, and `liveStats`/`getStatistics()` become `stats: ValueListenable<MonacoLiveStats>` with plain typed fields (the label records and the `line*1000+column` cursor encoding are gone).
- **Focus API consolidated**: `focus()`/`ensureEditorFocus({attempts, interval, intent})` become `requestFocus({intent})` with sensible retry defaults (attempts/interval remain optional parameters); `releaseNativeInputFocus()` is renamed `releaseNativeFocus()`.
- **View state is opaque and typed**: `saveViewState(): Map`/`restoreViewState(Map)` become `captureViewState(): MonacoViewState`/`restoreViewState(MonacoViewState)`; persist via `toJson()`.
- **`MonacoAssets` slimmed**: `assetInfo()` returns a typed `MonacoAssetDiagnostics`; `indexHtmlPath`/`assetBaseDir` are internal (use `assetInfo().path`).
- Behavioral changes: reads throw typed exceptions instead of returning defaults; commands issued before ready run FIFO after ready (preserving the old queue's last-write-wins outcome for consecutive `setText` calls); `updateOptions` is sparse; the markdown/vs-dark boot flash is gone (the first painted frame uses the requested options); unknown JS events surface as `MonacoUnknownEvent` instead of a debug print; `EditorOptions.fromJson` parses only the 3.0 `toJson` shape (apps that persisted hand-built 2.x option JSON re-serialize once with 3.0 `toJson`).

### Added
- **Wire protocol v3.** Every command, event, and callback rides a single versioned, request-correlated JSON envelope channel that behaves identically on Android, iOS, macOS, Windows, and Web - no per-platform result decoding anywhere. A two-phase boot (page handshake, then one boot command carrying options/text/language/theme) means the editor is born configured, and `controller.capabilities` exposes the handshake (`protocolVersion`, `monacoVersion`, `lsp`, `diff`).
- **Dart-defined custom editor actions.** `controller.addAction(MonacoActionDescriptor(...), run)` registers an action with typed keybindings (`MonacoKeybinding`/`MonacoKey`, e.g. Cmd/Ctrl+S save hooks), command-palette presence, and optional context-menu placement; the returned `MonacoActionRegistration.dispose()` removes it. The example app's main demo now ships a Cmd/Ctrl+S save hook.
- **Diff editor.** `MonacoDiffEditor` widget and headless `MonacoDiffController` (`setTexts`, `getModifiedText`, `getLineChangeCount`, `updateOptions`, `updateDiffOptions`, `setTheme`, `revealNextChange`/`revealPreviousChange`), configured via `MonacoDiffOptions` (side-by-side or inline, original editability, whitespace handling, `extra` passthrough). New demo: `example/lib/diff_example.dart`.
- **Multi-document editing.** `openDocument` returns URI-pinned `MonacoDocument` handles that can edit their model even while another document is visible; documents keep independent undo stacks and dirty state, and content-change events carry the document URI. The multi-editor example is now a tabbed single-editor, multi-document demo.
- **`MonacoDecorationSet`**: multiple independent decoration owners (e.g. search highlights + lint underlines) that no longer clobber each other.
- **Sealed `MonacoEvent` union** on `controller.events` with typed convenience streams; `MonacoContentChanged` carries structured change ranges (`changes`, capped at 64 KB with `truncated: true` beyond) enabling diff-based sync without full-text pulls; unknown event names surface as `MonacoUnknownEvent`.
- **Sealed `MonacoException` hierarchy**: `MonacoJavaScriptError`, `MonacoProtocolError`, `MonacoTimeoutError` (implements `TimeoutException`, so existing `on TimeoutException` catches keep working), and `MonacoDisposedError`, each carrying the failing operation name.
- **`MonacoPageConfig`**: groups `customCss`, `allowCdnFonts`, and `allowedConnectSources` for `create` and both widgets.
- **`MonacoDefaults`** (the curated `editorOptions` base the widget merges under user options, plus default theme/language) and **`MonacoFontStacks`** (the former `MonacoFont` stacks as `String` constants).
- **`MonacoAssetDiagnostics`**: typed asset cache info (`exists`, `path`, `monacoVersion`, `fileCount`, `totalSizeBytes`/`totalSizeMB`, `generatedHtmlCount`).
- **Brightness-following default theme**: a null `EditorOptions.theme` resolves from the ambient Flutter brightness (dark gets `vs-dark`, light gets `vs`) and re-resolves when the platform switches modes; an explicit theme always wins.
- **Open extension types with dot shorthand**: custom themes (`MonacoTheme('app-dark')`), contributed languages (`MonacoLanguage('mylang')`), and arbitrary command ids (`MonacoAction('my.command')`) are first-class, and Dart 3.10+ shorthands work at call sites (`executeAction(.formatDocument)`, `setTheme(.vsDark)`).
- **`MonacoEditor.onError`**: async command failures the widget itself triggers now surface through this callback (default: `FlutterError.reportError`) instead of being silently debug-printed. `MonacoDiffEditor` has the same hook.

### Changed
- `getEditorState()` now completes in one bridge round trip (was five sequential calls) and finally populates `theme` (was always `null`).
- The LSP subsystem rides protocol v3 internally; its public API is unchanged from 2.3.0 and is pinned by a golden surface test. `LanguageServerConnection`, transports, `LspServerProcess`, and reconnect policies all work exactly as before.
- The bridge JavaScript ships as real asset files (`assets/monaco/bridge/*.js`) instead of a Dart string literal, and the generated HTML is rewritten on every load - a package upgrade can never serve a stale bridge, and the manual cache-bust constant is gone.

### Removed
- The 15 controller convenience action methods (`format`, `find`, `replace`, `toggleWordWrap`, `selectAll`, `undo`, `redo`, `cut`, `copy`, `paste`, `foldAll`, `unfoldAll`, `toggleLineComment`, `indentLines`, `outdentLines`); use `executeAction` with the matching `MonacoAction` constant (`.formatDocument`, `.commentLine`, `.startFindReplaceAction`, ...).
- The marker conveniences `setErrorMarkers`/`setWarningMarkers`/`clearAllMarkers`; build `MarkerData.error(...)`/`MarkerData.warning(...)` lists and clear owners explicitly.
- `MonacoConstants` (see `MonacoDefaults`) and the `MonacoFont` enum (see `MonacoFontStacks`).
- `MonacoAssets.htmlGenerationVersion` and public `generateIndexHtml`: HTML generation is internal and regenerated automatically on every load, so no cache-bust bookkeeping remains.

## [2.3.0] - 2026-07-06

### Added
- **Language Server Protocol support.** `MonacoController.connectLanguageServer` connects the editor to a real language server through Monaco 0.55's built-in LSP client; once connected, completions, hover, go-to-definition, references, rename, formatting, code actions, folding, inlay hints, semantic tokens, and diagnostics come straight from the server with nothing to wire up in Dart. The returned `LanguageServerConnection` exposes `state`/`stateChanges`/`whenClosed`, `disconnect()`, and experimental `sendRequest`/`sendNotification` escape hatches for non-standard server extensions. `disconnectLanguageServer`, `languageServerConnections`, and `languageServerConnection(id)` round out the controller API.
- Three pluggable LSP transports: `LspWebSocketTransport` (server behind a `ws://`/`wss://` endpoint - works on every supported platform), `LspBridgedTransport` (Dart owns the wire; JSON-RPC is relayed through the Flutter bridge - no port, no proxy, no CSP changes), and `LspCustomTransport` (user-registered JavaScript factory on `window.flutterMonacoLspTransports` for worker/iframe/custom setups).
- `LspServerProcess.start(executable, args)` spawns a local stdio language server (e.g. `pyright-langserver --stdio`) on desktop and hands you a fully wired bridged transport, with stderr forwarding, graceful stop (stdin EOF, then SIGTERM, then SIGKILL), and automatic shutdown when the connection or controller is disposed.
- Optional automatic reconnect for WebSocket/custom transports via `LspReconnectPolicy.exponentialBackoff(...)` on `connectLanguageServer`; drops after the connection was open reconnect with backoff and surface each attempt on `stateChanges`.
- `allowedConnectSources` on `MonacoController.create` and the `MonacoEditor` widget: an explicit Content-Security-Policy opt-in for `connect-src` origins. Required for WebSocket language servers (the default policy blocks all `ws://`/`wss://` handshakes); entries that could inject CSP directives are rejected.
- Exported `LspStdioMessageEncoder`/`LspStdioMessageDecoder` (LSP `Content-Length` framing codec) for apps that integrate their own process or socket plumbing with `LspBridgedTransport`.
- New LSP demo in the example app (`example/lib/lsp_example.dart`) covering both the WebSocket and the local stdio-process paths.
- Opt-in **edge scroll handoff** for editors embedded in scrollable pages. With `MonacoEditor(scrollHandoff: MonacoScrollHandoff.edge(...))`, wheel or trackpad scrolling keeps moving Monaco until the editor reaches its scroll edge (or the document has nothing to scroll), then continues into a configured `ScrollController` or the nearest enclosing vertical `Scrollable`; reversing direction hands the wheel back to the editor. Disabled by default: existing apps keep the exact previous scroll-trapping behavior. Ctrl/meta wheel (editor zoom, browser zoom, macOS pinch) and Monaco's own scrollable overlays (suggest list, hover docs, menus, peek editors) are never handed off, and `scrollBeyondLastLine` blank space counts as editor-scrollable. This is edge handoff across the WebView bridge, not native nested scrolling.
- `MonacoScrollHandoff` (with `MonacoScrollHandoffDetails`, `MonacoScrollHandoffMode`, `MonacoScrollHandoffSource`) including an `onHandoff` callback to consume forwarded deltas in app code.
- `MonacoController.onScrollHandoff` (typed stream of unconsumed scroll deltas) and `MonacoController.setScrollHandoffSources(...)` for headless or custom-widget integrations that want the events without `MonacoEditor`'s built-in scrolling.
- An experimental, separately opt-in touch source (`MonacoScrollHandoff.edge(mobileTouch: true)`). Touch forwarding is observation-only (it never blocks Monaco's touch handling, never opens the keyboard, and yields to text selection) and has no native momentum or fling transfer.
- New scroll handoff demo in the example app (`example/lib/scroll_handoff_example.dart`): a scrollable page with short, long, and handoff-disabled editors plus live toggles.

### Changed
- Upgraded the bundled Monaco Editor from 0.54.0 to 0.55.1 (first version to ship `monaco.lsp`). Extracted assets re-extract once on first launch after upgrading. The deprecated `monaco.languages.json/css/html/typescript` namespaces are still aliased by Monaco, and the bridge's JSON diagnostics configuration now prefers the new top-level `monaco.json` namespace, so existing code and raw-JS integrations keep working.
- Removed a stray `debugger;` statement from the bundled Monaco 0.55.1 LSP diagnostics feature (an upstream build artifact) so opening the web inspector while an LSP connection starts no longer pauses the editor.

### Fixed
- Mobile web (#11 hardening): the keyboard viewport-fit no longer engages just because the editor is partially scrolled offscreen. It previously pinned `#editor-container` to the on-screen band whenever the iframe extended past the viewport, so an editor inside a scrollable Flutter page stopped scrolling away with the page (its content "anchored" to the screen), and pinch zoom fought the pin. The pin now activates only while the visual viewport is actually constrained - the soft keyboard shrinking it, or Safari panning it to chase the caret - and never while pinch-zoomed. The keyboard behavior on iOS Safari is unchanged.
- Mobile web: disposing an editor no longer leaks its Monaco instance. The viewport-fit and keyboard-baseline listeners the editor document registers on the host page's `visualViewport`/window survived `dispose()` (removing an iframe fires no `pagehide`), keeping the whole dead editor document - Monaco included - reachable from the host page. Parent-side listeners now self-detach once the frame leaves the DOM, are all detached eagerly on `dispose()`, and the load-retry path no longer leaks the keyboard-baseline listener either.
- Flutter Web: creating multiple editors in the same frame no longer collides. The iframe view id was derived purely from the wall clock (milliseconds), so editors initialized in the same millisecond shared one platform-view id and one message token: every `HtmlElementView` resolved to the first iframe and the remaining editors never became ready (stuck on the loading spinner). View ids now include a per-instance counter, keeping every editor's iframe and bridge messages isolated.

## [2.2.2] - 2026-07-06

### Fixed
- Flutter Web: disabling editor interaction now returns the keyboard to Flutter, not just the pointer. `setInteractionEnabled(false)` (and the `MonacoFocusGuard` route-overlay path that calls it) previously made the iframe pointer-inert and blurred Monaco's textarea, but the parent document's focus stayed ON the iframe element, so every key event kept dispatching inside the iframe: Escape could not close a dialog shown over the editor, Tab could not traverse it, and a button-only alert stayed keyboard-dead until its first click. The interaction toggle now performs the same two-sided handoff as the desktop platforms: blur inside the iframe, then move the parent document's focus onto the editor's own `<flutter-view>` host (multi-view safe, `tabindex` fallback, no scroll jump), so Flutter overlays receive keys immediately. `MonacoController.releaseNativeInputFocus()` performs the same handoff on web instead of being a no-op.

### Docs
- Documented that `MonacoFocusGuard` bridges route overlays only within its own `Navigator`: with nested navigators (for example `showDialog` with its default `useRootNavigator: true` while the editor lives in a nested navigator), the observer on one navigator never notifies a guard subscribed to a route of another. Apps with nested navigators should observe every navigator that can host overlays and drive `setInteractionEnabled` from that (see the focus guide).

## [2.2.1] - 2026-07-06

### Fixed
- Fixed Flutter Web WASM compatibility metadata by moving native-only Monaco asset extraction behind conditional storage helpers. Web builds no longer import `path_provider` through `MonacoAssets`, while native platforms keep the same asset extraction behavior.

## [2.2.0] - 2026-07-05

### Added
- Added a macOS native focus plugin that performs the real NSWindow first-responder handoff between the Flutter view and the editor's WKWebView. Clicking Monaco now restores typing through the same native mechanism that made right-click "wake the editor up", instead of an in-page focus replay. The package registers as a plugin on macOS; run your app's usual build (CocoaPods integration is automatic) after upgrading.
- Added `MonacoController.hasNativeInputFocus()`, the authoritative desktop input-readiness signal: whether the OS currently routes keyboard input to the editor (macOS first responder, Windows WebView2 native focus). Returns `null` where the platform cannot answer. Use it instead of inferring readiness from `onFocus`/`onBlur`, which only report DOM focus.
- Added `MonacoController.releaseNativeInputFocus()` to hand native keyboard focus back to the Flutter view programmatically (mirrors the handoff Windows already had via `webview_flutter_windows`).

### Fixed
- macOS: user clicks on an already-focused editor no longer run the full in-page focus replay (a blur/refocus cycle that double-blinked the caret). When the native handoff verifies or restores first-responder state, the idempotent in-page focus is enough; the replay now runs only as a fallback when the native plugin is unavailable (for example custom embeddings or tests) or the handoff fails, and at most once per recovery instead of once per retry attempt.

## [2.1.1] - 2026-06-21

### Fixed
- Fixed desktop editor input recovery after Flutter text fields or dialogs leave a stale text-input client active before Monaco is focused.

## [2.1.0] - 2026-06-21

### Added
- Added `MonacoFocusIntent` so apps can distinguish direct user-initiated editor focus recovery from background focus maintenance.

### Fixed
- Fixed macOS WKWebView input readiness recovery when Monaco appears focused but typing and paste are ignored.
- Kept background focus nudges cooperative with focused Flutter text inputs, and preserved the Windows WebView2 no-replay behavior for right-clicks and repeated primary clicks.

## [2.0.0] - 2026-06-20

### Changed
- Raised the minimum supported SDK to Dart 3.12 and Flutter 3.44, and moved Windows support to the maintained `webview_flutter_windows` package.

### Fixed
- Windows editor focus now recovers after native-focus loss, avoids replaying focus on right-click or repeated clicks, and no longer steals the keyboard from focused Flutter text inputs.
- Mobile Safari on Flutter Web: touch scrolling inside the editor no longer pans the host page (#11). The generated editor document and the host iframe statically declare `touch-action: none` and `overscroll-behavior: none`, so touches that Monaco does not claim can no longer chain out of the frame.
- Mobile web soft keyboard (#11): while the keyboard constrains the browser's visual viewport, the editor now pins itself to the visible part of its frame and keeps the caret revealed.
- iOS/macOS worker bootstrap: the WKWebView worker shim now emits escaped newline sequences inside JavaScript string literals, so Monaco language workers load instead of falling back to the main thread.

## [1.7.1] - 2026-06-20

### Fixed
- **Flutter Web: Monaco failed to load under path URL strategy (#14).** With `usePathUrlStrategy()` (or any non-root route such as GoRouter `/canvas/:id`), the bundled `vs/` URL was built from the browser route, so `loader.js` 404'd and the editor surfaced "Failed to load Monaco loader.js". Asset URLs now resolve through Flutter's asset manager against the document `<base href>`, independent of the current route - so Monaco loads correctly under deep routes, a sub-path `<base href>`, and a CDN `assetBase`.

## [1.7.0] - 2026-05-19

### Added
- **Themable chrome.** `MonacoEditorTheme` (`InheritedTheme`) styles the built-in loading, error, and status-bar widgets. Composes through `showDialog` and nested overrides; missing values fall back to the surrounding Material theme.
- **Typed custom themes.** `MonacoThemeDefinition` (freezed) registers custom syntax themes via `defineTheme(...)`, `defineThemeFromJson(id, data)`, or `fromMonacoThemeData(id, data)`. Pair with `EditorOptions.themeId`, `setThemeById`, and `getThemeId()` (read live theme id) to switch and persist user choices.
- **Typed bridge errors.** Command methods throw `MonacoJavaScriptException` on failure instead of returning silent defaults. Reads with documented defaults (`getValue`, `getLineCount`, `getLineContent`) still honor them.
- **Reliable macOS background.** New `setHostPageBackgroundColor` recolors Monaco's HTML host page. Widget `backgroundColor` applies to both native and host-page layers.

### Docs
- README: section on migrating from native Flutter code editors covering settings, theme registration, chrome theming, and background colors.

## [1.6.0] - 2026-05-18

### Added
- `MonacoOverlayBoundary` widget and `MonacoScaffold` convenience wrapper for static Flutter overlays (FABs, drawers, persistent bars, custom `Stack` children) that previously had pointer events swallowed by the editor iframe on Web. `MonacoScaffold` auto-protects the standard Scaffold overlay slots (`floatingActionButton`, `drawer`, `endDrawer`, `bottomSheet`, `bottomNavigationBar`, `persistentFooterButtons`); `MonacoOverlayBoundary` is the underlying primitive for arbitrary overlay subtrees.
- `MonacoController.runWithInteractionDisabled(action)` for transient overlays (snackbars, toasts, imperative `Overlay.insert` entries) that are neither route-based nor static enough for `MonacoOverlayBoundary`.
- Internal `MonacoWebInteractionCoordinator` that ref-counts iframe pointer-events so route overlays (`MonacoFocusGuard`) and static overlays compose without fighting.

### Fixed
- Fixed soft keyboard activation for `MonacoEditor` on native Android and iOS by letting the platform view own the tap-to-input gesture path.
- Fixed Android Flutter Web scroll gestures so scrolling focused Monaco content no longer opens the keyboard on release, while preserving intentional keyboard-open scrolling.
- Fixed a Flutter Web first-load race by waiting for iframe attachment and retrying transient Monaco load failures.
- Fixed the example iOS runner build configuration.

### Changed
- Example app switched to `MonacoScaffold`, wired `MonacoRouteObserver` + `MonacoFocusGuard`, and dropped the `pointer_interceptor` dependency.

### Docs
- Rewrote the README "Web: Handling Overlays" section to cover route overlays (`MonacoFocusGuard`), static overlays (`MonacoScaffold` / `MonacoOverlayBoundary`), and transient overlays (`runWithInteractionDisabled`).

## [1.5.0] - 2026-05-16

### Added
- JSON diagnostics support: `MonacoController.setJsonDiagnostics()` enables schema-based validation with inline errors and warnings for JSON content.
- `JsonDiagnosticsOptions` and `JsonDiagnosticsSchema` models for configuring validation rules, severity levels, and schema associations.
- `DiagnosticsSeverity` enum (`error`, `warning`, `ignore`) for controlling diagnostic severity across JSON language features.
- Added `MonacoController.runJavaScript(String script)` as an advanced fire-and-forget JavaScript escape hatch. It waits for the editor to be ready before executing.
- Added `MonacoController.evaluateJavaScript<T>(String expression, {T? defaultValue})` for typed JavaScript evaluation with cross-platform result normalization.
- Added `MonacoController.runJavaScriptReturningResultRaw(String script)` for advanced callers who need the platform-native return value.

### Fixed
- `JsonDiagnosticsSchema.fromJson` now throws when both `uri` and `schemaUri` keys are missing instead of silently falling back to a bogus URI.

### Security
- Documented that JavaScript escape-hatch methods do not sanitize input and that callers should use `jsonEncode` when embedding dynamic values.

## [1.4.0] - 2026-01-25

### Added
- Added `interactionEnabled` to `MonacoEditor` and `MonacoController.setInteractionEnabled`. This allows Flutter Web overlays (dialogs, dropdowns) to receive pointer events when they overlap the Monaco editor.
- Added `autoDisableInteraction` to `MonacoFocusGuard` to automatically toggle editor interaction based on route changes.
- Web: Focus enforcement is now gated by the interaction flag to prevent focus stealing when overlays are active.

### Fixed
- `createModel` now returns a valid URI or throws when Monaco returns invalid data.
- `lineHeight` now behaves as a multiplier in Dart and is converted to pixels for Monaco.
- Completion suggestions now fall back to the default range when item ranges are omitted.
- Font ligatures respect `EditorOptions.fontLigatures`.
- Windows message logging is gated for debug builds to avoid release noise.

## [1.3.0] - 2026-01-24

- Added Web platform support.

## [1.2.1] - 2026-01-08
### Fixed
- Publish workflow now uses GitHub OIDC via the official Dart publish workflow.

## [1.2.0] - 2026-01-08
### Added
- `MonacoAction` registry with comprehensive Monaco 0.54.0 action IDs for type-safe `executeAction` calls.
- Test utilities for platform WebView and controller bootstrapping (`PlatformWebViewController`, `MonacoController.createForTesting`).

### Changed
- Unknown language/theme IDs now default to `markdown` and `vsDark` respectively.
- Controller bootstrapping and WebView initialization now use a unified platform adapter with safer lifecycle handling.

### Fixed
- `executeAction` now tries `editor.getAction(id).run()` first, then falls back to `trigger` for broader action support.
- Asset extraction now reports incomplete copies and resets initialization state after failures.

## [1.1.1] - 2025-11-16
### Changed
- Bundled Monaco Editor updated to **v0.54.0** (latest stable drop from Microsoft). Existing apps automatically pick up the new assets on next launch.

## [1.1.0] - 2025-11-16
### Added
- Full IntelliSense bridge: JavaScript hooks + `MonacoController.registerCompletionSource` / `registerStaticCompletions`.
- Strongly typed completion models (`CompletionItem`, `CompletionList`, `CompletionRequest`, `CompletionItemKind`, `InsertTextRule`).
- README + example updates showing how to source completions from snippets or remote services.

### Fixed
- Export ordering and analyzer fixes to keep the public API clean.

## [1.0.0] - 2025-09-15
- Reliable typing after route/app switches on macOS/Windows - no right‑click needed.
- Optional `MonacoFocusGuard` to auto‑restore focus on resume/route return.
- New guide: doc/focus-and-platform-views.md with best practices and snippets.
- Sensible defaults: word wrap ON, minimap OFF, consistent across APIs.

## [0.1.0] - 2025-08-16

### Initial Release 🎉

#### Features
- **Full Monaco Editor Integration** - Complete VS Code editor experience in Flutter
- **100+ Language Support** - Syntax highlighting for all major programming languages
- **Multiple Themes** - VS Light, VS Dark, High Contrast Black, High Contrast Light
- **Cross-Platform Support** - Works on Android, iOS, macOS, and Windows
- **Type-Safe API** - Comprehensive typed bindings with enums for all configurations
- **Multi-Editor Support** - Run multiple independent editor instances
- **Live Statistics** - Real-time line/character counts and selection information
- **Find & Replace** - Full programmatic find/replace with regex support
- **Decorations & Markers** - Add highlights, errors, warnings to code
- **Event Streams** - Listen to content changes, selection, focus events
- **Versioned Asset Caching** - Efficient one-time asset installation (~30MB)
- **Custom Fonts** - Support for Fira Code, JetBrains Mono, Cascadia Code, and more
- **Editor Actions** - Format, undo, redo, cut, copy, paste, select all
- **Clipboard Operations** - Full clipboard support across platforms
- **Navigation** - Scroll to top/bottom, reveal line, focus management
- **Content Management** - Get/set value, language switching, theme switching
- **Advanced Options** - Word wrap, minimap, line numbers, rulers, bracket colorization

#### Platform Requirements
- **Android**: 5.0+ (API level 21)
- **iOS**: 11.0+
- **macOS**: 10.13+
- **Windows**: 10 version 1809+ with WebView2 Runtime

#### Known Limitations
- Web platform not supported (asset bundling limitations)
- Linux platform not supported (WebKitGTK integration pending)
- Initial startup requires ~1-2 seconds for asset extraction (one-time)
- Each editor instance consumes ~30-100MB memory depending on content

#### Dependencies
- `webview_flutter`: - For mobile and macOS WebView
- `webview_windows`: - For Windows WebView2
- `path_provider`: - For asset caching
- `dart_helper_utils`: - For utility extensions
- `freezed`: - For immutable models

[0.1.0]: https://github.com/omar-hanafy/flutter_monaco/releases/tag/v0.1.0
