// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { isMac } from '#shared/utils/browser.ts'

const MODIFIERS = ['control', 'alt', 'shift', 'meta'] as const

const KEY_ALIASES: Record<string, string> = {
  ctrl: 'control',
  cmd: 'meta',
  command: 'meta',
  option: 'alt',
  esc: 'escape',
  return: 'enter',
  up: 'arrowup',
  down: 'arrowdown',
  left: 'arrowleft',
  right: 'arrowright',
  ' ': 'space',
}

const isModifier = (key: string) => (MODIFIERS as readonly string[]).includes(key)

const resolveAlias = (key: string) => {
  // `mod` is the old view's magic key: `cmd` on macOS, `ctrl` everywhere else.
  if (key === 'mod') return isMac() ? 'meta' : 'control'

  return KEY_ALIASES[key] ?? key
}

// A typed symbol already carries its shift state (`?` is `shift`+`/` on one layout and
//   something else on the next), so shift only counts for letters and named keys.
const isShiftSignificant = (key: string) => key.length > 1 || /^[a-z]$/.test(key)

const buildCombination = (modifiers: Set<string>, key: string) => {
  if (!isShiftSignificant(key)) modifiers.delete('shift')

  return [...MODIFIERS.filter((modifier) => modifiers.has(modifier)), key].join('+')
}

/**
 * Brings a combination like `ctrl+Enter`, `mod+enter` or `shift+c` into the canonical form the
 *   keyboard event bus matches on: lowercase, modifiers in a fixed order, the key last.
 */
export const normalizeKeyboardCombination = (combination: string) => {
  const parts = combination
    .toLowerCase()
    .split('+')
    .map((part) => resolveAlias(part.trim()))

  const key = parts.pop()

  if (!key || isModifier(key) || !parts.every(isModifier))
    throw new Error(`Invalid keyboard combination: "${combination}"`)

  return buildCombination(new Set(parts), key)
}

const physicalKeyName = (event: KeyboardEvent) => {
  const physical = event.code.match(/^(?:Key([A-Z])|Digit(\d))$/)

  return physical ? (physical[1] ?? physical[2]).toLowerCase() : null
}

const isNonLatinLetter = (key: string) => /^\p{L}$/u.test(key) && !/^[a-z]$/.test(key)

const eventKeyName = (event: KeyboardEvent) => {
  const key = event.key.toLowerCase()

  // With `option` held, macOS types a substitute character (`option`+`c` is `ç`), and a
  //   non-Latin layout types its own letter (`р` on the H key of a Russian one). The old view
  //   matched these by key code, i.e. by the Latin letter of the physical key.
  if (event.altKey || (isNonLatinLetter(key) && event.code.startsWith('Key'))) {
    const physical = physicalKeyName(event)
    if (physical) return physical
  }

  return resolveAlias(key)
}

/**
 * The canonical combination of a key press, or `null` for a press of a modifier key alone.
 */
export const keyboardEventCombination = (event: KeyboardEvent) => {
  if (!event.key) return null

  const key = eventKeyName(event)

  if (isModifier(key)) return null

  const modifiers = new Set<string>()

  if (event.ctrlKey) modifiers.add('control')
  if (event.altKey) modifiers.add('alt')
  if (event.shiftKey) modifiers.add('shift')
  if (event.metaKey) modifiers.add('meta')

  return buildCombination(modifiers, key)
}
