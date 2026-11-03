<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
</script>

<template>
  <div class="flex flex-col gap-3">
    <CommonSkeleton class="h-4 w-1/2" />

    <div class="flex flex-col gap-1.5">
      <CommonSkeleton class="h-3 w-16" />
      <CommonSkeleton class="h-3 w-3/4" />
    </div>

    <div class="grid grid-cols-1 gap-3 @sm:grid-cols-2">
      <div v-for="n in 4" :key="n" class="flex flex-col gap-1.5">
        <CommonSkeleton class="h-3 w-16" />
        <CommonSkeleton class="h-3 w-2/3" />
      </div>
    </div>

    <div class="flex flex-col gap-1.5">
      <CommonSkeleton class="h-3 w-16" />
      <CommonSkeleton v-for="n in 3" :key="n" class="h-3" :style="{ width: `${100 - n * 20}%` }" />
    </div>
  </div>
</template>
