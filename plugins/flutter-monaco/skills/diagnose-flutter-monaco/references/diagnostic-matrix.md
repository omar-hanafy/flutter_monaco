# Diagnostic matrix

## Boot and assets

| Symptom | Evidence | Likely boundary |
| --- | --- | --- |
| Blank editor before handshake | WebView console, generated page load, `MonacoAssets.assetInfo()` | asset resolution or page script failure |
| Web readiness error says iframe detached | build lifecycle and painted platform view | controller mounted only after readiness or hidden with `Offstage` |
| Native extraction repeatedly runs or fails | diagnostics path/version/file count, filesystem error | cache/sentinel/permissions |
| Protocol version mismatch | `MonacoProtocolError`, handshake versions | stale page/bridge assets or inconsistent package code |
| macOS boot times out after an empty WebView error | `macos/Runner/*.entitlements` | sandboxed app without `com.apple.security.network.client` |
| Diff shows no changes; JSON, CSS, HTML, or TypeScript validation and completion are missing | platform, page origin, console errors about workers | Monaco background workers could not start |

Do not delete caches until diagnostics prove corruption. Cache clearing can hide a lifecycle or versioning bug.

## Commands and documents

| Symptom | Inspect |
| --- | --- |
| Typed JavaScript error | exception `operation`, JS name/stack, matching bridge handler |
| Timeout during/after page reload | `onPageReloaded`, command timing, retry ownership |
| Wrong file changes | active document versus retained pinned handle and stable URI |
| LSP sees no file | stable file URI, language id, connection selector/workspace |

Reads intentionally throw on bridge failures. Do not restore silent defaults.

## Focus layers

1. Flutter focus: route and widget focus tree.
2. Native input focus: platform WebView owns keyboard events.
3. Monaco DOM focus: `onFocusChanged` and editor cursor state.

Use `hasNativeInputFocus()` for layer 2 and `onFocusChanged` for layer 3. `requestFocus(intent: MonacoFocusIntent.user)` coordinates the layers. `releaseNativeFocus()` hands input back to Flutter.

Test focus by typing after route return/app resume, not only by checking a boolean. Preserve recovery hooks in `MonacoFocusGuard`; avoid redundant pointer-triggered retries.

## Web overlays

| Overlay kind | Correct mechanism |
| --- | --- |
| `ModalRoute` such as dialog/menu | `MonacoRouteObserver` and `MonacoFocusGuard` |
| Persistent in-tree widget | `MonacoOverlayBoundary` or `MonacoScaffold` |
| Time-bounded imperative overlay | `runWithInteractionDisabled` |

If nested navigators are involved, verify which navigator owns the route. A root dialog is invisible to an observer attached only to a nested navigator.

## LSP

Distinguish transport open from LSP initialize success. Inspect CSP, server stderr, JSON-RPC framing, stable URIs, language selector, and state transitions. Never log credentials.

From 4.0, a server that exits or drops during the handshake fails `connectLanguageServer` at once with the cause (for `LspServerProcess`, a `ProcessException` carrying the exit code and the last stderr lines) instead of the initialization timeout. A page reload ends every connection as `failed` with `MonacoPageReloadedError`. Since Monaco 0.56 (package 4.0), server markdown is untrusted: `command:` links render as plain text and inline HTML styling is stripped, which is expected behavior rather than a rendering bug.

## Scroll handoff

Capture the start position, edge, direction, phase, gesture id, and policy. Under `newGestureOnly`, momentum from the gesture that reached the edge is contained; a new outward gesture hands off. Under `continuous`, unconsumed deltas may chain immediately. Test trackpad momentum separately from wheel steps and touch.

## Page reload recovery

The controller can replay its boot payload and live action/completion registrations. The app still owns additional documents, markers, decorations, view state, theme/config changes applied after boot, and language-server reconnection. Listen to `onPageReloaded` and restore only those app-owned layers.
