<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  unseenCount?: number
}

const props = withDefaults(defineProps<Props>(), {
  unseenCount: 0,
})

defineEmits<{
  show: [MouseEvent]
}>()

const truncatedUnseenCount = computed(() => (props.unseenCount > 99 ? '99+' : props.unseenCount))
</script>

<template>
  <button
    v-bind="$attrs"
    :aria-label="$t('Show notifications')"
    class="rounded-full outline-blue-800 focus-visible:outline"
    @click="$emit('show', $event)"
  >
    <slot />
  </button>
  <CommonLabel
    v-if="unseenCount > 0"
    size="xs"
    class="pointer-events-none absolute -bottom-[3px] z-20 block rounded-full border-2 border-white bg-pink-500 px-1 py-0.5 text-center font-bold text-white! ltr:left-[54%] rtl:right-[54%] dark:border-gray-500"
    :aria-label="$t('Unseen notifications count')"
    role="status"
  >
    {{ truncatedUnseenCount }}
  </CommonLabel>
</template>
