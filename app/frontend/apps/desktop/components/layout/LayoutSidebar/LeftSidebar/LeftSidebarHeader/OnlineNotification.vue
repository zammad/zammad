<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useWebNotification, whenever } from '@vueuse/core'
import { onMounted, watch, ref } from 'vue'

import CommonPopover from '#shared/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#shared/components/CommonPopover/usePopover.ts'
import { useActivityMessage } from '#shared/composables/activity-message/useActivityMessage.ts'
import { useBrowserNotifications } from '#shared/composables/useBrowserNotifications.ts'
import { useOnlineNotificationSound } from '#shared/composables/useOnlineNotification/useOnlineNotificationSound.ts'
import { useOnlineNotificationCount } from '#shared/entities/online-notification/composables/useOnlineNotificationCount.ts'
import { useOnlineNotificationList } from '#shared/entities/online-notification/composables/useOnlineNotificationList.ts'
import { cleanupMarkup } from '#shared/utils/markup.ts'

import NotificationButton from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationButton.vue'
import NotificationPopover from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationPopover.vue'

const { unseenCount } = useOnlineNotificationCount()

const { popover, popoverTarget, toggle, close } = usePopover()

const { play, isEnabled } = useOnlineNotificationSound()

const { notificationPermission, isGranted, requestNotification } =
  useBrowserNotifications()

const { show, isSupported } = useWebNotification()

const {
  notificationList,
  loading: isLoading,
  hasUnseenNotification,
  refetch,
} = useOnlineNotificationList()

const watcher = whenever(unseenCount, (newCount, oldCount) => {
  if (!isSupported.value) return watcher.stop()
  if (!isGranted.value && newCount > oldCount) return

  const notification = notificationList.value.at(-1)

  if (!notification) return

  const { message } = useActivityMessage(ref(notification))

  const title = cleanupMarkup(message)

  show({
    title,
    icon: `/assets/images/logo.svg`,
    tag: notification.id,
    silent: true,
  })
})

watch(
  unseenCount,
  (newCount, oldCount) => {
    if (!isEnabled.value || !oldCount) return
    if (newCount > oldCount && isGranted.value) play()
  },
  {
    flush: 'post',
  },
)

/**
 * ⚠️ Browsers enforce user interaction before allowing media playback
 * @chrome https://developer.chrome.com/blog/autoplay
 * @firefox https://support.mozilla.org/en-US/kb/block-autoplay
 */
onMounted(() => {
  // If notificationPermission is undefined, we never have asked for permission
  if (isEnabled.value && !notificationPermission.value) requestNotification()
})
</script>

<template>
  <div
    id="app-online-notification"
    ref="popoverTarget"
    :aria-label="$t('Notifications')"
    class="relative"
  >
    <NotificationButton :unseen-count="unseenCount" @show="toggle(true)" />

    <CommonPopover ref="popover" orientation="right" :owner="popoverTarget">
      <NotificationPopover
        :unseen-count="unseenCount"
        :loading="isLoading"
        :has-unseen-notification="hasUnseenNotification"
        :notification-list="notificationList"
        @refetch="refetch"
        @close="close"
      />
    </CommonPopover>
  </div>
</template>
