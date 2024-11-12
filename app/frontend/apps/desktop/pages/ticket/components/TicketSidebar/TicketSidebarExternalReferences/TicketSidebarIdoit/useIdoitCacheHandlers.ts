// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { cloneDeep } from 'lodash-es'

import type {
  TicketExternalReferencesIdoitObjectAddMutation,
  TicketExternalReferencesIdoitObjectListQuery,
} from '#shared/graphql/types.ts'
import { getApolloClient } from '#shared/server/apollo/client.ts'

import { TicketExternalReferencesIdoitObjectListDocument } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIdoitObjectList.api.ts'

import type { ApolloCache, FetchResult } from '@apollo/client/core'
import type { Ref } from 'vue'

export const useIdoitCacheHandlers = (
  objectIds: Ref<number[]>,
  ticketId: Ref<ID | undefined>,
) => {
  const { cache } = getApolloClient()

  const modifyObjectItemAddCache = (
    cache: ApolloCache<TicketExternalReferencesIdoitObjectListQuery>,
    {
      data,
    }: Omit<
      FetchResult<TicketExternalReferencesIdoitObjectAddMutation>,
      'context'
    >,
  ) => {
    if (!data) return

    const { ticketExternalReferencesIdoitObjectAdd } = data

    if (!ticketExternalReferencesIdoitObjectAdd?.idoitObjects?.length) return

    const queryOptions = {
      query: TicketExternalReferencesIdoitObjectListDocument,
      variables: {
        ticketId: ticketId.value,
        idoitObjectIds: ticketId.value ? undefined : objectIds.value,
      },
    }

    let existingIdoitObjects =
      cache.readQuery<TicketExternalReferencesIdoitObjectListQuery>(
        queryOptions,
      )

    const newIdPresent =
      existingIdoitObjects?.ticketExternalReferencesIdoitObjectList?.find(
        (object) => {
          return ticketExternalReferencesIdoitObjectAdd?.idoitObjects?.some(
            (idoitObject) => idoitObject.idoitObjectId === object.idoitObjectId,
          )
        },
      )

    if (newIdPresent) return

    existingIdoitObjects = {
      ...existingIdoitObjects,
      ticketExternalReferencesIdoitObjectList: [
        ...(existingIdoitObjects?.ticketExternalReferencesIdoitObjectList ||
          []),
        ...ticketExternalReferencesIdoitObjectAdd.idoitObjects!,
      ],
    }

    if (!ticketId.value) {
      queryOptions.variables.idoitObjectIds = [
        ...(objectIds.value || []),
        ...ticketExternalReferencesIdoitObjectAdd.idoitObjects.map(
          (object) => object.idoitObjectId,
        ),
      ]
    }

    cache.writeQuery({
      ...queryOptions,
      data: {
        ...existingIdoitObjects,
      },
    })
  }

  const removeObjectListCacheUpdate = (id: number) => {
    const queryOptions = {
      query: TicketExternalReferencesIdoitObjectListDocument,
      variables: {
        ticketId: ticketId.value,
        idoitObjectIds: ticketId.value ? undefined : objectIds.value,
      },
    }

    const existingIdoitObjects =
      cache.readQuery<TicketExternalReferencesIdoitObjectListQuery>(
        queryOptions,
      )

    if (!existingIdoitObjects) return

    const oldObjects = cloneDeep(existingIdoitObjects)

    if (!ticketId.value) {
      queryOptions.variables.idoitObjectIds = objectIds.value.filter(
        (idoitObjectId) => idoitObjectId !== id,
      )
    }

    cache.writeQuery({
      ...queryOptions,
      data: {
        ticketExternalReferencesIdoitObjectList:
          existingIdoitObjects.ticketExternalReferencesIdoitObjectList.filter(
            (object) => object.idoitObjectId !== id,
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
