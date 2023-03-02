// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { UserUpdatesDocument } from '@shared/graphql/subscriptions/userUpdates.api'
import type {
  UserUpdatesSubscriptionVariables,
  UserUpdatesSubscription,
} from '@shared/graphql/types'
import { QueryHandler } from '@shared/server/apollo/handler'
import { computed, nextTick, ref, watch } from 'vue'
import { useUserObjectAttributesStore } from '@shared/entities/user/stores/objectAttributes'
import { useErrorHandler } from '@shared/errors/useErrorHandler'
import { useUserLazyQuery } from '../graphql/queries/user.api'

export const useUserDetail = () => {
  const internalId = ref(0)
  const fetchSecondaryOrganizationsCount = ref<Maybe<number>>(3)
  const { createQueryErrorHandler } = useErrorHandler()

  const userQuery = new QueryHandler(
    useUserLazyQuery(
      () => ({
        userInternalId: internalId.value,
        secondaryOrganizationsCount: 3,
      }),
      () => ({ enabled: internalId.value > 0 }),
    ),
    {
      errorCallback: createQueryErrorHandler({
        notFound: __(
          'User with specified ID was not found. Try checking the URL for errors.',
        ),
        forbidden: __('You have insufficient rights to view this user.'),
      }),
    },
  )

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

  return {
    loading,
    user,
    userQuery,
    objectAttributes,
    loadAllSecondaryOrganizations,
    loadUser,
  }
}
