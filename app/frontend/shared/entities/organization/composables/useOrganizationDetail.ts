// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref, type ComputedRef, type Ref, toRef } from 'vue'

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

export const SECONDARY_ORGANIZATIONS_FETCH_COUNT = 5

export const useOrganizationDetail = (
  organizationId: Ref<string | undefined> | ComputedRef<string | undefined>,
  initialDisplayLimit = 5,
  additionalPageSize = 100,
  errorCallback?: (error: GraphQLHandlerError) => boolean,
  fetchPolicy?: WatchQueryFetchPolicy,
) => {
  // Track whether show-more has been clicked for this instance
  const hasLoadedMore = ref(false)

  const organizationQuery = new QueryHandler(
    useOrganizationQuery(
      () => ({
        organizationId: organizationId.value!,
        first: SECONDARY_ORGANIZATIONS_FETCH_COUNT,
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

  const organizationResult = organizationQuery.result()

  organizationQuery.subscribeToMore<
    OrganizationUpdatesSubscriptionVariables,
    OrganizationUpdatesSubscription
  >(() => ({
    document: OrganizationUpdatesDocument,
    variables: {
      organizationId: organizationId.value!,
      // Once the user has expanded the list, request enough members in each
      // subscription update to cover all previously loaded items so that the
      // relay-pagination cache is not silently reset to the first page only.
      first: hasLoadedMore.value
        ? organizationResult.value?.organization.allMembers?.totalCount
        : SECONDARY_ORGANIZATIONS_FETCH_COUNT,
    },
  }))

  const loading = organizationQuery.loading()
  const loadingWithoutCachedResult = organizationQuery.loadingWithoutCachedResult()

  const organization = computed(() => organizationResult.value?.organization as Organization)

  const fetchMoreMembers = () => {
    if (!organizationId) return

    hasLoadedMore.value = true

    organizationQuery.fetchMore({
      variables: {
        first: additionalPageSize,
        after: organizationResult.value?.organization?.allMembers?.pageInfo.endCursor,
      },
    })
  }

  const viewScreenAttributes = toRef(useOrganizationObjectAttributesStore(), 'viewScreenAttributes')

  const allOrganizationMembers = computed(
    () => normalizeEdges(organization.value?.allMembers) || [],
  )

  const organizationMembers = computed(() => {
    const all = allOrganizationMembers.value

    // Once show-more was clicked, show all cached items
    if (hasLoadedMore.value) {
      return all
    }

    // Initially show only initialDisplayLimit items
    return {
      array: all.array.slice(0, initialDisplayLimit),
      totalCount: all.totalCount,
    }
  })

  return {
    loading,
    loadingWithoutCachedResult,
    organizationQuery,
    organization,
    objectAttributes: viewScreenAttributes,
    organizationMembers,
    fetchMoreMembers,
  }
}
