<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useIntersectionObserver, type UseIntersectionObserverOptions } from '@vueuse/core'
import { computed, useTemplateRef } from 'vue'

interface Props {
  options?: UseIntersectionObserverOptions
}

const props = defineProps<Props>()

const intersectionOptions = computed<UseIntersectionObserverOptions>(() => ({
  ...props.options,
  threshold: props.options?.threshold ?? 0.1,
}))

const intersecting = defineModel<boolean>({
  required: false,
  default: false,
})

useIntersectionObserver(
  useTemplateRef('indicator'),
  ([{ isIntersecting }]) => {
    intersecting.value = isIntersecting
  },
  intersectionOptions.value,
)
</script>

<template>
  <div aria-hidden="true" class="pointer-events-none relative h-0">
    <!-- We need a small height due to FIREFOX, chromium based browsers pick up the h-0 -->
    <span ref="indicator" class="absolute inset-x-0 h-px" />
  </div>
</template>
