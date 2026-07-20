<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

withDefaults(
  defineProps<{
    index?: number
  }>(),
  {
    index: 0,
  },
)

const titleWidths = ['w-1/3', 'w-1/2', 'w-2/5', 'w-3/5', 'w-1/4']
</script>

<template>
  <li class="flex items-center gap-3 rounded-xl bg-blue-200 px-3 py-2.5 dark:bg-gray-500">
    <CommonSkeleton class="size-8" alternative-background />
    <CommonSkeleton
      class="h-3.5"
      :class="titleWidths[(index - 1) % titleWidths.length]"
      :style="{ 'animation-delay': `${((index - 1) % 3) * 0.1}s` }"
      alternative-background
    />
  </li>
</template>
