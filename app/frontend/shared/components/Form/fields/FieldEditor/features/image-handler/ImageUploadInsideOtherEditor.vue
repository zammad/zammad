<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  width?: number
  height?: number
}

const props = defineProps<Props>()

// The image itself cannot be loaded here, only a size from the content tells how big it will be.
const style = computed(() => {
  if (!props.width) return props.height ? { height: `${props.height}px` } : {}

  return {
    width: `${props.width}px`,
    aspectRatio: props.height ? `${props.width} / ${props.height}` : undefined,
    maxWidth: '100%',
  }
})
</script>

<template>
  <span
    class="inline-flex flex-col items-center justify-center gap-1 overflow-hidden bg-black px-4 py-2.5 text-white opacity-50"
    :class="{ 'min-h-24 min-w-40': !width && !height }"
    :style="style"
  >
    <CommonIcon name="image" class="text-white" />
    <CommonLabel class="text-white">{{ $t('Uploading…') }}</CommonLabel>
  </span>
</template>
