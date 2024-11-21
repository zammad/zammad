<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { OnlineNotification } from '#shared/graphql/types.ts'

import NotificationItem from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationPopover/NotificationList/NotificationItem.vue'

interface Props {
  list: OnlineNotification[]
}
defineProps<Props>()

defineEmits<{
  seen: [OnlineNotification]
  remove: [OnlineNotification]
}>()
</script>

<template>
  <ol class="space-y-2 px-3 pb-3">
    <li v-if="list?.length === 0">
      <CommonLabel>{{ $t('No unread notifications.') }}</CommonLabel>
    </li>
    <template v-else>
      <NotificationItem
        v-for="notification in list"
        :key="notification.id"
        :notification="notification"
        @seen="$emit('seen', $event)"
        @remove="$emit('remove', $event)"
      />
    </template>
  </ol>
</template>
