<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
defineProps<{
  position: 'left' | 'right' | 'system'
  reaction?: Maybe<string>
}>()
</script>

<template>
  <div
    v-if="reaction"
    class="absolute bottom-0 flex w-fit translate-y-1/2 items-center gap-1"
    :class="{
      'ltr:right-3 rtl:left-3': position === 'left' || position === 'system',
      'ltr:left-3 rtl:right-3': position === 'right',
    }"
  >
    <CommonLabel
      class="cursor-default rounded-md border px-1 py-0.5"
      :class="{
        'border-neutral-100 bg-neutral-50 dark:border-gray-900 dark:bg-gray-500':
          position === 'left',
        'border-neutral-100 bg-blue-100 dark:border-gray-900 dark:bg-stone-500':
          position === 'right',
        'border-neutral-500 bg-blue-50 dark:border-neutral-500 dark:bg-gray-800':
          position === 'system',
      }"
      size="small"
      >{{ reaction }}</CommonLabel
    >
  </div>
</template>
