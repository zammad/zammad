// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref, type Ref, watch } from 'vue'

import { useReactiveNow } from '#shared/composables/useReactiveNow.ts'

import type { TicketLiveAppUser } from '../types.ts'

// Default idle time from 5 minutes.
const IDLE_TIME_MS = 5 * 60 * 1000

export const useTicketLiveUsersDisplay = (
  liveUsers: Ref<TicketLiveAppUser[]>,
) => {
  const viewingUsers = ref<TicketLiveAppUser[]>([])
  const idleUsers = ref<TicketLiveAppUser[]>([])

  const reactiveNow = useReactiveNow()

  watch(
    [liveUsers, reactiveNow],
    () => {
      const localViewingUsers: TicketLiveAppUser[] = []
      const localIdleUsers: TicketLiveAppUser[] = []

      liveUsers.value.forEach((liveUser) => {
        if (
          new Date(liveUser.lastInteraction).getTime() + IDLE_TIME_MS <
          reactiveNow.value.getTime()
        ) {
          localIdleUsers.push(liveUser)
        } else {
          localViewingUsers.push(liveUser)
        }
      })

      viewingUsers.value = localViewingUsers
      idleUsers.value = localIdleUsers
    },
    { immediate: true },
  )

  return {
    viewingUsers,
    idleUsers,
  }
}
