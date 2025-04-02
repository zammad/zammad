// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import {
  type LinkListQuery,
  type LinkUpdatesSubscriptionVariables,
  type LinkUpdatesSubscription,
} from '#shared/graphql/types.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import type { ObjectLike } from '#shared/types/utils.ts'
import getUuid from '#shared/utils/getUuid.ts'

import { useLinkListQuery } from '../graphql/queries/linkList.api.ts'
import { LinkUpdatesDocument } from '../graphql/subscriptions/linkUpdates.api.ts'

import { useObjectLinkTypes } from './useObjectLinkTypes.ts'

import type { Ref } from 'vue'

export const useObjectLinks = (
  object: Ref<ObjectLike | undefined>,
  targetType: string,
) => {
  const { linkTypes } = useObjectLinkTypes()

  const objectId = computed(() => object.value?.id)

  const linkListQuery = new QueryHandler(
    useLinkListQuery(() => ({
      objectId: objectId.value,
      targetType,
    })),
  )

  const linkListQueryResult = linkListQuery.result()
  const linkListQueryLoading = linkListQuery.loading()

  linkListQuery.subscribeToMore<
    LinkUpdatesSubscriptionVariables,
    LinkUpdatesSubscription
  >(() => ({
    document: LinkUpdatesDocument,
    variables: {
      objectId: objectId.value,
      targetType,
    },
    updateQuery: (_, { subscriptionData }) => {
      if (!subscriptionData.data?.linkUpdates.links) {
        return null as unknown as LinkListQuery
      }

      return {
        linkList: subscriptionData.data.linkUpdates.links,
      }
    },
  }))

  const links = computed(() => {
    if (!linkListQueryResult.value?.linkList) return []

    return linkListQueryResult.value?.linkList
  })

  const linkTypesWithLinks = computed(() => {
    return linkTypes
      .map((type) => ({
        ...type,
        id: getUuid(),
        links: links.value.filter((link) => link.type === type.value),
      }))
      .filter((type) => type.links.length > 0)
  })

  const hasLinks = computed(() => {
    return linkTypesWithLinks.value.some((type) => type.links.length > 0)
  })

  return {
    linkListIsLoading: linkListQueryLoading,
    linkTypesWithLinks,
    hasLinks,
  }
}
