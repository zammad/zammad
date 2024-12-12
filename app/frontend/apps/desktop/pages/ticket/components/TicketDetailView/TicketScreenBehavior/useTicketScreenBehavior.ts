// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed, type Ref } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'
import { EnumTicketScreenBehavior } from '#shared/graphql/types.ts'
import { useWalker } from '#shared/router/walker.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useUserCurrentTaskbarTabsStore } from '#desktop/entities/user/current/stores/taskbarTabs.ts'

export const useTicketScreenBehavior = (
  currentTaskbarTabId: Ref<string | undefined>,
) => {
  const { deleteTaskbarTab } = useUserCurrentTaskbarTabsStore()

  const { user } = storeToRefs(useSessionStore())

  const walker = useWalker()

  const secondaryAction = computed(
    () => user.value?.preferences?.secondaryAction,
  )

  const closeCurrentTaskbarTab = () => {
    if (!currentTaskbarTabId.value) return

    deleteTaskbarTab(currentTaskbarTabId.value)
  }

  const closeAndGoBack = () => {
    walker.back('/')
    closeCurrentTaskbarTab()
  }

  const handleScreenBehavior = ({
    screenBehaviour,
    ticket,
  }: {
    screenBehaviour?: EnumTicketScreenBehavior
    ticket: TicketById
  }) => {
    const currentScreenBehaviour = screenBehaviour || secondaryAction.value

    switch (currentScreenBehaviour) {
      case EnumTicketScreenBehavior.CloseTabOnTicketClose:
        if (ticket.state.stateType.name === 'closed') {
          closeAndGoBack()
        }
        break
      case EnumTicketScreenBehavior.CloseTab:
        closeAndGoBack()
        break
      case EnumTicketScreenBehavior.CloseNextInOverview:
        // :TODO handle situation if a Macro should advance to next ticket from overview
        break
      case EnumTicketScreenBehavior.StayOnTab:
      default:
        break
    }
  }

  return { handleScreenBehavior }
}
