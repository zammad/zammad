<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

interface Props {
  collapsed?: boolean
}

defineProps<Props>()

const labelWidths = ['w-3/4', 'w-1/2', 'w-2/3', 'w-5/6', 'w-1/2']
</script>

<template>
  <div v-if="collapsed" class="flex justify-center py-1">
    <CommonSkeleton class="h-9 w-9" />
  </div>
  <div v-else class="flex flex-col gap-1.5 p-1">
    <div
      v-for="(width, index) in labelWidths"
      :key="index"
      class="flex items-center gap-2 rounded-md px-2 py-3"
    >
      <CommonSkeleton :style="{ 'animation-delay': `${index * 0.1}s` }" class="h-4 w-4 shrink-0" />
      <CommonSkeleton
        :style="{ 'animation-delay': `${index * 0.1 + 0.05}s` }"
        :class="width"
        class="h-4"
      />
    </div>
  </div>
</template>
