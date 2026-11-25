// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useEventListener } from '@vueuse/core'
import { effectScope, toValue } from 'vue'

import { useKeyboardShortcutEventBus } from '#shared/composables/useKeyboardEventBus/useKeyboardEventBus.ts'
import getUuid from '#shared/utils/getUuid.ts'

import {
  forgetSelectionOnShift,
  hasSelection,
  isTextEntry,
  trackSelectionOnShift,
} from './guards.ts'
import {
  getKeyboardShortcut,
  getKeyboardShortcutCombinations,
  isKeyboardShortcutAvailable,
} from './keyboardShortcutCatalogue.ts'
import { useKeyboardShortcutsEnabled } from './useKeyboardShortcutsEnabled.ts'

import type {
  KeyboardShortcutHandler,
  KeyboardShortcutOptions,
  RegistryKeyboardShortcutKey,
} from './types.ts'

export const REPEATED_PRESS_WINDOW = 5500

let lastPress: { combination: string; time: number; count: number } | undefined

const countPress = (combination: string) => {
  const now = Date.now()

  if (
    lastPress &&
    lastPress.combination === combination &&
    lastPress.time + REPEATED_PRESS_WINDOW > now
  ) {
    lastPress = { combination, time: now, count: lastPress.count + 1 }
  } else {
    lastPress = { combination, time: now, count: 1 }
  }

  return lastPress.count
}

const resetPressOnEscape = (event: KeyboardEvent) => {
  if (event.key === 'Escape') lastPress = undefined
}

let areGuardListenersActive = false

const activateGuardListeners = () => {
  if (areGuardListenersActive) return
  areGuardListenersActive = true

  effectScope(true).run(() => {
    useEventListener(window, 'keydown', trackSelectionOnShift)
    useEventListener(window, 'keyup', trackSelectionOnShift)
    useEventListener(window, 'blur', forgetSelectionOnShift)
    useEventListener(window, 'keyup', resetPressOnEscape)
  })
}

/**
 * Registers a keyboard shortcut of the desktop view on the combinations of its catalogue entry,
 *   for the users the entry names, governed by the shortcut switch the old desktop view keeps in
 *   local storage. Not meant for the editor's own text-editing keys.
 */
export const useKeyboardShortcut = (
  key: RegistryKeyboardShortcutKey,
  handler: KeyboardShortcutHandler,
  options: KeyboardShortcutOptions = {},
) => {
  const { isEnabled } = useKeyboardShortcutsEnabled()

  activateGuardListeners()

  const entry = getKeyboardShortcut(key)

  const isActive = () => {
    if (!isEnabled.value) return false
    if (!isKeyboardShortcutAvailable(entry)) return false
    if (options.onlyOutsideInputs && isTextEntry()) return false
    if (options.onlyWithoutSelection && hasSelection()) return false
    if (options.enabled !== undefined && !toValue(options.enabled)) return false

    return true
  }

  getKeyboardShortcutCombinations(key).forEach((combination) => {
    const { shortcutKey } = useKeyboardShortcutEventBus(combination, {
      key: getUuid(),
      isActive,
      handler: (event) => handler({ event, count: countPress(shortcutKey) }),
    })
  })

  return { isEnabled }
}
