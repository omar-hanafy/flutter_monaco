---
name: upgrade-bundled-monaco
description: Upgrade the Monaco Editor engine and bundled assets inside the flutter_monaco package while preserving bridge, LSP, worker, cache, warmup, and archive invariants. Use when changing MonacoAssets.monacoVersion or replacing assets/monaco/min. Do not use for upgrading the Dart package dependency in a consuming app.
---

# Upgrade Bundled Monaco

An engine upgrade changes a large generated asset tree and can break private Monaco/LSP internals without a Dart compile error. Use the upstream release as source, inspect licenses and archive contents, and keep the upgrade isolated from unrelated API work.

Read [references/engine-upgrade-checklist.md](references/engine-upgrade-checklist.md) completely before replacing assets.

## Operating contract

- **Audience:** `flutter_monaco` maintainers upgrading the Monaco Editor engine bundled in the package archive.
- **Expected inputs:** Exact current and target Monaco versions, official release notes/artifact provenance, current asset and archive inventories, supported runtime platforms, and available LSP/runtime smoke infrastructure.
- **Realistic scenario:** Replace bundled Monaco 0.57.0 with an exact newer npm release while preserving workers, dynamic chunks, cache invalidation, bridge commands, LSP behavior, licenses, and package size discipline.

## Workflow

1. Record the current `MonacoAssets.monacoVersion`, asset file count/size, current tests, and public package archive size.
2. Read official Monaco Editor release notes and identify API, loader, worker, language bundle, CSP, and LSP-internal changes between exact versions.
3. Obtain the official release artifact through a reproducible command and verify its version. Do not copy an unknown local `node_modules` tree.
4. Replace only the intended `assets/monaco/min/` distribution and preserve package bridge assets under `assets/monaco/bridge/`.
5. Update the single Dart version constant and every deliberate test fixture/assertion that pins it.
6. Rebuild or verify the Web warmup manifest and dynamic chunk discovery.
7. Run source invariants, protocol/asset tests, real JavaScript bridge tests, analyzer, full Flutter tests, docs, dry-run publication, and representative runtime smoke tests.
8. Inspect the final archive for missing workers/languages, accidental source maps, duplicate trees, or unexplained size growth.

## Safety, decisions, and failure handling

- If the exact target version or official artifact provenance is missing and cannot be discovered from the task or repository, stop before downloading or replacing assets. Never substitute an arbitrary latest release.
- If upstream packaging/layout changed, stop and inspect the loader and worker resolution before deleting or renaming files.
- If Monaco LSP client internals changed, prove initialize, diagnostics, and one request-driven feature with a real server before release.
- If browser or native platform smoke is unavailable, name that platform as unverified.
- Do not bump the Dart-JS protocol version merely because the Monaco engine version changed.
- If any asset, bridge, worker, LSP, or archive check fails, stop publication and preserve the earliest failure evidence. Do not patch generated minified files or delete the prior asset tree outside the project's reviewed version-control workflow.

## Verification and report

Do not call the upgrade complete until source/asset invariants, the full Flutter suite, Node bridge tests, docs, Pana, publish dry-run, archive inspection, and every available runtime smoke pass. Include old/new engine versions, artifact source, license result, file count/size delta, dynamic chunks/workers found, LSP internal assumptions reviewed, Dart/Node/runtime tests, archive delta, and any untested platform.
