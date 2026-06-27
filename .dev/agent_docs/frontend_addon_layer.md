<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

# Frontend addon layer

How an external addon (szpm package) extends the new Vue frontend — without
overwriting core files, without runtime monkey-patching, and in a way that
survives the planned Vapor migration.

## Mechanism: build-time weave

An addon's UI changes are applied by **rewriting the targeted core SFC's source
text at build time, before the Vue compiler runs** — a Vite `enforce: 'pre'`
plugin in `app/frontend/build/addonWeave` (see its `README.md` for internals).

It is Vapor-safe by construction: it edits the compiler's _input_ (template
source), not the vnode tree at runtime, so whatever compiler runs next compiles
the merged source normally — the vdom compiler today, the Vapor compiler later.
(Runtime monkey-patching — wrapping `render`, walking/cloning vnodes — is the
opposite: automatic but vdom-only, and cannot work under Vapor.) Core SFCs are
never modified on disk; only the in-memory module is rewritten during the build.

## Multi-addon: per-addon manifests, discovered

There is **no central rule list**. Each addon ships its own `*.weave.mjs`
manifest next to its code; `discoverRules.mjs` globs every manifest under
`app/frontend` and concatenates them. Core names no addon — adding one is
dropping a manifest + its code, never editing a shared core file. Any number of
addons compose.

## Manifest format

`…/<addon>.weave.mjs` (plain JS — it is imported at config time):

```js
export const addonWeaveRules = [
  {
    target: 'shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue',
    scriptSetup: [
      "import { useThing } from '#shared/addons/<addon>/useThing.ts'",
      'const __addonThing = useThing(() => props.entity)',
    ].join('\n'),
    template: [
      // decorate the element (class / style / attribute)
      { match: { component: 'CommonAvatar' }, addAttribute: ':class="__addonThing"' },
      // inject a sibling before / after a matched element
      { match: { hasClass: 'addon-anchor-ticket-reply' }, insertBefore: '<MyBanner />' },
    ],
  },
]
```

- `target` — core SFC path (suffix match); stays byte-for-byte untouched.
- `scriptSetup` — code appended inside the SFC's `<script setup>` (imports +
  setup), referencing the addon's own files via `#shared` / `#desktop` aliases.
- `template` — semantic edits on the parsed template AST (not raw text). Each op
  is a `match` plus an action: **additive** (composable) `insertBefore` /
  `insertAfter` (sibling), `prepend` / `append` (first/last child), `addAttribute`,
  `setAttribute` / `removeAttribute` (override/remove `name` or `:name`),
  `wrap: { open, close }`; or **destructive** (stands alone) `replace` / `remove`.
  `match` accepts `component` / `element` / `tag` / `id` / `testId` / `hasClass` /
  `attr: { name, value? }` / `root` (AND-combined, component≠native) and must hit
  ≥1 element; overlapping edits — even across addons — fail the build too.

The addon's logic (composables/components) lives in its own files. Data usually
comes from the Apollo cache (`objectAttributeValues` etc. — a stable public
GraphQL contract), so an addon rarely needs anything new from core.

## Testing

- **Vitest** — render the **pristine** core component; the weave runs during the
  test build (the plugin is in `vite.config.mjs`), so the woven behavior is what
  you assert. Seed the Apollo cache via the mock client for cache-backed
  composables.
- **For addons, prefer Capybara/system tests** — they exercise the package in the
  real, built app (the weave actually applied on install), which is the addon's
  main risk. Vitest is the faster secondary check.
- A test runs in CI **only if registered** in the addon's `.gitlab-ci.yml`
  `script` (and listed in the `.szpm` `files`); CI does not auto-discover specs.

## Gotchas

- **Discovery roots on `process.cwd()`, not `import.meta.url`** — Vite bundles
  `vite.config.mjs` (and its imports) to a temp file before running, so an
  `import.meta.url`-relative path resolves wrong and the glob finds nothing.
- A newly linked addon's woven SFC can be stale in a **warm Vite cache** (the
  pristine SFC source never changed, so only a config-dependency change busts
  it). A fresh build / CI run is unaffected.
- Avatar/icon colors: use the desktop **design tokens** (`var(--color-…)`), not
  hard-coded hsl/rgb.

## Honest scope

- **Vapor itself is not yet exercised** (this Vue has no Vapor compiler); the
  Vapor-safety is by construction and must be confirmed once the repo builds
  Vapor.
- Matching is AST-based (component/element identity, `id`, `data-test-id`, a
  static class, or the root) and edits splice at exact source offsets; a missed
  anchor **fails the build loudly**. A failing weave fails the _whole_ build —
  there is no per-addon isolation (intended: a failed install over a broken UI).
- Manifest discovery globs `app/frontend`; the real source of truth should be the
  installed-package (szpm) list.
