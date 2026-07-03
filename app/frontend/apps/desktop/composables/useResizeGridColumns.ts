// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage, useWindowSize, watchThrottled } from '@vueuse/core'
import { ref, computed, type Ref, watch } from 'vue'

import emitter from '#shared/utils/emitter.ts'

import { SidebarName, SidebarPosition } from '#desktop/components/layout/types.ts'
import { useSidebarDisplay } from '#desktop/components/layout/useSidebarDisplay.ts'
import { useAppBreakpoints } from '#desktop/composables/responsiveness/useAppBreakpoints.ts'

export const DEFAULT_START_SIDEBAR_WIDTH = 260
export const DEFAULT_END_SIDEBAR_WIDTH = 360

export const DEFAULT_SMALL_SCREEN_START_SIDEBAR_WIDTH = 225
export const DEFAULT_SMALL_SCREEN_END_SIDEBAR_WIDTH = 300

export const MINIMUM_START_SIDEBAR_WIDTH = 200
export const MINIMUM_END_SIDEBAR_WIDTH = 300

export const SIDEBAR_COLLAPSED_WIDTH = 56

export const useResizeGridColumns = (
  sidebarName: SidebarName,
  position: SidebarPosition = SidebarPosition.Start,
) => {
  const defaultSidebarWidth =
    position === SidebarPosition.Start ? DEFAULT_START_SIDEBAR_WIDTH : DEFAULT_END_SIDEBAR_WIDTH

  const defaultSmallScreenSidebarWidth =
    position === SidebarPosition.Start
      ? DEFAULT_SMALL_SCREEN_START_SIDEBAR_WIDTH
      : DEFAULT_SMALL_SCREEN_END_SIDEBAR_WIDTH

  const minSidebarWidth =
    position === SidebarPosition.Start ? MINIMUM_START_SIDEBAR_WIDTH : MINIMUM_END_SIDEBAR_WIDTH

  const { isSidebarCollapsed } = useSidebarDisplay(sidebarName)

  const { isSmallScreen } = useAppBreakpoints()

  const storage = `${sidebarName}-sidebar-width`

  const persistedSidebarWidth = sidebarName
    ? useLocalStorage(storage, defaultSidebarWidth)
    : ref(defaultSidebarWidth)

  const currentSidebarWidth: Ref<number> = ref(defaultSidebarWidth)

  const setupSidebarWidth = () => {
    currentSidebarWidth.value = isSmallScreen.value
      ? defaultSmallScreenSidebarWidth
      : persistedSidebarWidth.value
  }

  const persistSidebarWidth = (width: number) => {
    if (isSmallScreen.value) return

    persistedSidebarWidth.value = width
  }

  const resetSidebarWidth = () => {
    currentSidebarWidth.value = isSmallScreen.value
      ? defaultSmallScreenSidebarWidth
      : defaultSidebarWidth
    persistSidebarWidth(defaultSidebarWidth)
  }

  setupSidebarWidth()

  watch(isSmallScreen, setupSidebarWidth)

  // Sync currentSidebarWidth when localStorage changes in another window/tab.
  // useLocalStorage already reacts to cross-tab storage events, but currentSidebarWidth
  // is a separate ref that is only initialized once, so we need to keep it in sync.
  watch(persistedSidebarWidth, (newWidth) => {
    if (isSmallScreen.value) return

    currentSidebarWidth.value = newWidth
  })

  const { width: screenWidth } = useWindowSize()
  const maxWidth = computed(() => screenWidth.value / 3)

  const currentWidth = computed(() =>
    isSidebarCollapsed.value ? SIDEBAR_COLLAPSED_WIDTH : currentSidebarWidth.value,
  )

  const gridColumns = computed(() =>
    position === SidebarPosition.End
      ? `minmax(0, 1fr) ${currentWidth.value}px`
      : `${currentWidth.value}px minmax(0, 1fr)`,
  )

  const resizeSidebar = (width: number) => {
    if (isSmallScreen.value) return resetSidebarWidth()
    if (width <= minSidebarWidth || width >= maxWidth.value) return

    currentSidebarWidth.value = width
    persistSidebarWidth(width)
  }

  watchThrottled(
    currentSidebarWidth,
    () => {
      emitter.emit('resize-layout')
    },
    {
      throttle: 100,
    },
  )

  return {
    currentSidebarWidth,
    maxSidebarWidth: maxWidth,
    minSidebarWidth,
    gridColumns,
    isSidebarCollapsed,
    resizeSidebar,
    resetSidebarWidth,
  }
}
