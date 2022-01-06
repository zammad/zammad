<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div id="Notifications" class="flex justify-center w-full">
    <div class="fixed top-0 right-0 z-50">
      <transition-group
        tag="div"
        enter-class="opacity-0"
        leave-active-class="transition-opacity duration-1000 opacity-0"
      >
        <div v-for="notification in notifications" v-bind:key="notification.id">
          <div class="flex justify-center">
            <div
              class="flex items-center py-2 px-4 m-1 rounded"
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
  warn: 'bg-yellow text-white',
  success: 'bg-green text-white',
  error: 'bg-red text-white',
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
