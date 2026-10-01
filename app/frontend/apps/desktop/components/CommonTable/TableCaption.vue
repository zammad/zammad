<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
interface Props {
  show?: boolean
}

defineProps<Props>()
</script>

<template>
  <caption class="mb-2 text-left text-sm/snug text-normal" :class="{ 'sr-only absolute': !show }">
    <slot />
  </caption>
</template>
