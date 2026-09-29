<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { whenever } from '@vueuse/core'
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'

import { useActivityMessage } from '#shared/composables/activity-message/useActivityMessage.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
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
import {
  useBrowserNotification,
  useBrowserNotificationTab,
} from '#desktop/composables/useBrowserNotification.ts'

const webNotificationList = new Map<ID, Notification>()

const { unseenCount } = useOnlineNotificationCount()

const { popover, popoverTarget, toggle, open, close } = usePopover()

const { play, isEnabled } = useOnlineNotificationSound()

const { notificationsCountSubscription } = useOnlineNotificationCount()

const { permissionGranted, show } = useBrowserNotification()

const { isNotifyingTab } = useBrowserNotificationTab()

const {
  notificationList,
  loading: isLoading,
  hasUnseenNotification,
  refetch,
} = useOnlineNotificationList()

const { markAllRead, deleteNotification, seenNotification, deleteAllNotifications } =
  useOnlineNotificationActions()

const { waitForConfirmation } = useConfirmation()

let mutationTriggered = false
let hasInitialCountRun = false
let previousUnseenCount = 0

const router = useRouter()

const handleOpenWebNotification = (notification: OnlineNotification, link?: string) => {
  window.focus()

  if (link) router.push(`/${link}`)

  close()
}

const runMarkAsSeen = async (notification: OnlineNotification) => {
  if (notification.seen) return

  mutationTriggered = true

  await seenNotification(notification.id)

  mutationTriggered = false
}

const removeNotification = async (notification: OnlineNotification) =>
  deleteNotification(notification.id).then(() => {
    webNotificationList.get(notification.id)?.close()
    webNotificationList.delete(notification.id)
  })

const closeWebNotifications = () => {
  webNotificationList.forEach((notification) => notification.close())

  webNotificationList.clear()
}

const runMarkAllRead = async () => {
  mutationTriggered = true

  const ids = notificationList.value.map((notification) => notification.id)

  await markAllRead(ids)

  mutationTriggered = false

  closeWebNotifications()
}

const runClearAll = async () => {
  // Close without restoring the focus to the owner, otherwise it would be moved back to the
  //   notification button while the confirmation dialog is opening.
  popover.value?.closePopover(true)

  const confirmed = await waitForConfirmation(
    __('All notifications will be deleted. This action cannot be undone.'),
    {
      confirmationVariant: 'delete',
      headerTitle: __('Clear all notifications'),
      buttonLabel: __('Delete all'),
    },
  )

  if (!confirmed) {
    open()
    return
  }

  mutationTriggered = true

  try {
    const cleared = await deleteAllNotifications()

    if (cleared) closeWebNotifications()
  } finally {
    mutationTriggered = false
  }
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

  // The permission is requested centrally after login; without it, the
  //   browser notification is skipped and only the badge and sound remain.
  //   The same goes for a tab that is not the one showing them.
  if (
    permissionGranted.value &&
    isNotifyingTab.value &&
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

    if (webNotification) {
      webNotificationList.set(notification.id, webNotification)
      webNotification.onclick = () => handleOpenWebNotification(notification, link)
    }
  }

  previousUnseenCount = result.onlineNotificationsCount.unseenCount
})

// The tab that took over is in front and shows the badge itself.
watch(isNotifyingTab, (notifying) => {
  if (!notifying) closeWebNotifications()
})

whenever(
  unseenCount,
  (newCount, oldCount) => {
    if (isEnabled.value && oldCount !== undefined && newCount > oldCount) play()
  },
  { flush: 'post' },
)
const truncatedUnseenCount = computed(() =>
  unseenCount.value && unseenCount.value > 99 ? '99+' : unseenCount.value,
)

defineOptions({
  inheritAttrs: false,
})
</script>

<template>
  <div class="relative">
    <NotificationButton
      id="app-online-notification"
      ref="popoverTarget"
      v-bind="$attrs"
      @show="toggle(true)"
    >
      <slot />
    </NotificationButton>

    <CommonLabel
      v-if="unseenCount && unseenCount > 0"
      size="xs"
      class="pointer-events-none absolute -bottom-0.75 z-20 block rounded-full border-2 border-white bg-pink-500 px-1 py-0.5 text-center font-bold text-white! ltr:left-[54%] rtl:right-[54%] dark:border-gray-500"
      :aria-label="$t('Unseen notifications count')"
      role="status"
    >
      {{ truncatedUnseenCount }}
    </CommonLabel>

    <CommonPopover ref="popover" z-index="53" orientation="right" :owner="popoverTarget">
      <NotificationPopover
        :unseen-count="unseenCount"
        :loading="isLoading"
        :has-unseen-notification="hasUnseenNotification"
        :notification-list="notificationList"
        @visited="close"
        @seen="runMarkAsSeen"
        @remove="removeNotification"
        @seen-all="runMarkAllRead"
        @clear-all="runClearAll"
      />
    </CommonPopover>
  </div>
</template>
