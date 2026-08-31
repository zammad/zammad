// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref, type Ref, watch } from 'vue'

import { useReactiveNow } from '#shared/composables/useReactiveNow.ts'

import type { TaskbarLiveAppUser } from '../types.ts'

// Default idle time from 5 minutes.
const IDLE_TIME_MS = 5 * 60 * 1000

export const useTaskbarLiveUsersDisplay = (liveUserList: Ref<TaskbarLiveAppUser[]>) => {
  const liveUsers = ref<TaskbarLiveAppUser[]>([])
  const viewingUsers = ref<TaskbarLiveAppUser[]>([])
  const idleUsers = ref<TaskbarLiveAppUser[]>([])

  const reactiveNow = useReactiveNow()

  watch(
    [liveUserList, reactiveNow],
    () => {
      const localLiveUsers: TaskbarLiveAppUser[] = []

      liveUserList.value?.forEach((liveUser) => {
        if (
          liveUser.lastInteraction &&
          new Date(liveUser.lastInteraction).getTime() + IDLE_TIME_MS < reactiveNow.value.getTime()
        ) {
          localLiveUsers.push({
            user: liveUser.user,
            editing: liveUser.editing,
            app: liveUser.app,
            isIdle: true,
          })
        } else {
          localLiveUsers.push({
            user: liveUser.user,
            editing: liveUser.editing,
            app: liveUser.app,
            isIdle: false,
          })
        }
      })

      liveUsers.value = localLiveUsers
      viewingUsers.value = localLiveUsers.filter((user) => !user.isIdle)
      idleUsers.value = localLiveUsers.filter((user) => user.isIdle)
    },
    { immediate: true },
  )

  return {
    liveUsers,
    viewingUsers,
    idleUsers,
  }
}
