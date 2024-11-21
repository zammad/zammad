<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
interface Props {
  unseenCount: number
}

defineProps<Props>()

defineEmits<{
  show: [MouseEvent]
}>()
</script>

<template>
  <button
    v-bind="$attrs"
    :aria-label="$t('Show notifications')"
    class="flex h-9 w-9 items-center justify-center rounded-full outline-1 outline-blue-800 focus-visible:outline"
    @click="$emit('show', $event)"
  >
    <!--  :TODO Add custom branding  -->
    <CommonIcon name="logo" class="z-10 block h-full w-full" />
  </button>
  <CommonLabel
    v-if="unseenCount > 0"
    size="xs"
    class="pointer-events-none absolute bottom-1 z-20 block min-w-4 max-w-10 truncate rounded-full border-2 border-white bg-pink-500 px-0.5 py-0.5 text-center font-bold text-white ltr:-right-0 rtl:-left-0 dark:border-gray-500"
    :aria-label="$t('Unseen notifications count')"
    role="status"
  >
    {{ unseenCount }}
  </CommonLabel>
</template>
