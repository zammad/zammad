<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
</script>

<template>
  <div>
    <div class="mb-2.5 space-y-2">
      <CommonSkeleton :style="{ 'animation-delay': `${0.1}s` }" class="h-5 w-full" />
      <CommonSkeleton :style="{ 'animation-delay': `${0.2}s` }" class="h-4 w-1/3" />
    </div>

    <div class="mb-2.5 pb-2.5 space-y-2 border-b border-neutral-100 dark:border-gray-900">
      <CommonSkeleton :style="{ 'animation-delay': `${0.3}s` }" class="h-4 w-1/4" />
      <div class="flex items-center gap-2 w-full">
        <CommonSkeleton
          :style="{ 'animation-delay': `${0.4}s` }"
          class="w-6 h-6 shrink-0"
          rounded
        />
        <CommonSkeleton :style="{ 'animation-delay': `${0.4}s` }" class="h-6 w-1/2" />
      </div>
      <CommonSkeleton :style="{ 'animation-delay': `${0.5}s` }" class="h-4 w-1/3" />
      <div class="flex items-center gap-2 w-full">
        <CommonSkeleton
          :style="{ 'animation-delay': `${0.6}s` }"
          class="w-6 h-6 shrink-0"
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
</template>
