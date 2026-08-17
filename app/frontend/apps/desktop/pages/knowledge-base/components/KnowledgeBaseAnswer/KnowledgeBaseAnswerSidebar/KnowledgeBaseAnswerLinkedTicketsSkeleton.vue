<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
</script>

<template>
  <div class="flex w-full flex-col rounded-lg bg-blue-200 p-1 dark:bg-gray-700">
    <div class="flex items-center gap-2 p-2.5 px-1.5">
      <CommonSkeleton alternative-background rounded class="size-5 shrink-0" />
      <CommonSkeleton alternative-background class="h-4 w-32" />
    </div>

    <div class="flex items-center gap-2 p-2.5 px-1.5">
      <CommonSkeleton alternative-background rounded class="size-5 shrink-0" />
      <CommonSkeleton alternative-background class="h-4 w-40" />
    </div>
  </div>
</template>
