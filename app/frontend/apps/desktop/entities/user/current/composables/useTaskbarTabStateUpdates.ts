// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref, type Ref } from 'vue'

import type { FormRef } from '#shared/components/Form/types.ts'
import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'
import type { FormUpdaterOptions } from '#shared/types/form.ts'

import { useUserCurrentTaskbarItemStateUpdatesSubscription } from '../graphql/subscriptions/userCurrentTaskbarItemStateUpdates.api.ts'

export const useTaskbarTabStateUpdates = (
  currentTaskbarTabId: Ref<string | undefined>,
  form: Ref<FormRef | undefined>,
  autoSaveTriggerFormUpdater: (options?: FormUpdaterOptions) => void,
) => {
  const skipNextStateUpdate = ref(false)
  const applyTaskbarState = ref(false)

  const setSkipNextStateUpdate = (skip: boolean) => {
    // When it's after a applay taskbar state it was not a manual change in the current tab.
    if (skip && applyTaskbarState.value) {
      skipNextStateUpdate.value = false
      return
    }

    skipNextStateUpdate.value = skip
  }

  const stateUpdatesSubscription = new SubscriptionHandler(
    useUserCurrentTaskbarItemStateUpdatesSubscription(
      () => ({
        taskbarItemId: currentTaskbarTabId.value!,
      }),
      () => ({
        enabled: !!currentTaskbarTabId.value,
      }),
    ),
  )

  stateUpdatesSubscription.onSubscribed().then(() => {
    stateUpdatesSubscription.onResult((result) => {
      let listenFormUpdaterProcessing: string | undefined
      if (
        currentTaskbarTabId.value &&
        !skipNextStateUpdate.value &&
        result.data?.userCurrentTaskbarItemStateUpdates.stateChanged
      ) {
        listenFormUpdaterProcessing = form.value?.formNode.on(
          'message-removed',
          ({ payload }) => {
            if (
              !listenFormUpdaterProcessing ||
              payload.key !== 'formUpdaterProcessing'
            ) {
              return
            }

            applyTaskbarState.value = false
            form.value?.formNode.off(listenFormUpdaterProcessing)
          },
        )

        applyTaskbarState.value = true

        autoSaveTriggerFormUpdater({
          includeDirtyFields: true,
          additionalParams: {
            taskbarId: currentTaskbarTabId.value,
            applyTaskbarState: true,
          },
        })
      }

      setSkipNextStateUpdate(false)
    })
  })

  return { setSkipNextStateUpdate }
}
