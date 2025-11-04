// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed, ref, type ComputedRef, type Ref } from 'vue'

import type {
  OrganizationUpdatesSubscriptionVariables,
  OrganizationUpdatesSubscription,
  Organization,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import type { GraphQLHandlerError } from '#shared/types/error.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import { useOrganizationQuery } from '../graphql/queries/organization.api.ts'
import { OrganizationUpdatesDocument } from '../graphql/subscriptions/organizationUpdates.api.ts'
import { useOrganizationObjectAttributesStore } from '../stores/objectAttributes.ts'

import type { WatchQueryFetchPolicy } from '@apollo/client/core'

export const useOrganizationDetail = (
  organizationId: Ref<string | undefined> | ComputedRef<string | undefined>,
  errorCallback?: (error: GraphQLHandlerError) => boolean,
  fetchPolicy?: WatchQueryFetchPolicy,
) => {
  const fetchMembersCount = ref<Maybe<number>>(3)

  const organizationQuery = new QueryHandler(
    useOrganizationQuery(
      () => ({
        organizationId: organizationId.value!,
        membersCount: 3,
      }),
      () => ({
        enabled: Boolean(organizationId.value),
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

  const organization = computed(() => organizationResult.value?.organization as Organization)

  const loadAllMembers = () => {
    if (!organizationId) return

    organizationQuery
      .refetch({
        organizationId: organizationId.value,
        membersCount: null,
      })
      .then(() => {
        fetchMembersCount.value = null
      })
  }

  const { viewScreenAttributes } = storeToRefs(useOrganizationObjectAttributesStore())

  const organizationMembers = computed(() => normalizeEdges(organization.value?.allMembers) || [])

  return {
    loading,
    organizationQuery,
    organization,
    objectAttributes: viewScreenAttributes,
    organizationMembers,
    loadAllMembers,
  }
}
