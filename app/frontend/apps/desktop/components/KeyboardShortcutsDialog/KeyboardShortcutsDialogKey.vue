<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  displayKey: string
}>()

const ARROW_KEYS: Record<string, { icon: string; label: string }> = {
  arrowup: { icon: 'caret-up-fill', label: '▲' },
  arrowdown: { icon: 'caret-down-fill', label: '▼' },
  arrowleft: { icon: 'caret-left-fill', label: '◀' },
  arrowright: { icon: 'caret-right-fill', label: '▶' },
}

const arrow = computed(() => ARROW_KEYS[props.displayKey])
</script>

<template>
  <kbd
    class="flex min-w-5 items-center justify-center rounded-sm border border-green-200 bg-blue-200 font-mono text-xs/snug font-bold text-normal shadow-[0_3px_0_var(--color-green-200)] dark:border-gray-200 dark:bg-gray-700 dark:shadow-[0_3px_0_var(--color-gray-200)]"
    :class="arrow ? 'p-0.5' : 'px-1.5 py-0.5'"
  >
    <template v-if="arrow">
      <CommonIcon :name="arrow.icon" size="tiny" decorative />
      <span class="sr-only">{{ arrow.label }}</span>
    </template>
    <template v-else>{{ displayKey }}</template>
  </kbd>
</template>
