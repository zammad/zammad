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
  ms: 150,
})
</script>

<template>
  <div
    v-if="loading || debouncedLoading"
    class="mt-4 flex flex-col gap-8"
    :class="{ invisible: !debouncedLoading }"
  >
    <div v-for="i in 2" :key="i" class="flex flex-col gap-4">
      <CommonSkeleton
        v-for="j in 3"
        :key="j"
        class="block rounded-lg"
        :class="{
          'h-5 w-25': j === 1,
          'h-6 w-full': j !== 1,
        }"
        :style="{ 'animation-delay': `${(i * 3 + j) * 0.1}s` }"
      />
    </div>
  </div>
  <slot v-else />
</template>
