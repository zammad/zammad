# fallow Setup

## Overview

[fallow](https://fallow.tools) analyzes the module graph of `app/frontend`: unused files, exports and store members,
unused dependencies, import cycles, code duplication and complexity. It covers the Vue/TypeScript stack only.

Zammad pins fallow as a development dependency and commits its configuration in `.fallowrc.json`, so the shell
commands work in every checkout after `pnpm install` without further setup:

```sh
pnpm analyse:fallow          # Full report: dead code, duplication, complexity.
pnpm analyse:fallow:audit    # Only the findings the branch introduces compared to origin/develop or $FALLOW_AUDIT_BASE.
pnpm analyse:fallow:dupes    # Cross-directory clone groups.
pnpm analyse:fallow:health   # Complexity hotspots and ranked refactoring targets.
pnpm exec fallow dead-code --trace <file>:<export>   # Why fallow considers an export unused.
```

The health report is advisory: its score and hotspots rank files by complexity, fan-in, churn and cycles, and
the audit only warns about the cyclomatic and cognitive complexity a merge request introduces. The CRAP metric is switched
off in `.fallowrc.json` because fallow estimates coverage without data; enable it together with `health.coverage`
once a Vitest coverage report is fed in. Findings for `<template>` blocks mean "split the component", not "extract
a function".

The merge request pipeline runs the same audit as the advisory job `lint: fallow audit`. The analysis cache in
`.fallow/` is gitignored.

## Agent Hooks

Coding agents do not decide when to audit; the committed hooks in `.dev/hooks/` run the audit for them, registered
for Claude Code in `.claude/settings.json` and for Codex in `.codex/hooks.json`:

- `after-edit.sh` (the `Stop` hook) audits the branch after every turn in which frontend files or
  `package.json` changed, next to the linters.
- `fallow-gate.sh` (a `PreToolUse` hook on the shell tool) audits the branch before each `git commit` and
  `git push` of the agent and blocks the command on a `fail` verdict. Every other command passes through.

Both pass the introduced findings of a `warn` verdict on without blocking: `fallow-gate.sh` as additional context
for the agent, `after-edit.sh` as `Stop` hook feedback in Claude Code — once per change of the findings, since it
continues the turn — and as a warning to the user in Codex, whose `Stop` hook cannot reach the model.

Both call `fallow-audit.sh`, which compares the branch with `origin/develop` and reports only the findings the
branch introduces, formatted by `fallow-findings.mjs`. Export `FALLOW_AUDIT_BASE` (e.g. `origin/stable/7.2`)
before starting the agent when the merge request targets another branch. A runtime error, such as a missing base
ref, never blocks: the hook prints one line and skips. Human commits are not gated locally; the pipeline job
covers them. The agent-facing guidance on reading a blocked audit and on when to run fallow by hand is in
`.dev/agent_docs/code_analysis.md`.

## Agent Permissions

The read-only fallow commands (`pnpm analyse:fallow*`, `dead-code`, `dupes`, `trace`, `explain` and
`fix --dry-run`) are allowed in the shared `.claude/settings.json`; `fallow fix --yes` still asks.

## Auto-Fix

`fallow fix` removes unused `export` keywords, enum members and `package.json` dependencies; it never deletes
files. Preview first, and scope it to the directories your branch touched — the path argument is the only scope the
fix planner honours, `--base` and `--diff-file` narrow the report but not the planned fixes (fallow 3.33):

```sh
pnpm exec fallow fix --dry-run app/frontend/shared/utils   # Preview the fixes in one directory.
pnpm exec fallow fix --yes app/frontend/shared/utils       # Apply them; review the diff.
```

Dependency removals edit `package.json` only; run `pnpm install` afterwards. Do not run `fix` without a path, and do
not run it in CI. fallow only sees this repository: an export that a
frontend addon imports through `#shared` or `#desktop` looks unused here and would be stripped. For a whole-project
cleanup, treat the dry run as a worklist and check each export against the addons before removing it; mark exports
that exist for addons with a `@public` JSDoc tag or list them under `ignoreExports`.

## Configuration Notes

`.fallowrc.json` works around what fallow cannot see on its own; keep it in sync when the project changes:

- Modules registered through a parent-relative `import.meta.glob('../…')` pattern are not resolved. The targets of
  such globs are listed under `dynamicallyLoaded`; a new glob of that shape needs an entry, otherwise its modules
  show up as unused files.
- `.graphql` documents are declared as entries because only graphql-codegen reads them.
- fallow ignores every `build/` directory by default, so `app/frontend/build/` is re-included explicitly.
- Packages that are only referenced by name in a config (`eslint-import-resolver-typescript`) or by the TypeScript
  compiler (`tslib` via `importHelpers`) are listed under `ignoreDependencies`.

The upstream [documentation](https://fallow.tools/docs/) covers the configuration keys and output formats in
detail.
