<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

# Build-time skin marker

Auto-stamps a stable, customer-facing CSS hook onto eligible native top-level
SFC roots so the new Vue frontend can be **restyled without overwriting core
files** — the new-stack replacement for the legacy
`app/assets/stylesheets/custom/` custom-CSS feature.

## Why

On the new stack there are no stable selectors: Tailwind utility classes change
on every restyle and Vue scoped styles add a random `[data-v-…]` attribute. So a
customer (or an addon, or a test) has nothing reliable to target. This plugin
stamps an intentional, stable attribute, automatically, on every eligible native
top-level SFC root — no dev has to remember to add it.

It is a Vite `enforce: 'pre'` plugin that rewrites SFC **source** before the Vue
compiler runs (the same approach as `../addonWeave`), so it is **Vapor-safe by
construction** — whatever compiler runs next sees ordinary source.

## What gets stamped

`data-zammad-target="<ComponentName>"` is added to the **native** top-level root
element(s) of each SFC (`<ComponentName>` = the SFC file basename; qualified to
`Folder/ComponentName` when that name is shared — see below).

A root that is **not** a native element — a component, `<slot>`, `<template>` or
`<component :is>` — is **skipped**. A marker on a component root would fall
through (Vue attribute fallthrough) onto the child's rendered DOM node and
collapse two identities onto one element. Multi-root templates get every native
root stamped.

So this is broad, automatic coverage of native-rooted components — not a promise
of "every component / every element".

## How customer CSS uses it

Target a component by name, or scope to an area by combining a container with a
descendant:

```css
/* every button in the ticket-detail bottom bar */
[data-zammad-target='TicketDetailBottomBar'] [data-zammad-target='CommonButton'] {
  border-radius: 0;
}
```

Only a component's native top-level root gets the automatic build-time marker —
route containers get the same attribute separately, via a runtime binding (see
[Route-page scope](#route-page-scope) below) — so reach an inner element by
combining the component's target with a plain descendant selector:

```css
/* the icon inside every button (the inner element has no marker of its own) */
[data-zammad-target='CommonButton'] svg {
  color: var(--color-blue-800);
}
```

The value is the component name, so the marker is **broad**: it selects _all_
instances of a component. The few components whose file name is shared by another
component get a `Folder/ComponentName` value instead (e.g.
`UserTaskbarTabs/Organization`), so each stays distinct. A single control among
identical siblings (e.g. the ticket Update button vs a Discard button — both
`CommonButton`) isn't isolable by the CSS marker alone — but the addon weave can pin
it (below).

For changes CSS can't make — adding/replacing DOM, or hitting a **specific** instance
the marker can't isolate — an addon uses the build-time
[addon weave](../addonWeave/README.md): it rewrites the target SFC's source before
compile (zero core change). Its `match` is AND-combined, so `target` (the file) +
component + a source attribute pins one node — e.g. only the submit button in the
ticket bottom bar, not the neighbouring discard button:

```js
{
  target:
    'apps/desktop/pages/ticket/components/TicketDetailView/TicketDetailBottomBar/TicketDetailBottomBar.vue',
  template: [
    {
      match: { component: 'CommonButton', attr: { name: 'variant', value: 'submit' } },
      insertAfter: '<MyAddonAction />',
    },
  ],
}
```

CSS can't isolate that button (`variant` is only Tailwind classes at runtime); the
weave sees `variant="submit"` in the source. It matches source structure — not the
runtime marker — so a _hand-placed_ `data-zammad-target` anchor is the one thing it
can `attr`-match. Reading entity _data_ (e.g. an org's custom attribute) uses the
weave's `scriptSetup`; see [addon weave](../addonWeave/README.md).

## Route-page scope

Route containers aren't SFC roots, so they never get the automatic build-time
marker described above. They carry the same `data-zammad-target` attribute
through a separate, hand-added **runtime** binding instead — value = the active
route name — so custom CSS can scope to a whole page and compose with the
build-time component markers inside it:

```css
/* only on the ticket-detail page */
[data-zammad-target='TicketDetailView'] [data-zammad-target='CommonButton'] {
  border-radius: 0;
}
```

This binding lives on the element that already wraps the router-view:
`#main-content` on desktop
(`apps/desktop/components/layout/LayoutPage.vue`) and `<main>` on mobile
(`apps/mobile/components/layout/LayoutMain.vue`). Both are nested containers, not
SFC roots, so they never clash with the auto-stamped markers. Route names share the
value space with component names, but since the page container always wraps its
content the descendant combinator still resolves correctly.

Public routes render one tier up (outside those layouts), so they carry the same
bind on their own shell: the nested `<main>` of `LayoutPublicPage` (desktop
login / signup / password-reset / guided-setup). Again the nested element, not the
shell root — the root already gets the auto `LayoutPublicPage` component stamp.
Public pages that already have a native root (mobile login, desktop error) need
nothing extra: the build-time stamp gives them their route name for free (their
component name equals the route name).

## Not yet (honest scope)

- **Precise single-element handles.** Only the broad, component-name marker
  exists. Targeting one specific control among identical siblings would need an
  opt-in, hand-placed handle — deferred until a real need appears.
- **Customer-CSS delivery.** Where integrators write the CSS is
  `app/frontend/apps/*/styles/custom/` (bundled, unlayered, beats Tailwind
  utilities without `!important`). A runtime/admin upload path is a separate
  follow-up.
- **Scoped styles** (~24 SFCs) compile to `[data-v-…]` = specificity (0,2,0) and
  out-specify an unlayered `(0,1,0)` customer rule. Custom CSS also loads
  _before_ component styles, so equal specificity still loses on source order —
  overriding a scoped-styled element needs specificity strictly greater than
  (0,2,0), e.g. a tripled selector
  (`[data-zammad-target='X'][data-zammad-target='X'][data-zammad-target='X']`),
  until those are emitted into an early cascade layer.
- **Unlayered non-scoped `<style>` blocks** (5 SFCs — FormLayout, FieldEditorInput,
  AiAssistantTextTools, HighlightMenu, mobile's FieldAutoCompleteInputDialog) are
  unlayered too, but their component modules load _after_ the eagerly-bundled custom
  CSS (imported early in `main.ts`), so at equal specificity they win on **source
  order** — overriding one needs higher specificity or `!important` (same early-layer
  fix as scoped styles). The "unlayered beats layered" rule only covers Tailwind's
  `@layer`; it does not cover these.
- **Contract governance** (an allowlist/snapshot guard so a component rename
  can't silently break a customer theme) is a follow-up.
- **Data-driven decoration** (e.g. avatar color from an org's custom attribute)
  cannot be done in CSS — that stays an `../addonWeave` `scriptSetup` concern. The
  marker is styling-only.
- **Dev HMR drops the auto marker until a full reload.** The build-time stamp is
  injected `enforce: 'pre'`, but `@vitejs/plugin-vue`'s hot-update path re-parses the
  SFC straight from disk and bypasses that transform — so after you edit a component
  in `pnpm dev`, its auto `data-zammad-target` is missing from the hot-patched render
  until a hard reload (which re-runs the full pipeline). Production builds transform
  once and are unaffected; the runtime route bind (a real source attribute) survives
  HMR. So when checking markers in dev, hard-reload first.
- Disabled under test (`VITE_TEST_MODE`) so it does not perturb component DOM
  snapshots; the logic is covered by `__tests__/plugin.spec.ts` directly.
