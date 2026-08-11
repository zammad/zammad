// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'

import skinMarkerPlugin, {
  MARKER_ATTRIBUTE,
  findAmbiguousNames,
  markerValue,
  qualifiedName,
  stampSource,
} from '../plugin.mjs'

const ID = '/app/frontend/shared/components/CommonExample/CommonExample.vue'

const stamp = (template: string, id = ID) =>
  stampSource(`<template>\n${template}\n</template>\n`, id)

const markerCount = (source: string) => source.match(new RegExp(MARKER_ATTRIBUTE, 'g'))?.length ?? 0

describe('skin-marker plugin', () => {
  it('stamps the native root with the component name from the filename', () => {
    expect(stamp('  <div class="x">hi</div>')).toContain(
      `<div ${MARKER_ATTRIBUTE}="CommonExample" class="x">`,
    )
  })

  it('stamps every native root of a multi-root template', () => {
    const out = stamp('  <header>a</header>\n  <main>b</main>')
    expect(out).toContain(`<header ${MARKER_ATTRIBUTE}="CommonExample">`)
    expect(out).toContain(`<main ${MARKER_ATTRIBUTE}="CommonExample">`)
  })

  it('does not stamp a component root (fallthrough would collapse identities)', () => {
    expect(stamp('  <CommonAvatar :size="2" />')).not.toContain(MARKER_ATTRIBUTE)
  })

  it('does not stamp a <slot> or <template> root', () => {
    expect(stamp('  <slot />')).not.toContain(MARKER_ATTRIBUTE)
    expect(stamp('  <template v-if="x"><span>1</span></template>')).not.toContain(MARKER_ATTRIBUTE)
  })

  it('stamps only the native roots in a mixed multi-root template', () => {
    const out = stamp('  <div>native</div>\n  <CommonAvatar />')
    expect(out).toContain(`<div ${MARKER_ATTRIBUTE}="CommonExample">`)
    expect(markerCount(out)).toBe(1)
  })

  it('is idempotent — never double-stamps an already-marked root', () => {
    const already = `<template>\n  <div ${MARKER_ATTRIBUTE}="Manual">x</div>\n</template>\n`
    expect(stampSource(already, ID)).toBe(already)
  })

  // --- plugin wiring ---

  it('only rewrites main .vue requests, never sub-blocks or node_modules', () => {
    const plugin = skinMarkerPlugin()
    const sfc = `<template><div>x</div></template>\n`
    expect(plugin.transform(sfc, `${ID}?vue&type=template`)).toBeNull()
    expect(plugin.transform(sfc, '/app/frontend/styles.css')).toBeNull()
    expect(plugin.transform(sfc, '/x/node_modules/foo/Foo.vue')).toBeNull()
    expect(plugin.transform(sfc, ID)?.code).toContain(MARKER_ATTRIBUTE)
  })

  it('returns null when there is nothing to stamp (no native root)', () => {
    expect(skinMarkerPlugin().transform('<template><CommonAvatar /></template>\n', ID)).toBeNull()
  })
})

describe('skin-marker name qualification', () => {
  it('qualifies with the nearest PascalCase ancestor, skipping lowercase folders', () => {
    expect(
      qualifiedName('apps/desktop/components/UserTaskbarTabs/Organization/Organization.vue'),
    ).toBe('UserTaskbarTabs/Organization')
    expect(
      qualifiedName('apps/desktop/components/Search/QuickSearch/entities/Organization.vue'),
    ).toBe('QuickSearch/Organization')
  })

  it('falls back to the bare name when there is no PascalCase ancestor', () => {
    expect(qualifiedName('shared/components/CommonButton/CommonButton.vue')).toBe('CommonButton')
  })

  it('flags a name ambiguous only when two can render in the same app', () => {
    // desktop/mobile mirrors are separate bundles → not ambiguous.
    expect(
      findAmbiguousNames([
        'apps/desktop/components/CommonButton/CommonButton.vue',
        'apps/mobile/components/CommonButton/CommonButton.vue',
      ]).has('CommonButton'),
    ).toBe(false)
    // two within one app → ambiguous.
    expect(
      findAmbiguousNames([
        'apps/desktop/components/UserTaskbarTabs/Organization/Organization.vue',
        'apps/desktop/components/Search/QuickSearch/entities/Organization.vue',
      ]).has('Organization'),
    ).toBe(true)
    // a shared component co-renders in every app → ambiguous with an app copy.
    expect(
      findAmbiguousNames([
        'shared/components/CommonInputSearch/CommonInputSearch.vue',
        'apps/desktop/components/CommonInputSearch/CommonInputSearch.vue',
      ]).has('CommonInputSearch'),
    ).toBe(true)
  })

  it('ignores non-bundle files (e.g. test-support) — they never force qualification', () => {
    // a test-support component sharing a real component's name must NOT mark it ambiguous
    expect(
      findAmbiguousNames([
        'apps/desktop/components/CommonButton/CommonButton.vue',
        'tests/support/components/CommonButton.vue',
      ]).has('CommonButton'),
    ).toBe(false)
    // even a shared component + a same-named test-support file stays unambiguous
    expect(
      findAmbiguousNames([
        'shared/components/CommonInputSearch/CommonInputSearch.vue',
        'tests/support/components/CommonInputSearch.vue',
      ]).has('CommonInputSearch'),
    ).toBe(false)
  })

  it('uses the plain name unless the name is ambiguous', () => {
    const file = 'apps/desktop/components/UserTaskbarTabs/Organization/Organization.vue'
    expect(markerValue(file, new Set())).toBe('Organization')
    expect(markerValue(file, new Set(['Organization']))).toBe('UserTaskbarTabs/Organization')
  })

  it('stamps a qualified value when the name is ambiguous', () => {
    const out = stampSource(
      '<template>\n  <div>x</div>\n</template>\n',
      'apps/desktop/components/UserTaskbarTabs/Organization/Organization.vue',
      new Set(['Organization']),
    )
    expect(out).toContain(`${MARKER_ATTRIBUTE}="UserTaskbarTabs/Organization"`)
  })
})
