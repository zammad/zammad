// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

/**
 * Build-time addon weave plugin (AST-based).
 *
 * The Vapor-safe alternative to runtime monkey-patching. An addon declares rules
 * (discovered from its `*.weave.mjs` manifests); this Vite plugin rewrites the
 * targeted core SFC's SOURCE TEXT *before* the Vue compiler runs (`enforce:
 * 'pre'`). Because the output is plain SFC source — not a vnode tree at runtime,
 * and not a vdom-only `nodeTransform` — whatever compiler runs next compiles it
 * normally: the vdom compiler today, and the Vapor compiler unchanged tomorrow.
 *
 * Matching is SEMANTIC, on the parsed template AST (not fragile substring
 * matching), so it survives core whitespace/formatting changes. It FAILS THE
 * BUILD LOUDLY when a matcher hits nothing, a manifest is malformed, or edits
 * overlap — better a failed install build than an addon feature that silently
 * vanishes. Core files on disk are never modified.
 *
 * See ./README.md for the rule reference (matchers + actions) and examples.
 */

import { parse } from 'vue/compiler-sfc'

// Vue compiler NodeTypes (stable enum). We act on elements + static/bound attrs.
const NODE_TYPE_ELEMENT = 1
const NODE_TYPE_ATTRIBUTE = 6
const NODE_TYPE_DIRECTIVE = 7
// Vue ElementTypes (stable enum): native element vs component, so `element` and
// `component` matchers stay distinct.
const ELEMENT_TYPE_ELEMENT = 0
const ELEMENT_TYPE_COMPONENT = 1

const MATCH_KEYS = ['component', 'element', 'tag', 'id', 'testId', 'hasClass', 'attr', 'root']

// Additive actions compose on one element; destructive actions must stand alone.
const ADDITIVE_ACTIONS = [
  'insertBefore',
  'insertAfter',
  'prepend',
  'append',
  'addAttribute',
  'setAttribute',
  'removeAttribute',
  'wrap',
]
const DESTRUCTIVE_ACTIONS = ['replace', 'remove']

// The `*.weave.mjs` file this rule came from — stamped on by discoverRules.mjs.
// Appended to every rule error as a "fix this file" pointer, so a failure names
// the addon manifest to edit, not just the core SFC it failed to weave into.
// Empty for hand-built rules (e.g. unit tests) that carry no manifest.
const ruleSource = (rule) => (rule.manifest ? `\n  → fix the weave rule in: ${rule.manifest}` : '')

const staticAttr = (node, name) =>
  node.props.find((prop) => prop.type === NODE_TYPE_ATTRIBUTE && prop.name === name)

// Find a static attribute (`name`) or a bound directive (`:name`) on a node.
const findProp = (node, name) => {
  if (name.startsWith(':')) {
    const arg = name.slice(1)
    return node.props.find(
      (prop) =>
        prop.type === NODE_TYPE_DIRECTIVE && prop.name === 'bind' && prop.arg?.content === arg,
    )
  }
  return staticAttr(node, name)
}

const matchesNode = (node, match) => {
  // Every provided field must hold (AND). `component` and `element` also pin the
  // node kind, so a component never matches `element` and a native element never
  // matches `component` — a wrong-kind manifest fails loudly instead of weaving
  // the wrong node.
  if (match.component != null) {
    if (node.tag !== match.component || node.tagType !== ELEMENT_TYPE_COMPONENT) return false
  }
  if (match.element != null) {
    if (node.tag !== match.element || node.tagType !== ELEMENT_TYPE_ELEMENT) return false
  }
  if (match.tag != null && node.tag !== match.tag) return false
  if (match.id != null && staticAttr(node, 'id')?.value?.content !== match.id) return false
  if (match.testId != null && staticAttr(node, 'data-test-id')?.value?.content !== match.testId) {
    return false
  }
  if (match.hasClass != null) {
    const classes = staticAttr(node, 'class')?.value?.content?.split(/\s+/) ?? []
    if (!classes.includes(match.hasClass)) return false
  }
  if (match.attr != null) {
    const attr = staticAttr(node, match.attr.name)
    if (!attr) return false
    if (match.attr.value != null && attr.value?.content !== match.attr.value) return false
  }
  return true
}

// Element nodes (with top-level depth flag) from the parsed template AST.
const collectElements = (root) => {
  const out = []
  const walk = (node, depth) => {
    if (node.type === NODE_TYPE_ELEMENT) out.push({ node, depth })
    for (const child of node.children ?? []) walk(child, depth + 1)
  }
  for (const child of root.children ?? []) walk(child, 0)
  return out
}

