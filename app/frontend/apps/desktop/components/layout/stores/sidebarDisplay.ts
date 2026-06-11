// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'
import { isEqual } from 'lodash-es'
import { defineStore } from 'pinia'
import { computed, readonly, ref, watch } from 'vue'

import { useAppBreakpoints } from '#desktop/composables/responsiveness/useAppBreakpoints.ts'

import { SidebarName, type ToggleOptions } from '../types.ts'

const defaultCollapsedState = () => ({
  [SidebarName.Primary]: false,
  [SidebarName.TicketContent]: false,
  [SidebarName.TicketOverviews]: false,
  [SidebarName.PersonalSetting]: false,
})

export const useSidebarDisplayStore = defineStore('sidebarDisplay', () => {
  const { isSmallScreen } = useAppBreakpoints()

  // For large screens lg and above
  const persistedCollapsed = useLocalStorage('sidebar-collapsed', defaultCollapsedState)

  // For small screens below lg
  const sessionCollapsed = ref(defaultCollapsedState())

  const currentCollapsed = computed<Record<SidebarName, boolean>>((oldValue) => {
    const newValue = isSmallScreen.value ? sessionCollapsed.value : persistedCollapsed.value

    if (oldValue && isEqual(newValue, oldValue)) return oldValue

    return newValue
  })

  // When entering small-screen mode, seed the session state from persisted so the
  // storage switch (persisted → session) produces no apparent state change. Without
  // this, a sidebar that was closed in persisted storage would look like it "expanded"
  // after the switch (session default = false/open), spuriously triggering the
  // cross-collapse watchers in LayoutPage / LayoutContent and collapsing both sidebars.
  watch(
    isSmallScreen,
    (isSmall) => {
      if (!isSmall) return
      sessionCollapsed.value = { ...persistedCollapsed.value }
    },
    { immediate: true },
  )

  const isCollapsed = (name: SidebarName) =>
    isSmallScreen.value ? sessionCollapsed.value[name] : persistedCollapsed.value[name]

  const setCollapsed = (name: SidebarName, value: boolean, options?: ToggleOptions) => {
    if (isSmallScreen.value || options?.storage === 'session') {
      sessionCollapsed.value[name] = value
      return
    }

    persistedCollapsed.value[name] = value
  }

  const toggleSidebar = (name: SidebarName, value?: boolean, options?: ToggleOptions) => {
    setCollapsed(name, value ?? !isCollapsed(name), options)

    return isCollapsed(name)
  }

  return {
    persistedCollapsed: readonly(persistedCollapsed),
    sessionCollapsed: readonly(sessionCollapsed),
    currentCollapsed,
    setCollapsed,
    toggleSidebar,
  }
})
