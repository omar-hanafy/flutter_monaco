# AI coding-assistant support

Flutter Monaco publishes package-specific guidance for Claude Code and OpenAI Codex
from the repository's `plugins/flutter-monaco/` directory. The extension helps an
assistant use the real 3.x and 4.x API, diagnose layered WebView failures, migrate 2.x code,
and keep the Dart-to-JavaScript bridge synchronized.

The extension is installed from GitHub, not by `dart pub add`. It is deliberately
excluded from the pub.dev archive and does not affect application size or runtime
behavior.

## What the extension includes

Six shared skills cover the package's high-risk workflows:

- `integrate-flutter-monaco`
- `configure-flutter-monaco-lsp`
- `diagnose-flutter-monaco`
- `migrate-flutter-monaco-v2-to-v3`
- `maintain-flutter-monaco-bridge`
- `upgrade-bundled-monaco`

Claude Code also receives a narrowly scoped, read-only
`bridge-contract-reviewer` agent. Codex plugins cannot bundle custom agents, so the
source repository contains an equivalent project agent at
`.codex/agents/bridge-contract-reviewer.toml`. That Codex agent is available only
when working in this checkout. The bridge-maintenance skill remains the canonical
procedure for both reviewers.

## Install for Claude Code

```bash
claude plugin marketplace add omar-hanafy/flutter_monaco --sparse .claude-plugin plugins
claude plugin install flutter-monaco@flutter-monaco-plugins --scope user
```

Run `/reload-plugins` in an active Claude Code session or start a new session.
Skills normally activate from context. To select one explicitly, enter its
namespaced slash command, for example:

```text
/flutter-monaco:integrate-flutter-monaco
/flutter-monaco:diagnose-flutter-monaco
/flutter-monaco:maintain-flutter-monaco-bridge
```