/**
 * Compute the source edits for one rule against an already-parsed descriptor.
 * Pure (no apply) so the plugin can gather edits across every matching rule and
 * conflict-check them together. Per-rule guards live here.
 */
const collectRuleEdits = (descriptor, rule, id) => {
  // Loud migration guard: reject the old string-splice format outright.
  if ('templateReplace' in rule || 'scriptSetupAppend' in rule) {
    throw new Error(
      `[addon-weave] ${id}: legacy rule format (templateReplace/scriptSetupAppend). ` +
        `Migrate to { template: [{ match, insertBefore/insertAfter/addAttribute/wrap/replace/remove }], scriptSetup }.` +
        ruleSource(rule),
    )
  }

  // Edits as { start, end, text }, offsets ABSOLUTE in the SFC source. A
  // zero-width insert has start === end; replace/remove span [start, end).
  const edits = []

  if (rule.scriptSetup) {
    if (!descriptor.scriptSetup) {
      throw new Error(
        `[addon-weave] ${id}: rule has scriptSetup but the SFC has no <script setup>.${ruleSource(rule)}`,
      )
    }
    const at = descriptor.scriptSetup.loc.end.offset
    edits.push({ start: at, end: at, text: `\n${rule.scriptSetup}\n` })
  }

  for (const op of rule.template ?? []) {
    if (!MATCH_KEYS.some((key) => op.match?.[key] != null)) {
      throw new Error(
        `[addon-weave] ${id}: template op has no usable match (${MATCH_KEYS.join('/')}).${ruleSource(rule)}`,
      )
    }
    if (!descriptor.template?.ast) {
      throw new Error(
        `[addon-weave] ${id}: rule has a template op but the SFC has no <template>.${ruleSource(rule)}`,
      )
    }

    const present = [...ADDITIVE_ACTIONS, ...DESTRUCTIVE_ACTIONS].filter((key) => op[key] != null)
    if (present.length === 0) {
      throw new Error(`[addon-weave] ${id}: template op has no action.${ruleSource(rule)}`)
    }
    const destructive = DESTRUCTIVE_ACTIONS.filter((key) => op[key] != null)
    if (destructive.length > 0 && present.length > 1) {
      throw new Error(
        `[addon-weave] ${id}: '${destructive[0]}' must be the only action on its op.${ruleSource(rule)}`,
      )
    }

    const matched = collectElements(descriptor.template.ast).filter(
      ({ node, depth }) => matchesNode(node, op.match) && (!op.match.root || depth === 0),
    )
    if (matched.length === 0) {
      throw new Error(
        `[addon-weave] ${id}: no element matched ${JSON.stringify(op.match)} — cannot weave.${ruleSource(rule)}`,
      )
    }

    for (const { node } of matched) {
      const start = node.loc.start.offset
      const end = node.loc.end.offset
      const tagEnd = start + 1 + node.tag.length

      // `order` breaks ties at a shared offset (lower = earlier in the output).
      // At the start offset, an outer sibling (insertBefore, order 0) precedes the
      // wrapper open (order 1); at the end offset, the wrapper close (order 0)
      // precedes the outer sibling (insertAfter, order 1) — so wrap nests inside.
      if (op.insertBefore) edits.push({ start, end: start, text: `${op.insertBefore}\n`, order: 0 })
      if (op.insertAfter) edits.push({ start: end, end, text: `\n${op.insertAfter}`, order: 1 })
      if (op.prepend || op.append) {
        if (!node.children?.length) {
          throw new Error(
            `[addon-weave] ${id}: append/prepend needs a non-empty element; <${node.tag}> has no children.${ruleSource(rule)}`,
          )
        }
        if (op.prepend) {
          const at = node.children[0].loc.start.offset
          edits.push({ start: at, end: at, text: op.prepend })
        }
        if (op.append) {
          const at = node.children[node.children.length - 1].loc.end.offset
          edits.push({ start: at, end: at, text: op.append })
        }
      }
      if (op.addAttribute) edits.push({ start: tagEnd, end: tagEnd, text: ` ${op.addAttribute}` })
      if (op.setAttribute) {
        const prop = findProp(node, op.setAttribute.name)
        if (!prop) {
          throw new Error(
            `[addon-weave] ${id}: setAttribute target not found: ${op.setAttribute.name} on <${node.tag}>.${ruleSource(rule)}`,
          )
        }
        const text = `${op.setAttribute.name}="${op.setAttribute.value}"`
        edits.push({ start: prop.loc.start.offset, end: prop.loc.end.offset, text })
      }
      if (op.removeAttribute) {
        const prop = findProp(node, op.removeAttribute)
        if (!prop) {
          throw new Error(
            `[addon-weave] ${id}: removeAttribute target not found: ${op.removeAttribute} on <${node.tag}>.${ruleSource(rule)}`,
          )
        }
        edits.push({ start: prop.loc.start.offset, end: prop.loc.end.offset, text: '' })
      }
      if (op.wrap) {
        if (!op.wrap.open || !op.wrap.close) {
          throw new Error(
            `[addon-weave] ${id}: wrap needs both { open, close }.${ruleSource(rule)}`,
          )
        }
        edits.push({ start, end: start, text: op.wrap.open, order: 1 })
        edits.push({ start: end, end, text: op.wrap.close, order: 0 })
      }
      if (op.replace) edits.push({ start, end, text: op.replace })
      if (op.remove) edits.push({ start, end, text: '' })
    }
  }

  // Carry the source manifest on every edit so a cross-rule overlap can name both
  // colliding addons, not just the core SFC.
  for (const edit of edits) edit.manifest = rule.manifest
  return edits
}

