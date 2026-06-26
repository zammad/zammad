<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
</script>

<template>
  <div class="flex flex-col gap-2">
    <div
      class="flex w-full flex-col gap-2 rounded-lg bg-blue-200 px-2.5 pt-1 pb-1.5 dark:bg-gray-700"
    >
      <div class="space-y-2">
        <CommonSkeleton alternative-background class="h-3 w-12" />
        <div class="flex items-center gap-1 px-1.5">
          <CommonSkeleton alternative-background rounded class="size-5 shrink-0" />
          <CommonSkeleton alternative-background class="h-4 w-32" />
        </div>
      </div>

      <div class="border-t border-neutral-300 dark:border-gray-900" />

      <div class="space-y-2">
        <CommonSkeleton alternative-background class="h-3 w-14" />
        <div class="flex items-center gap-1 px-1.5">
          <CommonSkeleton alternative-background rounded class="size-5 shrink-0" />
          <CommonSkeleton alternative-background class="h-4 w-40" />
        </div>
      </div>
    </div>

    <CommonSkeleton class="h-8 w-8 self-end" />
  </div>
</template>
