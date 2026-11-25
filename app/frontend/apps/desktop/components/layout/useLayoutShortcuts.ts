// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick } from 'vue'
import { useRouter } from 'vue-router'

import { useKeyboardShortcut } from '#shared/composables/useKeyboardShortcut/useKeyboardShortcut.ts'
import emitter from '#shared/utils/emitter.ts'

import { toggleKeyboardShortcutsDialog } from '#desktop/components/KeyboardShortcutsDialog/useKeyboardShortcutsDialog.ts'
import ticketCreateMenuItem from '#desktop/components/layout/LayoutSidebar/LeftSidebar/MenuContainer/AddMenu/plugins/ticket-create.ts'
import { SidebarName } from '#desktop/components/layout/types.ts'
import { useSidebarDisplay } from '#desktop/components/layout/useSidebarDisplay.ts'
import { useThemeStore } from '#desktop/stores/theme.ts'

const outsideInputs = { onlyOutsideInputs: true }

/**
 * The navigation and appearance shortcuts available on every page of the desktop layout. Each
 *   one takes the path the corresponding mouse action takes.
 */
export const useLayoutShortcuts = () => {
  const router = useRouter()

  const { toggleSidebar } = useSidebarDisplay(SidebarName.Primary)

  // Builds without the dashboard route start on the root path.
  useKeyboardShortcut(
    'dashboard',
    () => router.push(router.hasRoute('Dashboard') ? { name: 'Dashboard' } : '/'),
    outsideInputs,
  )

  useKeyboardShortcut('overviews', () => router.push({ name: 'TicketOverview' }), outsideInputs)

  useKeyboardShortcut(
    'new-ticket',
    () => router.push(ticketCreateMenuItem.link as string),
    outsideInputs,
  )

  // The search field is not rendered while the sidebar is collapsed.
  useKeyboardShortcut(
    'search',
    () => {
      toggleSidebar(false)
      nextTick(() => emitter.emit('focus-quick-search-field'))
    },
    outsideInputs,
  )

  useKeyboardShortcut('list-of-shortcuts', toggleKeyboardShortcutsDialog, outsideInputs)

  useKeyboardShortcut('logout', () => router.push('/logout'), outsideInputs)

  const { flipTheme } = useThemeStore()

  useKeyboardShortcut('toggle-dark-mode', flipTheme, outsideInputs)
}
