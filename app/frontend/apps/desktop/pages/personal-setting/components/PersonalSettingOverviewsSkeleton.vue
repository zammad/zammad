<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
</script>

<template>
  <div class="mb-4">
    <CommonSkeleton class="mt-0.5 mb-1 h-4 w-44" />

    <div class="rounded-lg bg-blue-200 dark:bg-gray-700">
      <ul class="flex flex-col p-1">
        <li v-for="i in 5" :key="i" class="flex min-h-9 items-start gap-2.5 rounded-lg p-2.5">
          <CommonSkeleton alternative-background class="mt-1 h-4 w-3 shrink-0" />
          <CommonSkeleton alternative-background class="h-4 grow" />
        </li>
      </ul>
    </div>

    <div class="mt-4 flex flex-col items-end">
      <CommonSkeleton class="h-8 w-36" />
    </div>
  </div>
</template>
