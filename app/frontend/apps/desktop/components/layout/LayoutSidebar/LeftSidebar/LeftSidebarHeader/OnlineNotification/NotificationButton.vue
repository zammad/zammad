<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
defineEmits<{
  show: [MouseEvent]
}>()
</script>

<template>
  <button
    :aria-label="$t('Show notifications')"
    class="rounded-full outline-blue-800 focus-visible:outline"
    @click="$emit('show', $event)"
  >
    <slot />
  </button>
</template>
