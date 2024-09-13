// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { ref } from 'vue'

import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'
import type { FormUpdaterOptions } from '#shared/types/form.ts'

import { useUserCurrentTaskbarItemStateUpdatesSubscription } from '../graphql/subscriptions/userCurrentTaskbarItemStateUpdates.api.ts'
import { useUserCurrentTaskbarTabsStore } from '../stores/taskbarTabs.ts'

export const useTaskbarTabStateUpdates = (
  autoSaveTriggerFormUpdater: (options?: FormUpdaterOptions) => void,
) => {
  const skipNextStateUpdate = ref(false)
  const { activeTaskbarTabId } = storeToRefs(useUserCurrentTaskbarTabsStore())

  const setSkipNextStateUpdate = (skip: boolean) => {
    skipNextStateUpdate.value = skip
  }

  const stateUpdatesSubscription = new SubscriptionHandler(
    useUserCurrentTaskbarItemStateUpdatesSubscription(
      () => ({
        taskbarItemId: activeTaskbarTabId.value as string,
      }),
      () => ({
        enabled: !!activeTaskbarTabId.value,
      }),
    ),
  )

  stateUpdatesSubscription.onResult((result) => {
    if (
      activeTaskbarTabId.value &&
      !skipNextStateUpdate.value &&
      result.data?.userCurrentTaskbarItemStateUpdates.stateChanged
    ) {
      autoSaveTriggerFormUpdater({
        additionalParams: {
          taskbarId: activeTaskbarTabId.value,
          applyTaskbarState: true,
        },
      })
    }

    setSkipNextStateUpdate(false)
  })

  return { setSkipNextStateUpdate }
}