All six commands are listed in the
[`plugins/flutter-monaco` README on GitHub](https://github.com/omar-hanafy/flutter_monaco/blob/main/plugins/flutter-monaco/README.md).

Update:

```bash
claude plugin marketplace update flutter-monaco-plugins
claude plugin update flutter-monaco@flutter-monaco-plugins
```

Run `/reload-plugins` or start a new session to use the updated plugin.

Remove:

```bash
claude plugin uninstall flutter-monaco@flutter-monaco-plugins --scope user
claude plugin marketplace remove flutter-monaco-plugins
```

The commands above target Claude Code CLI and its user-scoped plugin state. The
Claude Code VS Code extension and Desktop Code local or SSH sessions are documented
plugin surfaces, but this release smoke-tested the CLI only. Local user plugin state
does not transfer automatically to Claude Code on the web.

## Install for OpenAI Codex CLI

```bash
codex plugin marketplace add omar-hanafy/flutter_monaco --sparse .agents --sparse plugins
codex plugin add flutter-monaco@flutter-monaco
```

Start a new Codex session so it loads the installed skills. In Codex CLI, enter
`/plugins` to browse the configured marketplace, inspect the plugin, and install or
enable it interactively. To select a skill explicitly, mention it with `$`, for
example:

```text
$integrate-flutter-monaco
$diagnose-flutter-monaco
$maintain-flutter-monaco-bridge
```

Update:

```bash
codex plugin marketplace upgrade flutter-monaco
codex plugin add flutter-monaco@flutter-monaco
```

Start a new Codex session after refreshing and reinstalling the plugin.

Remove:

```bash
codex plugin remove flutter-monaco@flutter-monaco
codex plugin marketplace remove flutter-monaco
```

### ChatGPT desktop and web

The ChatGPT desktop app can read `.agents/plugins/marketplace.json` from the
repository root. Clone this repository, open that checkout in the desktop app,
restart the app, select Work mode or Codex, open
Plugins, choose **Flutter Monaco Plugins**, and install **Flutter Monaco**. Start a
new chat after installation. This repo-local flow requires the checkout because the
marketplace source is relative to the repository root.

To update the desktop copy, update the checkout and restart the app before opening
Plugins again. Remove or disable it from the Installed row in the Plugins directory.

ChatGPT web Work mode installs curated or workspace-shared plugins through its
Plugins directory. The GitHub and CLI commands above do not register this
repository there, and this release is not claimed as an OpenAI public-directory
submission.

## Supported clients and versions

| Client | Support in this release |
|---|---|
| Claude Code CLI 2.1.215 (validated) | GitHub marketplace plugin, six skills, and the bundled read-only reviewer |
| Claude Code VS Code extension and Desktop Code local or SSH sessions | Documented plugin surfaces; graphical installation was not smoke-tested for this release |
| Claude Code on the web | Local user plugin installations do not transfer automatically; this repository does not auto-enable the plugin there |
| Codex CLI 0.144.6 (validated) | GitHub marketplace plugin and six skills; this checkout also exposes the project reviewer |
| ChatGPT desktop Work mode and Codex | Documented repo-marketplace browser support when this checkout is open; graphical installation was not smoke-tested for this release |
| ChatGPT web Work mode | Curated and workspace-shared plugin browser only; this repository release has not been submitted to the public directory |
| Chat mode, Codex IDE integrations, and mobile | Plugins are not available on these surfaces |

The package skills target Flutter Monaco 3.x and 4.x after inspecting the app's
resolved dependency. The migration skill covers the breaking 2.x to 3.x transition,
which applies unchanged to a 4.x target. The 3.x to 4.0 upgrade keeps every editor
API (it raises the toolchain floor and moves Material to `material_ui`), so it has
no dedicated migration skill; the package README's "Migrating from 3.x to 4.0"
section covers it.

Start a new assistant session after install or update. Existing sessions can keep a
cached plugin snapshot.

## Security and privacy

The plugin contains instructions, references, eval fixtures, and read-only reviewer
definitions. It contains no hooks, MCP server, app, connector, executable, runtime
service, authentication flow, or credential configuration. Installing it does not
contact a Flutter Monaco service. As with any coding assistant, the host can read or
change only what its own user-approved tools and sandbox permit.

The plugin is installed from the GitHub repository, not from pub.dev. Dart package
publishing excludes hidden manifest directories, so `.pubignore` excludes the whole
`plugins/` tree rather than publishing visible skills without their hidden Claude
and Codex manifests. `dart pub add flutter_monaco` installs only the Flutter package.

## Validation and eval scope

Maintainers validate both product manifests and the shared extension contract from
the repository root:

```bash
claude plugin validate ./plugins/flutter-monaco --strict
claude plugin validate . --strict
dart run tool/validate_ai_extensions.dart
```

The eval fixture set covers four case classes per skill: positive selection,
realistic execution, adjacent negative triggering, and required information that is
missing. The repository validator checks that coverage and fixture structure. It
cannot prove that every future model will select or execute a skill correctly, so
release work also uses fresh-session forward tests.

The installed Claude Code CLI currently labels `claude plugin eval` as early access
and does not expose it as a stable release gate. This project does not claim a native
Claude eval pass until that command is available and actually runs.

Authenticated behavior checks are opt-in and never run in CI. Claude requires a
separate config directory containing a local marketplace installation of this plugin.
The runner fails closed unless the plugin is enabled at version `4.0.0`, its cache is a
byte-for-byte copy of this checkout, and its marketplace points to this checkout. It
then loads only that isolated user configuration, the verified plugin, a fixed empty
MCP set, nonpersistent sessions, disabled auto-memory, and disposable fixtures.
Execution sessions preapprove only the focused format, analysis, test, and archive
commands listed by the runner; other shell commands remain subject to Claude Code's
noninteractive permission denial. The default `sonnet` model, per-case USD cap, and
600-second per-case timeout can be overridden, so review expected model cost and
duration before running all 24 cases:

```bash
eval_claude_config="$(mktemp -d)"
trap 'rm -rf "$eval_claude_config"' EXIT
CLAUDE_CONFIG_DIR="$eval_claude_config" claude auth login
CLAUDE_CONFIG_DIR="$eval_claude_config" claude plugin marketplace add "$PWD"
CLAUDE_CONFIG_DIR="$eval_claude_config" claude plugin install \
  flutter-monaco@flutter-monaco-plugins --scope user
dart run tool/ai_extension_behavior_runner.dart \
  --client claude \
  --claude-config-dir "$eval_claude_config" \
  --all \
  --case-timeout-seconds 600 \
  --output /tmp/flutter-monaco-claude-evals.json
```

Codex requires a separate authenticated home so the runner cannot use or modify a
maintainer's normal plugins. The runner fails closed unless the installed local
plugin is enabled, is version `4.0.0`, and is a byte-for-byte copy of this checkout:

```bash
eval_codex_home="$(mktemp -d)"
trap 'rm -rf "$eval_codex_home"' EXIT
CODEX_HOME="$eval_codex_home" codex login
CODEX_HOME="$eval_codex_home" codex plugin marketplace add "$PWD"
CODEX_HOME="$eval_codex_home" codex plugin add flutter-monaco@flutter-monaco
dart run tool/ai_extension_behavior_runner.dart \
  --client codex \
  --codex-home "$eval_codex_home" \
  --all \
  --case-timeout-seconds 600 \
  --output /tmp/flutter-monaco-codex-evals.json
```

Natural positive prompts do not name a skill. Execution prompts use each client's
explicit invocation and may edit only their temporary fixture. Negative and
missing-input cases are read-only. Review every report's raw response, selected
skills, fixture status, tracked diff, and bounded untracked text artifacts against its
`expectations`; binary and oversized artifacts are reported without dumping unsafe or
unbounded content. A client exit code alone does not establish semantic success.

## Adding capabilities and migrations

Keep shared skill content under `plugins/flutter-monaco/skills/`. For every new or
changed skill, add positive-selection, realistic-execution, adjacent-negative, and
missing-input cases to the canonical 24-case-style matrix and rerun static plus
authenticated validation. A future nontrivial breaking release gets a dedicated
versioned `migrate-flutter-monaco-vX-to-vY` skill with representative normal, edge,
already-migrated, unsupported-version, and recovery fixtures. Do not fold distinct
major-version transitions into the existing 2.x-to-3.x procedure.

## Specification references

The release metadata and commands follow the current primary documentation:

- [Claude Code plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [Claude Code plugins](https://code.claude.com/docs/en/plugins) and [plugin reference](https://code.claude.com/docs/en/plugins-reference)
- [OpenAI Codex plugin building](https://learn.chatgpt.com/docs/build-plugins) and [plugin installation](https://learn.chatgpt.com/docs/plugins)
- [OpenAI skill building](https://learn.chatgpt.com/docs/build-skills) and [Codex custom agents](https://learn.chatgpt.com/docs/agent-configuration/subagents)
- [Dart package publishing and archive rules](https://dart.dev/tools/pub/publishing)

## Troubleshooting assistant installation

- If a Claude skill is missing, verify the marketplace and plugin, run
  `/reload-plugins`, or start a new session.
- If a Codex skill is missing, verify it with `codex plugin list` or `/plugins`, then
  start a new session.
- If guidance is stale, update the marketplace and reinstall or update the plugin,
  then start a new session.
- If two marketplaces use the same name, remove the stale registration before adding
  this repository again.
- If a suggestion conflicts with the installed Dart package, inspect the resolved
  package source. The live API is authoritative.
