<!-- Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div id="Notifications" class="w-full flex justify-center">
    <div class="fixed z-50" style="top: 30px; right: 0">
      <transition-group
        tag="div"
        enter-class="opacity-0"
        leave-active-class="transition-opacity duration-1000 opacity-0"
      >
        <div v-for="notification in notifications" v-bind:key="notification.id">
          <div class="flex justify-center">
            <div
              class="flex items-center py-2 px-4 rounded m-1"
              v-bind:class="getClassName(notification.type)"
            >
              <CommonIcon
                v-bind:name="iconNameMap[notification.type]"
                v-bind:fixed-size="{ width: 10, height: 10 }"
              />
              <span class="ml-2 text-sm">{{
                notification.messagePlaceholder
                  ? i18n.t(
                      notification.message,
                      ...notification.messagePlaceholder,
                    )
                  : i18n.t(notification.message)
              }}</span>
            </div>
          </div>
        </div>
      </transition-group>
    </div>
  </div>
</template>

<script setup lang="ts">
import useNotifications from '@common/composables/useNotifications'
import { NotificationTypes } from '@common/types/notification'

const notificationTypeClassMap = {
  warn: 'bg-yellow-500 text-white',
  success: 'bg-green-500 text-white',
  error: 'bg-red-500 text-white',
  info: 'bg-white text-black',
}

const iconNameMap = {
  warn: 'info',
  success: 'checkmark',
  error: 'danger',
  info: 'info',
}

const { notifications } = useNotifications()

const getClassName = (notificationType: NotificationTypes) => {
  return notificationTypeClassMap[notificationType]
}
</script>
