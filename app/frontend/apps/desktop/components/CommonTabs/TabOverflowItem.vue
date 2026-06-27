<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useIntersectionObserver } from '@vueuse/core'
import { ref, useTemplateRef } from 'vue'

import { useKeepAliveHooks } from '#desktop/composables/useKeepAliveHooks.ts'

interface Props {
  container: HTMLElement | null
  rootMargin: string
}

const props = defineProps<Props>()

const emit = defineEmits<{
  visible: [boolean]
}>()

const item = useTemplateRef('item')

// Start invisible to prevent flicker for the last item on overflow menu -> the observer corrects this on the first callback.
const isVisible = ref(false)

const { resume, pause } = useIntersectionObserver(
  item,
  ([{ isIntersecting }]) => {
    isVisible.value = isIntersecting
    emit('visible', isIntersecting)
  },
  {
    root: () => props.container,
    rootMargin: props.rootMargin,
    threshold: 1,
  },
)

useKeepAliveHooks({
  onDeactivated: pause,
  onReactivated: resume,
})
</script>

<template>
  <li ref="item" :class="{ 'pointer-events-none invisible': !isVisible }">
    <slot />
  </li>
</template>
