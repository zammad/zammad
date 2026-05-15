// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { injectLocal, provideLocal } from '@vueuse/shared'
import { isEqual } from 'lodash-es'
import { computed, ref, watch, type InjectionKey, type Ref } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'
import emitter from '#shared/utils/emitter.ts'

import { useTicketSidebarPlugins } from '../components/TicketSidebar/plugins/index.ts'

import type { TicketSidebarPlugin } from '../components/TicketSidebar/plugins/types.ts'
import type { TicketSidebarContext, TicketSidebarInformation } from '../types/sidebar.ts'

export const TICKET_SIDEBAR_SYMBOL = Symbol(
  'ticket-sidebar',
) as InjectionKey<TicketSidebarInformation>

export const useProvideTicketSidebar = (context: Ref<TicketSidebarContext>) => {
  const shownSidebars = ref<Record<string, boolean>>({})
  const switchedSidebar = ref<string>()

  const { userId } = useSessionStore()

  const showSidebar = (sidebar: string) => {
    shownSidebars.value[sidebar] = true
  }

  const hideSidebar = (sidebar: string) => {
    shownSidebars.value[sidebar] = false
  }

  const switchSidebar = (newSidebar: string) => {
    switchedSidebar.value = newSidebar
    emitter.emit('expand-collapsed-content', `${userId}-ticket-detail`)
  }

  const sidebarPlugins = useTicketSidebarPlugins(context.value.screenType)

  const availableSidebarPlugins = computed<Record<string, TicketSidebarPlugin>>(
    (currentAvailableSidebarPlugins) => {
      const newCurrentSidebarPlugins = Object.fromEntries(
        Object.entries(sidebarPlugins)
          .filter(([, sidebarPlugin]) => sidebarPlugin.views.includes(context.value.view))
          .filter(([, sidebarPlugin]) =>
            typeof sidebarPlugin.available === 'function'
              ? sidebarPlugin.available(context.value)
              : true,
          ),
      )

      if (
        currentAvailableSidebarPlugins &&
        isEqual(currentAvailableSidebarPlugins, newCurrentSidebarPlugins)
      )
        return currentAvailableSidebarPlugins

      return newCurrentSidebarPlugins
    },
  )

  const activeSidebar = computed<string | null>(() => {
    if (!Object.keys(availableSidebarPlugins.value)?.length) return null
    if (
      switchedSidebar.value &&
      availableSidebarPlugins.value[switchedSidebar.value] &&
      shownSidebars.value[switchedSidebar.value]
    )
      return switchedSidebar.value

    const sidebar = Object.entries(availableSidebarPlugins.value).find(
      ([sidebar]) => shownSidebars.value[sidebar],
    )?.[0]

    return sidebar === undefined ? ' ' : sidebar // ' ' is a fallback value for a non-selectable sidebar to prevent flickering if sidebar is loading
  })

  const hasSidebar = computed(() => Boolean(activeSidebar.value))

  watch(hasSidebar, () => {
    emitter.emit('resize-layout')
  })

  provideLocal(TICKET_SIDEBAR_SYMBOL, {
    shownSidebars,
    activeSidebar,
    availableSidebarPlugins,
    sidebarPlugins,
    hasSidebar,
    showSidebar,
    hideSidebar,
    switchSidebar,
  })
}

export const useTicketSidebar = () => {
  return injectLocal(TICKET_SIDEBAR_SYMBOL) as TicketSidebarInformation
}
