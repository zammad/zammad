<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'

import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
import CommonTableRowsSkeleton from '#desktop/components/CommonTable/Skeleton/CommonTableRowsSkeleton.vue'

interface Props {
  rows?: number
  loading?: boolean
  loadingNewPage?: boolean
}

const props = defineProps<Props>()

const { debouncedLoading } = useDebouncedLoading({
  isLoading: computed(() => !!props.loading && !props.loadingNewPage),
})

const headerClasses = {
  1: 'w-5 flex-shrink-0',
  2: 'w-36',
  3: 'w-5',
  4: 'w-24',
  5: 'w-16',
  6: 'w-20',
  7: 'w-32',
}
</script>

<template>
  <template v-if="loading !== undefined">
    <div v-if="loading || debouncedLoading" :class="{ invisible: !debouncedLoading }">
      <div class="flex justify-between gap-3 px-2.5 py-3">
        <CommonSkeleton
          v-for="n in 7"
          :key="n"
          :style="{ 'animation-delay': `${n * 0.1}s` }"
          class="h-3"
          :class="headerClasses[n as keyof typeof headerClasses]"
        />
      </div>
      <CommonTableRowsSkeleton :rows="rows || 10" />
    </div>
    <slot v-else />
  </template>
  <template v-else>
    <div class="flex justify-between gap-3 px-2.5 py-3">
      <CommonSkeleton
        v-for="n in 7"
        :key="n"
        :style="{ 'animation-delay': `${n * 0.1}s` }"
        class="h-3"
        :class="headerClasses[n as keyof typeof headerClasses]"
      />
    </div>
    <CommonTableRowsSkeleton :rows="rows || 10" />
  </template>
</template>
