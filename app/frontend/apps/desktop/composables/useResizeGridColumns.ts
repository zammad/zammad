// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage, useWindowSize } from '@vueuse/core'
import { shallowRef, computed, type Ref } from 'vue'

import { SidebarPosition } from '#desktop/components/layout/types.ts'

export const DEFAULT_START_SIDEBAR_WIDTH = 260
export const DEFAULT_END_SIDEBAR_WIDTH = 360
export const MINIMUM_START_SIDEBAR_WIDTH = 200
export const MINIMUM_END_SIDEBAR_WIDTH = 300
export const SIDEBAR_COLLAPSED_WIDTH = 56

export const useResizeGridColumns = (
  storageKey?: string,
  position: SidebarPosition = SidebarPosition.Start,
) => {
  const defaultSidebarWidth =
    position === SidebarPosition.Start
      ? DEFAULT_START_SIDEBAR_WIDTH
      : DEFAULT_END_SIDEBAR_WIDTH

  const minSidebarWidth =
    position === SidebarPosition.Start
      ? MINIMUM_START_SIDEBAR_WIDTH
      : MINIMUM_END_SIDEBAR_WIDTH

  const isSidebarCollapsed = shallowRef(false)

  let currentSidebarWidth: Ref<number>

  const storageId = `${storageKey}-sidebar-width`

  if (storageKey) {
    currentSidebarWidth = useLocalStorage(storageId, defaultSidebarWidth)
  } else {
    currentSidebarWidth = shallowRef(defaultSidebarWidth)
  }

  const { width: screenWidth } = useWindowSize()
  const maxWidth = computed(() => screenWidth.value / 3)

  const gridColumns = computed(() => {
    const width = isSidebarCollapsed.value
      ? SIDEBAR_COLLAPSED_WIDTH
      : currentSidebarWidth.value

    if (position === SidebarPosition.End)
      return {
        gridTemplateColumns: `1fr ${width}px`,
      }

    return {
      gridTemplateColumns: `${width}px 1fr`,
    }
  })

  const resizeSidebar = (width: number) => {
    if (width <= minSidebarWidth || width >= maxWidth.value) return

    currentSidebarWidth.value = width
  }

  const collapseSidebar = () => {
    isSidebarCollapsed.value = true
  }

  const expandSidebar = () => {
    isSidebarCollapsed.value = false
  }

  const resetSidebarWidth = () => {
    currentSidebarWidth.value = defaultSidebarWidth
  }

  return {
    currentSidebarWidth,
    maxSidebarWidth: maxWidth,
    minSidebarWidth,
    gridColumns,
    isSidebarCollapsed,
    resizeSidebar,
    collapseSidebar,
    expandSidebar,
    resetSidebarWidth,
  }
}
