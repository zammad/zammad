// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { useAppName } from '#shared/composables/useAppName.ts'
import type SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import type { TaskbarLiveAppUser, TaskbarLiveUser } from '../types.ts'
import type { OperationVariables } from '@apollo/client/core'

// The live users of one taskbar key, flattened to one entry per user.
//
// The subscription is handed in rather than built here: each entity has one of its own, with its
//   own permission requirement and its own key (see Taskbar::TriggersSubscriptions). What they
//   return is the same list, so everything past it is shared.
//
// Structurally typed over the returned entry instead of one entity's generated type, whose
//   `__typename` literal would fit only its own caller.
export const useTaskbarLiveUserList = <
  TResult,
  TLiveUser extends Pick<TaskbarLiveUser, 'apps'> & { user: { id: string } },
  TVariables extends OperationVariables = OperationVariables,
>(
  subscription: SubscriptionHandler<TResult, TVariables>,
  selectLiveUsers: (data: TResult) => TLiveUser[],
) => {
  const liveUserList = ref<TaskbarLiveAppUser[]>([])

  const { userId } = useSessionStore()

  const appName = useAppName()

  const updateLiveUserList = (liveUsers: TLiveUser[]) => {
    const mappedLiveUsers: TaskbarLiveAppUser[] = []

    liveUsers.forEach((liveUser) => {
      let appItems = liveUser.apps.filter((data) => data.editing)

      // Skip own live user item, when it's holds only the current app and is not editing on the other one.
      if (liveUser.user.id === userId) {
        if (appItems.length === 0) return

        appItems = appItems.filter((item) => item.name !== appName)

        if (appItems.length === 0) return
      }

      if (appItems.length === 0) {
        appItems = liveUser.apps
      }

      // Sort app items by last interaction.
      appItems.sort((a, b) => {
        return new Date(b.lastInteraction).getTime() - new Date(a.lastInteraction).getTime()
      })

      mappedLiveUsers.push({
        // The subscriptions select a subset of the user fields the popovers rendering this take.
        //   Widened here, once, rather than at every caller.
        user: liveUser.user as TaskbarLiveAppUser['user'],
        editing: appItems[0].editing,
        lastInteraction: appItems[0].lastInteraction,
        app: appItems[0].name,
      })
    })

    return mappedLiveUsers
  }

  subscription.onResult((result) => {
    liveUserList.value = result.data ? updateLiveUserList(selectLiveUsers(result.data)) : []
  })

  return {
    liveUserList,
  }
}
