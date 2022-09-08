// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { UserUpdatesDocument } from '@shared/graphql/subscriptions/userUpdates.api'
import type {
  UserUpdatesSubscriptionVariables,
  UserUpdatesSubscription,
} from '@shared/graphql/types'
import { QueryHandler } from '@shared/server/apollo/handler'
import { whenever } from '@vueuse/shared'
import { computed, nextTick, ref } from 'vue'
import { useUserLazyQuery } from '../graphql/queries/user.api'
import { useUserObjectManagerAttributesStore } from '../stores/objectManagerAttributes'

export const useUserDetail = () => {
  const internalId = ref(0)

  const userQuery = new QueryHandler(
    useUserLazyQuery(
      () => ({
        userInternalId: internalId.value,
      }),
      () => ({ enabled: internalId.value > 0 }),
    ),
  )

  const loadUser = (id: number) => {
    internalId.value = id
    nextTick(() => {
      userQuery.load()
    })
  }

  const userResult = userQuery.result()
  const loading = userQuery.loading()

  const user = computed(() => userResult.value?.user)

  const objectAttributesManager = useUserObjectManagerAttributesStore()

  const objectAttributes = computed(
    () => objectAttributesManager.attributes || [],
  )

  const stopWatch = whenever(
    () => user.value != null,
    () => {
      if (!user.value) return

      stopWatch()

      userQuery.subscribeToMore<
        UserUpdatesSubscriptionVariables,
        UserUpdatesSubscription
      >({
        document: UserUpdatesDocument,
        variables: {
          userId: user.value.id,
        },
      })
    },
  )

  return {
    loading,
    user,
    objectAttributes,
    loadUser,
  }
}
