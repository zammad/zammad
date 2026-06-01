<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { Notification } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { getNotificationClasses } from '#shared/initializer/initializeNotificationClasses.ts'

import CommonNotificationsItem from './CommonNotificationsItem.vue'
const notificationTypeClassMap = getNotificationClasses()

const { notifications, removeNotification } = useNotifications()

const handleAction = (notification: Notification) => {
  if (!notification.persistent) return

  notification.actionCallback?.()
}

/**
 * @param clickFromCloseButton
 * When persistent is active we only close the notification on close button click
 * We reuse the same callback
 */
const handleClose = (notification: Notification, clickFromCloseButton = false) => {
  if (notification.persistent && !clickFromCloseButton) return

  const { closeCallback } = notification

  removeNotification(notification.id)
  closeCallback?.()
}
</script>

<template>
  <div
    id="Notifications"
    class="pointer-events-none fixed inset-x-0 top-0 z-50 px-3"
    :class="notificationTypeClassMap.baseContainer"
    role="alert"
    aria-live="polite"
    aria-atomic="true"
  >
    <TransitionGroup
      tag="ol"
      class="flex w-full flex-col items-center space-y-3 py-3"
      enter-from-class="opacity-0"
      leave-to-class="opacity-0"
      leave-active-class="transition-opacity duration-250 absolute"
      enter-active-class="transition-opacity duration-250"
      move-class="transition-transform duration-250"
    >
      <li v-for="notification in notifications" :key="notification.id" class="pointer-events-auto">
        <CommonNotificationsItem
          class="grid w-fit gap-1"
          :class="[
            notificationTypeClassMap.base,
            notificationTypeClassMap[notification.type],
            {
              'cursor-pointer': !notification.currentProgress,
              'grid-cols-[min-content_1fr_fit-content]': notification.currentProgress,
              'grid-cols-[min-content_1fr]': !notification.currentProgress,
            },
          ]"
          :notification="notification"
          @action="handleAction"
          @close="handleClose"
        />
      </li>
    </TransitionGroup>
  </div>
</template>
