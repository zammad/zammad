<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

# Custom CSS — mobile app (build-time skin)

Drop your own `.css` files in this folder to restyle the **mobile** Vue 3 app
**without editing core files**. Every `.css` file here (including subfolders) is
bundled into the mobile SPA at build time via the eager glob in `index.ts`, which
`app/frontend/apps/mobile/main.ts` imports right after the app's own styles
(`import '#mobile/styles/custom/index.ts'`).

The desktop app has its own folder at `app/frontend/apps/desktop/styles/custom/`.
This is the new-stack sibling of the legacy `app/assets/stylesheets/custom/` (which
feeds only the old CoffeeScript frontend, via Sprockets).

- **Build-time only.** Changes require a frontend rebuild (`rails assets:precompile`); the dev
  server hot-reloads edits to existing files (a brand-new file may need a restart).
  There is no runtime/admin upload path yet.
- **Valid CSS only.** These files are part of the build; a broken file fails it.

## How it overrides app styles

These files load **unlayered** and **after** the app's own styles. Per the CSS
Cascade Layers spec, an unlayered rule beats every Tailwind `@layer`
utility/component/base rule regardless of specificity — so you do **not** need
`!important`. Do **not** wrap rules in `@layer { … }` (that rejoins the layered
cascade). You may read design tokens, e.g. `color: var(--color-blue-800)`.

Exceptions: a few component `<style>` blocks still out-rank a plain rule — scoped
styles (higher specificity) and a handful of unlayered ones that load later — so
overriding those needs higher specificity or `!important`.

## What to target

Target the stable `data-zammad-target` marker Zammad auto-stamps on the rendered
DOM (value = the component name):

```css
[data-zammad-target='CommonButton'] {
  border-radius: 0;
}
```

Files are bundled in sorted path order, so a later filename wins; prefix with
numbers (e.g. `00-base.css`, `90-overrides.css`) for deterministic ordering.
