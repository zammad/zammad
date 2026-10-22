# Code Analysis with fallow

[fallow](https://fallow.tools) builds the module graph of `app/frontend` and
reports what the linters cannot see across files: unused files, exports, enum,
class and store members, unused dependencies, import cycles, copy-paste
duplication and oversized functions. It covers the Vue/TypeScript stack only,
not Ruby or CoffeeScript. The config is `.fallowrc.json`; the hooks, permissions
and the MCP server are described in
`doc/developer_manual/development_environment/fallow-setup.md`.

## What runs on its own

The audit does not depend on anyone remembering it:

- **After every turn**, the `Stop` hook (`.dev/hooks/after-edit.sh`) audits
  the branch next to the linters whenever frontend files or `package.json`
  changed.
- **Before `git commit` and `git push`**, the `PreToolUse` hook
  (`.dev/hooks/fallow-gate.sh`) runs the same audit and blocks the command.
- **In the MR pipeline**, `lint: fallow audit` runs it as an advisory job.

The audit compares the branch with `origin/develop` (`FALLOW_AUDIT_BASE`
overrides the base, e.g. for a stable branch) and lists only the findings the
branch introduces. Inherited findings in touched files carry
`introduced: false` and never block. Error-severity findings make the verdict
`fail`: unused files, exports, enum and class members and import cycles.
Functions above the complexity thresholds, duplication and unused
devDependencies only `warn` while fallow is evaluated; unused store members
`warn` by fallow's default, because a store's members can be reached dynamically.
A `warn` verdict never blocks: both hooks pass its introduced findings on as
advice (the `Stop` hook only when they change). Address them while the code is
open where the change allows it — split the function, reuse the duplicated
code — and leave the rest to the review.

The audit only looks at the files the branch changes. Removing the last
consumer of a helper passes it as long as the helper's own file is untouched,
so it does not replace the cleanup check below.

When a hook blocks:

- Fix the finding. Work that is not wired up yet shows as unused: finish it
  rather than deleting it.
- A finding that is wrong for a reason fallow cannot see is configured or
  suppressed with the reason, see below.
- `pnpm analyse:fallow:audit` prints the full report with the inherited
  findings; `pnpm exec fallow dead-code --trace <file>:<export>` explains why
  one export counts as unused, including re-export chains.
- A runtime error never blocks; the hook prints one line and skips.

## When to run it yourself

- **Before writing a helper, composable or component**: check whether one
  already exists. `pnpm exec fallow dupes --skip-local` lists cross-directory
  clones; `pnpm exec fallow dupes --trace dup:<fingerprint>` shows one group with
  its suggested extraction. Also search `app/frontend/shared/utils/` and
  `app/frontend/shared/composables/` by name first.
- **Before deleting an export or file that looks unused**:
  `pnpm exec fallow dead-code --trace <file>:<export>` explains why fallow
  considers it unused. Modules registered through `import.meta.glob` are easy
  to misjudge, see below. Search for remaining uses with `git grep`, not plain
  `rg`: `rg` skips hidden directories, and the Cypress support code lives in
  `.dev/cypress`.
- **After removing the last consumer of something**:
  `pnpm exec fallow fix --dry-run <directory>` lists the exports, enum members
  and dependencies left behind there. Apply with `--yes <directory>` only after
  the dry run; the path is the only scope the fix planner honours (`--base`
  does not narrow it), so never run it without one, and never in CI. Exports
  consumed by frontend addons are invisible to fallow — they live outside this
  repository — so an unexpected "unused" export in `#shared` needs that check
  before it goes.
- **For a refactoring target**: `pnpm analyse:fallow:health` ranks files by
  complexity, fan-in, churn and cycles. A `<template>` finding asks for a
  component split, not for a helper function. The CRAP metric is off because
  fallow only estimates coverage.

## Reading the results

- `.dev/cypress` is analysed as a workspace package with its own
  `package.json`; the rest of `.dev` is ignored. The package cycle between it
  and the Cypress specs in `app/frontend/cypress` is inherent to that layout, so
  `package-cycle` is off. Its packages are installed separately
  (`pnpm cypress:install`), so `cypress` imports are never reported as
  unresolved.
- `import.meta.glob` with a parent-relative pattern (`'../components/…'`) is not
  followed by fallow; the targets of such globs are listed under
  `dynamicallyLoaded` in `.fallowrc.json`. A new glob of that shape needs an
  entry there, otherwise its modules show up as unused files.
- An export is used as soon as any file imports the module as a namespace
  (`import * as …`), so an unused export next to such an import goes unreported.
- `.graphql` documents are entries: only graphql-codegen reads them. Generated
  GraphQL files stay in the graph but never produce findings.
- fallow ignores the negated patterns of an `import.meta.glob` array and lets
  `./*.ts` match subdirectories, so a plugin registry glob pulls in its
  `__tests__` files and its own module. The import cycles through a `__tests__`
  file come from that; they are not real. Exports of the glob targets count as
  used, since a glob is read like a namespace import.
- Cycles closed by a lazy `import()` are left out (`ignoreLazyImports`): they
  cannot break module initialisation.
- An exported `Props` of a `.vue` file is never reported, nor the per-app
  `routes`, `initializeForm` and `EXTENSION_NAME` exports (`ignoreExports`).
  Export `Props` only when another file imports it.
- Duplication and similarity results are advisory. A clone between the desktop
  and mobile app is not automatically wrong — the apps diverge on purpose in
  places — but shared logic belongs in `app/frontend/shared/`.

## Suppressing a finding

Prefer fixing the config over inline markers. Where a marker is the right tool
(`// fallow-ignore-next-line unused-export`), give the reason in the same
comment, as with any other lint suppression.
