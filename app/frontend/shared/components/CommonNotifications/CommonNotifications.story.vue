<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref } from 'vue'
import CommonNotifications from './CommonNotifications.vue'
import useNotifications from './composable'
import type { NewNotification } from './types'
import { NotificationTypes } from './types'

const types = [
  NotificationTypes.Error,
  NotificationTypes.Warn,
  NotificationTypes.Success,
  NotificationTypes.Info,
]

const selectedType = ref(NotificationTypes.Success)

const { notify } = useNotifications()

const showNotification = (options: Partial<NewNotification> = {}) => {
  notify({
    message: 'This is a notification message',
    persistent: false,
    type: selectedType.value,
    durationMS: 5000,
    ...options,
  })
}

// eslint-disable-next-line no-alert
const alert = (msg: string) => window.alert(msg)
</script>

<template>
  <Story>
    <Variant title="Default">
      <template #controls>
        <HstSelect
          v-model="selectedType"
          title="Notification Type"
          :options="types"
        />
      </template>
      <div>
        <button @click="showNotification()">Show Notification</button>
      </div>
      <button
        @click="
          showNotification({
            persistent: true,
            callback: () => {
              alert('Callback executed.')
            },
          })
        "
      >
        Notification with callback
      </button>

      <CommonNotifications />
    </Variant>
  </Story>
</template>
