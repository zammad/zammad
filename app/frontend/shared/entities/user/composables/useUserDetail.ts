// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, type ComputedRef, ref, type Ref, toRef } from 'vue'

import { useUserQuery } from '#shared/entities/user/graphql/queries/user.api.ts'
import { useUserObjectAttributesStore } from '#shared/entities/user/stores/objectAttributes.ts'
import { UserUpdatesDocument } from '#shared/graphql/subscriptions/userUpdates.api.ts'
import type {
  UserUpdatesSubscriptionVariables,
  UserUpdatesSubscription,
  User,
  UserQuery,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import type { GraphQLHandlerError } from '#shared/types/error.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import type { WatchQueryFetchPolicy } from '@apollo/client/core'

export const SECONDARY_ORGANIZATIONS_FETCH_COUNT = 5

export const useUserDetail = (
  userId: Ref<string | undefined> | ComputedRef<string | undefined>,
  initialDisplayLimit = 5,
  additionalPageSize = 100,
  errorCallback?: (error: GraphQLHandlerError) => boolean,
  fetchPolicy: WatchQueryFetchPolicy = 'cache-and-network',
  hasOrganizationCounts = false,
) => {
  // Track whether show-more has been clicked for this instance
  const hasLoadedMore = ref(false)

  const userQuery = new QueryHandler(
    useUserQuery(
      () => ({
        userId: userId.value!,
        secondaryOrganizationsCount: SECONDARY_ORGANIZATIONS_FETCH_COUNT,
        hasOrganizationCounts,
      }),
      () => ({ enabled: Boolean(userId.value), fetchPolicy }),
    ),
    {
      errorCallback,
    },
  )

  const userResult = userQuery.result()

  userQuery.subscribeToMore<UserUpdatesSubscriptionVariables, UserUpdatesSubscription>(() => ({
    document: UserUpdatesDocument,
    variables: {
      userId: userId.value!,
      secondaryOrganizationsCount: hasLoadedMore.value
        ? userResult.value?.user.secondaryOrganizations?.totalCount
        : SECONDARY_ORGANIZATIONS_FETCH_COUNT,
      hasOrganizationCounts,
    },
    updateQuery: (_, { subscriptionData }) => {
      if (!subscriptionData.data?.userUpdates.user) return null as unknown as UserQuery

      return {
        user: subscriptionData.data.userUpdates.user,
      }
    },
  }))

  const loading = userQuery.loading()
  const loadingWithoutCachedResult = userQuery.loadingWithoutCachedResult()

  const user = computed(() => userResult.value?.user as User)

  const fetchMoreSecondaryOrganizations = () => {
    if (!user.value) return

    hasLoadedMore.value = true

    userQuery.fetchMore({
      variables: {
        secondaryOrganizationsCount: additionalPageSize,
        after: userResult.value?.user.secondaryOrganizations?.pageInfo.endCursor,
      },
    })
  }

  const viewScreenAttributes = toRef(useUserObjectAttributesStore(), 'viewScreenAttributes')

  const allSecondaryOrganizations = computed(() =>
    normalizeEdges(user.value?.secondaryOrganizations),
  )

  const secondaryOrganizations = computed(() => {
    const all = allSecondaryOrganizations.value

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
    user,
    userQuery,
    objectAttributes: viewScreenAttributes,
    secondaryOrganizations,
    fetchMoreSecondaryOrganizations,
  }
}
