// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import type { TicketInformation } from '#desktop/entities/ticket/types.ts'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

import type { MenuStateUpdate } from './types'

export const items: MenuItem[] = [
  { label: __('Yellow'), key: 'highlight-yellow' },
  { label: __('Green'), key: 'highlight-green' },
  { label: __('Blue'), key: 'highlight-blue' },
  { label: __('Pink'), key: 'highlight-pink' },
  { label: __('Purple'), key: 'highlight-purple' },
  {
    separatorTop: true,
    icon: 'eraser-fill',
    key: 'remove-highlight',
    label: __('Remove highlight'),
  },
]
const updateItem = (highlightMenu: TicketInformation['highlightMenu'], updates: MenuStateUpdate) =>
  Object.assign(highlightMenu, updates)

export const useHighlightMenuState = () => {
  const { highlightMenu } = useTicketInformation()

  const activeMenuItem = computed<MenuItem>(() => highlightMenu.activeMenuItem)
  const isActive = computed<boolean>(() => highlightMenu.isActive)
  const isEraserActive = computed<boolean>(
    () => activeMenuItem.value?.key === 'remove-highlight' || highlightMenu.isEraserActive,
  )

  const setActive = (active?: boolean) =>
    updateItem(highlightMenu, { isActive: active ?? !highlightMenu.isActive })

  const selectItem = (item: MenuItem) =>
    updateItem(highlightMenu, {
      activeMenuItem: item,
      isEraserActive: item.key === 'remove-highlight',
    })

  const reset = () =>
    updateItem(highlightMenu, {
      isActive: false,
    })

  return {
    items,
    activeMenuItem,
    isActive,
    isEraserActive,
    setActive,
    selectItem,
    reset,
  }
}
