<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
</script>

<template>
  <div class="mb-4">
    <CommonSkeleton class="mt-0.5 mb-1 h-4 w-24" />

    <div class="rounded-lg bg-blue-200 dark:bg-gray-700">
      <div class="flex flex-row flex-wrap gap-2.5 p-2.5">
        <CommonSkeleton alternative-background rounded class="size-20" />
      </div>

      <div class="border-t border-neutral-300 dark:border-gray-900" />

      <div class="flex w-full justify-center gap-4 p-1">
        <CommonSkeleton alternative-background class="h-8 w-24" />
        <CommonSkeleton alternative-background class="h-8 w-24" />
      </div>
    </div>
  </div>
</template>
