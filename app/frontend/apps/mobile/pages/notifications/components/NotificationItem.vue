<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import type { NotificationListItem } from '../types/notificaitons'

defineProps<{
  notification: NotificationListItem
}>()

defineEmits<{
  (e: 'remove', notification: NotificationListItem): void
}>()
</script>

<template>
  <div class="flex">
    <div class="flex items-center ltr:pr-2 rtl:pl-2">
      <CommonIcon
        name="trash"
        class="cursor-pointer text-red"
        size="tiny"
        @click="$emit('remove', notification)"
      />
    </div>
    <div class="flex items-center ltr:pr-2 rtl:pl-2">
      <div
        class="h-3 w-3 rounded-full"
        :class="{ 'bg-blue': !notification.read }"
        data-test-id="notificationRead"
      ></div>
    </div>
    <div class="flex flex-1 border-b border-white/10 py-4">
      <div class="flex items-center ltr:mr-4 rtl:ml-4">
        <CommonUserAvatar :entity="notification.user" />
      </div>

      <div class="flex flex-col">
        <div class="flex leading-4 text-gray-100">
          #{{ notification.id }}
          <div class="px-1">·</div>
          <!-- TODO what name? -->
          Name
        </div>
        <div class="text-lg leading-5">
          <strong
            >{{ notification.title
            }}{{ notification.message ? ': ' : '' }}</strong
          >{{ notification.message ? `“${notification.message}”` : '' }}
        </div>
        <div class="mt-1 flex text-gray">
          <!-- TODO what name? -->
          Gina
          <div class="px-1">·</div>
          <CommonDateTime :date-time="notification.createdAt" type="relative" />
        </div>
      </div>
    </div>
  </div>
</template>
