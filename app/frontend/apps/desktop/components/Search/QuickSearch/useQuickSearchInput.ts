// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick } from 'vue'

import emitter from '#shared/utils/emitter.ts'

import { SidebarName } from '#desktop/components/layout/types.ts'
import { useSidebarDisplay } from '#desktop/components/layout/useSidebarDisplay.ts'

export const useQuickSearchInput = () => {
  const { toggleSidebar } = useSidebarDisplay(SidebarName.Primary)

  const resetQuickSearchInputField = () => {
    emitter.emit('reset-quick-search-field')
  }

  // The input is not rendered while the primary sidebar is collapsed, so expand it first.
  const openQuickSearchWith = (search: string) => {
    toggleSidebar(false)
    nextTick(() => emitter.emit('set-quick-search-field', search))
  }

  return {
    resetQuickSearchInputField,
    openQuickSearchWith,
  }
}
