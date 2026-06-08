<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useIntersectionObserver } from '@vueuse/core'
import { useTemplateRef } from 'vue'

const intersecting = defineModel<boolean>({
  required: false,
  default: false,
})

useIntersectionObserver(
  useTemplateRef('indicator'),
  ([{ isIntersecting }]) => {
    intersecting.value = isIntersecting
  },
  {
    threshold: 0.1,
  },
)
</script>

<template>
  <div ref="indicator">
    <slot />
  </div>
</template>
