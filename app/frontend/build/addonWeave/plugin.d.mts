// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

/** Semantic matcher for a template element. At least one field is required. */
export interface AddonWeaveMatch {
  /** Component tag, case-sensitive (e.g. `CommonAvatar`). */
  component?: string
  /** Native element tag (e.g. `div`). */
  element?: string
  /** Any tag (component or element). */
  tag?: string
  /** Static `id` attribute value. */
  id?: string
  /** Static `data-test-id` attribute value. */
  testId?: string
  /** A token in the element's static `class` attribute. */
  hasClass?: string
  /** A static attribute by name, optionally with a specific value. */
  attr?: { name: string; value?: string }
  /** Restrict to a top-level (template root) element. */
  root?: boolean
}

export interface AddonWeaveTemplateOp {
  match: AddonWeaveMatch
  /** Markup inserted as a sibling before the matched element. */
  insertBefore?: string
  /** Markup inserted as a sibling after the matched element. */
  insertAfter?: string
  /** Markup inserted as the first child of the matched element. */
  prepend?: string
  /** Markup inserted as the last child of the matched element. */
  append?: string
  /** Attribute added to the matched element's opening tag (e.g. `:class="x"`). */
  addAttribute?: string
  /** Override an existing attribute (`name` or `:name`) with a new value. */
  setAttribute?: { name: string; value: string }
  /** Remove an existing attribute (`name` or `:name`). */
  removeAttribute?: string
  /** Wrap the matched element in `open`…element…`close`. */
  wrap?: { open: string; close: string }
  /** Replace the whole matched element (incl. children) with this markup. */
  replace?: string
  /** Remove the whole matched element. */
  remove?: boolean
}

export interface AddonWeaveRuleBody {
  /** Code appended to the SFC's `<script setup>` block. */
  scriptSetup?: string
  /** Template edits; each op's `match` must hit ≥1 element or the build fails. */
  template?: AddonWeaveTemplateOp[]
}

export interface AddonWeaveRule extends AddonWeaveRuleBody {
  /** Core SFC this rule applies to, matched by `file.endsWith(target)`. */
  target: string
}

interface AddonWeavePlugin {
  name: string
  enforce: 'pre'
  transform(code: string, id: string): { code: string; map: null } | null
}

export function weaveSource(code: string, rule: AddonWeaveRuleBody, id: string): string

export default function addonWeavePlugin(rules?: AddonWeaveRule[]): AddonWeavePlugin
