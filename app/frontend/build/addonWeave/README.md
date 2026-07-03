<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

# Build-time addon weave

Lets an external addon extend the new Vue frontend **without overwriting core
files, without runtime monkey-patching, and in a way that survives the planned
Vapor migration**.

## Why

Runtime patching (wrapping `render`, walking the vnode tree) is automatic and
needs no core change — but it is coupled to Vue's vdom internals and **cannot
work under Vapor Mode** (no vnode tree, no render function returning vnodes).
Every _Vapor-safe_ alternative (outlets, slots, provide/inject, a resolver)
needs a **manual core edit per extension point**, which the addon model forbids
as the default.

The one mechanism that is **automatic, zero-core-change, arbitrary-location, and
Vapor-safe** is to rewrite the targeted core SFC's **source text at build time**,
before the Vue compiler runs. Whatever compiler runs next compiles the merged
source normally — the vdom compiler today, the Vapor compiler unchanged later.

## How it works (multi-addon)

| File                | Role                                                                                                              |
| ------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `plugin.mjs`        | Vite plugin (`enforce: 'pre'`): parses each matching SFC + template AST, splices the rule's edits into the source |
| `discoverRules.mjs` | globs every addon's `*.weave.mjs` under `app/frontend` and aggregates rules                                       |

There is **no central rule list**. Each addon ships its own manifest next to its
code; `discoverRules` finds them all at build time and concatenates them (sorted
for deterministic ordering). Core lists nothing and names no addon — adding an
addon is dropping a manifest + its code, never editing a shared core file. Any
number of addons compose.

`vite.config.mjs` wires it up:

```js
const addonWeaveRules = await discoverAddonWeaveRules()
// plugins: [ addonWeavePlugin(addonWeaveRules), … ]
```

## Addon manifest format

An addon ships `…/<addon>.weave.mjs` (plain JS — it is imported at config time):

```js
export const addonWeaveRules = [
  {
    target: 'shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue',
    scriptSetup: [
      "import { useThing } from '#shared/addons/<addon>/useThing.ts'",
      'const __addonThing = useThing(() => props.entity)',
    ].join('\n'),
    template: [
      // decorate: add a class/style/attribute to the matched element
      { match: { component: 'CommonAvatar' }, addAttribute: ':class="__addonThing"' },
      // inject a sibling before/after the matched element
      { match: { hasClass: 'addon-anchor-ticket-reply' }, insertBefore: '<MyBanner />' },
    ],
  },
]
```

- `target` — core SFC path (suffix match). Core stays byte-for-byte untouched.
- `scriptSetup` — code appended inside the SFC's `<script setup>` (imports +
  setup), referencing the addon's own files via `#shared` / `#desktop` aliases.
- `template` — semantic AST edits; each op is a `match` plus actions. Matching is
  on the parsed AST (not raw text), so it survives core whitespace/format changes.
  Each op's `match` must hit **at least one** element, and edits must not
  **overlap** (even across different addons) — both fail the build loudly.

### Matchers (`match`, AND-combined)

| Field       | Matches                                   | Example                                     |
| ----------- | ----------------------------------------- | ------------------------------------------- |
| `component` | a component by tag (not a native element) | `{ component: 'CommonAvatar' }`             |
| `element`   | a native element by tag (not a component) | `{ element: 'div' }`                        |
| `tag`       | any tag — component or native             | `{ tag: 'button' }`                         |
| `id`        | static `id` attribute value               | `{ id: 'layout-page' }`                     |
| `testId`    | static `data-test-id` value               | `{ testId: 'ticket-detail' }`               |
| `hasClass`  | a token in the static `class`             | `{ hasClass: 'addon-anchor-ticket-reply' }` |
| `attr`      | a static attribute (value optional)       | `{ attr: { name: 'role', value: 'feed' } }` |
| `root`      | a top-level (template root) element       | `{ root: true }`                            |

### Actions

Additive actions compose on one op; a destructive action must be the only action.

| Action            | Kind        | Effect                                | Example                                       |
| ----------------- | ----------- | ------------------------------------- | --------------------------------------------- |
| `insertBefore`    | additive    | sibling before the element            | `insertBefore: '<Banner />'`                  |
| `insertAfter`     | additive    | sibling after the element             | `insertAfter: '<Badge />'`                    |
| `prepend`         | additive    | first child of the element            | `prepend: '<First />'`                        |
| `append`          | additive    | last child of the element             | `append: '<Last />'`                          |
| `addAttribute`    | additive    | add an attribute to the opening tag   | `addAttribute: ':class="x"'`                  |
| `setAttribute`    | additive    | override an existing `name` / `:name` | `setAttribute: { name: ':size', value: '2' }` |
| `removeAttribute` | additive    | remove an existing `name` / `:name`   | `removeAttribute: 'data-test-id'`             |
| `wrap`            | additive    | wrap the element                      | `wrap: { open: '<span>', close: '</span>' }`  |
| `replace`         | destructive | swap the whole element for new markup | `replace: '<MyThing />'`                      |
| `remove`          | destructive | delete the element                    | `remove: true`                                |

The addon's logic (composables/components) lives in its own files and is imported
by the woven `scriptSetup`. `objectAttributeValues` etc. are already in the Apollo
cache (a stable public GraphQL contract), so an addon usually needs nothing new
from core.

## Not yet proven (honest scope)

- **Vapor itself is not exercised** (this Vue has no Vapor compiler). Vapor-safety
  is by construction (the transform edits compiler _input_); confirm empirically
  once the repo can build Vapor.
- A missed anchor **fails the whole build** (loud, by design) — there is no
  per-addon failure isolation, so one addon with a stale anchor blocks the build.
  That is the intended trade for a paid addon: a failed install over a silently
  broken UI. Every rule failure names the `*.weave.mjs` file it came from (and an
  overlap conflict names both), so the message points at the addon manifest to
  fix, not just the core SFC the rule targeted.
- Manifest discovery globs `app/frontend`; the real source of truth should be the
  installed-package (szpm) list.
- `insertBefore` output is not re-indented to match surrounding siblings (valid,
  just not pretty in the compiled source).