/** Apply edits to the source, rejecting any that target overlapping ranges. */
const applyEdits = (code, rawEdits, id) => {
  if (rawEdits.length === 0) return code

  // Tag each edit with its collection order; ties at a shared offset fall back to
  // it so same-kind edits keep their collection order in the output.
  const edits = rawEdits.map((edit, seq) => ({ ...edit, seq }))

  // Reject overlapping edits — checked across ALL rules together, so a later
  // addon's `replace`/`remove` can't silently discard an earlier addon's edit on
  // the same element.
  const ascending = [...edits].sort((a, b) => a.start - b.start || a.end - b.end)
  let lastEnd = -1
  let lastEdit = null
  for (const edit of ascending) {
    if (edit.start < lastEnd) {
      // Name both weave files involved so the collision is fixable without
      // guessing which two addons overlap on this element.
      const files = [...new Set([lastEdit?.manifest, edit.manifest].filter(Boolean))]
      const from = files.length
        ? `\n  → conflict between weave rules in: ${files.join(' and ')}`
        : ''
      throw new Error(
        `[addon-weave] ${id}: conflicting weave edits target overlapping source.${from}`,
      )
    }
    if (edit.end > lastEnd) {
      lastEnd = edit.end
      lastEdit = edit
    }
  }

  // Apply right-to-left so earlier offsets stay valid. At a shared offset the sort
  // is the REVERSE of the desired output order (a later-applied insert lands
  // before an earlier one), hence descending `end`, `order`, then `seq`.
  return [...edits]
    .sort(
      (a, b) =>
        b.start - a.start || b.end - a.end || (b.order ?? 0) - (a.order ?? 0) || b.seq - a.seq,
    )
    .reduce((out, edit) => `${out.slice(0, edit.start)}${edit.text}${out.slice(edit.end)}`, code)
}

/**
 * Apply a single rule to one SFC's source, returning the rewritten source.
 * Exported for unit testing; the plugin gathers edits across all matching rules.
 */
export const weaveSource = (code, rule, id) => {
  const { descriptor, errors } = parse(code, { filename: id })
  if (errors.length) {
    throw new Error(`[addon-weave] ${id}: failed to parse SFC: ${errors[0].message}`)
  }
  return applyEdits(code, collectRuleEdits(descriptor, rule, id), id)
}

export default function addonWeavePlugin(rules = []) {
  // No addons → no work. Omit the transform hook entirely so the bundler never
  // calls into this plugin (and never marshals every module's source across the
  // boundary just to skip it) — that overhead otherwise dominates plugin time on
  // addon-free builds, even though there is nothing to do.
  if (rules.length === 0) return { name: 'zammad:addon-weave' }

  return {
    name: 'zammad:addon-weave',
    enforce: 'pre',
    transform(code, id) {
      const file = id.split('?')[0]
      // Only the main SFC request; a query means a sub-block (template/script) — skip.
      if (!file.endsWith('.vue') || id.includes('?')) return null

      const matching = rules.filter((rule) => file.endsWith(rule.target))
      if (matching.length === 0) return null

      // Parse ONCE and gather every matching rule's edits against the same source,
      // so overlap detection spans all addons — a later rule cannot silently
      // discard an earlier one's edit on the same element.
      const { descriptor, errors } = parse(code, { filename: file })
      if (errors.length) {
        throw new Error(`[addon-weave] ${file}: failed to parse SFC: ${errors[0].message}`)
      }
      const edits = matching.flatMap((rule) => collectRuleEdits(descriptor, rule, file))
      const out = applyEdits(code, edits, file)
      return out === code ? null : { code: out, map: null }
    },
  }
}
