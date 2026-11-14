// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { noop } from 'lodash-es'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import type { OperationMutationFunction } from '#shared/types/server/apollo/handler.ts'

import type { StoreObject } from '@apollo/client'

type MutationVariables<TMutation extends OperationMutationFunction> =
  TMutation extends OperationMutationFunction<infer _TResult, infer TVariables> ? TVariables : never

interface EntryDeleteOptions<TEntry, TVariables> {
  variables: (entry: TEntry) => TVariables
  errorNotificationMessage: string
  successNotification: {
    id: string
    message: string
  }
}

// The mutation composable is taken as a whole instead of by its result and variables types:
//   Apollo's `update` option does not resolve while the variables type is still open.
export const useEntryDelete = <
  TEntry extends StoreObject,
  TMutation extends OperationMutationFunction,
>(
  deleteMutation: TMutation,
  options: EntryDeleteOptions<TEntry, MutationVariables<TMutation>>,
) => {
  const { notify } = useNotifications()

  const { waitForVariantConfirmation } = useConfirmation()

  const deleteEntry = (entry: TEntry) => {
    const entryDeleteMutation = new MutationHandler(
      deleteMutation({
        update(cache) {
          cache.evict({ id: cache.identify(entry) })
          cache.gc()
        },
      }),
      {
        errorNotificationMessage: options.errorNotificationMessage,
      },
    )

    entryDeleteMutation
      .send(options.variables(entry))
      .then(() => {
        notify({
          ...options.successNotification,
          type: NotificationTypes.Success,
        })
      })
      // The handler has reported the failure already.
      .catch(noop)
  }

  const confirmEntryDelete = async (entry: TEntry) => {
    const confirmed = await waitForVariantConfirmation('delete')

    if (confirmed) deleteEntry(entry)
  }

  return { confirmEntryDelete }
}
