// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick } from 'vue'

import type { RegistryKeyboardShortcutKey } from '#shared/composables/useKeyboardShortcut/types.ts'
import { useKeyboardShortcut } from '#shared/composables/useKeyboardShortcut/useKeyboardShortcut.ts'
import emitter from '#shared/utils/emitter.ts'

/**
 * Toggles a popover of the main sidebar by a shortcut. An active quick search hides the sidebar
 *   buttons the popovers are anchored to, so it is closed first, as in the old desktop view.
 */
export const useSidebarPopoverShortcut = (key: RegistryKeyboardShortcutKey, toggle: () => void) =>
  useKeyboardShortcut(
    key,
    () => {
      emitter.emit('reset-quick-search-field')
      nextTick(toggle)
    },
    { onlyOutsideInputs: true },
  )
