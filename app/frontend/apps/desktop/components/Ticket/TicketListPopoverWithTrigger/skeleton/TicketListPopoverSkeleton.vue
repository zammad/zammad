<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
</script>

<template>
  <div class="flex flex-col gap-3">
    <div class="flex items-center h-9 gap-2">
      <CommonSkeleton :style="{ 'animation-delay': `${0.1}s` }" class="h-5 w-5" rounded />
      <CommonSkeleton :style="{ 'animation-delay': `${0.1}s` }" class="h-4 w-4/5" />
    </div>
    <div class="flex items-center h-9 gap-2">
      <CommonSkeleton :style="{ 'animation-delay': `${0.2}s` }" class="h-5 w-5" rounded />
      <CommonSkeleton :style="{ 'animation-delay': `${0.2}s` }" class="h-4 w-3/5" />
    </div>
    <div class="flex items-center h-9 gap-2">
      <CommonSkeleton :style="{ 'animation-delay': `${0.3}s` }" class="h-5 w-5" rounded />
      <CommonSkeleton :style="{ 'animation-delay': `${0.3}s` }" class="h-4 w-full" />
    </div>
  </div>
</template>
