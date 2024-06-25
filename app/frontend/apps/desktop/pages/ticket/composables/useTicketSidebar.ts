// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref, type Ref } from 'vue'

import { useTicketSidebarPlugins } from '../components/TicketSidebar/plugins/index.ts'

import type { TicketSidebarPlugin } from '../components/TicketSidebar/plugins/types.ts'
import type { TicketSidebarContext } from '../components/types.ts'

const shownSidebars = ref<Record<string, boolean>>({})
const switchedSidebar = ref<string>()

const showSidebar = (sidebar: string) => {
  shownSidebars.value[sidebar] = true
}

const hideSidebar = (sidebar: string) => {
  shownSidebars.value[sidebar] = false
}

const switchSidebar = (newSidebar: string) => {
  switchedSidebar.value = newSidebar
}

export const useTicketSidebar = (context: Ref<TicketSidebarContext>) => {
  const sidebarPlugins = useTicketSidebarPlugins()

  const availableSidebarPlugins = computed(() =>
    Object.fromEntries(
      Object.entries(sidebarPlugins).filter(([, sidebarPlugin]) =>
        typeof sidebarPlugin.available === 'function'
          ? sidebarPlugin.available(context.value)
          : true,
      ),
    ),
  )

  const activeSidebar = computed<string | null>(() => {
    if (!Object.keys(availableSidebarPlugins.value)?.length) return null

    if (
      switchedSidebar.value &&
      availableSidebarPlugins.value[switchedSidebar.value] &&
      shownSidebars.value[switchedSidebar.value]
    )
      return switchedSidebar.value

    return Object.entries(availableSidebarPlugins.value).filter(
      ([sidebar]) => shownSidebars.value[sidebar],
    )?.[0]?.[0]
  })

  const activeSidebarPlugin = computed<TicketSidebarPlugin | null>(() => {
    if (
      activeSidebar.value &&
      availableSidebarPlugins.value[activeSidebar.value]
    )
      return availableSidebarPlugins.value[
        activeSidebar.value
      ] as TicketSidebarPlugin

    return null
  })

  const hasSidebar = computed(() => Boolean(activeSidebar.value))

  return {
    shownSidebars,
    activeSidebar,
    activeSidebarPlugin,
    availableSidebarPlugins,
    sidebarPlugins,
    hasSidebar,
    showSidebar,
    hideSidebar,
    switchSidebar,
  }
}
