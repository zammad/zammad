// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { toValue, type App } from 'vue'

import { KEYBOARD_SHORTCUT_REACH_GUARD } from '#shared/composables/useKeyboardShortcut/keyboardShortcutReach.ts'
import type {
  KeyboardShortcutReach,
  KeyboardShortcutReachGuard,
  RegistryKeyboardShortcutKey,
} from '#shared/composables/useKeyboardShortcut/types.ts'

import { closeOpenPopovers } from '#desktop/components/CommonPopover/usePopoverInstances.ts'
import {
  closeKeyboardShortcutsDialog,
  KEYBOARD_SHORTCUTS_DIALOG_NAME,
} from '#desktop/components/KeyboardShortcutsDialog/useKeyboardShortcutsDialog.ts'
import { useOverlayCoverage } from '#desktop/composables/useOverlayCoverage.ts'

// The list of shortcuts is a reference, not a task: it gives way to the navigation.
const isListOfShortcuts = (id: string) => id === `dialog-${KEYBOARD_SHORTCUTS_DIALOG_NAME}`

// These toggle a popover of their own, which closing all popovers first would reopen.
const POPOVER_TOGGLES = new Set<RegistryKeyboardShortcutKey>(['user-menu', 'notifications'])

/**
 * A shortcut reaches only what the mouse reaches: the backdrop of a tab's dialog or side panel
 *   covers the page and leaves the navigation of the sidebar free, a full-screen one covers both.
 */
export const keyboardShortcutReachGuard = {
  isReachable: (reach: KeyboardShortcutReach) => {
    const { shownOverlays, isPageCovered } = useOverlayCoverage()

    switch (reach) {
      case 'application':
        return !shownOverlays.value.some(
          (overlay) => toValue(overlay.coversApplication) && !isListOfShortcuts(overlay.id),
        )
      case 'page':
        return !isPageCovered.value
      case 'focus': {
        const topmost = shownOverlays.value.at(-1)
        if (!topmost) return true

        return !!toValue(topmost.element)?.contains(document.activeElement)
      }
      default:
        return true
    }
  },

  // Like a click, which closes the popover it lands outside of.
  beforeRun: (key: RegistryKeyboardShortcutKey, reach: KeyboardShortcutReach) => {
    if (reach !== 'application' && reach !== 'page') return

    if (!POPOVER_TOGGLES.has(key)) closeOpenPopovers()

    if (reach === 'application' && key !== 'list-of-shortcuts')
      return closeKeyboardShortcutsDialog()
  },
} satisfies KeyboardShortcutReachGuard

export const initializeKeyboardShortcutReach = (app: App) => {
  app.provide(KEYBOARD_SHORTCUT_REACH_GUARD, keyboardShortcutReachGuard)
}
