<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
defineProps<{
  direction: 'start' | 'end'
}>()

defineEmits<{
  'scroll-start': [direction: 'start' | 'end']
  'scroll-stop': []
}>()
</script>

<template>
  <div
    class="group absolute top-0 z-55 flex h-full w-25 items-center justify-center"
    :class="{
      'ScrollButtonStart inset-s-0': direction === 'start',
      'ScrollButtonEnd inset-e-0': direction === 'end',
    }"
    role="button"
    tabindex="0"
    @focusin="$emit('scroll-start', direction)"
    @focusout="$emit('scroll-stop')"
    @mouseover="$emit('scroll-start', direction)"
    @mouseleave="$emit('scroll-stop')"
  >
    <div
      class="flex size-9 items-center justify-center rounded-lg bg-blue-600 text-black group-hover:bg-blue-800 group-hover:text-white dark:bg-blue-900 dark:text-white"
    >
      <CommonIcon
        :name="direction === 'start' ? 'arrow-left' : 'arrow-right'"
        size="small"
        decorative
      />
    </div>
  </div>
</template>

<style scoped>
.ScrollButtonStart {
  background: linear-gradient(270deg, rgba(237, 241, 242, 0), var(--color-blue-200));
}

.ScrollButtonEnd {
  background: linear-gradient(90deg, rgba(237, 241, 242, 0), var(--color-blue-200));
}

[data-theme='dark'] {
  .ScrollButtonStart {
    background: linear-gradient(270deg, rgba(50, 50, 52, 0), var(--color-gray-500));
  }

  .ScrollButtonEnd {
    background: linear-gradient(90deg, rgba(50, 50, 52, 0), var(--color-gray-500));
  }
}
</style>
