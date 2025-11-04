<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
</script>

<template>
  <div>
    <div class="grid grid-cols-[max-content_1fr] grid-rows-2 gap-2">
      <!--   :TODO label for screen reader? or to many translation strings    -->
      <CommonSkeleton
        :style="{ 'animation-delay': `${0.1}s` }"
        class="row-span-2 h-12.5 w-12.5 space-y-2"
        rounded
      />
      <CommonSkeleton :style="{ 'animation-delay': `${0.1}s` }" class="h-6 w-full" />
      <CommonSkeleton :style="{ 'animation-delay': `${0.3}s` }" class="h-4 w-1/2" />
    </div>

    <div class="mb-2.5 space-y-2 border-b border-white pb-2.5 dark:border-black">
      <CommonSkeleton :style="{ 'animation-delay': `${0.4}s` }" class="h-4 w-1/2" />
      <CommonSkeleton :style="{ 'animation-delay': `${0.5}s` }" class="h-5 w-full" />
      <CommonSkeleton :style="{ 'animation-delay': `${0.6}s` }" class="h-4 w-1/2" />
    </div>

    <div class="space-y-2">
      <CommonSkeleton :style="{ 'animation-delay': `${0.7}s` }" class="h-4 w-1/2" />
      <CommonSkeleton :style="{ 'animation-delay': `${0.8}s` }" class="h-6 w-full" />
      <CommonSkeleton :style="{ 'animation-delay': `${0.9}s` }" class="h-6 w-full" />
      <CommonSkeleton :style="{ 'animation-delay': `${1}s` }" class="h-6 w-full" />
    </div>
  </div>
</template>
