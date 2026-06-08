<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'

import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

interface Props {
  loading?: boolean
}

const props = defineProps<Props>()

const { debouncedLoading } = useDebouncedLoading({
  isLoading: computed(() => props.loading ?? false),
})
</script>

<template>
  <div v-if="loading || debouncedLoading" :class="{ invisible: !debouncedLoading }">
    <div class="mb-2.5 space-y-2">
      <CommonSkeleton :style="{ 'animation-delay': `${0.1}s` }" class="h-5 w-full" />
      <CommonSkeleton :style="{ 'animation-delay': `${0.2}s` }" class="h-4 w-1/3" />
    </div>

    <div class="mb-2.5 space-y-2 border-b border-neutral-100 pb-2.5 dark:border-gray-900">
      <CommonSkeleton :style="{ 'animation-delay': `${0.3}s` }" class="h-4 w-1/4" />
      <div class="flex w-full items-center gap-2">
        <CommonSkeleton
          :style="{ 'animation-delay': `${0.4}s` }"
          class="h-6 w-6 shrink-0"
          rounded
        />
        <CommonSkeleton :style="{ 'animation-delay': `${0.4}s` }" class="h-6 w-1/2" />
      </div>
      <CommonSkeleton :style="{ 'animation-delay': `${0.5}s` }" class="h-4 w-1/3" />
      <div class="flex w-full items-center gap-2">
        <CommonSkeleton
          :style="{ 'animation-delay': `${0.6}s` }"
          class="h-6 w-6 shrink-0"
          rounded
        />
        <CommonSkeleton :style="{ 'animation-delay': `${0.6}s` }" class="h-6 w-3/4" />
      </div>
    </div>

    <div class="space-y-2">
      <CommonSkeleton :style="{ 'animation-delay': `${0.7}s` }" class="h-4 w-1/4" />
      <CommonSkeleton :style="{ 'animation-delay': `${0.8}s` }" class="h-6 w-1/5" />
      <CommonSkeleton :style="{ 'animation-delay': `${0.9}s` }" class="h-4 w-1/3" />
      <CommonSkeleton :style="{ 'animation-delay': `${1}s` }" class="h-6 w-1/4" />
    </div>
  </div>
  <slot v-else />
</template>
