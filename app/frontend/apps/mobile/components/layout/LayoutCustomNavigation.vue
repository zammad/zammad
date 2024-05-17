<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onBeforeUnmount, onMounted } from 'vue'

import { useCustomLayout } from './useCustomLayout.ts'

const { setCustomLayout } = useCustomLayout()

onMounted(() => {
  setCustomLayout(true)
})

onBeforeUnmount(() => {
  setCustomLayout(false)
})
</script>

<template>
  <teleport to="[data-bottom-navigation]">
    <slot />
  </teleport>
</template>
