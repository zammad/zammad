<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  count: number
  // Pink as long as the count is not zero.
  highlight?: boolean
}

const props = defineProps<Props>()

const isHighlighted = computed(() => props.highlight && props.count > 0)
</script>

<template>
  <span class="relative inline-flex">
    <span
      v-if="isHighlighted"
      class="absolute inset-0 animate-sonar rounded-full border-2 border-pink-500 motion-reduce:hidden"
    />
    <CommonBadge
      :variant="isHighlighted ? 'highlight' : 'custom'"
      class="pointer-events-none relative h-4.5 min-w-4.5 border-2 border-neutral-75 px-1! py-0! leading-none font-bold dark:border-gray-500"
      :class="{ 'bg-stone-200 text-white dark:bg-gray-500': !isHighlighted }"
      size="xs"
      rounded
    >
      {{ count }}
    </CommonBadge>
  </span>
</template>
