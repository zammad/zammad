// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { cloneDeep } from 'lodash-es'

import type {
  TicketExternalReferencesIdoitUpObjectAddMutation,
  TicketExternalReferencesIdoitUpObjectListQuery,
} from '#shared/graphql/types.ts'
import { getApolloClient } from '#shared/server/apollo/client.ts'

import { TicketExternalReferencesIdoitUpObjectListDocument } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIdoitUpObjectList.api.ts'

import type { ApolloCache, FetchResult } from '@apollo/client'
import type { Ref } from 'vue'

export const useIdoitUpCacheHandlers = (
  objectIds: Ref<string[]>,
  ticketId: Ref<ID | undefined>,
) => {
  const { cache } = getApolloClient()

  const modifyObjectItemAddCache = (
    cache: ApolloCache,
    { data }: Omit<FetchResult<TicketExternalReferencesIdoitUpObjectAddMutation>, 'context'>,
  ) => {
    if (!data) return

    const { ticketExternalReferencesIdoitUpObjectAdd } = data

    if (!ticketExternalReferencesIdoitUpObjectAdd?.idoitUpObjects?.length) return

    const queryOptions = {
      query: TicketExternalReferencesIdoitUpObjectListDocument,
      variables: {
        ticketId: ticketId.value,
        idoitUpObjectIds: ticketId.value ? undefined : objectIds.value,
      },
    }

    let existingIdoitUpObjects =
      cache.readQuery<TicketExternalReferencesIdoitUpObjectListQuery>(queryOptions)

    const newIdPresent = existingIdoitUpObjects?.ticketExternalReferencesIdoitUpObjectList?.find(
      (object) => {
        return ticketExternalReferencesIdoitUpObjectAdd?.idoitUpObjects?.some(
          (idoitUpObject) => idoitUpObject.idoitUpObjectId === object.idoitUpObjectId,
        )
      },
    )

    if (newIdPresent) return

    existingIdoitUpObjects = {
      ...existingIdoitUpObjects,
      ticketExternalReferencesIdoitUpObjectList: [
        ...(existingIdoitUpObjects?.ticketExternalReferencesIdoitUpObjectList || []),
        ...ticketExternalReferencesIdoitUpObjectAdd.idoitUpObjects!,
      ],
    }

    if (!ticketId.value) {
      queryOptions.variables.idoitUpObjectIds = [
        ...(objectIds.value || []),
        ...ticketExternalReferencesIdoitUpObjectAdd.idoitUpObjects.map(
          (object) => object.idoitUpObjectId,
        ),
      ]
    }

    cache.writeQuery({
      ...queryOptions,
      data: {
        ...existingIdoitUpObjects,
      },
    })
  }

  const removeObjectListCacheUpdate = (id: string) => {
    const queryOptions = {
      query: TicketExternalReferencesIdoitUpObjectListDocument,
      variables: {
        ticketId: ticketId.value,
        idoitUpObjectIds: ticketId.value ? undefined : objectIds.value,
      },
    }

    const existingIdoitUpObjects =
      cache.readQuery<TicketExternalReferencesIdoitUpObjectListQuery>(queryOptions)

    if (!existingIdoitUpObjects) return

    const oldObjects = cloneDeep(existingIdoitUpObjects)

    if (!ticketId.value) {
      queryOptions.variables.idoitUpObjectIds = objectIds.value.filter(
        (idoitUpObjectId) => idoitUpObjectId !== id,
      )
    }

    cache.writeQuery({
      ...queryOptions,
      data: {
        ticketExternalReferencesIdoitUpObjectList:
          existingIdoitUpObjects.ticketExternalReferencesIdoitUpObjectList.filter(
            (object) => object.idoitUpObjectId !== id,
          ),
      },
    })

    return () =>
      cache.writeQuery({
        ...queryOptions,
        data: oldObjects,
      })
  }

  return { removeObjectListCacheUpdate, modifyObjectItemAddCache }
}
