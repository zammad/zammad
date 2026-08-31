<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

interface Props {
  hasUnseenNotification: boolean
  hasNotifications: boolean
}

defineProps<Props>()

defineEmits<{
  'mark-all': []
  'clear-all': []
}>()
</script>

<template>
  <footer
    v-if="hasUnseenNotification || hasNotifications"
    class="rounded-b-xl bg-neutral-50 px-3 dark:bg-gray-500"
  >
    <div
      class="flex min-w-0 items-center justify-end gap-2.5 border-t border-t-neutral-100 py-3 dark:border-t-gray-900"
    >
      <CommonButton
        v-if="hasUnseenNotification"
        class="min-w-16 shrink!"
        prefix-icon="lightning"
        @click="$emit('mark-all')"
      >
        <span v-tooltip.truncate.supportive="$t('mark all as read')">
          {{ $t('mark all as read') }}
        </span>
      </CommonButton>
      <CommonButton
        v-if="hasNotifications"
        class="min-w-16 shrink!"
        prefix-icon="trash3"
        @click="$emit('clear-all')"
      >
        <span v-tooltip.truncate.supportive="$t('clear all')">
          {{ $t('clear all') }}
        </span>
      </CommonButton>
    </div>
  </footer>
</template>
