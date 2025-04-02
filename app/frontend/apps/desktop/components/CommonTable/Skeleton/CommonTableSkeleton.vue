<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
import CommonTableRowsSkeleton from '#desktop/components/CommonTable/Skeleton/CommonTableRowsSkeleton.vue'

interface Props {
  rows?: number
}

defineProps<Props>()

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
  <div>
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
</template>
