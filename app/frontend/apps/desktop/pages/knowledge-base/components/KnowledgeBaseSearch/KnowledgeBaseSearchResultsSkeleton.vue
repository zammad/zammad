<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

withDefaults(
  defineProps<{
    count?: number
  }>(),
  {
    count: 3,
  },
)

const titleWidths = ['w-1/3', 'w-1/2', 'w-2/5', 'w-3/5', 'w-1/4']
</script>

<template>
  <ol class="flex flex-col gap-4" aria-hidden="true">
    <li
      v-for="index in count"
      :key="index"
      class="flex items-start gap-3 rounded-xl bg-blue-200 px-3 py-2.5 dark:bg-gray-500"
    >
      <CommonSkeleton class="size-8" alternative-background />
      <div
        class="flex grow flex-col gap-2 py-1"
        :style="{ 'animation-delay': `${((index - 1) % 3) * 0.1}s` }"
      >
        <CommonSkeleton
          class="h-3.5"
          :class="titleWidths[(index - 1) % titleWidths.length]"
          alternative-background
        />
        <CommonSkeleton class="h-3 w-4/5" alternative-background />
        <CommonSkeleton class="h-3 w-1/4" alternative-background />
      </div>
    </li>
  </ol>
</template>
