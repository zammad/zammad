// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

/**
 * Build-time skin-marker plugin.
 *
 * Auto-stamps `data-zammad-target="<value>"` onto the NATIVE top-level root
 * element(s) of every SFC, before the Vue compiler runs (`enforce: 'pre'`). This
 * gives customer custom CSS — and addon weave matchers, and tests — a stable,
 * predictable hook on every component without anyone hand-placing it. Like the
 * addon weave, it edits SFC *source*, not a vnode tree or a vdom-only
 * `nodeTransform`, so it survives the planned Vapor migration.
 *
 * The value is the component name (the SFC file basename), e.g. `CommonButton`.
 * When that name is ambiguous — the same file name is used by another component
 * that can render in the same app — it is qualified with the component's nearest
 * PascalCase ancestor folder instead (`UserTaskbarTabs/Organization` vs
 * `QuickSearch/Organization`). No hardcoded folder list: component/feature folders
 * are PascalCase and structural ones (components/views/entities/…) are lowercase,
 * so the qualifier falls out of the convention. The ambiguous set is discovered at
 * build time (see ./discoverClashes.mjs).
 *
 * Only NATIVE-element roots are stamped. A component / `<slot>` / `<template>` /
 * `<component :is>` root is skipped: a marker on a component root would fall
 * through onto the child's rendered DOM node (Vue attribute fallthrough, no
 * `inheritAttrs: false`) and collapse the parent's and child's identity onto one
 * element. See ./README.md.
 */

import { parse } from 'vue/compiler-sfc'

// Vue compiler NodeTypes / ElementTypes (stable enums).
const NODE_TYPE_ELEMENT = 1
const NODE_TYPE_ATTRIBUTE = 6
const ELEMENT_TYPE_ELEMENT = 0 // native element (not component / slot / template)

/** The auto-stamped, customer-facing CSS contract attribute. */
export const MARKER_ATTRIBUTE = 'data-zammad-target'

const bareName = (file) => file.slice(file.lastIndexOf('/') + 1, -'.vue'.length)

/**
 * Qualify a name with its nearest PascalCase ancestor folder. Component/feature
 * folders are PascalCase; structural/route folders (components, views, entities,
 * pages, …) are lowercase and are walked past — so no hardcoded folder list is
 * needed. Falls back to the bare name when there is no PascalCase ancestor.
 */
export const qualifiedName = (file) => {
  const parts = file.split('/')
  const name = bareName(file)
  for (let i = parts.length - 2; i >= 0; i -= 1) {
    if (parts[i] === name) continue
    if (/^[A-Z]/.test(parts[i])) return `${parts[i]}/${name}`
  }
  return name
}

/**
 * The marker value: the plain component name, or — when that name is ambiguous
 * (shared by another component that can render in the same app) — the qualified
 * name. Centralized so the emitted value stays consistent for CSS/tests.
 */
export const markerValue = (file, ambiguousNames) =>
  ambiguousNames.has(bareName(file)) ? qualifiedName(file) : bareName(file)

/**
 * From a list of SFC file paths, the set of file names used by more than one
 * component that can render in the SAME app (a shared component plus an app one,
 * or two within one app). Desktop/mobile mirror pairs are separate bundles and do
 * not count.
 */
export const findAmbiguousNames = (files) => {
  // Which app bundle a file belongs to. Anything outside desktop/mobile/shared
  // (e.g. test-support components under tests/) is not part of any bundle and can
  // never clash at runtime, so it is ignored below.
  const scopeOf = (file) => {
    if (file.includes('apps/desktop/')) return 'desktop'
    if (file.includes('apps/mobile/')) return 'mobile'
    if (file.includes('shared/')) return 'shared'
    return 'other'
  }
  const byName = new Map()
  for (const file of files) {
    const name = bareName(file)
    if (!byName.has(name)) byName.set(name, [])
    byName.get(name).push(scopeOf(file))
  }
  const ambiguous = new Set()
  for (const [name, scopes] of byName) {
    const shared = scopes.filter((s) => s === 'shared').length
    const desktop = scopes.filter((s) => s === 'desktop').length
    const mobile = scopes.filter((s) => s === 'mobile').length
    // A shared component co-renders in every app (so it clashes with any app copy,
    // or another shared one); two in one app collide directly. Non-bundle files
    // ('other') are excluded — they never render, so they can't force a clash.
    if ((shared >= 1 && shared + desktop + mobile >= 2) || desktop >= 2 || mobile >= 2) {
      ambiguous.add(name)
    }
  }
  return ambiguous
}

const alreadyMarked = (node) =>
  node.props.some((prop) => prop.type === NODE_TYPE_ATTRIBUTE && prop.name === MARKER_ATTRIBUTE)

// One insert per NATIVE top-level root. Components, `<slot>`, `<template>` and
// `<component :is>` roots have tagType !== native and are skipped (see header).
const markerEdits = (descriptor, value) => {
  const edits = []
  for (const node of descriptor.template?.ast?.children ?? []) {
    if (node.type !== NODE_TYPE_ELEMENT || node.tagType !== ELEMENT_TYPE_ELEMENT) continue
    if (alreadyMarked(node)) continue
    const tagEnd = node.loc.start.offset + 1 + node.tag.length
    edits.push({ at: tagEnd, text: ` ${MARKER_ATTRIBUTE}="${value}"` })
  }
  return edits
}

/** Stamp one SFC's source; returns it unchanged when there is nothing to mark. */
export const stampSource = (code, id, ambiguousNames = new Set()) => {
  const file = id.split('?')[0]
  const { descriptor, errors } = parse(code, { filename: file })
  if (errors.length) {
    throw new Error(`[skin-marker] ${file}: failed to parse SFC: ${errors[0].message}`)
  }
  // Apply right-to-left so earlier offsets stay valid (roots are disjoint anyway).
  return markerEdits(descriptor, markerValue(file, ambiguousNames))
    .sort((a, b) => b.at - a.at)
    .reduce((out, edit) => `${out.slice(0, edit.at)}${edit.text}${out.slice(edit.at)}`, code)
}

export default function skinMarkerPlugin(ambiguousNames = new Set()) {
  return {
    name: 'zammad:skin-marker',
    enforce: 'pre',
    transform(code, id) {
      const file = id.split('?')[0]
      // Only the main SFC request — a query means a sub-block (template/script).
      // Never third-party SFCs.
      if (!file.endsWith('.vue') || id.includes('?') || file.includes('/node_modules/')) {
        return null
      }
      const out = stampSource(code, file, ambiguousNames)
      return out === code ? null : { code: out, map: null }
    },
  }
}
