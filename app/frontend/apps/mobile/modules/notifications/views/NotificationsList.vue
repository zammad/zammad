<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
// TODO remove eslint-disable
/* eslint-disable zammad/zammad-detect-translatable-string */
import { computed, ref } from 'vue'
import LayoutCustomNavigation from '@mobile/components/layout/LayoutCustomNavigation.vue'
import { useHeader } from '@mobile/composables/useHeader'
import NotificationItem from '../components/NotificationItem.vue'
import type { NotificationListItem } from '../types/notificaitons'

useHeader({
  backUrl: '/',
})

// TODO make actual API call
// TODO subscribe to notification changes
const notifications = ref<NotificationListItem[]>([
  {
    id: '154362',
    title: 'State changed to closed',
    user: { id: '2', lastname: 'Biden', firstname: 'Joe' },
    read: false,
    createdAt: new Date().toUTCString(),
  },
  {
    id: '253223',
    title: 'Created internal note',
    message: 'Please give me a minute to check with our developers.',
    user: { id: '3', lastname: 'Rock', firstname: 'John' },
    read: true,
    createdAt: new Date(2022, 1, 1).toUTCString(),
  },
])

const markAllRead = () => {
  console.log(
    'mark read',
    notifications.value.map(({ id }) => id),
  )
}

const removeNotification = (notification: NotificationListItem) => {
  console.log('remove', notification)
}

const haveUnread = computed(() => notifications.value.some((n) => !n.read))
</script>

<template>
  <div class="ltr:pr-4 ltr:pl-3 rtl:pl-4 rtl:pr-3">
    <NotificationItem
      v-for="notification of notifications"
      :key="notification.id"
      :notification="notification"
      @remove="removeNotification($event)"
    />

    <LayoutCustomNavigation v-if="haveUnread">
      <div
        class="flex flex-1 cursor-pointer justify-center text-base text-blue"
        @click="markAllRead"
      >
        {{ $t('Mark all as read') }}
      </div>
    </LayoutCustomNavigation>
  </div>
</template>
