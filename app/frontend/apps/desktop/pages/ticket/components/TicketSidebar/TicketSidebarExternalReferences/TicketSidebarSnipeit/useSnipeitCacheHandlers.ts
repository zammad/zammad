// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { cloneDeep } from 'lodash-es'

import type {
  TicketExternalReferencesSnipeitAssetAddMutation,
  TicketExternalReferencesSnipeitAssetListQuery,
} from '#shared/graphql/types.ts'
import { getApolloClient } from '#shared/server/apollo/client.ts'

import { TicketExternalReferencesSnipeitAssetListDocument } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesSnipeitAssetList.api.ts'

import type { ApolloCache, FetchResult } from '@apollo/client/core'
import type { Ref } from 'vue'

export const useSnipeitCacheHandlers = (assetIds: Ref<number[]>, ticketId: Ref<ID | undefined>) => {
  const { cache } = getApolloClient()

  const modifyAssetItemAddCache = (
    cache: ApolloCache<TicketExternalReferencesSnipeitAssetListQuery>,
    { data }: Omit<FetchResult<TicketExternalReferencesSnipeitAssetAddMutation>, 'context'>,
  ) => {
    if (!data) return

    const { ticketExternalReferencesSnipeitAssetAdd } = data

    if (!ticketExternalReferencesSnipeitAssetAdd?.snipeitAssets?.length) return

    const queryOptions = {
      query: TicketExternalReferencesSnipeitAssetListDocument,
      variables: {
        ticketId: ticketId.value,
        snipeitAssetIds: ticketId.value ? undefined : assetIds.value,
      },
    }

    let existingSnipeitAssets =
      cache.readQuery<TicketExternalReferencesSnipeitAssetListQuery>(queryOptions)

    const newIdPresent = existingSnipeitAssets?.ticketExternalReferencesSnipeitAssetList?.find(
      (asset) => {
        return ticketExternalReferencesSnipeitAssetAdd?.snipeitAssets?.some(
          (snipeitAsset) => snipeitAsset.snipeitAssetId === asset.snipeitAssetId,
        )
      },
    )

    if (newIdPresent) return

    existingSnipeitAssets = {
      ...existingSnipeitAssets,
      ticketExternalReferencesSnipeitAssetList: [
        ...(existingSnipeitAssets?.ticketExternalReferencesSnipeitAssetList || []),
        ...ticketExternalReferencesSnipeitAssetAdd.snipeitAssets!,
      ],
    }

    if (!ticketId.value) {
      queryOptions.variables.snipeitAssetIds = [
        ...(assetIds.value || []),
        ...ticketExternalReferencesSnipeitAssetAdd.snipeitAssets.map(
          (asset) => asset.snipeitAssetId,
        ),
      ]
    }

    cache.writeQuery({
      ...queryOptions,
      data: {
        ...existingSnipeitAssets,
      },
    })
  }

  const removeAssetListCacheUpdate = (id: number) => {
    const queryOptions = {
      query: TicketExternalReferencesSnipeitAssetListDocument,
      variables: {
        ticketId: ticketId.value,
        snipeitAssetIds: ticketId.value ? undefined : assetIds.value,
      },
    }

    const existingSnipeitAssets =
      cache.readQuery<TicketExternalReferencesSnipeitAssetListQuery>(queryOptions)

    if (!existingSnipeitAssets) return

    const oldAssets = cloneDeep(existingSnipeitAssets)

    if (!ticketId.value) {
      queryOptions.variables.snipeitAssetIds = assetIds.value.filter(
        (snipeitAssetId) => snipeitAssetId !== id,
      )
    }

    cache.writeQuery({
      ...queryOptions,
      data: {
        ticketExternalReferencesSnipeitAssetList:
          existingSnipeitAssets.ticketExternalReferencesSnipeitAssetList.filter(
            (asset) => asset.snipeitAssetId !== id,
          ),
      },
    })

    return () =>
      cache.writeQuery({
        ...queryOptions,
        data: oldAssets,
      })
  }

  return { removeAssetListCacheUpdate, modifyAssetItemAddCache }
}
