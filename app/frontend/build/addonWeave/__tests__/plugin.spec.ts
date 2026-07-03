// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'

import addonWeavePlugin, { weaveSource } from '../plugin.mjs'

import type { AddonWeaveRuleBody } from '../plugin.mjs'

const SFC = `<script setup lang="ts">
const props = defineProps<{ value: number }>()
</script>

<template>
  <div class="wrapper addon-anchor-foo" data-test-id="host">
    <CommonAvatar :size="value" />
  </div>
</template>
`

const weave = (rule: AddonWeaveRuleBody) => weaveSource(SFC, rule, '/abs/CommonExample.vue')

describe('addon weave plugin (AST-based)', () => {
  it('appends scriptSetup code', () => {
    const out = weave({ scriptSetup: "import X from '#x/X.vue'\nconst a = 1" })
    expect(out).toContain("import X from '#x/X.vue'")
    expect(out).toContain('const a = 1')
  })

  it('inserts a sibling before a matched component', () => {
    const out = weave({
      template: [{ match: { component: 'CommonAvatar' }, insertBefore: '<Banner />' }],
    })
    expect(out).toMatch(/<Banner \/>\s*<CommonAvatar/)
  })

  it('inserts a sibling after a matched component', () => {
    const out = weave({
      template: [{ match: { component: 'CommonAvatar' }, insertAfter: '<Badge />' }],
    })
    expect(out).toMatch(/<CommonAvatar :size="value" \/>\s*<Badge \/>/)
  })

  it('adds an attribute (decoration) to a matched element', () => {
    const out = weave({
      template: [{ match: { component: 'CommonAvatar' }, addAttribute: ':class="__c"' }],
    })
    expect(out).toContain('<CommonAvatar :class="__c" :size="value" />')
  })

  it('replaces a matched element with new markup', () => {
    const out = weave({
      template: [{ match: { component: 'CommonAvatar' }, replace: '<MyAvatar />' }],
    })
    expect(out).toContain('<MyAvatar />')
    expect(out).not.toContain('<CommonAvatar')
  })

  it('removes a matched element', () => {
    const out = weave({ template: [{ match: { component: 'CommonAvatar' }, remove: true }] })
    expect(out).not.toContain('CommonAvatar')
  })

  it('wraps a matched element', () => {
    const out = weave({
      template: [
        {
          match: { component: 'CommonAvatar' },
          wrap: { open: '<span class="w">', close: '</span>' },
        },
      ],
    })
    expect(out).toMatch(/<span class="w"><CommonAvatar :size="value" \/><\/span>/)
  })

  it('composes additive actions on one op (wrap + addAttribute)', () => {
    const out = weave({
      template: [
        {
          match: { component: 'CommonAvatar' },
          wrap: { open: '<span>', close: '</span>' },
          addAttribute: 'data-x',
        },
      ],
    })
    expect(out).toContain('<span><CommonAvatar data-x :size="value" /></span>')
  })

  it('prepends and appends children inside a matched element', () => {
    // Whitespace-only text nodes are condensed away, so the div's first/last
    // child is the CommonAvatar element itself.
    const prepended = weave({ template: [{ match: { element: 'div' }, prepend: '<First />' }] })
    expect(prepended).toContain('<First /><CommonAvatar')

    const appended = weave({ template: [{ match: { element: 'div' }, append: '<Last />' }] })
    expect(appended).toMatch(/<CommonAvatar :size="value" \/><Last \/>/)
  })

  it('overrides a static and a bound attribute (setAttribute)', () => {
    const staticOut = weave({
      template: [{ match: { element: 'div' }, setAttribute: { name: 'class', value: 'new' } }],
    })
    expect(staticOut).toContain('class="new"')
    expect(staticOut).not.toContain('wrapper addon-anchor-foo')

    const boundOut = weave({
      template: [
        { match: { component: 'CommonAvatar' }, setAttribute: { name: ':size', value: 'big' } },
      ],
    })
    expect(boundOut).toContain(':size="big"')
    expect(boundOut).not.toContain(':size="value"')
  })

  it('removes an existing attribute (removeAttribute)', () => {
    const out = weave({
      template: [{ match: { element: 'div' }, removeAttribute: 'data-test-id' }],
    })
    expect(out).not.toContain('data-test-id="host"')
  })

  it('matches by a generic attribute (attr)', () => {
    expect(
      weave({
        template: [
          { match: { attr: { name: 'data-test-id', value: 'host' } }, addAttribute: 'data-m' },
        ],
      }),
    ).toContain('<div data-m ')
  })

  it('orders same-offset edits so siblings stay outside the wrap', () => {
    const out = weave({
      template: [
        {
          match: { component: 'CommonAvatar' },
          insertBefore: '<Before />',
          insertAfter: '<After />',
          wrap: { open: '<span>', close: '</span>' },
        },
      ],
    })
    // Before is an outer sibling before the wrap; After an outer sibling after it.
    expect(out).toMatch(/<Before \/>\s*<span><CommonAvatar :size="value" \/><\/span>\s*<After \/>/)
  })

  it('applies multiple scriptSetup snippets in rule order', () => {
    const out = addonWeavePlugin([
      { target: 'CommonExample.vue', scriptSetup: 'const first = 1' },
      { target: 'CommonExample.vue', scriptSetup: 'const second = 2' },
    ]).transform(SFC, '/abs/CommonExample.vue')?.code
    expect(out?.indexOf('const first = 1')).toBeLessThan(out?.indexOf('const second = 2') ?? -1)
  })

  it('matches by static class / id / data-test-id / root', () => {
    expect(
      weave({ template: [{ match: { hasClass: 'addon-anchor-foo' }, addAttribute: 'data-x' }] }),
    ).toContain('<div data-x ')
    expect(weave({ template: [{ match: { testId: 'host' }, addAttribute: 'data-y' }] })).toContain(
      '<div data-y ',
    )
    expect(weave({ template: [{ match: { root: true }, addAttribute: 'data-z' }] })).toContain(
      '<div data-z ',
    )
  })

  it('distinguishes component vs native element and AND-combines tag matchers', () => {
    // `element` must not match a component...
    expect(() =>
      weave({ template: [{ match: { element: 'CommonAvatar' }, remove: true }] }),
    ).toThrow(/no element matched/)
    // ...and `component` must not match a native element.
    expect(() => weave({ template: [{ match: { component: 'div' }, remove: true }] })).toThrow(
      /no element matched/,
    )
    // contradictory fields are AND-combined → no match (loud fail, not wrong node).
    expect(() =>
      weave({ template: [{ match: { component: 'CommonAvatar', tag: 'div' }, remove: true }] }),
    ).toThrow(/no element matched/)
    // `element` does match a real native element.
    expect(weave({ template: [{ match: { element: 'div' }, addAttribute: 'data-e' }] })).toContain(
      '<div data-e ',
    )
  })

  // --- loud failure: the core risk a build-time weave must guard against ---

  it('fails the build when a matcher hits nothing', () => {
    expect(() =>
      weave({ template: [{ match: { component: 'DoesNotExist' }, insertBefore: '<X />' }] }),
    ).toThrow(/no element matched/)
  })

  it('fails the build when scriptSetup is requested but there is no <script setup>', () => {
    const noScript = `<template><div /></template>\n`
    expect(() => weaveSource(noScript, { scriptSetup: 'const a = 1' }, '/abs/X.vue')).toThrow(
      /no <script setup>/,
    )
  })

  it('fails the build on an empty matcher', () => {
    expect(() => weave({ template: [{ match: {}, insertBefore: '<X />' }] })).toThrow(
      /no usable match/,
    )
  })

  it('fails when setAttribute targets an absent attribute', () => {
    expect(() =>
      weave({
        template: [{ match: { element: 'div' }, setAttribute: { name: 'nope', value: 'x' } }],
      }),
    ).toThrow(/setAttribute target not found/)
  })

  it('fails when append/prepend targets a childless element', () => {
    expect(() =>
      weave({ template: [{ match: { component: 'CommonAvatar' }, append: '<X />' }] }),
    ).toThrow(/needs a non-empty element/)
  })

  it('rejects the legacy string-splice rule format', () => {
    const legacy = {
      templateReplace: [{ find: 'x', replaceWith: 'y' }],
    } as unknown as AddonWeaveRuleBody
    expect(() => weave(legacy)).toThrow(/legacy rule format/)
  })

  it('fails when a destructive action is combined with another action', () => {
    expect(() =>
      weave({
        template: [{ match: { component: 'CommonAvatar' }, remove: true, insertBefore: '<X />' }],
      }),
    ).toThrow(/must be the only action/)
  })

  it('fails when a template op has no action', () => {
    expect(() => weave({ template: [{ match: { component: 'CommonAvatar' } }] })).toThrow(
      /no action/,
    )
  })

  it('fails on conflicting edits that target overlapping source', () => {
    expect(() =>
      weave({
        template: [
          { match: { component: 'CommonAvatar' }, replace: '<A />' },
          { match: { component: 'CommonAvatar' }, remove: true },
        ],
      }),
    ).toThrow(/conflicting weave edits/)
  })

  // --- plugin wiring ---

  it('only rewrites SFCs whose path matches a rule target', () => {
    const rule = {
      target: 'CommonExample.vue',
      template: [{ match: { component: 'CommonAvatar' }, addAttribute: 'data-x' }],
    }
    expect(addonWeavePlugin([rule]).transform(SFC, '/abs/Other.vue')).toBeNull()
    expect(
      addonWeavePlugin([rule]).transform(SFC, '/abs/CommonExample.vue?vue&type=template'),
    ).toBeNull()
    expect(addonWeavePlugin([rule]).transform(SFC, '/abs/CommonExample.vue')?.code).toContain(
      'data-x',
    )
  })

  it('installs no transform hook when there are no addon rules', () => {
    // Addon-free builds must pay zero per-module cost (no hook → no source marshalling).
    expect(addonWeavePlugin([]).transform).toBeUndefined()
  })

  it('detects conflicting edits ACROSS rules (multi-addon)', () => {
    // Addon A decorates the avatar; addon B replaces it — must fail, not silently
    // drop A's edit.
    const plugin = addonWeavePlugin([
      {
        target: 'CommonExample.vue',
        template: [{ match: { component: 'CommonAvatar' }, addAttribute: 'data-a' }],
      },
      {
        target: 'CommonExample.vue',
        template: [{ match: { component: 'CommonAvatar' }, replace: '<X />' }],
      },
    ])
    expect(() => plugin.transform(SFC, '/abs/CommonExample.vue')).toThrow(/conflicting weave edits/)
  })

  // --- error message points at the addon manifest to fix ---

  it('names the addon manifest in a rule error when one is stamped on', () => {
    // discoverRules stamps `manifest` on each rule; a failure must point at that
    // file, not just the core SFC, so the fix is obvious.
    const plugin = addonWeavePlugin([
      {
        target: 'CommonExample.vue',
        manifest:
          'app/frontend/shared/addons/special_organizations/special_organizations.weave.mjs',
        template: [{ match: { component: 'DoesNotExist' }, insertBefore: '<X />' }],
      },
    ] as unknown as Parameters<typeof addonWeavePlugin>[0])
    expect(() => plugin.transform(SFC, '/abs/CommonExample.vue')).toThrow(
      /special_organizations\.weave\.mjs/,
    )
  })

  it('names BOTH manifests in a cross-addon overlap conflict', () => {
    const plugin = addonWeavePlugin([
      {
        target: 'CommonExample.vue',
        manifest: 'app/frontend/shared/addons/addon_a/addon_a.weave.mjs',
        template: [{ match: { component: 'CommonAvatar' }, addAttribute: 'data-a' }],
      },
      {
        target: 'CommonExample.vue',
        manifest: 'app/frontend/shared/addons/addon_b/addon_b.weave.mjs',
        template: [{ match: { component: 'CommonAvatar' }, replace: '<X />' }],
      },
    ] as unknown as Parameters<typeof addonWeavePlugin>[0])
    expect(() => plugin.transform(SFC, '/abs/CommonExample.vue')).toThrow(/addon_a\.weave\.mjs/)
    expect(() => plugin.transform(SFC, '/abs/CommonExample.vue')).toThrow(/addon_b\.weave\.mjs/)
  })

  it('omits the manifest pointer for hand-built rules that carry none', () => {
    // weaveSource rules (unit-test / programmatic) have no manifest — the pointer
    // must simply be absent, never the string "undefined".
    expect(() =>
      weave({ template: [{ match: { component: 'DoesNotExist' }, insertBefore: '<X />' }] }),
    ).toThrow(/^(?!.*undefined).*no element matched/s)
  })
})
