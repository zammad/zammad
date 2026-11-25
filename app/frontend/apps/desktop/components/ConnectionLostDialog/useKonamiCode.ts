// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useEventListener } from '@vueuse/core'
import { ref } from 'vue'

import { keyboardEventCombination } from '#shared/composables/useKeyboardEventBus/keyboardCombination.ts'
import { isTextEntry } from '#shared/composables/useKeyboardShortcut/guards.ts'

const KONAMI_SEQUENCE = [
  'arrowup',
  'arrowup',
  'arrowdown',
  'arrowdown',
  'arrowleft',
  'arrowright',
  'arrowleft',
  'arrowright',
  'b',
  'a',
]

const KONAMI_KEYS = new Set(KONAMI_SEQUENCE)

export const useKonamiCode = () => {
  const unlocked = ref(false)
  const recentKeys: string[] = []

  useEventListener(
    window,
    'keydown',
    (event: KeyboardEvent) => {
      const combination = keyboardEventCombination(event)
      if (!combination) return

      // Captured ahead of the shortcuts, which skip a handled key: the page behind the dialog must
      //   not act on these keys (`a` toggles the notifications, the arrows navigate articles).
      //   A text field keeps the focus behind the dialog, and there the keys type, not trigger.
      if (KONAMI_KEYS.has(combination) && !isTextEntry()) event.preventDefault()

      if (unlocked.value || event.repeat) return

      recentKeys.push(combination)
      if (recentKeys.length > KONAMI_SEQUENCE.length) recentKeys.shift()

      if (recentKeys.join() !== KONAMI_SEQUENCE.join()) return

      unlocked.value = true
    },
    { capture: true },
  )

  return { unlocked }
}
