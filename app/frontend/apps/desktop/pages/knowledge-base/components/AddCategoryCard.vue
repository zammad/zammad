<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

const emit = defineEmits<{
  add: []
}>()
</script>

<template>
  <li
    class="flex min-h-42 flex-col items-center justify-center rounded-xl bg-blue-200 px-4 py-2.5 dark:bg-gray-500"
  >
    <CommonButton
      variant="secondary"
      size="large"
      prefix-icon="plus-square-fill"
      no-truncate
      class="whitespace-nowrap"
      @click="emit('add')"
    >
      {{ $t('Add category') }}
    </CommonButton>
  </li>
</template>
