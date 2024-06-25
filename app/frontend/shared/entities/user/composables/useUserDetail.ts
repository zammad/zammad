// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, nextTick, ref, watch, type Ref } from 'vue'

import { useUserLazyQuery } from '#shared/entities/user/graphql/queries/user.api.ts'
import { useUserObjectAttributesStore } from '#shared/entities/user/stores/objectAttributes.ts'
import { UserUpdatesDocument } from '#shared/graphql/subscriptions/userUpdates.api.ts'
import type {
  UserUpdatesSubscriptionVariables,
  UserUpdatesSubscription,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import type { GraphQLHandlerError } from '#shared/types/error.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import type { WatchQueryFetchPolicy } from '@apollo/client'

export const useUserDetail = (
  userId?: Ref<number>,
  errorCallback?: (error: GraphQLHandlerError) => boolean,
  fetchPolicy?: WatchQueryFetchPolicy,
) => {
  const internalId = userId || ref(0)
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

  watch(
    () => user.value?.id,
    (userId) => {
      if (!userId) return

      userQuery.subscribeToMore<
        UserUpdatesSubscriptionVariables,
        UserUpdatesSubscription
      >(() => ({
        document: UserUpdatesDocument,
        variables: {
          userId,
          secondaryOrganizationsCount: fetchSecondaryOrganizationsCount.value,
        },
      }))
    },
    { immediate: true },
  )

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
