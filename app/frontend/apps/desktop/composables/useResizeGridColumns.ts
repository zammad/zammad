// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref, computed, type Ref } from 'vue'
import { useLocalStorage, useWindowSize } from '@vueuse/core'

// :TODO - Move to a global config file or something
export const DEFAULT_SIDEBAR_WIDTH = 260
export const MINIMUM_SIDEBAR_WIDTH = 200
export const SIDEBAR_COLLAPSED_WIDTH = 48
export const useResizeGridColumns = (storageKey?: string) => {
  const isSidebarCollapsed = ref(false)

  let sidebarLocalStorage: Ref<number>
  if (storageKey) {
    sidebarLocalStorage = useLocalStorage(
      `${storageKey}-sidebar-width`,
      DEFAULT_SIDEBAR_WIDTH,
    )
  } else {
    sidebarLocalStorage = ref(DEFAULT_SIDEBAR_WIDTH)
  }

  const { width: screenWidth } = useWindowSize()

  const gridColumns = computed(() => {
    const sidebarWidth = isSidebarCollapsed.value
      ? SIDEBAR_COLLAPSED_WIDTH
      : sidebarLocalStorage.value

    return {
      gridTemplateColumns: `${sidebarWidth}px 1fr`,
    }
  })

  const resizeSidebar = (sidebarWidth: number) => {
    const maxWidth = screenWidth.value / 3

    if (sidebarWidth <= MINIMUM_SIDEBAR_WIDTH || sidebarWidth >= maxWidth)
      return

    sidebarLocalStorage.value = sidebarWidth
  }

  const collapseSidebar = () => {
    isSidebarCollapsed.value = true
  }

  const expandSidebar = () => {
    isSidebarCollapsed.value = false
  }

  const resetSidebarWidth = () => {
    sidebarLocalStorage.value = DEFAULT_SIDEBAR_WIDTH
  }

  return {
    gridColumns,
    isSidebarCollapsed,
    resizeSidebar,
    collapseSidebar,
    expandSidebar,
    resetSidebarWidth,
  }
}
