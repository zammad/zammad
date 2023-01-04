<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'
import type { ApolloCache } from '@apollo/client/cache'
import type { InMemoryCache } from '@apollo/client/core'
import { useHeader } from '@mobile/composables/useHeader'
import { useOnlineNotificationsQuery } from '@shared/entities/online-notification/graphql/queries/onlineNotifications.api'
import { QueryHandler, MutationHandler } from '@shared/server/apollo/handler'
import type { OnlineNotification, Scalars } from '@shared/graphql/types'
import { useOnlineNotificationMarkAllAsSeenMutation } from '@shared/entities/online-notification/graphql/mutations/markAllAsSeen.api'
import { useOnlineNotificationDeleteMutation } from '@shared/entities/online-notification/graphql/mutations/delete.api'
import { useOnlineNotificationCount } from '@shared/entities/online-notification/composables/useOnlineNotificationCount'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import NotificationItem from '../components/NotificationItem.vue'

useHeader({
  backUrl: '/',
})

const notificationsHandler = new QueryHandler(useOnlineNotificationsQuery())

const loading = notificationsHandler.loading()
const notificationsResult = notificationsHandler.result()
let mutationTriggered = false

const notifications = computed(
  () =>
    (notificationsResult.value?.onlineNotifications.edges
      ?.map((n) => n?.node)
      .filter(Boolean) as OnlineNotification[]) || [],
)

const updateCacheAfterRemoving = (
  cache: ApolloCache<InMemoryCache>,
  id: Scalars['ID'],
) => {
  const normalizedId = cache.identify({ id, __typename: 'OnlineNotification' })
  cache.evict({ id: normalizedId })
  cache.gc()
}

const removeNotification = (id: Scalars['ID']) => {
  const removeNotificationMutation = new MutationHandler(
    useOnlineNotificationDeleteMutation({
      variables: { onlineNotificationId: id },
      update(cache) {
        updateCacheAfterRemoving(cache, id)
      },
    }),
    {
      errorNotificationMessage: __('The notifcation could not be deleted.'),
    },
  )

  mutationTriggered = true

  removeNotificationMutation.send()
}

const markingAsSeen = ref(false)

const markAllRead = async () => {
  markingAsSeen.value = true

  const onlineNotificationIds = notifications.value
    .filter((elem) => !elem.seen)
    .map((elem) => elem.id)

  const mutation = new MutationHandler(
    useOnlineNotificationMarkAllAsSeenMutation({
      variables: { onlineNotificationIds },
    }),
    {
      errorNotificationMessage: __('Cannot set online notifications as seen'),
    },
  )

  mutationTriggered = true

  await mutation.send()

  markingAsSeen.value = false
}

// TODO: currently this triggered in some situtations a real subscription on the server: https://github.com/apollographql/apollo-client/issues/10117
const { unseenCount, notificationsCountSubscription } =
  useOnlineNotificationCount()

notificationsCountSubscription.watchOnResult(() => {
  notificationsHandler.refetch()
  if (!mutationTriggered) notificationsHandler.refetch()
  mutationTriggered = false
})

const haveUnread = computed(() => unseenCount.value > 0)
</script>

<template>
  <CommonLoader :loading="!notifications.length && loading">
    <div class="ltr:pr-4 ltr:pl-3 rtl:pl-4 rtl:pr-3">
      <NotificationItem
        v-for="notification of notifications"
        :key="notification.id"
        :item-id="notification.id"
        :type-name="notification.typeName"
        :object-name="notification.objectName"
        :seen="notification.seen"
        :created-at="notification.createdAt"
        :created-by="notification.createdBy"
        :meta-object="notification.metaObject"
        @remove="removeNotification"
      />

      <div v-if="!notifications.length" class="px-4 py-3 text-center text-base">
        {{ $t('No entries') }}
      </div>

      <!-- TODO: Add some better solution when mark as seen is running.
        Maybe disabled state that it can not be clicked twice or hidding the action completley. -->
      <div
        v-if="haveUnread"
        class="flex flex-1 cursor-pointer justify-center px-4 py-3 text-base text-blue"
        :class="{ 'text-red': markingAsSeen }"
        @click="markAllRead"
      >
        {{ $t('Mark all as read') }}
      </div>
    </div>
  </CommonLoader>
</template>
