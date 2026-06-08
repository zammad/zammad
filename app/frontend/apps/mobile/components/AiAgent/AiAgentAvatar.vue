<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  size?: 'small' | 'medium' | 'large'
}

const props = withDefaults(defineProps<Props>(), {
  size: 'small',
})

const sizeClass = computed(() => {
  switch (props.size) {
    case 'small':
      return 'w-6 h-6'
    case 'medium':
      return 'w-8 h-8'
    case 'large':
      return 'w-10 h-10'
    default:
      return 'w-8 h-8'
  }
})
</script>

<template>
  <div
    :class="sizeClass"
    class="relative rounded-full before:absolute before:inset-0 before:z-0 before:size-full before:animate-spin before:rounded-full before:bg-gradient-to-r before:from-blue before:to-pink before:[animation-duration:2s]"
  >
    <div
      :aria-label="$t('AI agent')"
      class="relative z-1 flex rounded-full border border-transparent bg-gray-600/90 bg-clip-padding p-1"
    >
      <CommonIcon class="h-full w-full text-blue" size="tiny" name="ai-agent" />
    </div>
  </div>
</template>
