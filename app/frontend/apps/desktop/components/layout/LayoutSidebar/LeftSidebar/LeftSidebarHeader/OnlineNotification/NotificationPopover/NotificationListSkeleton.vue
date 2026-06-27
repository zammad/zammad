<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
</script>

<template>
  <div class="grid grid-cols-[min-content_1fr] items-center gap-x-2">
    <CommonSkeleton rounded class="row-span-2 aspect-square size-8" />
    <CommonSkeleton class="col-start-2 h-3 w-full max-w-3xs" />
    <CommonSkeleton class="col-start-2 h-2 w-full max-w-1/4" />
  </div>
</template>
