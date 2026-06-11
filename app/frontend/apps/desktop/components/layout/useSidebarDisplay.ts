// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { isEqual } from 'lodash-es'
import { computed, toRef } from 'vue'

import { useSidebarDisplayStore } from '#desktop/components/layout/stores/sidebarDisplay.ts'

import { SidebarName, type ToggleOptions } from './types.ts'

export const useSidebarDisplay = (name: SidebarName) => {
  const store = useSidebarDisplayStore()
  const currentCollapsed = toRef(store, 'currentCollapsed')

  return {
    isSidebarCollapsed: computed<boolean>((previousCollapsed) => {
      const updatedCollapsed = currentCollapsed.value[name]

      if (previousCollapsed && isEqual(previousCollapsed, updatedCollapsed))
        return previousCollapsed

      return updatedCollapsed
    }),
    toggleSidebar: (value?: boolean, options?: ToggleOptions) =>
      store.toggleSidebar(name, value, options),
  }
}
