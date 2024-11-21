<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

interface Props {
  hasUnseenNotification: boolean
}

defineProps<Props>()

defineEmits<{
  'mark-all': []
}>()
</script>

<template>
  <header class="flex items-center justify-between gap-4 rounded-t-xl">
    <CommonLabel size="small" class="dark:text-neutral-500" tag="h3">
      {{ $t('Notifications') }}
    </CommonLabel>
    <CommonButton
      v-if="hasUnseenNotification"
      prefix-icon="lightning"
      @click="$emit('mark-all')"
    >
      {{ $t('mark all as read') }}
    </CommonButton>
  </header>
</template>
