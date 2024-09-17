// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'
import { EnumTicketScreenBehavior } from '#shared/graphql/types.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useUserCurrentTaskbarTabsStore } from '#desktop/entities/user/current/stores/taskbarTabs.ts'

export const useTicketScreenBehavior = () => {
  const taskbarTabsStore = useUserCurrentTaskbarTabsStore()
  const { activeTaskbarTabId } = storeToRefs(taskbarTabsStore)
  const { deleteTaskbarTab } = taskbarTabsStore

  const sessionStore = useSessionStore()
  const { user } = storeToRefs(sessionStore)

  const secondaryAction = computed(
    () => user.value?.preferences?.secondaryAction,
  )

  const closeCurrentTaskbarTab = () =>
    deleteTaskbarTab(activeTaskbarTabId.value as string)

  const closeAndGoToNextTask = () => {
    closeCurrentTaskbarTab()
    //
    // if (nextFollowingOpenTask) {
    //   console.log('next task')
    //   // :TODO get next task or previous task
    // } else {
    //   console.log('to overview')
    //   // :TODO go to overview if no open ticket is available
    // }
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
          closeAndGoToNextTask()
        }
        break
      case EnumTicketScreenBehavior.CloseTab:
        closeAndGoToNextTask()
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
