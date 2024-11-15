<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
interface Props {
  createdAt: string
}

const { createdAt } = defineProps<Props>()
</script>

<template>
  <div
    class="flex border-neutral-100 bg-blue-50 dark:border-gray-900 dark:bg-gray-500"
  >
    <div
      class="flex-initial rounded-t-lg border border-b-0 border-neutral-100 bg-blue-200 dark:border-gray-700 dark:bg-gray-700"
    >
      <CommonLabel
        class="m-1 rounded p-1 text-black dark:text-white"
        prefix-icon="calendar-date-time"
        size="medium"
      >
        <CommonDateTime
          :date-time="createdAt"
          type="absolute"
          absolute-format="datetime"
        />
      </CommonLabel>
    </div>
  </div>
</template>
