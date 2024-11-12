// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed, ref, type Ref } from 'vue'

import type {
  OrganizationUpdatesSubscriptionVariables,
  OrganizationUpdatesSubscription,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import type { GraphQLHandlerError } from '#shared/types/error.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import { useOrganizationQuery } from '../graphql/queries/organization.api.ts'
import { OrganizationUpdatesDocument } from '../graphql/subscriptions/organizationUpdates.api.ts'
import { useOrganizationObjectAttributesStore } from '../stores/objectAttributes.ts'

import type { WatchQueryFetchPolicy } from '@apollo/client/core'

export const useOrganizationDetail = (
  internalId: Ref<number | undefined>,
  errorCallback?: (error: GraphQLHandlerError) => boolean,
  fetchPolicy?: WatchQueryFetchPolicy,
) => {
  const organizationId = computed(() => {
    if (!internalId.value) return

    return convertToGraphQLId('Organization', internalId.value)
  })
  const fetchMembersCount = ref<Maybe<number>>(3)

  const organizationQuery = new QueryHandler(
    useOrganizationQuery(
      () => ({
        organizationInternalId: internalId.value,
        membersCount: 3,
      }),
      () => ({
        enabled: Boolean(internalId.value),
        fetchPolicy,
      }),
    ),
    {
      errorCallback,
    },
  )

  organizationQuery.subscribeToMore<
    OrganizationUpdatesSubscriptionVariables,
    OrganizationUpdatesSubscription
  >(() => ({
    document: OrganizationUpdatesDocument,
    variables: {
      organizationId: organizationId.value!,
      membersCount: fetchMembersCount.value,
    },
  }))

  const organizationResult = organizationQuery.result()
  const loading = organizationQuery.loading()

  const organization = computed(() => organizationResult.value?.organization)

  const loadAllMembers = () => {
    const organizationInternalId = organization.value?.internalId
    if (!organizationInternalId) {
      return
    }

    organizationQuery
      .refetch({
        organizationInternalId,
        membersCount: null,
      })
      .then(() => {
        fetchMembersCount.value = null
      })
  }

  const { viewScreenAttributes } = storeToRefs(
    useOrganizationObjectAttributesStore(),
  )

  const organizationMembers = computed(
    () => normalizeEdges(organization.value?.allMembers) || [],
  )

  return {
    loading,
    organizationQuery,
    organization,
    objectAttributes: viewScreenAttributes,
    organizationMembers,
    loadAllMembers,
  }
}
