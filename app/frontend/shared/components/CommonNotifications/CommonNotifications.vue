<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */

import type { Notification } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { getNotificationClasses } from '#shared/initializer/initializeNotificationClasses.ts'
import { markup } from '#shared/utils/markup.ts'

const notificationTypeClassMap = getNotificationClasses()

const { notifications, removeNotification } = useNotifications()

const getClassName = (notification: Notification) => {
  return notificationTypeClassMap[notification.type]
}

const clickHandler = (notification: Notification) => {
  const { callback } = notification
  removeNotification(notification.id)
  if (callback) callback()
}
</script>

<template>
  <div id="Notifications" class="flex w-full justify-center">
    <div
      class="fixed top-0 z-50"
      :class="notificationTypeClassMap.baseContainer"
      role="alert"
    >
      <TransitionGroup
        tag="div"
        enter-class="opacity-0"
        leave-active-class="transition-opacity duration-1000 opacity-0"
      >
        <div
          v-for="notification in notifications"
          :key="notification.id"
          data-test-id="notification"
        >
          <div class="flex justify-center">
            <div
              class="m-3 flex cursor-pointer items-center"
              :class="[
                notificationTypeClassMap.base,
                getClassName(notification),
              ]"
              role="button"
              tabindex="0"
              @keydown.enter="clickHandler(notification)"
              @click="clickHandler(notification)"
            >
              <CommonIcon
                :name="`common-notification-${notification.type}`"
                size="small"
                decorative
              />
              <span
                class="text-sm"
                :class="notificationTypeClassMap.message"
                v-html="
                  markup(
                    $t(
                      notification.message,
                      ...(notification.messagePlaceholder || []),
                    ),
                  )
                "
              />
            </div>
          </div>
        </div>
      </TransitionGroup>
    </div>
  </div>
</template>
