---
name: configure-flutter-monaco-lsp
description: Configure or troubleshoot Language Server Protocol support in a flutter_monaco 3.x or 4.x application using WebSocket, desktop stdio bridge, or custom transport. Use for connectLanguageServer, transport selection, CSP, stable document URIs, reconnect policy, and LSP lifecycle. Do not use for general editor integration or unrelated completion providers.
---

# Configure Flutter Monaco LSP

Match the transport to where the real language server runs. Inspect the app's platforms, server process or proxy, authentication requirements, sandboxing, and current `MonacoPageConfig` before editing.

Read [references/transport-guide.md](references/transport-guide.md) before implementation.

## Operating contract

- **Audience:** Engineers adding or repairing LSP in a consuming Flutter app that already uses `flutter_monaco` 3.x or 4.x.
- **Expected inputs:** The resolved package version, target platforms, server command or URL, protocol/framing, authentication model, workspace and document URI policy, and the owning app lifecycle.
- **Realistic scenario:** A desktop build should spawn Pyright over stdio while the Web build reaches a WebSocket proxy, with both paths restoring stable documents after an editor-page reload.

## Workflow

1. Identify the server executable/protocol and target platforms. Most language servers speak stdio, not WebSocket.
2. Select one transport:
   - `LspWebSocketTransport` for a WebSocket server or proxy on any platform.
   - `LspServerProcess`/`LspBridgedTransport` for a local stdio process on macOS or Windows.
   - `LspCustomTransport` only when the app owns a compatible JavaScript transport factory.
3. Give every opened file a stable `file:///` URI. Confirm language ids and workspace paths match what the server expects.
4. Configure CSP for WebSocket connections through `MonacoPageConfig.allowedConnectSources`. Do not add broad sources such as `*` when one origin is sufficient.
5. Connect only after the editor can mount. Keep the returned `LanguageServerConnection`, observe its state, and define disconnect/reconnect behavior.
6. Define page-reload recovery. Listen to `controller.onPageReloaded`, recreate app-owned documents from durable state, and reconnect; the controller cannot infer either layer. From 4.0 the reload already ends every connection as `failed` with `MonacoPageReloadedError`, frees its id, and runs a bridged transport's `onClose`, so start a fresh `LspServerProcess`. On 3.x, disconnect the stale registered connection first, because duplicate live ids are rejected.
7. Test an actual language feature and failure path. A successful socket alone does not prove initialization or document synchronization.

## Safety and decision points

- `connectLanguageServer` resolves only after the LSP `initialize` handshake succeeds.
- Browser WebSockets cannot send custom headers. Use an appropriate authenticated proxy or a carefully handled short-lived query credential; do not hard-code secrets.
- A sandboxed macOS app usually cannot spawn an arbitrary external binary. Confirm the distribution and entitlements model before disabling sandboxing.
- Automatic reconnect applies to WebSocket/custom transports, not a terminated local process. Respawn bridged processes in app code.
- Multiple servers share Monaco's `lsp` marker owner. Prefer one server per editor unless their diagnostics are disjoint.
- Disconnecting or disposing the controller must stop owned transports/processes.
- From 4.0, when `connectLanguageServer` throws, a bridged transport's `onClose` has already completed. `LspServerProcess.stop` is idempotent, so a defensive second stop is safe.
- Server markdown is untrusted from 4.0 (Monaco 0.56): hovers, completion documentation, and signature help render `command:` links as plain text and strip inline HTML styling; `http`, `https`, `mailto`, and `file` links still work.
- Automatic transport reconnect does not restore a connection discarded by a full editor-page reload. Recreate the connection after documents are restored.
- Raw `sendRequest`, `sendNotification`, and Monaco LSP internals are experimental and must be rechecked on engine upgrades.

## Failure handling and stop conditions

- If the server endpoint or executable, target platforms, transport ownership, URI/workspace model, or authentication constraints cannot be discovered, stop before editing and request the missing contract.
- If the server or required platform cannot be exercised, report the validated configuration boundary and do not claim reliable language features.
- Preserve the first connection/initialize error and sanitized server diagnostics. Do not switch transports, weaken CSP, disable sandboxing, or expose credentials merely to make the connection open.

## Verification

- Observe `connecting`, `open`, and terminal `closed` or `failed` states.
- Open a file with a stable URI and prove at least diagnostics plus one request-driven feature such as hover, completion, or rename.
- Test unreachable endpoint/process exit and verify the UI gets an actionable state.
- On Web, inspect the browser console for CSP failures.
- Run analyzer and the app's relevant tests without requiring a live server in the normal unit suite.

Report the chosen transport, server ownership, auth/CSP decisions, lifecycle, and which real feature was exercised.
