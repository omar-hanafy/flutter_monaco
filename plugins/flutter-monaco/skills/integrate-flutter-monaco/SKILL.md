---
name: integrate-flutter-monaco
description: Integrate flutter_monaco 3.x or 4.x into a Flutter application, including editor lifecycle, documents, platform setup, focus, overlays, and disposal. Use when adding MonacoEditor or MonacoController, designing an editor screen, or reviewing a new flutter_monaco integration. Do not use for a 2.x migration, LSP-only work, package bridge maintenance, or a bundled Monaco engine upgrade.
---

# Integrate Flutter Monaco

Build the integration against the installed package version and its public API. Read `pubspec.yaml`, `pubspec.lock`, the consuming screen, and the current `flutter_monaco` README before changing code. Never invent a bridge method or copy a 2.x example into a 3.x or 4.x app.

Read [references/integration-patterns.md](references/integration-patterns.md) before implementation.

## Operating contract

- **Audience:** Engineers integrating `flutter_monaco` 3.x or 4.x into a consuming Flutter application.
- **Expected inputs:** The resolved dependency, target platforms and SDK floors, owning screen/state pattern, content and save source of truth, required editor features, and relevant tests.
- **Realistic scenario:** Add a three-tab editor with stable file URIs, app-owned persistence, clickable Web overlays, and keyboard recovery after route return.

## Workflow

1. Confirm the dependency version and target platforms. Flutter Monaco 4.x requires Flutter 3.47.7 and Dart 3.13.5 and supports Android 7/API 24+, iOS 15+, macOS 12+, Windows with the WebView2 Runtime, and Web; 3.x supported iOS 13+ and macOS 10.15+. Linux is unsupported. A sandboxed macOS app needs the `com.apple.security.network.client` entitlement.
2. Choose ownership deliberately:
   - Prefer `MonacoEditor` for a screen that wants widget-owned creation, loading, errors, and disposal.
   - Create a `MonacoController` when the app must prepare, share, or coordinate the controller outside the widget.
   - When an external controller is rendered by `MonacoEditor(controller: ...)`, the widget still applies its current `options`, resolved theme/language, initial text, background, interaction, and scroll configuration after readiness. Keep those values consistent with the controller's boot configuration or designate the widget as the intentional live configuration owner. Supply page policy to `MonacoController.create`; the widget's `page` is ignored for an external controller.
3. Define content ownership. Use `initialText` only for boot content. After readiness, content belongs to `controller.document`; multi-file apps should open documents with stable `file:///` URIs.
4. Wire lifecycle in the correct order. `MonacoController.create` returns before the editor is ready. On Web, mount and paint `controller.webViewWidget` before awaiting `whenReady`.
5. Add only the platform behavior the screen needs: focus recovery, route/static overlay protection, scroll handoff, diff editing, or asset precaching.
6. Dispose what the app owns. Never dispose an externally owned controller from a child widget.
7. Validate the smallest supported platform set that proves the design, then run analyzer and tests.

## Decision points and safety invariants

- Use `controller.document.setText`, `getText`, and `setLanguage`; content operations are not controller methods since 3.0.
- On 4.x, Material comes from `package:material_ui`. The editor chrome reads its `Theme`, and `MonacoScaffold` and `MonacoEditorThemeData` take its types. Migrate an app that still imports `package:flutter/material.dart` with `dart fix --apply --code=migrate_design_widgets` rather than mixing the two libraries.
- Await `controller.whenReady` before treating a self-created controller as live.
- Keep the Web platform view painted under loading UI. `Offstage`, `Visibility(visible: false)`, or inserting the widget only after readiness prevents boot.
- Use sparse `EditorOptions` updates. Do not reconstruct all defaults to change one option.
- Give files stable, unique URIs. Reusing or changing URIs casually breaks model identity, undo state, diagnostics, and LSP features.
- Use `requestFocus`, `releaseNativeFocus`, and `onFocusChanged`. DOM focus and native keyboard readiness are different signals.
- Use `MonacoRouteObserver` plus `MonacoFocusGuard` for route overlays, `MonacoOverlayBoundary` or `MonacoScaffold` for static overlays, and `runWithInteractionDisabled` for transient imperative overlays.
- Prefer the typed API. Use `runJavaScript` only when the public surface cannot express the requirement, and document its CSP and version assumptions.
- Treat app storage as durable truth. Call `markSaved` only after persistence succeeds, and keep old data recoverable while changing a stored format.

## Failure handling and stop conditions

- If the consumer source, resolved flutter_monaco version, or target platforms are unavailable, stop before implementation and request that evidence.
- If controller ownership, document ownership, or required editor behavior cannot be inferred without changing the app's architecture, ask for that decision rather than choosing silently.
- Preserve the first `MonacoException` and any storage error separately. Do not replace failed reads with empty content or mark a failed write as saved.

## Verification

- Run `dart analyze` with scope appropriate to the app.
- Exercise creation, first paint, text edits, route exit/re-entry, and disposal.
- On Web, verify cold-cache boot and clickable overlays.
- On desktop/mobile targets in scope, verify keyboard input rather than checking only `onFocusChanged`.
- If the screen opens multiple files, verify stable URIs, switching, background edits, undo state, and dirty tracking.

Report the ownership model, lifecycle order, platforms tested, and any untested platform-specific behavior.
