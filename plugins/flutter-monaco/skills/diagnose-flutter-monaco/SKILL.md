---
name: diagnose-flutter-monaco
description: Diagnose unknown or cross-layer failures where flutter_monaco is on the failing path, including boot, assets, Web mounting, protocol, Monaco focus, overlays, page reload, LSP, or scroll handoff. Use when the package's failing layer is not yet established or a MonacoException crosses boundaries. Route an already-localized LSP transport, CSP, URI, or lifecycle problem to configure-flutter-monaco-lsp. Do not use for routine integration or a standard Flutter TextField or form issue that does not render or import flutter_monaco.
---

# Diagnose Flutter Monaco

Find the failing layer before proposing a fix. Read the exact package version, platform, exception type/message/operation, lifecycle order, and relevant app code. Treat logs and external reviews as hypotheses.

Read [references/diagnostic-matrix.md](references/diagnostic-matrix.md) and select the narrowest matching path.

## Operating contract

- **Audience:** Consuming-app engineers and package maintainers investigating a failure whose owning layer is not yet proven.
- **Expected inputs:** The resolved package and Flutter versions, target platform, smallest reproduction, first typed error and stack, lifecycle sequence, relevant integration source, and available platform/browser logs.
- **Realistic scenario:** A self-created controller works on Windows but a Web editor remains blank because app code awaits `whenReady` before mounting its iframe.

## Method

1. Reproduce the smallest failure and record package version, Flutter version, platform, first failure, and whether it survives a route/app lifecycle event.
2. Classify the boundary: assets/page creation, platform view mount, protocol handshake/command, document model, focus, overlay hit testing, LSP, reload recovery, or scroll ownership.
3. Inspect the actual source and tests for that boundary. Do not bypass typed APIs with JavaScript before proving the public API is insufficient.
4. Add one observation that separates competing causes. Examples include `MonacoAssets.assetInfo()`, `controller.capabilities`, `hasNativeInputFocus`, browser CSP output, connection state, or a focused fake-protocol test.
5. If the request authorizes a fix, implement the smallest root-cause correction and add a regression test at the ownership boundary. For a diagnosis-only request, stop after the evidence-backed cause and recommended correction.
6. When code changed, re-run the exact reproduction plus analyzer and relevant tests.

## Safety and failure handling

- A self-created controller on Web must be mounted and painted before `whenReady` can finish. A timeout after conditional mounting is a lifecycle defect, not a slow command.
- `onFocusChanged == true` means Monaco's DOM has focus. It does not prove the native WebView has keyboard input focus.
- Request focus when entering or recovering the editor. Do not replay focus on every click or selection event; that can steal focus and create loops.
- A visible Flutter overlay above a Web iframe is not necessarily clickable. Classify it as route, static, or transient and use the matching package primitive.
- Preserve the first typed `MonacoException`. Do not turn an asset, reload, or protocol error into an empty document/default value.
- On page reload, the controller restores the boot editor and registered completions/actions, but the app must restore extra documents, post-boot configuration, and LSP connections.
- Verify against the installed version. The 2.x focus and content APIs are not valid names in 3.x or 4.x.
- If credentials, a device, a server binary, or the failing route are unavailable, stop at the last proven boundary and name the missing input. Do not manufacture a root cause from a neighboring symptom.
- If a proposed fix moves ownership to another layer or changes user-visible behavior, present that decision before implementing it.

## Verification

- Re-run the smallest reproduction and one adjacent non-failing path.
- Run scoped analysis and the tests for the owning boundary; add a regression test when a fix is authorized.
- Exercise the relevant lifecycle or platform transition instead of treating compilation as runtime proof.

## Output

Report evidence in this order: symptom, failing layer, proof, root cause, fix, regression coverage, and remaining platform uncertainty.
