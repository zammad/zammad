// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage, useWindowSize } from '@vueuse/core'
import { shallowRef, computed, type Ref } from 'vue'

export const DEFAULT_SIDEBAR_WIDTH = 260
export const MINIMUM_SIDEBAR_WIDTH = 200
export const SIDEBAR_COLLAPSED_WIDTH = 48

export const useResizeGridColumns = (storageKey?: string) => {
  const isSidebarCollapsed = shallowRef(false)

  let currentSidebarWidth: Ref<number>
  const storageId = `${storageKey}-sidebar-width`
  if (storageKey) {
    currentSidebarWidth = useLocalStorage(storageId, DEFAULT_SIDEBAR_WIDTH)
  } else {
    currentSidebarWidth = shallowRef(DEFAULT_SIDEBAR_WIDTH)
  }

  const { width: screenWidth } = useWindowSize()
  const maxWidth = computed(() => screenWidth.value / 3)

  const gridColumns = computed(() => {
    const width = isSidebarCollapsed.value
      ? SIDEBAR_COLLAPSED_WIDTH
      : currentSidebarWidth.value

    return {
      gridTemplateColumns: `${width}px 1fr`,
    }
  })

  const resizeSidebar = (width: number) => {
    if (width <= MINIMUM_SIDEBAR_WIDTH || width >= maxWidth.value) return

    currentSidebarWidth.value = width
  }

  const collapseSidebar = () => {
    isSidebarCollapsed.value = true
  }

  const expandSidebar = () => {
    isSidebarCollapsed.value = false
  }

  const resetSidebarWidth = () => {
    currentSidebarWidth.value = DEFAULT_SIDEBAR_WIDTH
  }

  return {
    currentSidebarWidth,
    maxSidebarWidth: maxWidth,
    minSidebarWidth: MINIMUM_SIDEBAR_WIDTH,
    gridColumns,
    isSidebarCollapsed,
    resizeSidebar,
    collapseSidebar,
    expandSidebar,
    resetSidebarWidth,
  }
}
