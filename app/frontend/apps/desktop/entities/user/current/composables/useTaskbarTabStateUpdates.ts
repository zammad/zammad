// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormRef } from '#shared/components/Form/types.ts'
import { EnumTaskbarStateUpdate, type FormUpdaterQueryVariables } from '#shared/graphql/types.ts'
import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'
import type { FormUpdaterOptions } from '#shared/types/form.ts'

import { useUserCurrentTaskbarItemStateUpdatesSubscription } from '../graphql/subscriptions/userCurrentTaskbarItemStateUpdates.api.ts'

import type { Ref } from 'vue'

export const useTaskbarTabStateUpdates = (
  currentTaskbarTabId: Ref<string | undefined>,
  form: Ref<FormRef | undefined>,
  autoSaveTriggerFormUpdater: (options?: FormUpdaterOptions) => void,
  resetFormChanges?: () => Promise<void> | void,
) => {
  const stateUpdatesSubscription = new SubscriptionHandler(
    useUserCurrentTaskbarItemStateUpdatesSubscription(
      () => ({
        taskbarItemId: currentTaskbarTabId.value!,
      }),
      () => ({
        enabled: !!currentTaskbarTabId.value,
        context: {
          skipSubscriptionCallback: (variables: FormUpdaterQueryVariables) => {
            return variables.meta.additionalData.taskbarId === currentTaskbarTabId.value
          },
        },
      }),
    ),
  )

  stateUpdatesSubscription.onSubscribed().then(() => {
    stateUpdatesSubscription.onResult((result) => {
      if (currentTaskbarTabId.value) {
        const stateUpdateType = result.data?.userCurrentTaskbarItemStateUpdates.stateUpdateType

        if (stateUpdateType === EnumTaskbarStateUpdate.Reset) {
          resetFormChanges?.()
        } else {
          autoSaveTriggerFormUpdater({
            includeDirtyFields: true,
            additionalParams: {
              taskbarId: currentTaskbarTabId.value,
              applyTaskbarState: true,
            },
          })
        }
      }
    })
  })
}
