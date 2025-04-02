<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
interface Props {
  show?: boolean
}

defineProps<Props>()
</script>

<template>
  <caption
    class="mb-2 text-left text-sm leading-snug text-gray-100 dark:text-neutral-400"
    :class="{ 'sr-only absolute': !show }"
  >
    <slot />
  </caption>
</template>
