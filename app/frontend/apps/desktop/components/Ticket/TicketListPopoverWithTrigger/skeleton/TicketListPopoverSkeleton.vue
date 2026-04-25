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
  <div
    v-if="loading || debouncedLoading"
    class="flex flex-col gap-3"
    :class="{ invisible: !debouncedLoading }"
  >
    <div class="flex h-9 items-center gap-2">
      <CommonSkeleton :style="{ 'animation-delay': `${0.1}s` }" class="h-5 w-5" rounded />
      <CommonSkeleton :style="{ 'animation-delay': `${0.1}s` }" class="h-4 w-4/5" />
    </div>
    <div class="flex h-9 items-center gap-2">
      <CommonSkeleton :style="{ 'animation-delay': `${0.2}s` }" class="h-5 w-5" rounded />
      <CommonSkeleton :style="{ 'animation-delay': `${0.2}s` }" class="h-4 w-3/5" />
    </div>
    <div class="flex h-9 items-center gap-2">
      <CommonSkeleton :style="{ 'animation-delay': `${0.3}s` }" class="h-5 w-5" rounded />
      <CommonSkeleton :style="{ 'animation-delay': `${0.3}s` }" class="h-4 w-full" />
    </div>
  </div>
  <slot v-else />
</template>
