<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useOnlineNotificationActions } from '#shared/entities/online-notification/composables/useOnlineNotificationActions.ts'
import { useOnlineNotificationCount } from '#shared/entities/online-notification/composables/useOnlineNotificationCount.ts'
import { useOnlineNotificationsQuery } from '#shared/entities/online-notification/graphql/queries/onlineNotifications.api.ts'
import type { OnlineNotification, Scalars } from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { edgesToArray } from '#shared/utils/helpers.ts'

import CommonLoader from '#mobile/components/CommonLoader/CommonLoader.vue'
import { useHeader } from '#mobile/composables/useHeader.ts'

import NotificationItem from '../components/NotificationItem.vue'

const notificationsHandler = new QueryHandler(useOnlineNotificationsQuery())

const loading = notificationsHandler.loadingWithoutCachedResult()
const notificationsResult = notificationsHandler.result()
let mutationTriggered = false

useHeader({
  backUrl: '/',
  backAvoidHomeButton: true,
  refetch: computed(() => loading.value && notificationsResult.value != null),
})

const notifications = computed(
  () => edgesToArray(notificationsResult.value?.onlineNotifications) as OnlineNotification[],
)

const { seenNotification, markAllRead, deleteAllNotifications } = useOnlineNotificationActions()

const runSeenNotification = (id: Scalars['ID']['output']) => {
  mutationTriggered = true
  seenNotification(id)
}

const markingAsSeen = ref(false)

const runMarkAllRead = async () => {
  markingAsSeen.value = true

  const onlineNotificationIds = notifications.value
    .filter((elem) => !elem.seen)
    .map((elem) => elem.id)

  mutationTriggered = true

  await markAllRead(onlineNotificationIds)

  markingAsSeen.value = false
}

const clearingAll = ref(false)

const { waitForConfirmation } = useConfirmation()

const runClearAll = async () => {
  const confirmed = await waitForConfirmation(
    __('All notifications will be deleted. This action cannot be undone.'),
    {
      headerTitle: __('Clear all notifications'),
      buttonLabel: __('Delete all'),
      buttonVariant: 'danger',
    },
  )

  if (!confirmed) return

  clearingAll.value = true

  mutationTriggered = true

  try {
    await deleteAllNotifications()
  } finally {
    clearingAll.value = false
  }
}

const notificationRemoved = () => {
  mutationTriggered = true
}

// TODO: currently this triggered in some situations a real subscription on the server: https://github.com/apollographql/apollo-client/issues/10117
const { unseenCount, notificationsCountSubscription } = useOnlineNotificationCount()

notificationsCountSubscription.watchOnResult(() => {
  notificationsHandler.refetch()
  if (!mutationTriggered) notificationsHandler.refetch()
  mutationTriggered = false
})

const haveUnread = computed(() => (unseenCount.value ? unseenCount.value > 0 : false))
</script>

<template>
  <CommonLoader :loading="loading">
    <div class="ltr:pr-4 ltr:pl-3 rtl:pr-3 rtl:pl-4">
      <NotificationItem
        v-for="notification of notifications"
        :key="notification.id"
        :activity="notification"
        @remove="notificationRemoved"
        @seen="runSeenNotification"
      />

      <div v-if="!notifications.length" class="px-4 py-3 text-center text-base">
        {{ $t('No entries') }}
      </div>

      <!-- TODO: Add some better solution when mark as seen is running.
        Maybe disabled state that it can not be clicked twice or hidding the action completley. -->
      <div class="flex justify-center gap-6">
        <button
          v-if="haveUnread"
          type="button"
          class="cursor-pointer py-3 text-base text-blue"
          :class="{ 'text-red': markingAsSeen }"
          @click="runMarkAllRead"
        >
          {{ $t('Mark all as read') }}
        </button>

        <button
          v-if="notifications.length"
          type="button"
          class="cursor-pointer py-3 text-base text-blue"
          :class="{ 'text-red': clearingAll }"
          @click="runClearAll"
        >
          {{ $t('Clear all') }}
        </button>
      </div>
    </div>
  </CommonLoader>
</template>
