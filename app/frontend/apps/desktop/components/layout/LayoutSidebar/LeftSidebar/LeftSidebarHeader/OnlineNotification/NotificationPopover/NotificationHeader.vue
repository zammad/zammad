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
  <header class="flex items-center justify-between gap-4 rounded-t-xl">
    <CommonLabel size="small" class="dark:text-neutral-500" tag="h3">
      {{ $t('Notifications') }}
    </CommonLabel>
    <div class="flex items-center gap-2.5">
      <CommonButton v-if="hasUnseenNotification" prefix-icon="lightning" @click="$emit('mark-all')">
        {{ $t('mark all as read') }}
      </CommonButton>
      <CommonButton v-if="hasNotifications" prefix-icon="trash3" @click="$emit('clear-all')">
        {{ $t('Clear all') }}
      </CommonButton>
    </div>
  </header>
</template>
