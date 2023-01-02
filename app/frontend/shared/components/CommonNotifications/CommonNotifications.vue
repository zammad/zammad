<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */

import useNotifications from '@shared/components/CommonNotifications/composable'
import type { Notification } from '@shared/components/CommonNotifications/types'
import { markup } from '@shared/utils/markup'

const notificationTypeClassMap = {
  warn: 'bg-yellow text-white',
  success: 'bg-green text-white',
  error: 'bg-red/60 text-white',
  info: 'bg-white text-black',
}

const iconNameMap = {
  warn: 'mobile-info',
  success: 'mobile-check',
  error: 'mobile-warning',
  info: 'mobile-info',
}

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
    <div class="fixed top-0 z-50 ltr:right-0 rtl:left-0" role="alert">
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
              class="m-3 flex cursor-pointer items-center rounded py-2 px-4"
              :class="getClassName(notification)"
              @click="clickHandler(notification)"
            >
              <CommonIcon :name="iconNameMap[notification.type]" size="small" />
              <span
                class="text-sm ltr:ml-2 rtl:mr-2"
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
