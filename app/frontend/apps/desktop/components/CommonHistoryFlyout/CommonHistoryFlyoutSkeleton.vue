<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

defineProps<{
  line: number
}>()
</script>

<template>
  <div class="flex flex-col gap-2.5">
    <CommonSkeleton class="mb-3 h-3 w-full max-w-45" />

    <div class="flex items-center gap-1">
      <CommonSkeleton rounded class="aspect-square size-6 ltr:ml-2 rtl:mr-2" />
      <CommonSkeleton class="h-3 w-full max-w-30" />
    </div>

    <CommonSkeleton
      v-for="n in line"
      :key="n"
      class="h-3 max-w-xl"
      :style="{ width: `${Math.max(100 - n * 25, 25)}%` }"
    />
  </div>
</template>
