<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { usePermission, useWebNotification, whenever } from '@vueuse/core'
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'

import { useActivityMessage } from '#shared/composables/activity-message/useActivityMessage.ts'
import { useOnlineNotificationSound } from '#shared/composables/useOnlineNotification/useOnlineNotificationSound.ts'
import { useOnlineNotificationActions } from '#shared/entities/online-notification/composables/useOnlineNotificationActions.ts'
import { useOnlineNotificationCount } from '#shared/entities/online-notification/composables/useOnlineNotificationCount.ts'
import { useOnlineNotificationList } from '#shared/entities/online-notification/composables/useOnlineNotificationList.ts'
import type { OnlineNotification } from '#shared/graphql/types.ts'
import { edgesToArray } from '#shared/utils/helpers.ts'
import { cleanupMarkup } from '#shared/utils/markup.ts'

import CommonPopover from '#desktop/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#desktop/components/CommonPopover/usePopover.ts'
import NotificationButton from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationButton.vue'
import NotificationPopover from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationPopover.vue'

const webNotificationList = new Map<ID, Notification>()

const { unseenCount } = useOnlineNotificationCount()

const { popover, popoverTarget, toggle, close } = usePopover()

const { play, isEnabled } = useOnlineNotificationSound()

const notificationPermission = usePermission('notifications')

const { notificationsCountSubscription } = useOnlineNotificationCount()

const { show, isSupported, permissionGranted, ensurePermissions } = useWebNotification()

const {
  notificationList,
  loading: isLoading,
  hasUnseenNotification,
  refetch,
} = useOnlineNotificationList()

const { seenNotification, markAllRead, deleteNotification } = useOnlineNotificationActions()

let mutationTriggered = false
let hasInitialCountRun = false
let previousUnseenCount = 0

const router = useRouter()

const runSeenNotification = async (notification: OnlineNotification) => {
  mutationTriggered = true
  close()
  await seenNotification(notification.metaObject?.id as string)
  mutationTriggered = false
  webNotificationList.get(notification.id)?.close()
  webNotificationList.delete(notification.id)
}

const handleOpenWebNotification = (notification: OnlineNotification, link?: string) => {
  window.focus()

  if (link) router.push(`/${link}`)

  runSeenNotification(notification)
}

const removeNotification = async (notification: OnlineNotification) =>
  deleteNotification(notification.id).then(() => {
    webNotificationList.get(notification.id)?.close()
    webNotificationList.delete(notification.id)
  })

const runMarkAllRead = async () => {
  mutationTriggered = true

  const ids = notificationList.value.map((notification) => notification.id)

  await markAllRead(ids)

  mutationTriggered = false

  if (!webNotificationList.size) return

  webNotificationList.forEach((notification) => notification.close())

  webNotificationList.clear()
}

notificationsCountSubscription.watchOnResult(async (result) => {
  if (!hasInitialCountRun) {
    previousUnseenCount = result.onlineNotificationsCount.unseenCount
    hasInitialCountRun = true
    return
  }

  if (mutationTriggered) {
    previousUnseenCount = result.onlineNotificationsCount.unseenCount
    return
  }

  const { data } = await refetch()

  if (
    permissionGranted.value &&
    isSupported.value &&
    data?.onlineNotifications &&
    result.onlineNotificationsCount.unseenCount > previousUnseenCount
  ) {
    const notifications = edgesToArray(data.onlineNotifications)
    if (!notifications) return

    const notification = notifications[0] as OnlineNotification
    const { message, link } = useActivityMessage(ref(notification))
    const title = cleanupMarkup(message)

    const webNotification = await show({
      title,
      icon: `/assets/images/logo.svg`,
      tag: notification.id,
      dir: 'auto',
      silent: true,
    })

    if (!webNotification) return

    webNotificationList.set(notification.id, webNotification)
    webNotification.onclick = () => handleOpenWebNotification(notification, link)
  }

  previousUnseenCount = result.onlineNotificationsCount.unseenCount
})

whenever(
  unseenCount,
  (newCount, oldCount) => {
    if (isEnabled.value && oldCount !== undefined && newCount > oldCount) play()
  },
  { flush: 'post' },
)

onMounted(() => {
  if (isEnabled.value && !notificationPermission.value) ensurePermissions()
})

defineOptions({
  inheritAttrs: false,
})
</script>

<template>
  <div
    id="app-online-notification"
    ref="popoverTarget"
    :aria-label="$t('Notifications')"
    class="relative"
  >
    <NotificationButton v-bind="$attrs" :unseen-count="unseenCount" @show="toggle(true)">
      <slot />
    </NotificationButton>
    <CommonPopover ref="popover" orientation="right" :owner="popoverTarget">
      <NotificationPopover
        :unseen-count="unseenCount"
        :loading="isLoading"
        :has-unseen-notification="hasUnseenNotification"
        :notification-list="notificationList"
        @seen="runSeenNotification"
        @remove="removeNotification"
        @seen-all="runMarkAllRead"
      />
    </CommonPopover>
  </div>
</template>
