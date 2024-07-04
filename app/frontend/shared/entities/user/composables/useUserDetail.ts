// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, nextTick, ref, type Ref } from 'vue'

import { useUserLazyQuery } from '#shared/entities/user/graphql/queries/user.api.ts'
import { useUserObjectAttributesStore } from '#shared/entities/user/stores/objectAttributes.ts'
import { UserUpdatesDocument } from '#shared/graphql/subscriptions/userUpdates.api.ts'
import type {
  UserUpdatesSubscriptionVariables,
  UserUpdatesSubscription,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import type { GraphQLHandlerError } from '#shared/types/error.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import type { WatchQueryFetchPolicy } from '@apollo/client'

export const useUserDetail = (
  internalIdRef?: Ref<number>,
  errorCallback?: (error: GraphQLHandlerError) => boolean,
  fetchPolicy?: WatchQueryFetchPolicy,
) => {
  const internalId = internalIdRef || ref(0)
  const userId = computed(() => convertToGraphQLId('User', internalId.value))
  const fetchSecondaryOrganizationsCount = ref<Maybe<number>>(3)

  const userQuery = new QueryHandler(
    useUserLazyQuery(
      () => ({
        userInternalId: internalId.value,
        secondaryOrganizationsCount: 3,
      }),
      () => ({ enabled: internalId.value > 0, fetchPolicy }),
    ),
    {
      errorCallback,
    },
  )

  if (internalId.value) {
    userQuery.load()
  }

  const loadUser = (id: number) => {
    internalId.value = id

    nextTick(() => {
      userQuery.load()
    })
  }

  const loadAllSecondaryOrganizations = () => {
    userQuery
      .refetch({
        userInternalId: internalId.value,
        secondaryOrganizationsCount: null,
      })
      .then(() => {
        fetchSecondaryOrganizationsCount.value = null
      })
  }

  const userResult = userQuery.result()
  const loading = userQuery.loading()

  const user = computed(() => userResult.value?.user)

  const objectAttributesManager = useUserObjectAttributesStore()

  const objectAttributes = computed(
    () => objectAttributesManager.viewScreenAttributes || [],
  )

  userQuery.subscribeToMore<
    UserUpdatesSubscriptionVariables,
    UserUpdatesSubscription
  >(() => ({
    document: UserUpdatesDocument,
    variables: {
      userId: userId.value,
      secondaryOrganizationsCount: fetchSecondaryOrganizationsCount.value,
    },
  }))

  const secondaryOrganizations = computed(() =>
    normalizeEdges(user.value?.secondaryOrganizations),
  )

  return {
    loading,
    user,
    userQuery,
    objectAttributes,
    secondaryOrganizations,
    loadAllSecondaryOrganizations,
    loadUser,
  }
}
